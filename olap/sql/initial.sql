CREATE SCHEMA IF NOT EXISTS olap;

CREATE TABLE IF NOT EXISTS olap.dim_airline (
    airline_id SERIAL PRIMARY KEY,
    airline_name VARCHAR(100) UNIQUE NOT NULL,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS olap.dim_country (
    country_id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE
);

CREATE TABLE IF NOT EXISTS olap.dim_city (
    city_id SERIAL PRIMARY KEY,
    country_id INT REFERENCES olap.dim_country (country_id),
    name VARCHAR(255) UNIQUE
);

CREATE TABLE IF NOT EXISTS olap.dim_airport (
    airport_id SERIAL PRIMARY KEY,
    city_id INT REFERENCES olap.dim_city (city_id),
    airport_code CHAR(3) UNIQUE NOT NULL,
    airport_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS olap.dim_arrive_time (
    time_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    day_of_week VARCHAR(20),
    month INT,
    quarter INT,
    year INT
);

CREATE TABLE IF NOT EXISTS olap.dim_departure_time (
    time_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    day_of_week VARCHAR(20),
    month INT,
    quarter INT,
    year INT
);

CREATE TABLE IF NOT EXISTS olap.dim_booking_time (
    time_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    day_of_week VARCHAR(20),
    month INT,
    quarter INT,
    year INT
);

CREATE TABLE IF NOT EXISTS olap.dim_payment_method (
    payment_method_id SERIAL PRIMARY KEY,
    name  VARCHAR(20) NOT NULL CHECK (name IN ('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer'))
);

CREATE TABLE IF NOT EXISTS olap.dim_payment_status (
    payment_status_id SERIAL PRIMARY KEY,
    name  VARCHAR(20) NOT NULL CHECK (name IN ('Success', 'Failed', 'Pending'))
);

CREATE TABLE IF NOT EXISTS olap.dim_flight_booking_status (
    flight_booking_status_id SERIAL PRIMARY KEY,
    name  VARCHAR(20) NOT NULL CHECK (name IN ('Confirmed', 'Cancelled'))
);

CREATE TABLE IF NOT EXISTS olap.dim_customer (
    customer_id SERIAL PRIMARY KEY,
    passport_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    ts_created DATE NOT NULL default now(),
    ts_finished DATE
);

CREATE TABLE IF NOT EXISTS olap.dim_flight (
    flight_id SERIAL PRIMARY KEY,
    airline_id INT REFERENCES olap.dim_airline (airline_id),
    departure_airport_id INT REFERENCES olap.dim_airport (airport_id),
    arrival_airport_id INT REFERENCES olap.dim_airport (airport_id),
    departure_date INT REFERENCES olap.dim_departure_time (time_id),
    arrival_date INT REFERENCES olap.dim_arrive_time (time_id),
    flight_number VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS olap.fact_booking (
    booking_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES olap.dim_customer (customer_id),
    flight_id INT REFERENCES olap.dim_flight (flight_id),
    booking_date_id INT REFERENCES olap.dim_booking_time (time_id),
    payment_method_id INT REFERENCES olap.dim_payment_method (payment_method_id),
    payment_status_id INT REFERENCES olap.dim_payment_status (payment_status_id),
    flight_booking_status_id INT REFERENCES olap.dim_flight_booking_status (flight_booking_status_id),
    seat_number VARCHAR(10),
    total_amount DECIMAL(10, 2)
);


CREATE TABLE IF NOT EXISTS olap.fact_flight (
    flight_id SERIAL PRIMARY KEY,
    airline_id INT REFERENCES olap.dim_airline (airline_id),
    departure_airport_id INT REFERENCES olap.dim_airport (airport_id),
    arrival_airport_id INT REFERENCES olap.dim_airport (airport_id),
    departure_date INT REFERENCES olap.dim_departure_time (time_id),
    arrival_date INT REFERENCES olap.dim_arrive_time (time_id),
    flight_number VARCHAR(10),
    total_seats INT,
    available_seats INT,
    sold_seats INT,
    is_first_class_full BOOLEAN,
    popularity_index FLOAT
);