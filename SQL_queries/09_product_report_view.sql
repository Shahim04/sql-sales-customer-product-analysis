/*
--------------------------------------------------------------------------
 9. PRODUCT REPORT (VIEW)
--------------------------------------------------------------------------
 Question:
   Can we build one reusable product report that shows how each product
   performs (orders, units sold, customers, sales, recency, average order
   value) and classifies it as high, mid, or low performing?
--------------------------------------------------------------------------
*/
GO  -- CREATE VIEW must be the first statement in a batch in SQL Server

CREATE VIEW gold.product_report AS

-- Step 1: base query - join sales to products and pull the core columns
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.quantity,
        f.sales_amount,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
),

-- Step 2: aggregate to one row per product
product_aggregation AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        COUNT(DISTINCT order_number)  AS total_orders,         -- orders that included the product
        SUM(quantity)                 AS total_quantity_sold,  -- units sold
        COUNT(DISTINCT customer_key)  AS total_customers,      -- unique buyers
        SUM(sales_amount)             AS total_sales,          -- revenue
        MAX(order_date)               AS last_order_date,
        -- Lifespan = months between the product's first and last sale
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY product_key, product_name, category, subcategory
)

-- Step 3: add recency, average order value, and performance segment
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    total_orders,
    total_quantity_sold,
    total_customers,
    total_sales,
    last_order_date,
    lifespan,

    -- Recency: months since the product was last sold
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,

    -- Average order value (* 1.0 avoids integer division, NULLIF avoids division by zero)
    ROUND(total_sales * 1.0 / NULLIF(total_orders, 0), 2) AS avg_order_value,

    -- Performance segment based on total sales
    CASE
        WHEN total_sales >  300000 THEN 'High-Performance'
        WHEN total_sales >= 25000  THEN 'Mid-Range'
        ELSE 'Low-Performance'
    END AS segment
FROM product_aggregation;
