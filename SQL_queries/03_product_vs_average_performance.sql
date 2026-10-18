/*
--------------------------------------------------------------------------
 3. PERFORMANCE ANALYSIS (PRODUCT vs. ITS OWN AVERAGE)
--------------------------------------------------------------------------
 Question:
   For each product, which years performed above or below that product's
   own average sales? Which products are consistently strong, and which
   are inconsistent?
--------------------------------------------------------------------------
*/
WITH performance_analysis AS (
    -- Yearly sales per product
    SELECT
        YEAR(f.order_date)   AS order_year,
        p.product_name,
        SUM(f.sales_amount)  AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    -- Average yearly sales of the same product across all years
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    -- Gap between this year and the product's average
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
    -- Label each year relative to the product's average
    CASE
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change
FROM performance_analysis
ORDER BY product_name, order_year;
