/*
Purpose:
- Calculate a compact set of overall warehouse KPIs.
- Return the measures in a common name/value shape so they can be compared or loaded into a report.
*/

-- Transaction-level measures come from the sales fact table.
SELECT 
    'Total Sales' AS measure_name,
    CAST(SUM(sales) AS DECIMAL(18, 2)) AS value_name
FROM gold.fact_sales

UNION ALL

SELECT 
    'Total Quantity Sold',
    CAST(SUM(quantity) AS DECIMAL(18, 2))
FROM gold.fact_sales

UNION ALL

SELECT 
    'Average Selling Price',
    CAST(AVG(price) AS DECIMAL(18, 2))
FROM gold.fact_sales

UNION ALL

SELECT 
    'Total Orders',
    CAST(COUNT(DISTINCT order_number) AS DECIMAL(18, 2))
FROM gold.fact_sales

UNION ALL

SELECT 
    'Total Products',
    CAST(COUNT(product_key) AS DECIMAL(18, 2))
FROM gold.dim_product

UNION ALL

SELECT 
    'Total Customers',
    CAST(COUNT(customer_id) AS DECIMAL(18, 2))
FROM gold.dim_customer

UNION ALL

SELECT 
    'Customers Who Placed an Order',
    CAST(COUNT(DISTINCT customer_key) AS DECIMAL(18, 2))
FROM gold.fact_sales;
