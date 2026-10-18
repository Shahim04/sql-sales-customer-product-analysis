/*
--------------------------------------------------------------------------
 2. CUMULATIVE ANALYSIS (RUNNING TOTAL & MOVING AVERAGE)
--------------------------------------------------------------------------
 Question:
   What is our cumulative sales over time, and what is the moving average
   of product prices? Are we trending up or just having isolated good months?
--------------------------------------------------------------------------
*/
SELECT
    order_month,
    total_sales,
    -- Running total: adds each month's sales to everything before it
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,
    -- Moving average: average of the monthly average prices up to the current month
    AVG(avg_price)   OVER (ORDER BY order_month) AS moving_avg_price
FROM (
    -- Step 1: aggregate to one row per month
    SELECT
        DATETRUNC(MONTH, order_date) AS order_month,
        SUM(sales_amount)            AS total_sales,
        AVG(price)                   AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
) AS monthly_sales;
-- Note: no PARTITION BY here on purpose. Partitioning by order_month would
-- put every month in its own group and the "running" total would just
-- equal that single month's value.
