Create SCHEMA IF NOT EXISTS oltp;

CREATE TABLE IF NOT EXISTS oltp.airlines
(
    airline_name  VARCHAR(100) PRIMARY KEY,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS oltp.airports
(
    airport_code CHAR(3) PRIMARY KEY,
    airport_name VARCHAR(100) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    country      VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.flights
(
    flight_number          VARCHAR(10) PRIMARY KEY,
    airline_name           VARCHAR(100) REFERENCES oltp.airlines (airline_name),
    departure_airport_code CHAR(3) REFERENCES oltp.airports (airport_code),
    arrival_airport_code   CHAR(3) REFERENCES oltp.airports (airport_code),
    departure_time         TIMESTAMP      NOT NULL,
    arrival_time           TIMESTAMP      NOT NULL,
    base_price             DECIMAL(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.flight_seats
(
    flight_number VARCHAR(10) REFERENCES oltp.flights (flight_number),
    seat_number   VARCHAR(10),
    seat_class    VARCHAR(20) NOT NULL CHECK (seat_class IN ('Economy', 'Business', 'First Class')),
    is_available  BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (flight_number, seat_number)
);

CREATE TABLE IF NOT EXISTS oltp.customers
(
    passport_number VARCHAR(20) PRIMARY KEY,
    first_name      VARCHAR(50)         NOT NULL,
    last_name       VARCHAR(50)         NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    phone_number    VARCHAR(15)         NOT NULL
);

CREATE TABLE IF NOT EXISTS oltp.bookings
(
    booking_reference VARCHAR(20) PRIMARY KEY,
    passport_number   VARCHAR(20) REFERENCES oltp.customers (passport_number),
    flight_number     VARCHAR(10) REFERENCES oltp.flights (flight_number),
    seat_number       VARCHAR(10),
    booking_date      TIMESTAMP DEFAULT NOW(),
    status            VARCHAR(20)    NOT NULL CHECK (status IN ('Confirmed', 'Cancelled')),
    UNIQUE (flight_number, seat_number)
);

CREATE TABLE IF NOT EXISTS oltp.payments
(
    payment_reference VARCHAR(20) PRIMARY KEY,
    booking_reference VARCHAR(20) REFERENCES oltp.bookings (booking_reference),
    payment_date      TIMESTAMP DEFAULT NOW(),
    amount            DECIMAL(10, 2) NOT NULL,
    payment_method    VARCHAR(20)    NOT NULL CHECK (payment_method IN
                                                     ('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer')),
    payment_status    VARCHAR(20)    NOT NULL CHECK (payment_status IN ('Success', 'Failed', 'Pending'))
);

CREATE TABLE IF NOT EXISTS oltp.services
(
    service_name VARCHAR(255) PRIMARY KEY,
    price        int
);

CREATE TABLE IF NOT EXISTS oltp.booking_services
(
    service_name      VARCHAR(255) REFERENCES oltp.services (service_name),
    booking_reference VARCHAR(20) REFERENCES oltp.bookings (booking_reference),
    UNIQUE (service_name, booking_reference)
);
