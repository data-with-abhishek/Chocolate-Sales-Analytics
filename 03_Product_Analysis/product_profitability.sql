-- This file evaluates product profitability,
-- focusing on brand performance, margin consistency,
-- and identifying potential inefficiencies.

-- ============================================================
-- Product Brand Performance Summary
-- ============================================================

SELECT
    p.brand,
    SUM(s.quantity) AS total_quantity,
    SUM(s.revenue) AS total_revenue,
    SUM(s.cost) AS total_cost,
    SUM(s.profit) AS total_profit,

    -- Efficiency metrics
    SUM(s.revenue) * 1.0 / NULLIF(COUNT(DISTINCT s.order_id), 0) AS avg_order_value,
    SUM(s.revenue) * 1.0 / NULLIF(SUM(s.quantity), 0) AS avg_selling_price,

    -- Profitability
    SUM(s.profit) * 100.0 / NULLIF(SUM(s.revenue), 0) AS profit_margin_pct,

    -- Contribution %
    SUM(s.revenue) * 100.0 
        / SUM(SUM(s.revenue)) OVER() AS revenue_contribution_pct

FROM sales s
JOIN products p 
    ON s.product_id = p.product_id
GROUP BY p.brand
ORDER BY total_revenue DESC;


-- ============================================================
-- Product Profit Margin Analysis
-- ============================================================

SELECT
    product_id,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,

    -- Profit margin %
    SUM(profit) * 100.0 / NULLIF(SUM(revenue), 0) AS profit_margin_pct

FROM sales
GROUP BY product_id
ORDER BY profit_margin_pct DESC;


-- ============================================================
-- High Revenue but Low Profit Products (Inefficiency Detection)
-- ============================================================

WITH global_stats AS (
    SELECT 
        SUM(revenue) * 1.0 / COUNT(DISTINCT product_id) AS avg_revenue,
        SUM(profit) * 1.0 / COUNT(DISTINCT product_id) AS avg_profit
    FROM sales
)

SELECT
    s.product_id,
    SUM(s.revenue) AS total_revenue,
    SUM(s.profit) AS total_profit

FROM sales s
GROUP BY s.product_id

HAVING 
    SUM(s.revenue) > (SELECT avg_revenue FROM global_stats)
    AND SUM(s.profit) < (SELECT avg_profit FROM global_stats)

ORDER BY total_revenue DESC;


-- ============================================================
-- Insight:
-- Revenue and profitability are evenly distributed across brands,
-- with no single brand dominating overall performance.
--
-- Profit margins remain highly consistent (~40%) across most products,
-- indicating a standardized pricing and cost structure.
--
-- Only a small number of products generate high revenue but relatively lower profit,
-- highlighting limited but important margin inefficiencies.
--
-- Overall, product performance is stable and balanced,
-- with growth driven by a broad product portfolio rather than reliance on specific brands.
-- ============================================================
