INSERT INTO customers
SELECT
    i,
    'Customer ' || lpad(i::VARCHAR, 3, '0'),
    'customer' || i::VARCHAR || '@example.test',
    DATE '2023-01-01' + ((i * 7) % 700)::INTEGER,
    CASE i % 5 WHEN 0 THEN 'North' WHEN 1 THEN 'South' WHEN 2 THEN 'East' WHEN 3 THEN 'West' ELSE 'Central' END
FROM range(1, 121) t(i);

INSERT INTO products
SELECT
    i,
    'Product ' || lpad(i::VARCHAR, 2, '0'),
    CASE i % 4 WHEN 0 THEN 'Electronics' WHEN 1 THEN 'Home' WHEN 2 THEN 'Sports' ELSE 'Books' END,
    (15 + ((i * 17) % 180))::DECIMAL(12, 2)
FROM range(1, 21) t(i);

INSERT INTO orders
SELECT
    i,
    1 + ((i * 13) % 120),
    DATE '2024-01-01' + ((i * 3) % 730)::INTEGER,
    CASE WHEN i % 29 = 0 THEN 'refunded' WHEN i % 17 = 0 THEN 'cancelled' ELSE 'completed' END
FROM range(1, 601) t(i);

INSERT INTO order_items
SELECT
    (o.order_id * 10) + n.item_no,
    o.order_id,
    1 + ((o.order_id * 7 + n.item_no * 3) % 20),
    1 + ((o.order_id + n.item_no) % 4),
    p.unit_price
FROM orders o
CROSS JOIN (VALUES (1), (2), (3)) n(item_no)
JOIN products p ON p.product_id = 1 + ((o.order_id * 7 + n.item_no * 3) % 20)
WHERE (o.order_id + n.item_no) % 4 <> 0;

INSERT INTO payments
SELECT
    o.order_id,
    o.order_id,
    o.order_date + 1,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0),
    CASE o.status WHEN 'completed' THEN 'paid' WHEN 'refunded' THEN 'refunded' ELSE 'failed' END
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_date, o.status;
