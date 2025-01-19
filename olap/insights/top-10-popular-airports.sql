-- Top 10 popular airports
SELECT
    CONCAT(main.airport_name, ' (', city.name, ', ', country.name, ')') as full_name,
    COUNT(main.*) as count

FROM olap.dim_airport main
JOIN olap.dim_city city USING(city_id)
JOIN olap.dim_country country USING(country_id)
LEFT JOIN olap.dim_flight f on f.departure_airport_id = main.airport_id or f.arrival_airport_id = main.airport_id
GROUP BY main.airport_id, city.name, country.name
ORDER BY COUNT(main.*) DESC
LIMIT 10;
