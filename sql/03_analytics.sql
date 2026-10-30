CREATE OR REPLACE VIEW order_revenue AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    SUM(oi.quantity * oi.unit_price)::DECIMAL(14, 2) AS order_revenue,
    SUM(oi.quantity)::INTEGER AS units_sold
FROM orders o
JOIN order_items oi USING (order_id)
WHERE o.status = 'completed'
GROUP BY o.order_id, o.customer_id, o.order_date, o.status;

CREATE OR REPLACE VIEW monthly_revenue AS
WITH monthly AS (
    SELECT
        date_trunc('month', order_date)::DATE AS month,
        SUM(order_revenue)::DECIMAL(14, 2) AS revenue,
        COUNT(*) AS completed_orders,
        AVG(order_revenue)::DECIMAL(14, 2) AS average_order_value
    FROM order_revenue
    GROUP BY 1
)
SELECT
    month,
    revenue,
    completed_orders,
    average_order_value,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2
    ) AS month_over_month_growth_pct,
    SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM monthly;

CREATE OR REPLACE VIEW product_performance AS
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        COALESCE(SUM(oi.quantity) FILTER (WHERE o.order_id IS NOT NULL), 0)::INTEGER AS units_sold,
        COALESCE(SUM(oi.quantity * oi.unit_price) FILTER (WHERE o.order_id IS NOT NULL), 0)::DECIMAL(14, 2) AS revenue
    FROM products p
    LEFT JOIN order_items oi USING (product_id)
    LEFT JOIN orders o ON o.order_id = oi.order_id AND o.status = 'completed'
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS category_revenue_rank
FROM product_sales;

CREATE OR REPLACE VIEW customer_rfm AS
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.full_name,
        MAX(o.order_date) FILTER (WHERE o.status = 'completed') AS last_order_date,
        COUNT(DISTINCT o.order_id) FILTER (WHERE o.status = 'completed') AS frequency,
        COALESCE(SUM(oi.quantity * oi.unit_price) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(14, 2) AS monetary
    FROM customers c
    LEFT JOIN orders o USING (customer_id)
    LEFT JOIN order_items oi USING (order_id)
    GROUP BY c.customer_id, c.full_name
),
scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY last_order_date ASC NULLS FIRST) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary) AS monetary_score
    FROM customer_metrics
)
SELECT *,
    CASE
        WHEN frequency_score >= 4 AND monetary_score >= 4 AND recency_score >= 4 THEN 'Champions'
        WHEN frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal'
        WHEN recency_score <= 2 THEN 'At risk'
        ELSE 'Developing'
    END AS customer_segment
FROM scored;

CREATE OR REPLACE VIEW cohort_retention AS
WITH first_purchase AS (
    SELECT customer_id, date_trunc('month', MIN(order_date))::DATE AS cohort_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),
activity AS (
    SELECT DISTINCT
        o.customer_id,
        fp.cohort_month,
        date_trunc('month', o.order_date)::DATE AS activity_month,
        date_diff('month', fp.cohort_month, date_trunc('month', o.order_date)) AS months_since_first
    FROM orders o
    JOIN first_purchase fp USING (customer_id)
    WHERE o.status = 'completed'
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_customers
    FROM first_purchase
    GROUP BY cohort_month
)
SELECT
    a.cohort_month,
    a.months_since_first,
    cs.cohort_customers,
    COUNT(DISTINCT a.customer_id) AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT a.customer_id) / cs.cohort_customers, 2) AS retention_pct
FROM activity a
JOIN cohort_sizes cs USING (cohort_month)
GROUP BY a.cohort_month, a.months_since_first, cs.cohort_customers;
