/*
Purpose:
- Track sales performance over time at a monthly grain.
- DATETRUNC keeps all transactions in the same calendar month together.
*/

-- Compare monthly revenue, quantity, and customer activity in chronological order.
SELECT 
    DATETRUNC(MONTH,order_date) as date,
    sum(sales) as total_sales,
    sum(quantity) as total_quantity,
    count(customer_key) as total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY  DATETRUNC(MONTH,order_date)
ORDER BY  DATETRUNC(MONTH,order_date)

