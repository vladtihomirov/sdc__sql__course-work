-- Top 10 popular flights
with airoport_naming as (
    SELECT
        a.airport_id,
        CONCAT(a.airport_name, ' (', city.name, ', ', country.name, ')') as full_name
    FROM olap.dim_airport a
    JOIN olap.dim_city city USING(city_id)
    JOIN olap.dim_country country USING(country_id)
)
SELECT
    main.flight_number,
    main.popularity_index,
    departure_airport.full_name as departure_airport,
    arrival_airport.full_name as arrival_airport
FROM olap.fact_flight main
JOIN airoport_naming arrival_airport on main.arrival_airport_id = arrival_airport.airport_id
JOIN airoport_naming departure_airport on main.departure_airport_id = departure_airport.airport_id
ORDER BY main.popularity_index DESC
LIMIT 10
