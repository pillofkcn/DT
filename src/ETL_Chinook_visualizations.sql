// Top song by revenue
SELECT 
    t.name AS track_name,
    SUM(f.unit_price * f.quantity) AS total_revenue
FROM fact_invoice f
JOIN dim_track t ON f.track_id = t.track_id
GROUP BY t.name
ORDER BY total_revenue DESC
LIMIT 10;

// Transactions count by days of the week
SELECT 
    CASE 
        WHEN d.day = 1 THEN 'Monday'
        WHEN d.day = 2 THEN 'Tuesday'
        WHEN d.day = 3 THEN 'Wednesday'
        WHEN d.day = 4 THEN 'Thursday'
        WHEN d.day = 5 THEN 'Friday'
        WHEN d.day = 6 THEN 'Saturday'
        WHEN d.day = 7 THEN 'Sunday'
    END AS day_of_week,
    COUNT(fi.fact_id) AS total_activity
FROM fact_invoice fi
JOIN dim_date d ON fi.date_id = d.date
GROUP BY d.day
ORDER BY d.day
LIMIT 10;

// Best employees by revenue generated
SELECT 
    e.full_name AS employee_name,
    SUM(f.unit_price * f.quantity) AS total_revenue
FROM fact_invoice f
JOIN dim_employee e ON f.employee_id = e.employee_id
GROUP BY e.full_name
ORDER BY total_revenue DESC;

// Artists by generated revenue
SELECT 
    t.artist_name AS artist,
    SUM(f.unit_price * f.quantity) AS total_revenue
FROM fact_invoice f
JOIN dim_track t ON f.track_id = t.track_id
GROUP BY t.artist_name
ORDER BY total_revenue DESC
LIMIT 10;

// Countries by generated revenue
SELECT 
    c.country,
    COUNT(f.fact_id) AS total_transactions,
    SUM(f.unit_price * f.quantity) AS total_revenue
FROM fact_invoice f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC
LIMIT 10;