import argparse
import statistics
import sys
import time
from concurrent.futures import ThreadPoolExecutor

REGION = "us-east-2"
ATHENA_WORKGROUP = "lab-athena"
ATHENA_DB = "bookhive_lab"
REDSHIFT_WORKGROUP = "lab-bookhive"
REDSHIFT_DB = "dev"


def leer_sentencias(ruta, bucket):
    texto = open(ruta, encoding="utf-8").read().replace("{BUCKET}", bucket)
    texto = "\n".join(l for l in texto.splitlines() if not l.strip().startswith("--"))
    return [s.strip() for s in texto.split(";") if s.strip()]


def ejecutar_athena(sql):
    import boto3
    c = boto3.client("athena", region_name=REGION)
    t0 = time.time()
    qid = c.start_query_execution(
        QueryString=sql, WorkGroup=ATHENA_WORKGROUP,
        QueryExecutionContext={"Database": ATHENA_DB})["QueryExecutionId"]
    while True:
        q = c.get_query_execution(QueryExecutionId=qid)["QueryExecution"]
        estado = q["Status"]["State"]
        if estado in ("SUCCEEDED", "FAILED", "CANCELLED"):
            break
        time.sleep(0.5)
    if estado != "SUCCEEDED":
        raise RuntimeError(q["Status"].get("StateChangeReason", estado))
    return time.time() - t0, q["Statistics"].get("DataScannedInBytes", 0)


def ejecutar_redshift(sql):
    import boto3
    c = boto3.client("redshift-data", region_name=REGION)
    t0 = time.time()
    sid = c.execute_statement(WorkgroupName=REDSHIFT_WORKGROUP, Database=REDSHIFT_DB, Sql=sql)["Id"]
    while True:
        d = c.describe_statement(Id=sid)
        estado = d["Status"]
        if estado in ("FINISHED", "FAILED", "ABORTED"):
            break
        time.sleep(0.5)
    if estado != "FINISHED":
        raise RuntimeError(d.get("Error", estado))
    return time.time() - t0, 0


def main():
    ap = argparse.ArgumentParser(description="Ejecuta un archivo .sql en Athena o Redshift Serverless y mide los tiempos")
    ap.add_argument("--engine", choices=["athena", "redshift"], required=True)
    ap.add_argument("--sql", required=True)
    ap.add_argument("--bucket", default="", help="reemplaza {BUCKET} dentro del .sql")
    ap.add_argument("--rondas", type=int, default=1, help="veces que se repite cada sentencia")
    ap.add_argument("--concurrencia", type=int, default=1, help="consumidores en paralelo")
    a = ap.parse_args()

    ejecutar = ejecutar_athena if a.engine == "athena" else ejecutar_redshift
    sentencias = leer_sentencias(a.sql, a.bucket)
    tareas = [(i, s) for _ in range(a.rondas) for i, s in enumerate(sentencias, start=1)]

    def correr(t):
        i, sql = t
        try:
            seg, bytes_escaneados = ejecutar(sql)
            return i, seg, bytes_escaneados, None
        except Exception as e:
            return i, 0.0, 0, str(e)

    inicio = time.time()
    with ThreadPoolExecutor(max_workers=a.concurrencia) as pool:
        resultados = list(pool.map(correr, tareas))
    total = time.time() - inicio

    print(f"\nMotor: {a.engine} | archivo: {a.sql} | rondas: {a.rondas} | consumidores en paralelo: {a.concurrencia}")
    print(f"{'sentencia':<10}{'ok/total':<10}{'min s':>8}{'prom s':>8}{'max s':>8}{'MB escan.':>11}")
    errores = 0
    for i in range(1, len(sentencias) + 1):
        filas = [r for r in resultados if r[0] == i]
        ok = [r for r in filas if r[3] is None]
        errores += len(filas) - len(ok)
        if ok:
            tiempos = [r[1] for r in ok]
            mb = sum(r[2] for r in ok) / 1_000_000
            print(f"{'#' + str(i):<10}{f'{len(ok)}/{len(filas)}':<10}{min(tiempos):>8.2f}"
                  f"{statistics.mean(tiempos):>8.2f}{max(tiempos):>8.2f}{mb:>11.2f}")
        for r in filas:
            if r[3]:
                print(f"  ERROR en sentencia #{i}: {r[3]}")
    print(f"Tiempo total de pared: {total:.1f} s")
    sys.exit(1 if errores else 0)


if __name__ == "__main__":
    main()