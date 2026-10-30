CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    full_name VARCHAR NOT NULL,
    email VARCHAR NOT NULL UNIQUE,
    signup_date DATE NOT NULL,
    region VARCHAR NOT NULL
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR NOT NULL,
    category VARCHAR NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    status VARCHAR NOT NULL CHECK (status IN ('completed', 'cancelled', 'refunded'))
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id),
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12, 2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE payments (
    payment_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE REFERENCES orders(order_id),
    payment_date DATE NOT NULL,
    amount DECIMAL(14, 2) NOT NULL CHECK (amount >= 0),
    payment_status VARCHAR NOT NULL CHECK (payment_status IN ('paid', 'refunded', 'failed'))
);
