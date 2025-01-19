-- Monthly income
SELECT
    TO_CHAR(b.booking_date, 'Month YYYY') AS month_name,
    CONCAT(SUM(p.amount), '$') AS income
FROM oltp.payments p
JOIN oltp.bookings b ON p.booking_reference = b.booking_reference
WHERE p.payment_status = 'Success' -- Only consider successful payments
GROUP BY TO_CHAR(b.booking_date, 'Month YYYY'), EXTRACT(YEAR FROM b.booking_date), EXTRACT(MONTH FROM b.booking_date)
ORDER BY EXTRACT(YEAR FROM b.booking_date) DESC, EXTRACT(MONTH FROM b.booking_date) DESC;
