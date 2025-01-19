-- Airline income
SELECT
    a.airline_name,
    CONCAT(SUM(p.amount), '$') AS income
FROM oltp.payments p
JOIN oltp.bookings b ON p.booking_reference = b.booking_reference
JOIN oltp.flights f ON b.flight_number = f.flight_number
JOIN oltp.airlines a ON f.airline_name = a.airline_name
WHERE p.payment_status = 'Success'
GROUP BY a.airline_name
ORDER BY SUM(p.amount) DESC;