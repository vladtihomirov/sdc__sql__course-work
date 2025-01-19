INSERT INTO oltp.airlines (airline_name, contact_email, contact_phone)
SELECT airline_name, contact_email, contact_phone
FROM oltp.staging_airlines
ON CONFLICT (airline_name) DO NOTHING;

INSERT INTO oltp.airports (airport_code, airport_name, city, country)
SELECT airport_code, airport_name, city, country
FROM oltp.staging_airports
ON CONFLICT (airport_code) DO NOTHING;

INSERT INTO oltp.flights (flight_number, airline_name, departure_airport_code, arrival_airport_code, departure_time, arrival_time, base_price)
SELECT flight_number, airline_name, departure_airport_code, arrival_airport_code, departure_time, arrival_time, base_price
FROM oltp.staging_flights
ON CONFLICT (flight_number) DO NOTHING;

INSERT INTO oltp.flight_seats (flight_number, seat_number, seat_class, is_available)
SELECT flight_number, seat_number, seat_class, is_available
FROM oltp.staging_flight_seats
ON CONFLICT (flight_number, seat_number) DO NOTHING;

INSERT INTO oltp.customers (passport_number, first_name, last_name, email, phone_number)
SELECT passport_number, first_name, last_name, email, phone_number
FROM oltp.staging_customers
ON CONFLICT (passport_number) DO NOTHING;

INSERT INTO oltp.bookings (booking_reference, passport_number, flight_number, seat_number, booking_date, status)
SELECT booking_reference, passport_number, flight_number, seat_number, booking_date, status
FROM oltp.staging_bookings
ON CONFLICT (booking_reference) DO NOTHING;

INSERT INTO oltp.payments (payment_reference, booking_reference, payment_date, amount, payment_method, payment_status)
SELECT payment_reference, booking_reference, payment_date, amount, payment_method, payment_status
FROM oltp.staging_payments
ON CONFLICT (payment_reference) DO NOTHING;

INSERT INTO oltp.services (service_name, price)
SELECT service_name, price
FROM oltp.staging_services
ON CONFLICT (service_name) DO NOTHING;

INSERT INTO oltp.booking_services (service_name, booking_reference)
SELECT service_name, booking_reference
FROM oltp.staging_booking_services
ON CONFLICT (service_name, booking_reference) DO NOTHING;
