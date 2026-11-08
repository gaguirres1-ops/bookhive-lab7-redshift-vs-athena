CREATE TABLE IF NOT EXISTS libros (
  book_id          INT          NOT NULL,
  titulo           VARCHAR(100) NOT NULL,
  genero           VARCHAR(30),
  paginas_totales  INT
)
DISTSTYLE ALL
SORTKEY (book_id);

CREATE TABLE IF NOT EXISTS sesiones_lectura (
  session_id      BIGINT      NOT NULL,
  user_id         INT         NOT NULL,
  pais            CHAR(2),
  book_id         INT         NOT NULL,
  paginas_leidas  INT,
  duracion_min    INT,
  dispositivo     VARCHAR(10),
  inicio          TIMESTAMP
)
DISTKEY (book_id)
SORTKEY (inicio);

COPY libros
FROM 's3://{BUCKET}/datos/libros/libros.csv'
IAM_ROLE default
FORMAT AS CSV
IGNOREHEADER 1
REGION 'us-east-2';

COPY sesiones_lectura
FROM 's3://{BUCKET}/datos/sesiones/sesiones_lectura.csv'
IAM_ROLE default
FORMAT AS CSV
IGNOREHEADER 1
TIMEFORMAT 'auto'
REGION 'us-east-2';