/*

Product Report
=
Purpose:
- This report consolidates key product metrics and sales behaviors

Highlights:
1. Gathers product identifiers, names, categories, costs, and product lines.
2. Aggregates product-level metrics:
    - total orders
    - total sales
    - total quantity sold
    - total customers
    - lifespan (in months)
3. Calculates valuable KPIs:
    - recency (months since last sale)
    - average order value
    - average selling price
    - product cost segment
*/

-- Recreate the view so the report always reflects the current definition.
DROP VIEW IF EXISTS gold.product_report;
GO

CREATE VIEW gold.product_report AS

-- Keep one row per valid sales transaction and enrich it with product attributes.
-- Rows without an order date cannot contribute to time-based product metrics.
WITH base_query AS (
    SELECT
        f.order_number,
        f.product_key,
        f.customer_key,
        f.order_date,
        f.sales,
        f.quantity,
        f.price,
        p.product_id,
        p.product_number,
        p.product_name,
        p.category,
        p.subcategory,
        p.maintenance,
        p.cost,
        p.product_line
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_product p
        ON p.product_key = f.product_key
    WHERE f.order_date IS NOT NULL
),

-- Roll transaction-level data up to one row per product.
-- DISTINCT counts prevent duplicate line items from overstating orders or customers.
product_aggr AS (
    SELECT
        product_key,
        product_id,
        product_number,
        product_name,
        category,
        subcategory,
        maintenance,
        cost,
        product_line,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales) AS total_sales,
        SUM(quantity) AS total_quantity,
        AVG(price) AS average_selling_price,
        MIN(order_date) AS first_sale_date,
        MAX(order_date) AS last_sale_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY
        product_key,
        product_id,
        product_number,
        product_name,
        category,
        subcategory,
        maintenance,
        cost,
        product_line
)
SELECT
    product_key,
    product_id,
    product_number,
    product_name,
    category,
    subcategory,
    maintenance,
    cost,
    product_line,
    -- Group products by cost to support price-range analysis.
    CASE
        WHEN cost < 100 THEN 'Below 100'
        WHEN cost BETWEEN 100 AND 500 THEN '100-500'
        WHEN cost BETWEEN 501 AND 1000 THEN '501-1000'
        ELSE 'Above 1000'
    END AS product_cost_segment,
    total_orders,
    total_customers,
    total_sales,
    -- Classify products by total revenue for performance comparison.
    CASE
        WHEN total_sales > 50000 THEN 'Top-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Performer'
    ELSE 'Low'
    END AS product_segment,
    total_quantity,
    average_selling_price,
    first_sale_date,
    last_sale_date,
    lifespan,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency,
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS average_order_value
FROM product_aggr;
GO

-- Summarize the product report by revenue-performance segment.
SELECT
    product_segment,
    COUNT(product_key) AS total_products,
    SUM(total_orders) AS total_orders,
    SUM(total_customers) AS total_customers,
    SUM(total_sales) AS total_sales,
    SUM(total_quantity) AS total_quantity
FROM gold.product_report
GROUP BY product_segment;

