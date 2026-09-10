/*
Purpose:
- Explore the size and distribution of customers, products, and sales.
- Each independent query groups a business measure by one descriptive attribute.
*/

-- Customer count by country shows the geographic concentration of the customer base.
SELECT 
	country,
	COUNT(customer_key) AS Total_Customers
FROM gold.dim_customer
GROUP BY country;
GO

-- Customer count by gender shows the demographic composition of the customer base.
SELECT 
	gender,
	COUNT(customer_key) AS Total_Customers
FROM gold.dim_customer
GROUP BY gender;
GO

-- Product count by category shows the breadth of the product catalog.
SELECT 
	category,
	COUNT(product_key) AS Total_Products
FROM gold.dim_product
GROUP BY category;
GO

-- Average product cost by category helps compare the cost structure of categories.
SELECT 
	category,
	AVG(cost) AS Average_Cost
FROM gold.dim_product
GROUP BY category;
GO

-- Category revenue is calculated after attaching each sale to its product category.
SELECT 
	p.category,
	SUM(sales) total_sales
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
ON f.product_key = p.product_key
GROUP BY category;
GO

-- Customer revenue identifies the customers contributing the most sales.
WITH customer_revenue AS (
SELECT
	c.customer_key,
	c.frist_name,
	c.last_name,
	SUM(sales) Total_Sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON f.customer_key = c.customer_key
GROUP BY
	c.customer_key,
	c.frist_name,
	c.last_name
)
SELECT 
	*
FROM customer_revenue
ORDER BY Total_Sales DESC;
GO

-- Quantity by country highlights where the largest sales volumes are shipped or recorded.
WITH distribution_country AS (
SELECT 
	country,
	SUM(quantity) total_quantity
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON f.customer_key = c.customer_key
GROUP BY
	country
)
SELECT 
	*
FROM distribution_country
ORDER BY total_quantity DESC;