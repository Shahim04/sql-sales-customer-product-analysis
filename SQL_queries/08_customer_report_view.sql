/*
--------------------------------------------------------------------------
 8. CUSTOMER REPORT (VIEW)
--------------------------------------------------------------------------
 Question:
   Can we build one reusable customer report that combines demographics,
   segments, and key metrics (orders, spend, recency, average order value,
   average monthly spend) so analysts and dashboards can query it directly?
--------------------------------------------------------------------------
*/
GO  -- CREATE VIEW must be the first statement in a batch in SQL Server

CREATE VIEW gold.report_customers AS

-- Step 1: base query - join sales to customers and pull the core columns
WITH base_query AS (
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age   -- approximate age (counts year boundaries)
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
),

-- Step 2: aggregate to one row per customer
customer_aggregation AS (
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount)            AS total_spent,
        SUM(quantity)                AS total_quantity,
        COUNT(DISTINCT product_key)  AS total_products,
        MAX(order_date)              AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY customer_key, customer_number, customer_name, age
)

-- Step 3: add segments and calculated metrics
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,

    -- Age group
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE 'Above 50'
    END AS age_seg,

    -- Customer segment (same rules as query 7)
    CASE
        WHEN total_spent >  5000 AND lifespan >= 12 THEN 'VIP'
        WHEN total_spent <= 5000 AND lifespan >= 12 THEN 'Regular'
        ELSE 'New'
    END AS cus_seg,

    total_orders,
    total_spent,
    total_quantity,
    total_products,
    last_order_date,

    -- Recency: months since the customer's last order
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,

    -- Average order value (NULLIF avoids division by zero)
    total_spent / NULLIF(total_orders, 0) AS avg_order_value,

    -- Average monthly spend (a customer with a 0-month lifespan just gets total spend)
    CASE
        WHEN lifespan = 0 THEN total_spent
        ELSE total_spent / lifespan
    END AS avg_monthly_spend,

    lifespan
FROM customer_aggregation;
