--============================================================
--                ADVANCED BUSINESS INSIGHTS
--============================================================


-- 1. Top 3 Products by Revenue in Each Country
--============================================================
-- Insight:
-- Identifies highest-performing products within each country
-- to understand regional product preferences and revenue drivers.

WITH country_product_sales AS (

    SELECT
        st.country,
        s.product_id,
        SUM(s.revenue) AS total_revenue,

        RANK() OVER (
            PARTITION BY st.country
            ORDER BY SUM(s.revenue) DESC
        ) AS revenue_rank

    FROM sales s

    INNER JOIN stores st
        ON s.store_id = st.store_id

    GROUP BY
        st.country,
        s.product_id
)

SELECT
    country,
    product_id,
    total_revenue,
    revenue_rank

FROM country_product_sales

WHERE revenue_rank <= 3

ORDER BY
    country,
    revenue_rank;



-- 2. High Revenue Stores with Below Average Profit Margin
--============================================================
-- Insight:
-- Detects stores generating strong revenue but weaker profitability,
-- indicating possible operational inefficiencies or high costs.

WITH store_performance AS (

    SELECT
        st.store_id,
        st.store_name,

        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit

    FROM sales s

    INNER JOIN stores st
        ON s.store_id = st.store_id

    GROUP BY
        st.store_id,
        st.store_name
),

global_benchmark AS (

    SELECT
        AVG(total_revenue) AS avg_revenue,

        SUM(total_profit) * 100.0 /
        NULLIF(SUM(total_revenue), 0) AS global_margin_pct

    FROM store_performance
)

SELECT
    sp.store_id,
    sp.store_name,
    sp.total_revenue,
    sp.total_profit,

    sp.total_profit * 100.0 /
    NULLIF(sp.total_revenue, 0) AS store_margin_pct

FROM store_performance sp

CROSS JOIN global_benchmark gb

WHERE
    sp.total_revenue > gb.avg_revenue
    AND
    (
        sp.total_profit * 100.0 /
        NULLIF(sp.total_revenue, 0)
    ) < gb.global_margin_pct

ORDER BY store_margin_pct DESC;



-- 3. Best Performing Store Type by Country
--============================================================
-- Insight:
-- Identifies the most profitable store format in each country
-- to support expansion and operational strategy decisions.

WITH country_store_type AS (

    SELECT
        st.country,
        st.store_type,

        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit,

        RANK() OVER (
            PARTITION BY st.country
            ORDER BY SUM(s.profit) DESC
        ) AS profit_rank

    FROM sales s

    INNER JOIN stores st
        ON s.store_id = st.store_id

    GROUP BY
        st.country,
        st.store_type
)

SELECT
    country,
    store_type,
    total_revenue,
    total_profit

FROM country_store_type

WHERE profit_rank = 1

ORDER BY country;



-- 4. Dynamic Pareto Analysis (Stores Driving 80% Revenue)
--============================================================
-- Insight:
-- Identifies key stores contributing to the majority of revenue,
-- helping prioritize high-impact operational focus areas.

WITH store_summary AS (

    SELECT
        st.store_id,
        st.store_name,

        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit

    FROM sales s

    INNER JOIN stores st
        ON s.store_id = st.store_id

    GROUP BY
        st.store_id,
        st.store_name
),

running_revenue AS (

    SELECT
        store_id,
        store_name,
        total_profit,
        total_revenue,

        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
        ) AS cumulative_revenue,

        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
        ) * 100.0 /

        NULLIF(
            SUM(total_revenue) OVER (),
            0
        ) AS cumulative_contribution_pct

    FROM store_summary
),

pareto_cutoff AS (

    SELECT
        *,

        LAG(cumulative_contribution_pct)
        OVER (
            ORDER BY cumulative_contribution_pct
        ) AS previous_pct

    FROM running_revenue
)

SELECT
    store_id,
    store_name,
    total_profit,
    total_revenue,
    cumulative_contribution_pct

FROM pareto_cutoff

WHERE
    cumulative_contribution_pct <= 80

    OR
    (
        (
            previous_pct < 80
            OR previous_pct IS NULL
        )

        AND cumulative_contribution_pct >= 80
    )

ORDER BY total_revenue DESC;



-- 5. Underperforming Products
--============================================================
-- Insight:
-- Detects products generating strong revenue but weaker profit margins,
-- indicating pricing or cost optimization opportunities.

WITH product_performance AS (

    SELECT
        p.product_id,
        p.product_name,

        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit,

        SUM(s.profit) * 100.0 /
        NULLIF(SUM(s.revenue), 0) AS profit_margin_pct

    FROM sales s

    INNER JOIN products p
        ON s.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.product_name
),

global_product_metrics AS (

    SELECT
        AVG(total_revenue) AS avg_revenue,

        SUM(total_profit) * 100.0 /
        NULLIF(SUM(total_revenue), 0) AS global_margin_pct

    FROM product_performance
)

SELECT
    pp.*

FROM product_performance pp

CROSS JOIN global_product_metrics gm

WHERE
    pp.total_revenue > gm.avg_revenue
    AND
    pp.profit_margin_pct < gm.global_margin_pct;
