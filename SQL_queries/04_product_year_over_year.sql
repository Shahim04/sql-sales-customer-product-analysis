/*
--------------------------------------------------------------------------
 4. YEAR-OVER-YEAR ANALYSIS (PRODUCT GROWTH)
--------------------------------------------------------------------------
 Question:
   How did each product's sales change compared to the previous year?
   Which products are growing, which are declining, and where should we
   investigate?
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
    -- LAG pulls the previous year's value for the same product
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_sales,
    CASE
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increasing'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decreasing'
        ELSE 'No Change'   -- also covers a product's first year (no previous year to compare)
    END AS previous_year_change
FROM performance_analysis
ORDER BY product_name, order_year;
