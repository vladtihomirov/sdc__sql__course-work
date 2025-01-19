CREATE TABLE IF NOT EXISTS oltp.staging_airlines (
    airline_name  VARCHAR(100),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS oltp.staging_airports (
    airport_code CHAR(3),
    airport_name VARCHAR(100),
    city         VARCHAR(100),
    country      VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS oltp.staging_bookings (
    booking_reference varchar(20),
    passport_number   varchar(20),
    flight_number     varchar(10),
    seat_number       varchar(10),
    booking_date      timestamp,
    status            varchar(20)
);

CREATE TABLE IF NOT EXISTS oltp.staging_customers (
    passport_number varchar(20),
    first_name      varchar(50),
    last_name       varchar(50),
    email           varchar(100),
    phone_number    varchar(15)
);

CREATE TABLE IF NOT EXISTS oltp.staging_flights (
    flight_number          varchar(10),
    airline_name           varchar(100),
    departure_airport_code char(3),
    arrival_airport_code   char(3),
    departure_time         timestamp,
    arrival_time           timestamp,
    base_price             numeric(10, 2)
);

CREATE TABLE IF NOT EXISTS oltp.staging_payments (
    payment_reference VARCHAR(20),
    booking_reference VARCHAR(20),
    payment_date      TIMESTAMP,
    amount            DECIMAL(10, 2),
    payment_method    VARCHAR(20),
    payment_status    VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS oltp.staging_flight_seats (
    flight_number varchar(10),
    seat_number   varchar(10),
    seat_class    varchar(20),
    is_available  boolean
);

CREATE TABLE IF NOT EXISTS oltp.staging_services
(
    service_name VARCHAR(255),
    price        int
);

CREATE TABLE IF NOT EXISTS oltp.staging_booking_services
(
    service_name      VARCHAR(255),
    booking_reference VARCHAR(20)
);