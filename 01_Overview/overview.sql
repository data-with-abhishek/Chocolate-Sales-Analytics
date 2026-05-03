-- This query provides an overall snapshot of business performance,
-- including revenue, profitability, pricing, and order efficiency.

-- ============================================================
-- Overall Business Performance Summary
-- ============================================================

SELECT
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    SUM(cost) AS total_cost,
    SUM(profit) AS total_profit,

    -- Total discount value
    SUM(discount * revenue) AS total_discount,

    -- Average Order Value (AOV)
    SUM(revenue) * 1.0 / NULLIF(COUNT(DISTINCT order_id), 0) AS avg_order_value,

    -- Average Selling Price per unit
    SUM(revenue) * 1.0 / NULLIF(SUM(quantity), 0) AS avg_selling_price,

    -- Profit Margin %
    SUM(profit) * 100.0 / NULLIF(SUM(revenue), 0) AS profit_margin_pct

FROM sales;


-- ============================================================
-- Year-wise Business Performance Summary
-- ============================================================

SELECT
    YEAR(order_date) AS year,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    SUM(cost) AS total_cost,
    SUM(profit) AS total_profit,
    SUM(discount * revenue) AS total_discount

FROM sales
GROUP BY YEAR(order_date)
ORDER BY year ASC;


-- ============================================================
-- Insight:
-- The business demonstrates consistent revenue generation across years,
-- with stable profitability and pricing metrics.
-- These results establish a baseline for further trend and segment-level analysis.
-- ============================================================
