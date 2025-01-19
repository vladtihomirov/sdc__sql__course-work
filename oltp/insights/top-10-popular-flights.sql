-- Top 10 popular flights
WITH airport_naming AS (
    SELECT
        ap.airport_code,
        CONCAT(ap.airport_name, ' (', ap.city, ', ', ap.country, ')') AS full_name
    FROM oltp.airports ap
),
flight_popularity AS (
    SELECT
        f.flight_number,
        COUNT(fs.seat_number) AS total_seats,
        COUNT(CASE WHEN fs.is_available THEN 1 END) AS available_seats,
        COUNT(CASE WHEN b.status = 'Confirmed' THEN 1 END) AS sold_seats,
        COUNT(CASE WHEN fs.is_available AND fs.seat_class = 'First Class' THEN 1 END) = 0 AS is_first_class_full,
        CASE
            WHEN COUNT(fs.seat_number) > 0 THEN ROUND(
                ((COUNT(fs.seat_number) - COUNT(CASE WHEN fs.is_available THEN 1 END))::float / COUNT(fs.seat_number)::float)::numeric,
                2
            )
            ELSE 0
        END AS popularity_index,
        f.departure_airport_code,
        f.arrival_airport_code
    FROM oltp.flights f
    LEFT JOIN oltp.flight_seats fs ON f.flight_number = fs.flight_number
    LEFT JOIN oltp.bookings b ON f.flight_number = b.flight_number
    GROUP BY f.flight_number, f.departure_airport_code, f.arrival_airport_code
)
SELECT
    fp.flight_number,
    fp.popularity_index,
    dep_airport.full_name AS departure_airport,
    arr_airport.full_name AS arrival_airport
FROM flight_popularity fp
JOIN airport_naming dep_airport ON fp.departure_airport_code = dep_airport.airport_code
JOIN airport_naming arr_airport ON fp.arrival_airport_code = arr_airport.airport_code
ORDER BY fp.popularity_index DESC
LIMIT 10;
