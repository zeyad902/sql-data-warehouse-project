/*
Purpose:
- Calculate monthly sales and average price.
- Add year-specific running sales and a cumulative average price for trend analysis.
*/

SELECT
    *,
    SUM(total_sales) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date) as running_total,
    AVG(avg_price) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date) as moving_avgerage
FROM (
	-- Reduce the fact table to one row per month before applying window functions.
    SELECT 
        DATETRUNC(MONTH,order_date) order_date,
        SUM(sales) total_sales,
        AVG(price) avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH,order_date)
    ) t
