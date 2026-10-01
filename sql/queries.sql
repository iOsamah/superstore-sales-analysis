-- Superstore Sales — SQL Analysis
-- Table: orders (one row per order line, loaded from data/superstore_clean.csv)

-- Q1: What are the headline KPIs?
SELECT
    ROUND(SUM(sales), 2)                              AS total_sales,
    COUNT(DISTINCT order_id)                          AS total_orders,
    COUNT(DISTINCT customer_id)                       AS total_customers,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2)   AS avg_order_value
FROM orders;

-- Q2: How did sales change year over year?
WITH yearly AS (
    SELECT year, SUM(sales) AS sales
    FROM orders
    GROUP BY year
)
SELECT
    year,
    ROUND(sales, 2) AS sales,
    ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY year))
          / LAG(sales) OVER (ORDER BY year), 1) AS yoy_growth_pct
FROM yearly
ORDER BY year;

-- Q3: What share of sales does each region contribute?
SELECT
    region,
    ROUND(SUM(sales), 2) AS sales,
    ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM orders), 1) AS share_pct
FROM orders
GROUP BY region
ORDER BY sales DESC;

-- Q4: Which are the top 3 sub-categories within each category?
WITH ranked AS (
    SELECT
        category,
        sub_category,
        SUM(sales) AS sales,
        RANK() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rnk
    FROM orders
    GROUP BY category, sub_category
)
SELECT category, sub_category, ROUND(sales, 2) AS sales, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;

-- Q5: Who are the top 10 customers, and how much of total sales do they represent?
SELECT
    customer_name,
    segment,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(sales), 2)     AS sales,
    ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM orders), 2) AS share_pct
FROM orders
GROUP BY customer_id, customer_name, segment
ORDER BY sales DESC
LIMIT 10;

-- Q6: How is revenue split across customer segments?
SELECT
    segment,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(sales), 2)        AS sales,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS sales_per_customer,
    ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM orders), 1) AS share_pct
FROM orders
GROUP BY segment
ORDER BY sales DESC;

-- Q7: How long does each shipping mode take on average?
SELECT
    ship_mode,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(AVG(julianday(ship_date) - julianday(order_date)), 1) AS avg_days_to_ship
FROM orders
GROUP BY ship_mode
ORDER BY avg_days_to_ship;

-- Q8: Which months are strongest? (seasonality across all years)
SELECT
    month,
    month_name,
    ROUND(SUM(sales), 2) AS sales,
    ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM orders), 1) AS share_pct
FROM orders
GROUP BY month, month_name
ORDER BY month;

-- Q9: How many customers came back in a later year? (retention)
WITH first_year AS (
    SELECT customer_id, MIN(year) AS first_year
    FROM orders
    GROUP BY customer_id
)
SELECT
    f.first_year                           AS cohort,
    COUNT(DISTINCT f.customer_id)          AS new_customers,
    COUNT(DISTINCT CASE WHEN o.year > f.first_year THEN o.customer_id END) AS returned_later,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.year > f.first_year THEN o.customer_id END)
          / COUNT(DISTINCT f.customer_id), 1) AS return_rate_pct
FROM first_year f
JOIN orders o ON o.customer_id = f.customer_id
WHERE f.first_year < (SELECT MAX(year) FROM orders)  -- the last year has no later year to return in
GROUP BY f.first_year
ORDER BY cohort;

-- Q10: Which states sell the least in the South region? (expansion targets)
SELECT
    state,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(sales), 2)        AS sales
FROM orders
WHERE region = 'South'
GROUP BY state
ORDER BY sales
LIMIT 5;
