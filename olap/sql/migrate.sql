INSERT INTO olap.dim_airline (airline_name, contact_email, contact_phone)
SELECT DISTINCT airline_name, contact_email, contact_phone
FROM oltp.airlines
ON CONFLICT (airline_name) DO NOTHING;

INSERT INTO olap.dim_country (name)
SELECT DISTINCT country
FROM oltp.airports
ON CONFLICT (name) DO NOTHING;

INSERT INTO olap.dim_city (name, country_id)
SELECT DISTINCT a.city, dc.country_id
FROM oltp.airports a
JOIN olap.dim_country dc ON dc.name = a.country
ON CONFLICT (name) DO NOTHING;

INSERT INTO olap.dim_airport (airport_code, airport_name, city_id)
SELECT DISTINCT airport_code, airport_name, dc.city_id
FROM oltp.airports a
JOIN olap.dim_city dc ON dc.name = a.city
ON CONFLICT (airport_code) DO NOTHING;

INSERT INTO olap.dim_payment_method (name)
SELECT DISTINCT payment_method
FROM oltp.payments;

INSERT INTO olap.dim_payment_status (name)
SELECT DISTINCT payment_status
FROM oltp.payments;

INSERT INTO olap.dim_flight_booking_status (name)
SELECT DISTINCT status
FROM oltp.bookings;

INSERT INTO olap.dim_customer (passport_number, first_name, last_name, email, phone_number, ts_finished)
SELECT passport_number, first_name, last_name, email, phone_number, null
FROM oltp.customers
ON CONFLICT (passport_number) DO NOTHING;

INSERT INTO olap.dim_booking_time (date, day_of_week, month, quarter, year)
SELECT DISTINCT
    booking_date::DATE,
    TO_CHAR(booking_date, 'Day'),
    EXTRACT(MONTH FROM booking_date),
    EXTRACT(QUARTER FROM booking_date),
    EXTRACT(YEAR FROM booking_date)
FROM oltp.bookings;

INSERT INTO olap.dim_arrive_time (date, day_of_week, month, quarter, year)
SELECT DISTINCT
    arrival_time::DATE,
    TO_CHAR(arrival_time, 'Day'),
    EXTRACT(MONTH FROM arrival_time),
    EXTRACT(QUARTER FROM arrival_time),
    EXTRACT(YEAR FROM arrival_time)
FROM oltp.flights;

INSERT INTO olap.dim_departure_time (date, day_of_week, month, quarter, year)
SELECT DISTINCT
    departure_time::DATE,
    TO_CHAR(departure_time, 'Day'),
    EXTRACT(MONTH FROM departure_time),
    EXTRACT(QUARTER FROM departure_time),
    EXTRACT(YEAR FROM arrival_time)
FROM oltp.flights;

INSERT INTO olap.dim_flight (airline_id, departure_airport_id, arrival_airport_id, departure_date, arrival_date, flight_number)
SELECT
    a.airline_id,
    dep_airport.airport_id,
    arr_airport.airport_id,
    dep_time.time_id AS departure_date,
    arr_time.time_id AS arrival_date,
    f.flight_number
FROM oltp.flights f
JOIN olap.dim_airline a ON a.airline_name = f.airline_name
JOIN olap.dim_airport dep_airport ON dep_airport.airport_code = f.departure_airport_code
JOIN olap.dim_airport arr_airport ON arr_airport.airport_code = f.arrival_airport_code
JOIN olap.dim_departure_time dep_time ON dep_time.date = f.departure_time::DATE
JOIN olap.dim_arrive_time arr_time ON arr_time.date = f.arrival_time::DATE;

INSERT INTO olap.fact_booking (customer_id, flight_id, booking_date_id, payment_method_id, payment_status_id, flight_booking_status_id, seat_number, total_amount)
SELECT c.customer_id,
       f.flight_id,
       boo.time_id   AS booking_date_id,
       pm.payment_method_id,
       ps.payment_status_id,
       fbs.flight_booking_status_id,
       b.seat_number,
       SUM(p.amount) AS total_amount
FROM oltp.bookings b
         LEFT JOIN olap.dim_customer c ON c.passport_number = b.passport_number
         LEFT JOIN olap.dim_flight f ON f.flight_number = b.flight_number
         LEFT JOIN olap.dim_booking_time boo ON boo.date = b.booking_date::DATE
         LEFT JOIN olap.dim_flight_booking_status fbs ON fbs.name = b.status
         LEFT JOIN oltp.payments p ON p.booking_reference = b.booking_reference
         LEFT JOIN olap.dim_payment_method pm ON pm.name = p.payment_method
         LEFT JOIN olap.dim_payment_status ps ON ps.name = p.payment_status
group by c.customer_id, f.flight_id, boo.time_id, pm.payment_method_id, ps.payment_status_id, fbs.flight_booking_status_id, b.seat_number;

INSERT INTO olap.fact_flight (airline_id, departure_airport_id, arrival_airport_id, departure_date, arrival_date, flight_number, total_seats, available_seats, sold_seats, is_first_class_full, popularity_index)
SELECT
    a.airline_id,
    dep_airport.airport_id,
    arr_airport.airport_id,
    dep_time.time_id AS departure_date,
    arr_time.time_id AS arrival_date,
    f.flight_number,
    COUNT(fs.seat_number) AS total_seats,
    COUNT(CASE WHEN fs.is_available THEN 1 END) AS available_seats,
    COUNT(CASE WHEN b.status = 'Confirmed' THEN 1 END) AS sold_seats,
    COUNT(CASE WHEN fs.is_available AND fs.seat_class = 'First Class' THEN 1 END) > 0 AS is_first_class_full,
    CASE WHEN
        COUNT(fs.seat_number) > 0
    THEN ROUND(
        ((COUNT(fs.seat_number) - COUNT(CASE WHEN fs.is_available THEN 1 END))::float / COUNT(fs.seat_number)::float)::numeric,
         2
    )
    ELSE 0 END
        as popularity_index
FROM oltp.flights f
LEFT JOIN oltp.flight_seats fs USING (flight_number)
LEFT JOIN oltp.bookings b USING (flight_number)
JOIN olap.dim_airline a ON a.airline_name = f.airline_name
JOIN olap.dim_airport dep_airport ON dep_airport.airport_code = f.departure_airport_code
JOIN olap.dim_airport arr_airport ON arr_airport.airport_code = f.arrival_airport_code
JOIN olap.dim_departure_time dep_time ON dep_time.date = f.departure_time::DATE
JOIN olap.dim_arrive_time arr_time ON arr_time.date = f.arrival_time::DATE
GROUP BY a.airline_id, dep_airport.airport_id, arr_airport.airport_id, dep_time.time_id, arr_time.time_id, f.flight_number;

