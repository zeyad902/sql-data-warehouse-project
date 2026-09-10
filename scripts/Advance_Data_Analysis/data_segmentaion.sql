/*
Purpose:
- Group products into cost bands and count the products in each band.
- Group customers by sales history and total spending to distinguish VIP, Regular, and New customers.
*/

-- Assign each product to a cost band before counting products by segment.
WITH product_segmentation AS (
    SELECT 
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 501 AND 1000 THEN '501-1000'
        ELSE 'Above 1000'
        END AS product_segment
    FROM gold.dim_product
)
SELECT 
    product_segment,
    COUNT(product_key) AS total_number
FROM product_segmentation
GROUP BY product_segment

GO
/*
Group customers into three segments based on their spending behavior:
- VIP: Customers with at least 12 months of history and spending more than €5,000.
- Regular: Customers with at least 12 months of history but spending €5,000 or less.
- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group.
*/

-- Calculate each customer's sales total and active lifespan first.
WITH customer_sales AS (
    SELECT 
        customer_key,
        SUM(sales) total_sales,
        MIN(order_date) frist_date,
        MAX(order_date) last_date,
        DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
    FROM gold.fact_sales 
    GROUP BY customer_key
)
SELECT 
    customer_segmentaion,
    COUNT(customer_key) as total_customers
FROM (
    -- Add customer attributes and apply the business rules for each segment.
    SELECT
        c.customer_key,
        c.frist_name,
        c.last_name,
        s.total_sales,
        s.lifespan,
        CASE 
            WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_sales < 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segmentaion
    FROM customer_sales s
    JOIN gold.dim_customer c
    ON s.customer_key = c.customer_key
    )t
GROUP BY customer_segmentaion

