-- Top 10 popular airports
SELECT
    CONCAT(a.airport_name, ' (', a.city, ', ', a.country, ')') AS full_name,
    COUNT(f.*) AS count
FROM oltp.airports a
LEFT JOIN oltp.flights f
    ON f.departure_airport_code = a.airport_code OR f.arrival_airport_code = a.airport_code
GROUP BY a.airport_code, a.airport_name, a.city, a.country
ORDER BY COUNT(f.*) DESC
LIMIT 10;
