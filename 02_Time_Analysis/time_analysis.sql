-- This set of queries analyzes business performance over time,
-- focusing on growth trends, seasonality, and peak performance periods.

-- ============================================================
-- Year-over-Year (YoY) Growth Analysis
-- ============================================================

WITH yearly_summary AS (
    SELECT
        YEAR(order_date) AS year,
        SUM(revenue) AS total_revenue,
        SUM(profit) AS total_profit
    FROM sales
    GROUP BY YEAR(order_date)
),
yoy_calc AS (
    SELECT
        year,
        total_revenue,
        total_profit,
        LAG(total_revenue) OVER (ORDER BY year) AS prev_year_revenue,
        LAG(total_profit) OVER (ORDER BY year) AS prev_year_profit
    FROM yearly_summary
)

SELECT
    year,
    total_revenue,
    total_profit,
    total_revenue - prev_year_revenue AS yoy_movement,
    ROUND((total_revenue - prev_year_revenue) * 100.0 
        / NULLIF(prev_year_revenue, 0), 2) AS yoy_revenue_pct,
    ROUND((total_profit - prev_year_profit) * 100.0 
        / NULLIF(prev_year_profit, 0), 2) AS yoy_profit_pct
FROM yoy_calc
ORDER BY year ASC;


-- ============================================================
-- Month-over-Month (MoM) Growth Analysis
-- ============================================================

WITH monthly_summary AS (
    SELECT
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        SUM(profit) AS total_profit
    FROM sales
    GROUP BY YEAR(order_date), MONTH(order_date)
),
mom_calc AS (
    SELECT
        *,
        LAG(total_revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
        LAG(total_profit) OVER (ORDER BY year, month) AS prev_month_profit
    FROM monthly_summary
)

SELECT
    year,
    month,
    total_quantity,
    total_revenue,
    total_profit,
    total_revenue - prev_month_revenue AS mom_movement,
    ROUND((total_revenue - prev_month_revenue) * 100.0 
        / NULLIF(prev_month_revenue, 0), 2) AS mom_revenue_pct,
    ROUND((total_profit - prev_month_profit) * 100.0 
        / NULLIF(prev_month_profit, 0), 2) AS mom_profit_pct
FROM mom_calc
ORDER BY year ASC, month ASC;


-- ============================================================
-- Monthly Cumulative Performance & Contribution Analysis
-- ============================================================

WITH monthly_summary AS (
    SELECT
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        SUM(revenue) AS total_revenue,
        SUM(profit) AS total_profit
    FROM sales
    GROUP BY YEAR(order_date), MONTH(order_date)
)

SELECT
    year,
    month,
    total_revenue,
    total_profit,

    -- Running totals
    SUM(total_revenue) OVER (PARTITION BY year ORDER BY month) AS cumulative_revenue,
    SUM(total_profit) OVER (PARTITION BY year ORDER BY month) AS cumulative_profit,

    -- Contribution %
    ROUND(
        SUM(total_revenue) OVER (PARTITION BY year ORDER BY month) * 100.0
        / SUM(total_revenue) OVER (PARTITION BY year),
    2) AS revenue_contribution_pct,

    ROUND(
        SUM(total_profit) OVER (PARTITION BY year ORDER BY month) * 100.0
        / SUM(total_profit) OVER (PARTITION BY year),
    2) AS profit_contribution_pct

FROM monthly_summary
ORDER BY year ASC, month ASC;


-- ============================================================
-- Peak Month Identification (Above Average Performance)
-- ============================================================

WITH monthly_summary AS (
    SELECT
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        SUM(revenue) AS total_revenue,
        SUM(profit) AS total_profit
    FROM sales
    GROUP BY YEAR(order_date), MONTH(order_date)
),
global_stats AS (
    SELECT
        AVG(total_revenue) AS avg_revenue,
        AVG(total_profit) AS avg_profit
    FROM monthly_summary
)

SELECT 
    m.year,
    m.month,
    m.total_revenue,
    m.total_profit
FROM monthly_summary m
CROSS JOIN global_stats g
WHERE m.total_revenue > g.avg_revenue
  AND m.total_profit > g.avg_profit
ORDER BY m.total_revenue DESC;


-- ============================================================
/*
 Insight:
 The business shows consistent growth trends over time,
 with identifiable peak periods contributing disproportionately
 to annual performance. Revenue and profit patterns indicate
 seasonality and highlight key months driving overall results.
 */
-- ============================================================
