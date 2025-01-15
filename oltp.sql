DROP TABLE IF EXISTS payments, bookings, flight_seats, flights, customers, airports, airlines, services, booking_services CASCADE;

CREATE TABLE airlines
(
    airline_name  VARCHAR(100) PRIMARY KEY,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(15)
);

CREATE TABLE airports
(
    airport_code CHAR(3) PRIMARY KEY,
    airport_name VARCHAR(100) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    country      VARCHAR(100) NOT NULL
);

CREATE TABLE flights
(
    flight_number          VARCHAR(10) PRIMARY KEY,
    airline_name           VARCHAR(100) REFERENCES airlines (airline_name),
    departure_airport_code CHAR(3) REFERENCES airports (airport_code),
    arrival_airport_code   CHAR(3) REFERENCES airports (airport_code),
    departure_time         TIMESTAMP      NOT NULL,
    arrival_time           TIMESTAMP      NOT NULL,
    base_price             DECIMAL(10, 2) NOT NULL
);

CREATE TABLE flight_seats
(
    flight_number VARCHAR(10) REFERENCES flights (flight_number),
    seat_number   VARCHAR(10),
    seat_class    VARCHAR(20) NOT NULL CHECK (seat_class IN ('Economy', 'Business', 'First Class')),
    is_available  BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (flight_number, seat_number)
);

CREATE TABLE customers
(
    passport_number VARCHAR(20) PRIMARY KEY,
    first_name      VARCHAR(50)         NOT NULL,
    last_name       VARCHAR(50)         NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    phone_number    VARCHAR(15)         NOT NULL
);

CREATE TABLE bookings
(
    booking_reference VARCHAR(20) PRIMARY KEY,
    passport_number   VARCHAR(20) REFERENCES customers (passport_number),
    flight_number     VARCHAR(10) REFERENCES flights (flight_number),
    seat_number       VARCHAR(10),
    booking_date      TIMESTAMP DEFAULT NOW(),
    status            VARCHAR(20)    NOT NULL CHECK (status IN ('Confirmed', 'Cancelled')),
    UNIQUE (flight_number, seat_number)
);

CREATE TABLE payments
(
    payment_reference VARCHAR(20) PRIMARY KEY,
    booking_reference VARCHAR(20) REFERENCES bookings (booking_reference),
    payment_date      TIMESTAMP DEFAULT NOW(),
    amount            DECIMAL(10, 2) NOT NULL,
    payment_method    VARCHAR(20)    NOT NULL CHECK (payment_method IN
                                                     ('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer')),
    payment_status    VARCHAR(20)    NOT NULL CHECK (payment_status IN ('Success', 'Failed', 'Pending'))
);

CREATE TABLE services
(
    service_name VARCHAR(255) PRIMARY KEY,
    price        int
);

CREATE TABLE booking_services
(
    service_name      VARCHAR(255) REFERENCES services (service_name),
    booking_reference VARCHAR(20) REFERENCES bookings (booking_reference),
    UNIQUE (service_name, booking_reference)
);
