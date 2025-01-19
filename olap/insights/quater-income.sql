-- Quarter income
SELECT
    CONCAT('Q', dbt.quarter, ' ', dbt.year) as month_name,
    CONCAT(SUM(fb.total_amount), '$') as income
FROM olap.fact_booking fb
JOIN olap.dim_booking_time dbt on dbt.time_id = fb.booking_date_id
GROUP BY dbt.quarter, dbt.year
ORDER BY dbt.year DESC, dbt.quarter DESC
