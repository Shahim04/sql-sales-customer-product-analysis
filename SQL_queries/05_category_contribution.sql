/*
--------------------------------------------------------------------------
 5. PART-TO-WHOLE ANALYSIS (CATEGORY CONTRIBUTION)
--------------------------------------------------------------------------
 Question:
   Which product categories contribute the most to total revenue?
   Are we overly dependent on one category?
--------------------------------------------------------------------------
*/
WITH category_sales AS (
    -- Total sales per category
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,   -- grand total across all categories
    -- Category share of total; CAST to float avoids integer division
    CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;
