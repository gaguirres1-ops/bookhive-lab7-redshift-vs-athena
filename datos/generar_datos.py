#!/usr/bin/env python3
import argparse
import csv
import os
import random
from datetime import datetime, timedelta, timezone

LIBROS = [
    (1, "Don Quijote de la Mancha", "clasico", 1100),
    (2, "Frankenstein", "terror", 280),
    (3, "Dracula", "terror", 418),
    (4, "Orgullo y prejuicio", "romance", 432),
    (5, "Moby Dick", "aventura", 635),
    (6, "La Odisea", "epica", 350),
    (7, "Los miserables", "clasico", 1460),
    (8, "Anna Karenina", "romance", 864),
    (9, "Crimen y castigo", "clasico", 551),
    (10, "Alicia en el Pais de las Maravillas", "fantasia", 200),
    (11, "Platero y yo", "poesia", 150),
    (12, "Veinte mil leguas de viaje submarino", "aventura", 430),
]
PAISES = ["ES", "PE", "MX", "US", "AR", "CO", "CL", "IT", "DE", "FR"]
PESOS_PAIS = [18, 14, 14, 12, 8, 8, 6, 8, 6, 6]
DISPOSITIVOS = ["movil", "web", "tablet"]
PESOS_DISP = [60, 30, 10]
PESOS_LIBRO = [10, 7, 7, 25, 8, 6, 5, 7, 7, 8, 5, 5]
PESOS_HORA = [3 if h in (0, 1, 2, 3, 20, 21, 22, 23) else 1 for h in range(24)]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("--sesiones", type=int, default=200000)
    ap.add_argument("--usuarios", type=int, default=5000)
    ap.add_argument("--dias", type=int, default=30)
    ap.add_argument("--salida", default="datos/salida")
    ap.add_argument("--semilla", type=int, default=7)
    a = ap.parse_args()

    rng = random.Random(a.semilla)
    os.makedirs(os.path.join(a.salida, "libros"), exist_ok=True)
    os.makedirs(os.path.join(a.salida, "sesiones"), exist_ok=True)

    with open(os.path.join(a.salida, "libros", "libros.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["book_id", "titulo", "genero", "paginas_totales"])
        w.writerows(LIBROS)

    ahora = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0, tzinfo=None)
    with open(os.path.join(a.salida, "sesiones", "sesiones_lectura.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["session_id", "user_id", "pais", "book_id", "paginas_leidas",
                    "duracion_min", "dispositivo", "inicio"])
        for sid in range(1, a.sesiones + 1):
            libro = rng.choices(LIBROS, weights=PESOS_LIBRO)[0]
            dia = ahora - timedelta(days=rng.randint(0, a.dias - 1))
            inicio = dia.replace(hour=rng.choices(range(24), weights=PESOS_HORA)[0]) + timedelta(
                minutes=rng.randint(0, 59), seconds=rng.randint(0, 59))
            paginas = rng.randint(3, 60)
            w.writerow([sid, rng.randint(1, a.usuarios), rng.choices(PAISES, weights=PESOS_PAIS)[0],
                        libro[0], paginas, max(2, int(paginas * rng.uniform(0.8, 2.2))),
                        rng.choices(DISPOSITIVOS, weights=PESOS_DISP)[0],
                        inicio.strftime("%Y-%m-%d %H:%M:%S")])
    print(f"creado: {a.salida}/libros/libros.csv y {a.salida}/sesiones/sesiones_lectura.csv ({a.sesiones} sesiones)")


if __name__ == "__main__":
    main()