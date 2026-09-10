/*
Purpose:
- Analyze yearly product performance against:
   1. The product's average yearly sales
   2. The previous year's sales
*/

-- First create one revenue value per product and calendar year.
WITH yearly_sales AS (
    SELECT
        f.product_key,
        YEAR(f.order_date) AS sales_year,
        SUM(f.sales) AS current_sales
    FROM gold.fact_sales f
    WHERE f.order_date IS NOT NULL
    GROUP BY
        f.product_key,
        YEAR(f.order_date)
),

-- Window functions provide each product's long-term average and prior-year comparison.
performance AS (
    SELECT
        product_key,
        sales_year,
        current_sales,

        -- Calculate each window metric once and reuse it in the final comparison.
        AVG(current_sales) OVER (
            PARTITION BY product_key
        ) AS avg_sales,

        LAG(current_sales) OVER (
            PARTITION BY product_key
            ORDER BY sales_year
        ) AS prev_sales
    FROM yearly_sales
)

-- Label each year's result so increases and decreases can be reviewed quickly.
SELECT
    p.product_name,
    ps.sales_year AS order_date,

    ps.avg_sales,

    ps.current_sales - ps.avg_sales AS diff_avg,

    CASE
        WHEN ps.current_sales > ps.avg_sales THEN 'Above Avg'
        WHEN ps.current_sales < ps.avg_sales THEN 'Below Avg'
        ELSE 'Avg'
    END AS diff_change,

    ps.current_sales,

    ps.prev_sales,

    ps.current_sales - ps.prev_sales AS sales_diff,
    CASE WHEN ps.current_sales - ps.prev_sales > 0 THEN 'Increase'
         WHEN ps.current_sales - ps.prev_sales < 0 THEN 'Decrease'
    ELSE 'No Change'
    END AS previous_change

FROM performance ps
INNER JOIN gold.dim_product p
    ON ps.product_key = p.product_key
ORDER BY
    p.product_name,
    ps.sales_year;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

