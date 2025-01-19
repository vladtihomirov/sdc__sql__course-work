-- Quarter income
SELECT
    CONCAT('Q', EXTRACT(QUARTER FROM b.booking_date), ' ', EXTRACT(YEAR FROM b.booking_date)) AS quarter_name,
    CONCAT(SUM(p.amount), '$') AS income
FROM oltp.payments p
JOIN oltp.bookings b ON p.booking_reference = b.booking_reference
WHERE p.payment_status = 'Success'
GROUP BY EXTRACT(QUARTER FROM b.booking_date), EXTRACT(YEAR FROM b.booking_date)
ORDER BY EXTRACT(YEAR FROM b.booking_date) DESC, EXTRACT(QUARTER FROM b.booking_date) DESC;
