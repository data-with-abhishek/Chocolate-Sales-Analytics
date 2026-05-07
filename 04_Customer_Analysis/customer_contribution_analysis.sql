--============================================================
--                     CUSTOMER ANALYSIS
--============================================================


-- 1. Gender-wise Customer Performance Summary
--============================================================

SELECT
    c.gender,
    SUM(s.revenue) AS total_revenue,
    SUM(s.profit) AS total_profit
FROM sales s
INNER JOIN customers c
    ON s.customer_id = c.customer_id
GROUP BY c.gender;


-- 2. Top 10 Customers by Revenue & Profit
--============================================================

WITH customer_summary AS (
    SELECT
        customer_id,
        SUM(revenue) AS total_revenue,
        SUM(profit) AS total_profit
    FROM sales
    GROUP BY customer_id
),

customer_rank AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM customer_summary
)

SELECT
    customer_id,
    total_revenue,
    total_profit,
    revenue_rank,
    profit_rank
FROM customer_rank
WHERE revenue_rank <= 10;


-- 3. Customer Revenue Segmentation Analysis
--============================================================

WITH overall_customer_stats AS (
    SELECT
        customer_id,
        SUM(revenue) AS total_revenue,
        SUM(profit) AS total_profit,
        PERCENT_RANK() OVER (ORDER BY SUM(revenue) ASC) AS revenue_percentile
    FROM sales
    GROUP BY customer_id
),

customer_segments AS (
    SELECT
        *,
        CASE
            WHEN revenue_percentile >= 0.80 THEN 'High Value'
            WHEN revenue_percentile >= 0.20 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM overall_customer_stats
),

segment_summary AS (
    SELECT
        customer_segment,
        COUNT(customer_id) AS total_customers,
        SUM(total_revenue) AS segment_total_revenue,
        SUM(total_profit) AS segment_total_profit
    FROM customer_segments
    GROUP BY customer_segment
),

global_summary AS (
    SELECT
        SUM(total_customers) AS global_customers,
        SUM(segment_total_revenue) AS global_revenue,
        SUM(segment_total_profit) AS global_profit
    FROM segment_summary
)

SELECT
    s.customer_segment,
    s.total_customers,
    s.segment_total_revenue,
    s.segment_total_profit,

    s.segment_total_revenue * 100.0 /
        NULLIF(g.global_revenue, 0) AS revenue_contribution_pct,

    s.segment_total_profit * 100.0 /
        NULLIF(g.global_profit, 0) AS profit_contribution_pct,

    s.total_customers * 100.0 /
        NULLIF(g.global_customers, 0) AS customer_distribution_pct

FROM segment_summary s
CROSS JOIN global_summary g;


-- 4. Individual Customer Contribution Analysis
--============================================================

WITH customer_stats AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT s.order_id) AS total_orders,
        SUM(s.quantity) AS total_quantity,
        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit,

        ROW_NUMBER() OVER (
            ORDER BY SUM(s.revenue) DESC
        ) AS revenue_rank

    FROM sales s
    INNER JOIN customers c
        ON s.customer_id = c.customer_id

    GROUP BY c.customer_id
),

global_stats AS (
    SELECT
        SUM(total_orders) AS global_orders,
        SUM(total_quantity) AS global_quantity,
        SUM(total_revenue) AS global_revenue,
        SUM(total_profit) AS global_profit
    FROM customer_stats
)

SELECT
    c.customer_id,
    c.total_orders,
    c.total_quantity,
    c.total_revenue,
    c.total_profit,
    c.revenue_rank,

    c.total_revenue * 100.0 /
        NULLIF(g.global_revenue, 0) AS revenue_contribution_pct,

    c.total_profit * 100.0 /
        NULLIF(g.global_profit, 0) AS profit_contribution_pct

FROM customer_stats c
CROSS JOIN global_stats g;
