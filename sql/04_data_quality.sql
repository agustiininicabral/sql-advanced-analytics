-- Each query returns zero rows when its check passes.
SELECT 'orphan_order_customer' AS check_name, COUNT(*) AS failures
FROM orders o LEFT JOIN customers c USING (customer_id)
WHERE c.customer_id IS NULL
HAVING COUNT(*) > 0;

SELECT 'orphan_order_item' AS check_name, COUNT(*) AS failures
FROM order_items oi
LEFT JOIN orders o USING (order_id)
LEFT JOIN products p USING (product_id)
WHERE o.order_id IS NULL OR p.product_id IS NULL
HAVING COUNT(*) > 0;

SELECT 'negative_order_item_value' AS check_name, COUNT(*) AS failures
FROM order_items
WHERE quantity <= 0 OR unit_price < 0
HAVING COUNT(*) > 0;

SELECT 'payment_reconciliation' AS check_name, COUNT(*) AS failures
FROM payments p
JOIN orders o USING (order_id)
LEFT JOIN (
    SELECT order_id, SUM(quantity * unit_price) AS expected_amount
    FROM order_items GROUP BY order_id
) oi USING (order_id)
WHERE p.amount <> COALESCE(oi.expected_amount, 0)
HAVING COUNT(*) > 0;

SELECT 'duplicate_customer_email' AS check_name, COUNT(*) AS failures
FROM (SELECT email FROM customers GROUP BY email HAVING COUNT(*) > 1) d
HAVING COUNT(*) > 0;
