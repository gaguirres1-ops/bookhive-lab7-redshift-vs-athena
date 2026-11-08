SELECT l.titulo, COUNT(*) AS sesiones, SUM(s.paginas_leidas) AS paginas
FROM sesiones_lectura s
JOIN libros l ON l.book_id = s.book_id
GROUP BY l.titulo
ORDER BY paginas DESC
LIMIT 5;

SELECT pais, COUNT(*) AS sesiones, ROUND(AVG(duracion_min), 1) AS minutos_promedio
FROM sesiones_lectura
GROUP BY pais
ORDER BY sesiones DESC;

SELECT EXTRACT(hour FROM inicio) AS hora_utc, COUNT(*) AS sesiones
FROM sesiones_lectura
GROUP BY 1
ORDER BY sesiones DESC
LIMIT 5;