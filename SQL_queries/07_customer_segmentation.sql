/*
--------------------------------------------------------------------------
 7. DATA SEGMENTATION (CUSTOMERS BY SPENDING & LIFESPAN)
--------------------------------------------------------------------------
 Question:
   How many customers fall into each segment?
     - VIP     : lifespan of 12+ months and spending over 5,000
     - Regular : lifespan of 12+ months and spending of 5,000 or less
     - New     : lifespan under 12 months
--------------------------------------------------------------------------
*/
WITH customer_segmentation AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spent,
        MIN(f.order_date)   AS first_order,
        MAX(f.order_date)   AS last_order,
        -- Lifespan = months between first and last order
        DATEDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS lifespan
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    -- Assign each customer to a segment
    SELECT
        customer_key,
        CASE
            WHEN total_spent >  5000 AND lifespan >= 12 THEN 'VIP'
            WHEN total_spent <= 5000 AND lifespan >= 12 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_segmentation
) t
GROUP BY customer_segment
ORDER BY total_customers DESC;
