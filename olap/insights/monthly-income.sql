-- Monthly income
SELECT
    CONCAT(dbt.month, ' ', dbt.year) as month_name,
    CONCAT(SUM(fb.total_amount), '$') as income
FROM olap.fact_booking fb
JOIN olap.dim_booking_time dbt on dbt.time_id = fb.booking_date_id
GROUP BY dbt.month, dbt.year
ORDER BY dbt.year DESC, dbt.month DESC