-- Airline income
SELECT
    a.airline_name,
    CONCAT(SUM(fb.total_amount), '$') as income
FROM olap.fact_booking fb
JOIN olap.dim_booking_time dbt on dbt.time_id = fb.booking_date_id
JOIN olap.dim_flight df on df.flight_id = fb.flight_id
JOIN olap.dim_airline a on df.airline_id = a.airline_id
GROUP BY a.airline_name
ORDER BY SUM(fb.total_amount) DESC