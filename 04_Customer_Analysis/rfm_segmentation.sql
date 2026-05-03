-- This query performs RFM segmentation and evaluates
-- customer contribution to overall revenue distribution.

-- ============================================================
-- RFM Analysis (Recency, Frequency, Monetary)
-- + Customer Lifetime Value (Historical CLV)
-- ============================================================

-- Step 1: Get reference date (latest transaction date)
WITH ref_date AS (
    SELECT MAX(order_date) AS max_date 
    FROM sales
),

-- Step 2: Global statistics (used for Monetary scoring)
global_stat AS (
    SELECT
        SUM(revenue) * 1.0 / COUNT(DISTINCT customer_id) AS avg_revenue,
        SUM(revenue) AS global_total_revenue
    FROM sales
),

-- RFM metrics are calculated at customer level to evaluate behavior
-- and contribution across the entire dataset

-- Step 3: Base RFM metrics per customer
rfm_base AS (
    SELECT
        s.customer_id,
        MAX(s.order_date) AS last_order_date,
        
        -- Recency: Days since last purchase
        DATEDIFF(DAY, MAX(s.order_date), r.max_date) AS recency_days,
        
        -- Frequency: Total number of orders
        COUNT(DISTINCT s.order_id) AS frequency,
        
        -- Monetary: Total revenue generated
        SUM(s.revenue) AS total_revenue
        
    FROM sales s
    CROSS JOIN ref_date r
    GROUP BY s.customer_id, r.max_date
),

-- Step 4: Assign RFM scores (1–5 scale)
rfm_score AS (
    SELECT 
        r.*,

        -- Recency Score
        CASE
            WHEN recency_days <= 15 THEN 5
            WHEN recency_days <= 30 THEN 4
            WHEN recency_days <= 60 THEN 3
            WHEN recency_days <= 90 THEN 2
            ELSE 1
        END AS R_score,

        -- Frequency Score
        CASE 
            WHEN frequency >= 30 THEN 5
            WHEN frequency >= 26 THEN 4
            WHEN frequency >= 22 THEN 3
            WHEN frequency >= 18 THEN 2
            ELSE 1
        END AS F_score,

        -- Monetary Score (relative to average revenue)
        CASE
            WHEN r.total_revenue >= g.avg_revenue * 1.5 THEN 5
            WHEN r.total_revenue >= g.avg_revenue * 1.2 THEN 4
            WHEN r.total_revenue >= g.avg_revenue * 1.0 THEN 3
            WHEN r.total_revenue >= g.avg_revenue * 0.75 THEN 2
            ELSE 1
        END AS M_score

    FROM rfm_base r
    CROSS JOIN global_stat g
),

-- Step 5: Segment customers based on RFM scores
customer_segment AS (
    SELECT *,
    
        CONCAT(R_score, F_score, M_score) AS rfm_score_code,

        CASE 
            WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
            WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Loyal Customers'
            WHEN R_score >= 4 AND F_score <= 2 THEN 'New Customers'
            WHEN R_score <= 2 AND F_score >= 3 THEN 'At Risk'
            WHEN R_score <= 2 AND F_score <= 2 THEN 'Lost Customers'
            ELSE 'Potential'
        END AS segment

    FROM rfm_score
),

-- Step 6: Aggregate metrics by segment
segment_summary AS (
    SELECT
        segment,
        COUNT(customer_id) AS total_customers,
        SUM(total_revenue) AS total_revenue,
        SUM(total_revenue) * 1.0 / COUNT(customer_id) AS revenue_per_customer
    FROM customer_segment
    GROUP BY segment
)

-- Final Output: Contribution analysis
SELECT
    segment,
    total_customers,
    total_revenue,
    revenue_per_customer,
    total_customers * 100.0 / SUM(total_customers) OVER() AS customer_pct,
    total_revenue * 100.0 / SUM(total_revenue) OVER() AS revenue_pct
FROM segment_summary
ORDER BY total_revenue DESC;


-- ==================================================================================
-- ==================================================================================
-- Insight:
-- Revenue is distributed across multiple customer segments,
-- with no single segment contributing more than ~30%.
-- This indicates limited adherence to the traditional Pareto (80/20) principle.
-- ==================================================================================
-- ==================================================================================
