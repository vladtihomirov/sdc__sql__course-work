-- Updating contact info on conflict
INSERT INTO olap.dim_airline (airline_name, contact_email, contact_phone)
SELECT DISTINCT airline_name, contact_email, contact_phone
FROM oltp.airlines
ON CONFLICT (airline_name) DO UPDATE
    SET contact_email = excluded.contact_email,
        contact_phone = excluded.contact_phone;

-- Countries has only name and it is unique, so on conflict we do nothing
INSERT INTO olap.dim_country (name)
SELECT DISTINCT country
FROM oltp.airports
ON CONFLICT (name) DO NOTHING;

-- If somehow country changes - we update on conflict
INSERT INTO olap.dim_city (name, country_id)
SELECT DISTINCT a.city, dc.country_id
FROM oltp.airports a
         JOIN olap.dim_country dc ON dc.name = a.country
ON CONFLICT (name) DO UPDATE
    SET country_id = excluded.country_id;

-- Updating airport_name and city_id if needed
INSERT INTO olap.dim_airport (airport_code, airport_name, city_id)
SELECT DISTINCT airport_code, airport_name, dc.city_id
FROM oltp.airports a
         JOIN olap.dim_city dc ON dc.name = a.city
ON CONFLICT (airport_code) DO UPDATE
    SET airport_name = excluded.airport_name,
        city_id      = excluded.city_id;

-- Only adding new once, no need to update
INSERT INTO olap.dim_payment_method (name)
SELECT DISTINCT payment_method
FROM oltp.payments
ON CONFLICT (name) DO NOTHING;

-- Only adding new once, no need to update
INSERT INTO olap.dim_payment_status (name)
SELECT DISTINCT payment_status
FROM oltp.payments
ON CONFLICT (name) DO NOTHING;

-- Only adding new once, no need to update
INSERT INTO olap.dim_flight_booking_status (name)
SELECT DISTINCT status
FROM oltp.bookings
ON CONFLICT (name) DO NOTHING;

-- Creating upsert function for customer info
create function upsert_customer(i_passport_number character varying, i_first_name character varying,
                                i_last_name character varying, i_email character varying,
                                i_phone_number character varying) RETURNS void
    LANGUAGE plpgsql
AS
$$
BEGIN
    -- Check if customer info does not changed
    IF EXISTS(SELECT 1
              FROM olap.dim_customer
              WHERE passport_number = i_passport_number
                AND first_name = i_first_name
                AND email = i_email
                AND last_name = i_last_name
                ANd phone_number = i_phone_number) THEN
        RAISE WARNING  'Skipping update for passport_number: %, no changes detected.', i_passport_number;
        RETURN;
    END IF;

    -- Check if a customer with the given passport number exists
    IF (EXISTS (SELECT 1
                FROM olap.dim_customer
                WHERE passport_number = i_passport_number)) THEN
        -- Update the `ts_finished` timestamp for the existing record
        UPDATE olap.dim_customer
        SET ts_finished = now()
        WHERE passport_number = i_passport_number
          AND ts_finished IS NULL;

        -- Insert a new row with the new values and `ts_created` as now
        INSERT INTO olap.dim_customer (passport_number,
                                       first_name,
                                       last_name,
                                       email,
                                       phone_number,
                                       ts_created,
                                       ts_finished)
        VALUES (i_passport_number,
                i_first_name,
                i_last_name,
                i_email,
                i_phone_number,
                now(),
                NULL);
    ELSE
        -- If no record exists, insert a new row
        INSERT INTO olap.dim_customer (passport_number,
                                       first_name,
                                       last_name,
                                       email,
                                       phone_number,
                                       ts_created,
                                       ts_finished)
        VALUES (i_passport_number,
                i_first_name,
                i_last_name,
                i_email,
                i_phone_number,
                now(),
                NULL);
    END IF;
END;
$$;

-- Bulk upsert customers
DO
$$
    DECLARE
        customer_record RECORD;
    BEGIN
        FOR customer_record IN
            SELECT passport_number, first_name, last_name, email, phone_number
            FROM oltp.customers
            LOOP
                PERFORM upsert_customer(
                        customer_record.passport_number,
                        customer_record.first_name,
                        customer_record.last_name,
                        customer_record.email,
                        customer_record.phone_number
                        );
            END LOOP;
    END;
$$ LANGUAGE plpgsql;

INSERT INTO olap.dim_booking_time (date, day_of_week, month, quarter, year)
SELECT DISTINCT booking_date::DATE,
                TO_CHAR(booking_date, 'Day'),
                EXTRACT(MONTH FROM booking_date),
                EXTRACT(QUARTER FROM booking_date),
                EXTRACT(YEAR FROM booking_date)
FROM oltp.bookings
ON CONFLICT (date) DO NOTHING;

INSERT INTO olap.dim_arrive_time (date, day_of_week, month, quarter, year)
SELECT DISTINCT arrival_time::DATE,
                TO_CHAR(arrival_time, 'Day'),
                EXTRACT(MONTH FROM arrival_time),
                EXTRACT(QUARTER FROM arrival_time),
                EXTRACT(YEAR FROM arrival_time)
FROM oltp.flights
ON CONFLICT (date) DO NOTHING;

INSERT INTO olap.dim_departure_time (date, day_of_week, month, quarter, year)
SELECT DISTINCT departure_time::DATE,
                TO_CHAR(departure_time, 'Day'),
                EXTRACT(MONTH FROM departure_time),
                EXTRACT(QUARTER FROM departure_time),
                EXTRACT(YEAR FROM arrival_time)
FROM oltp.flights
ON CONFLICT (date) DO NOTHING;

-- On conflict updating airline_id, departure_airport_id, arrival_airport_id in case something changed during the flight
INSERT INTO olap.dim_flight (airline_id, departure_airport_id, arrival_airport_id, departure_date, arrival_date,
                             flight_number)
SELECT a.airline_id,
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
         JOIN olap.dim_arrive_time arr_time ON arr_time.date = f.arrival_time::DATE
ON CONFLICT (flight_number, departure_date, arrival_date) DO UPDATE
    SET airline_id           = excluded.airline_id,
        departure_airport_id = excluded.departure_airport_id,
        arrival_airport_id   = excluded.arrival_airport_id;

-- On conflict updating fields if customer changed booking
INSERT INTO olap.fact_booking (customer_id, flight_id, booking_date_id, payment_method_id, payment_status_id,
                               flight_booking_status_id, seat_number, total_amount)
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
group by c.customer_id, f.flight_id, boo.time_id, pm.payment_method_id, ps.payment_status_id,
         fbs.flight_booking_status_id, b.seat_number
ON CONFLICT (customer_id, flight_id, booking_date_id) DO UPDATE
    SET payment_method_id        = excluded.payment_method_id,
        payment_status_id        = excluded.payment_status_id,
        flight_booking_status_id = excluded.flight_booking_status_id,
        seat_number              = excluded.seat_number,
        total_amount             = excluded.total_amount;

-- On conflict updating airline_id, departure_airport_id, arrival_airport_id in case something changed during the flight
INSERT INTO olap.fact_flight (airline_id, departure_airport_id, arrival_airport_id, departure_date, arrival_date,
                              flight_number, total_seats, available_seats, sold_seats, is_first_class_full,
                              popularity_index)
SELECT a.airline_id,
       dep_airport.airport_id,
       arr_airport.airport_id,
       dep_time.time_id                                                                  AS departure_date,
       arr_time.time_id                                                                  AS arrival_date,
       f.flight_number,
       COUNT(fs.seat_number)                                                             AS total_seats,
       COUNT(CASE WHEN fs.is_available THEN 1 END)                                       AS available_seats,
       COUNT(CASE WHEN b.status = 'Confirmed' THEN 1 END)                                AS sold_seats,
       COUNT(CASE WHEN fs.is_available AND fs.seat_class = 'First Class' THEN 1 END) > 0 AS is_first_class_full,
       CASE
           WHEN
               COUNT(fs.seat_number) > 0
               THEN ROUND(
                   ((COUNT(fs.seat_number) - COUNT(CASE WHEN fs.is_available THEN 1 END))::float /
                    COUNT(fs.seat_number)::float)::numeric,
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
GROUP BY a.airline_id, dep_airport.airport_id, arr_airport.airport_id, dep_time.time_id, arr_time.time_id,
         f.flight_number
ON CONFLICT (flight_number, departure_date, arrival_date) DO UPDATE
    SET airline_id           = excluded.airline_id,
        departure_airport_id = excluded.departure_airport_id,
        arrival_airport_id   = excluded.arrival_airport_id;

