-- This file analyzes product performance,
-- identifying top revenue drivers, loss-making products,
-- and revenue concentration across the product portfolio.

-- ============================================================
-- Top 20 Revenue-Generating Products
-- ============================================================

WITH product_summary AS (
    SELECT
        s.product_id,
        SUM(s.quantity) AS total_quantity,
        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit
    FROM sales s
    GROUP BY s.product_id
)

SELECT TOP 20
    p.product_id,
    p.product_name,
    p.brand,
    ps.total_quantity,
    ps.total_revenue,
    ps.total_profit,
    RANK() OVER (ORDER BY ps.total_revenue DESC) AS rank_by_revenue
FROM product_summary ps
JOIN products p 
    ON ps.product_id = p.product_id
ORDER BY ps.total_revenue DESC;


-- ============================================================
-- Bottom 20 Products by Profit (Loss Analysis)
-- ============================================================

WITH product_summary AS (
    SELECT
        s.product_id,
        SUM(s.quantity) AS total_quantity,
        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit
    FROM sales s
    GROUP BY s.product_id
)

SELECT TOP 20
    p.product_id,
    p.product_name,
    p.brand,
    ps.total_quantity,
    ps.total_revenue,
    ps.total_profit,
    RANK() OVER (ORDER BY ps.total_profit ASC) AS rank_by_profit
FROM product_summary ps
JOIN products p 
    ON ps.product_id = p.product_id
ORDER BY ps.total_profit ASC;


-- ============================================================
-- Product Revenue Distribution & Pareto Analysis
-- ============================================================

WITH product_ranked AS (
    SELECT
        product_id,
        SUM(revenue) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(revenue) DESC) AS revenue_rank
    FROM sales
    GROUP BY product_id
)

SELECT TOP 20
    product_id,
    total_revenue,
    revenue_rank,

    -- Cumulative contribution %
    SUM(total_revenue) OVER (ORDER BY total_revenue DESC) * 100.0
        / SUM(total_revenue) OVER() AS cumulative_contribution_pct

FROM product_ranked
ORDER BY total_revenue DESC;


-- ============================================================
-- Insight:
-- Unlike the traditional 80/20 assumption, revenue is not driven
-- by a small subset of products.
--
-- The top 20% of products contribute only a limited share,
-- indicating weak Pareto behavior.
--
-- This shows that growth is distributed across the product portfolio,
-- not concentrated in a few top-performing items.
--
-- Additionally, some high-revenue products generate relatively lower profit,
-- highlighting opportunities for pricing and cost optimization.
-- ============================================================
