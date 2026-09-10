/*

Customer Report
=
Purpose:
- This report consolidates key customer metrics and behaviors

Highlights:
1. Gathers essential fields such as names, ages, and transaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
    - total orders
    - total sales
    - total quantity purchased
    - total products
    - lifespan (in months)
4. Calculates valuable KPIs:
    - recency (months since last order)
    - average order value
    - average monthly spend
*/
-- Recreate the view so customer metrics use the current report definition.
DROP VIEW IF EXISTS gold.customer_report;
GO

CREATE VIEW gold.customer_report AS

-- Keep valid dated transactions and attach customer identity and age information.
WITH base_query AS (
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.frist_name,' ',c.last_name) as customer_name,
        DATEDIFF(YEAR,c.birthdate,GETDATE()) as age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customer c
    ON c.customer_key = f.customer_key
    WHERE order_date IS NOT NULL
),

-- Aggregate transaction-level rows into one analytical row per customer.
customer_aggr AS (
    SELECT 
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) as total_orders,
        SUM(sales) as total_sales,
        SUM(quantity) as total_quantity,
        MAX(order_date) last_customer_order,
        DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY 
        customer_key,
        customer_number,
        customer_name,
        age
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    -- Age bands make customer demographics easier to compare in summaries.
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age between 20 and 29 THEN '20-29'
        WHEN age between 30 and 39 THEN '30-39'
        WHEN age between 40 and 49 THEN '40-49'
    ELSE '50 and above'
    END AS age_group,
    total_orders,
    total_sales,
    total_quantity,
    last_customer_order,
    lifespan,
    DATEDIFF(MONTH,last_customer_order,GETDATE()) as recency,
    -- Segment customers using both relationship length and total spending.
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales < 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segmentaion,
    -- Protect the ratio calculations from zero-order customers.
    CASE WHEN total_orders = 0 THEN 0 ELSE total_sales / total_orders END AS avg_order_value,
    CASE WHEN lifespan = 0 THEN total_sales ELSE total_sales / lifespan END AS avg_monthlu_spend
FROM customer_aggr

GO

-- Summarize customer activity by the spending/lifespan segment.
SELECT 
    customer_segmentaion,
     COUNT(customer_number) total_customers,
    sum(total_orders) total_orders,
    sum(total_sales) total_sales,
    sum(total_quantity) total_quantity
FROM gold.customer_report
GROUP BY customer_segmentaion
