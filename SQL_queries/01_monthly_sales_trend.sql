/*
--------------------------------------------------------------------------
 1. CHANGE OVER TIME (MONTHLY TREND)
--------------------------------------------------------------------------
 Question:
   How have our sales, customer count, and units sold changed month over
   month? Are there seasonal patterns or growth trends we should know about?
--------------------------------------------------------------------------
*/
SELECT
    DATETRUNC(MONTH, order_date)  AS order_month,      -- first day of each month
    SUM(sales_amount)             AS total_sales,      -- revenue for the month
    COUNT(DISTINCT customer_key)  AS total_customers,  -- unique buyers (each counted once per month)
    SUM(quantity)                 AS total_quantity    -- units sold
FROM gold.fact_sales
WHERE order_date IS NOT NULL                           -- ignore rows with no valid order date
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date);
