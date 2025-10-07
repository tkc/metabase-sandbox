CREATE SCHEMA IF NOT EXISTS sales;

DROP TABLE IF EXISTS sales.order_items;
DROP TABLE IF EXISTS sales.orders;
DROP TABLE IF EXISTS sales.products;
DROP TABLE IF EXISTS sales.customers;

CREATE TABLE sales.customers (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    city VARCHAR,
    state VARCHAR,
    joined_at DATE
);

CREATE TABLE sales.products (
    product_id INTEGER PRIMARY KEY,
    name VARCHAR,
    category VARCHAR,
    price DECIMAL(10,2)
);

CREATE TABLE sales.orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES sales.customers(customer_id),
    order_date DATE,
    status VARCHAR
);

CREATE TABLE sales.order_items (
    order_id INTEGER REFERENCES sales.orders(order_id),
    product_id INTEGER REFERENCES sales.products(product_id),
    quantity INTEGER,
    unit_price DECIMAL(10,2)
);

INSERT INTO sales.customers VALUES
 (1, 'Aiko', 'Suzuki', 'aiko.suzuki@example.com', 'Tokyo', 'Tokyo', DATE '2021-01-12'),
 (2, 'Daichi', 'Tanaka', 'daichi.tanaka@example.com', 'Osaka', 'Osaka', DATE '2021-03-22'),
 (3, 'Haruka', 'Yamada', 'haruka.yamada@example.com', 'Nagoya', 'Aichi', DATE '2021-05-05'),
 (4, 'Kenta', 'Watanabe', 'kenta.watanabe@example.com', 'Fukuoka', 'Fukuoka', DATE '2022-02-17'),
 (5, 'Mika', 'Kobayashi', 'mika.kobayashi@example.com', 'Sapporo', 'Hokkaido', DATE '2022-07-19');

INSERT INTO sales.products VALUES
 (1, 'Noise Cancelling Headphones', 'Electronics', 299.99),
 (2, 'Ergonomic Keyboard', 'Electronics', 129.50),
 (3, 'Standing Desk', 'Furniture', 549.00),
 (4, '4K Monitor', 'Electronics', 449.99),
 (5, 'Task Chair', 'Furniture', 239.00);

INSERT INTO sales.orders VALUES
 (1, 1, DATE '2023-01-10', 'completed'),
 (2, 2, DATE '2023-01-12', 'completed'),
 (3, 3, DATE '2023-02-05', 'completed'),
 (4, 4, DATE '2023-02-20', 'completed'),
 (5, 5, DATE '2023-03-02', 'processing'),
 (6, 1, DATE '2023-03-15', 'completed'),
 (7, 2, DATE '2023-03-18', 'completed'),
 (8, 3, DATE '2023-04-06', 'completed'),
 (9, 4, DATE '2023-04-22', 'completed'),
 (10, 5, DATE '2023-05-01', 'completed');

INSERT INTO sales.order_items VALUES
 (1, 1, 1, 299.99),
 (1, 2, 1, 129.50),
 (2, 3, 1, 549.00),
 (3, 4, 2, 449.99),
 (4, 5, 1, 239.00),
 (5, 2, 1, 129.50),
 (6, 1, 1, 299.99),
 (7, 2, 2, 129.50),
 (8, 4, 1, 449.99),
 (9, 5, 1, 239.00),
 (10, 3, 1, 549.00);
