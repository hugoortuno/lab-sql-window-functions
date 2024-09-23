-- Usar la base de datos sakila
USE sakila;

-- Creamos una consulta para rankear películas por su duración
SET @rank = 0;

SELECT 
    title, 
    length, 
    @rank := @rank + 1 AS ranking
FROM film
WHERE length IS NOT NULL 
  AND length > 0
ORDER BY length DESC;


-- Rankear películas por duración dentro de cada categoría de clasificación
SELECT 
    title, 
    length, 
    rating,
    RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS ranking
FROM film
WHERE length IS NOT NULL 
  AND length > 0;


-- Crear una tabla temporal con el recuento de películas por actor
WITH actor_film_count AS (
    SELECT 
        a.actor_id,
        CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
        COUNT(fa.film_id) AS total_films
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    GROUP BY a.actor_id
)
-- Seleccionamos al actor o actriz con más películas
SELECT 
    f.title, 
    af.actor_name, 
    af.total_films
FROM film f
JOIN film_actor fa ON f.film_id = fa.film_id
JOIN actor_film_count af ON fa.actor_id = af.actor_id
ORDER BY af.total_films DESC;


-- Recuperamos el número de clientes activos por mes
SELECT 
    DATE_FORMAT(r.rental_date, '%Y-%m') AS rental_month, 
    COUNT(DISTINCT r.customer_id) AS active_customers
FROM rental r
GROUP BY rental_month
ORDER BY rental_month;


WITH monthly_customers AS (
    SELECT 
        DATE_FORMAT(r.rental_date, '%Y-%m') AS rental_month, 
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM rental r
    GROUP BY rental_month
)
-- Recuperamos la cantidad de clientes del mes anterior
SELECT 
    rental_month, 
    active_customers,
    LAG(active_customers) OVER (ORDER BY rental_month) AS previous_month_customers
FROM monthly_customers;


WITH monthly_customers AS (
    SELECT 
        DATE_FORMAT(r.rental_date, '%Y-%m') AS rental_month, 
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM rental r
    GROUP BY rental_month
)
-- Calculamos el cambio porcentual en el número de clientes activos
SELECT 
    rental_month, 
    active_customers,
    LAG(active_customers) OVER (ORDER BY rental_month) AS previous_month_customers,
    ROUND(((active_customers - LAG(active_customers) OVER (ORDER BY rental_month)) / LAG(active_customers) OVER (ORDER BY rental_month)) * 100, 2) AS percent_change
FROM monthly_customers;


WITH current_month_customers AS (
    SELECT 
        DATE_FORMAT(r.rental_date, '%Y-%m') AS rental_month, 
        r.customer_id
    FROM rental r
),
previous_month_customers AS (
    SELECT 
        DATE_FORMAT(r.rental_date, '%Y-%m') AS rental_month, 
        r.customer_id
    FROM rental r
)
-- Calculamos los clientes que repiten en ambos meses
SELECT 
    cm.rental_month, 
    COUNT(DISTINCT cm.customer_id) AS retained_customers
FROM current_month_customers cm
JOIN previous_month_customers pm ON cm.customer_id = pm.customer_id 
  AND cm.rental_month = DATE_ADD(pm.rental_month, INTERVAL 1 MONTH)
GROUP BY cm.rental_month;
