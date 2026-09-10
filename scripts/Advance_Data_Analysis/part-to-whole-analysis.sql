/*
Purpose:
- Measure each product category's contribution to total revenue.
- The percentage uses the complete result set as its denominator.
*/

SELECT
    category,
    CONCAT(ROUND((CAST(sales AS FLOAT) / total_sales) * 100,2),'%') AS Contribute
FROM(
    -- Calculate category sales and the overall sales total in one grouped result.
SELECT
    category,
    SUM(sales) sales,
    SUM(SUM(sales)) OVER() total_sales
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
ON f.product_key = p.product_key
GROUP BY category
)t
ORDER BY sales DESC
