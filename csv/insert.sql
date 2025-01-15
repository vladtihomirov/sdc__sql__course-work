DROP TABLE IF EXISTS temp_customers;

CREATE TEMP TABLE temp_customers
(
    passport_number VARCHAR(20),
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    email           VARCHAR(100),
    phone_number    VARCHAR(20)
);

\COPY temp_customers (passport_number, first_name, last_name, email, phone_number) FROM '/Users/vladislav.tikhomirov/work/sdc__sql__course-work/csv/customers.csv' DELIMITER ',' CSV HEADER;

INSERT INTO customers (passport_number, first_name, last_name, email, phone_number)
SELECT passport_number, first_name, last_name, email, phone_number
FROM temp_customers;

DROP TABLE temp_customers CASCADE;
