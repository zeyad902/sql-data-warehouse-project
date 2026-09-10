/*
Purpose:
- Identify the products at the top and bottom of the sales ranking.
- Both queries use revenue rather than quantity, so the ranking reflects sales value.
*/

-- Which 5 products generate the highest revenue?
SELECT TOP 5
	p.product_name,
	SUM(sales) total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_product p
ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY SUM(sales) DESC


-- What are the 5 worst-performing products in terms of sales?

SELECT TOP 5
	p.product_name,
	SUM(sales) total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_product p
ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY SUM(sales) 