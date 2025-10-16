-- =====================================================
-- Demo Queries for Retail Store Performance Monitoring
-- =====================================================
-- These queries demonstrate the two main use cases:
-- 1. Store Performance & Pareto Analysis
-- 2. Historic Event Impact (Cyclone Alfred) Analysis
-- =====================================================

USE DATABASE Retail_SI_Demo;
USE SCHEMA Retail_SI_Demo;

-- =====================================================
-- USE CASE 1: STORE PERFORMANCE & PARETO ANALYSIS
-- =====================================================

-- Query 1.1: State-by-State Performance Comparison
-- Shows YTD performance across states to identify underperforming regions
SELECT 
    state_abbr,
    division,
    COUNT(*) as store_count,
    ROUND(SUM(total_revenue), 2) as state_revenue,
    ROUND(SUM(total_profit), 2) as state_profit,
    ROUND(AVG(profit_margin) * 100, 2) as avg_profit_margin_pct,
    ROUND(SUM(total_profit) / COUNT(*), 2) as profit_per_store
FROM V_STORE_PERFORMANCE
GROUP BY state_abbr, division
ORDER BY state_abbr, division;

-- Query 1.2: Pareto Analysis by State
-- Shows the 80/20 rule - which stores contribute to 80% of profits
SELECT 
    state_abbr,
    store_id,
    store_name,
    division,
    ROUND(total_profit, 2) as total_profit,
    ROUND(running_total, 2) as running_total,
    ROUND(state_total, 2) as state_total,
    cumulative_percentage,
    CASE 
        WHEN cumulative_percentage <= 80 THEN 'Top Performers (80%)'
        ELSE 'Underperformers (20%)'
    END as performance_tier
FROM (
    SELECT 
        state_abbr,
        store_id,
        store_name,
        division,
        total_profit,
        SUM(total_profit) OVER (PARTITION BY state_abbr ORDER BY total_profit DESC) as running_total,
        SUM(total_profit) OVER (PARTITION BY state_abbr) as state_total,
        ROUND(SUM(total_profit) OVER (PARTITION BY state_abbr ORDER BY total_profit DESC) / 
              SUM(total_profit) OVER (PARTITION BY state_abbr) * 100, 2) as cumulative_percentage
    FROM V_STORE_PERFORMANCE
    WHERE state_abbr IN ('QLD', 'NSW', 'VIC')
) ranked_stores
ORDER BY state_abbr, total_profit DESC;

-- Query 1.3: Financial Impact of Underperformance
-- Quantifies the dollar impact of underperforming stores
WITH state_totals AS (
    SELECT 
        state_abbr,
        SUM(total_profit) as total_state_profit,
        COUNT(*) as total_stores
    FROM V_STORE_PERFORMANCE
    WHERE state_abbr IN ('QLD', 'NSW', 'VIC')
    GROUP BY state_abbr
),
pareto_analysis AS (
    SELECT 
        v.state_abbr,
        v.store_id,
        v.store_name,
        v.total_profit,
        st.total_state_profit,
        st.total_stores,
        SUM(v.total_profit) OVER (PARTITION BY v.state_abbr ORDER BY v.total_profit DESC) as running_total,
        ROW_NUMBER() OVER (PARTITION BY v.state_abbr ORDER BY v.total_profit DESC) as store_rank
    FROM V_STORE_PERFORMANCE v
    JOIN state_totals st ON v.state_abbr = st.state_abbr
    WHERE v.state_abbr IN ('QLD', 'NSW', 'VIC')
)
SELECT 
    state_abbr,
    COUNT(CASE WHEN store_rank <= CEIL(total_stores * 0.2) THEN 1 END) as top_20_percent_stores,
    ROUND(SUM(CASE WHEN store_rank <= CEIL(total_stores * 0.2) THEN total_profit ELSE 0 END), 2) as top_20_percent_profit,
    COUNT(CASE WHEN store_rank > CEIL(total_stores * 0.2) THEN 1 END) as bottom_80_percent_stores,
    ROUND(SUM(CASE WHEN store_rank > CEIL(total_stores * 0.2) THEN total_profit ELSE 0 END), 2) as bottom_80_percent_profit,
    ROUND(total_state_profit, 2) as total_state_profit,
    ROUND(SUM(CASE WHEN store_rank <= CEIL(total_stores * 0.2) THEN total_profit ELSE 0 END) / total_state_profit * 100, 2) as top_20_percent_contribution,
    ROUND(SUM(CASE WHEN store_rank > CEIL(total_stores * 0.2) THEN total_profit ELSE 0 END) / total_state_profit * 100, 2) as bottom_80_percent_contribution
FROM pareto_analysis
GROUP BY state_abbr, total_state_profit, total_stores
ORDER BY state_abbr;

-- =====================================================
-- TIMESERIES ANALYSIS: WEEK-TO-WEEK SALES BY STATE
-- =====================================================

-- Query 2.1: Weekly Sales Timeseries by State (All Years)
-- Shows week-to-week sales trends across all states
SELECT 
    EXTRACT(YEAR FROM sale_date) as year,
    EXTRACT(WEEK FROM sale_date) as week_number,
    DATE_TRUNC('WEEK', sale_date) as week_start_date,
    state_abbr,
    division,
    COUNT(DISTINCT store_id) as store_count,
    ROUND(SUM(gross_revenue), 2) as weekly_revenue,
    ROUND(SUM(gross_profit), 2) as weekly_profit,
    ROUND(AVG(gross_revenue), 2) as avg_daily_revenue,
    ROUND(SUM(gross_profit) / NULLIF(SUM(gross_revenue), 0) * 100, 2) as profit_margin_pct
FROM FACT_DAILY_SALES f
JOIN DIM_STORE s ON f.store_id = s.store_id
GROUP BY EXTRACT(YEAR FROM sale_date), EXTRACT(WEEK FROM sale_date), 
         DATE_TRUNC('WEEK', sale_date), state_abbr, division
ORDER BY year, week_number, state_abbr;

-- Query 2.2: Weekly Sales Growth Rate by State
-- Shows week-over-week growth rates to identify trends
WITH weekly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM sale_date) as year,
        EXTRACT(WEEK FROM sale_date) as week_number,
        DATE_TRUNC('WEEK', sale_date) as week_start_date,
        state_abbr,
        ROUND(SUM(gross_revenue), 2) as weekly_revenue
    FROM FACT_DAILY_SALES f
    JOIN DIM_STORE s ON f.store_id = s.store_id
    GROUP BY EXTRACT(YEAR FROM sale_date), EXTRACT(WEEK FROM sale_date), 
             DATE_TRUNC('WEEK', sale_date), state_abbr
),
weekly_growth AS (
    SELECT 
        year,
        week_number,
        week_start_date,
        state_abbr,
        weekly_revenue,
        LAG(weekly_revenue) OVER (PARTITION BY state_abbr, year ORDER BY week_number) as prev_week_revenue
    FROM weekly_sales
)
SELECT 
    year,
    week_number,
    week_start_date,
    state_abbr,
    weekly_revenue,
    prev_week_revenue,
    ROUND(
        (weekly_revenue - prev_week_revenue) / NULLIF(prev_week_revenue, 0) * 100, 2
    ) as week_over_week_growth_pct,
    ROUND(weekly_revenue - prev_week_revenue, 2) as revenue_change
FROM weekly_growth
WHERE prev_week_revenue IS NOT NULL
ORDER BY year, week_number, state_abbr;

-- Query 2.3: Cyclone Impact Weekly Analysis
-- Shows the dramatic impact during cyclone weeks
SELECT 
    EXTRACT(YEAR FROM sale_date) as year,
    EXTRACT(WEEK FROM sale_date) as week_number,
    DATE_TRUNC('WEEK', sale_date) as week_start_date,
    state_abbr,
    CASE 
        WHEN s.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 'Impacted Postcode'
        ELSE 'Non-Impacted Postcode'
    END as impact_status,
    COUNT(DISTINCT s.store_id) as store_count,
    ROUND(SUM(gross_revenue), 2) as weekly_revenue,
    ROUND(SUM(gross_profit), 2) as weekly_profit,
    ROUND(AVG(gross_revenue), 2) as avg_daily_revenue,
    -- Cyclone period classification
    CASE 
        WHEN sale_date < '2024-02-01' THEN 'Pre-Cyclone'
        WHEN sale_date BETWEEN '2024-02-01' AND '2024-02-15' THEN 'During Cyclone'
        WHEN sale_date > '2024-02-15' THEN 'Post-Cyclone'
        ELSE 'Normal Period'
    END as cyclone_period
FROM FACT_DAILY_SALES f
JOIN DIM_STORE s ON f.store_id = s.store_id
WHERE EXTRACT(YEAR FROM sale_date) = 2024  -- Focus on 2024 for cyclone analysis
GROUP BY EXTRACT(YEAR FROM sale_date), EXTRACT(WEEK FROM sale_date), 
         DATE_TRUNC('WEEK', sale_date), state_abbr,
         CASE 
             WHEN s.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 'Impacted Postcode'
             ELSE 'Non-Impacted Postcode'
         END,
         CASE 
             WHEN sale_date < '2024-02-01' THEN 'Pre-Cyclone'
             WHEN sale_date BETWEEN '2024-02-01' AND '2024-02-15' THEN 'During Cyclone'
             WHEN sale_date > '2024-02-15' THEN 'Post-Cyclone'
             ELSE 'Normal Period'
         END
ORDER BY week_number, state_abbr, impact_status;

-- Query 2.4: Rolling 4-Week Average by State
-- Shows smoothed trends using rolling averages
WITH weekly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM sale_date) as year,
        EXTRACT(WEEK FROM sale_date) as week_number,
        DATE_TRUNC('WEEK', sale_date) as week_start_date,
        state_abbr,
        ROUND(SUM(gross_revenue), 2) as weekly_revenue
    FROM FACT_DAILY_SALES f
    JOIN DIM_STORE s ON f.store_id = s.store_id
    GROUP BY EXTRACT(YEAR FROM sale_date), EXTRACT(WEEK FROM sale_date), 
             DATE_TRUNC('WEEK', sale_date), state_abbr
)
SELECT 
    year,
    week_number,
    week_start_date,
    state_abbr,
    weekly_revenue,
    ROUND(
        AVG(weekly_revenue) OVER (
            PARTITION BY state_abbr, year 
            ORDER BY week_number 
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ), 2
    ) as rolling_4week_avg,
    ROUND(
        (weekly_revenue - 
         AVG(weekly_revenue) OVER (
             PARTITION BY state_abbr, year 
             ORDER BY week_number 
             ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
         )
        ) / NULLIF(
            AVG(weekly_revenue) OVER (
                PARTITION BY state_abbr, year 
                ORDER BY week_number 
                ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
            ), 0
        ) * 100, 2
    ) as vs_4week_avg_pct
FROM weekly_sales
ORDER BY year, week_number, state_abbr;

-- Query 2.5: Year-over-Year Weekly Comparison
-- Compares same weeks across different years
WITH weekly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM sale_date) as year,
        EXTRACT(WEEK FROM sale_date) as week_number,
        state_abbr,
        ROUND(SUM(gross_revenue), 2) as weekly_revenue
    FROM FACT_DAILY_SALES f
    JOIN DIM_STORE s ON f.store_id = s.store_id
    GROUP BY EXTRACT(YEAR FROM sale_date), EXTRACT(WEEK FROM sale_date), state_abbr
),
yoy_comparison AS (
    SELECT 
        week_number,
        state_abbr,
        MAX(CASE WHEN year = 2023 THEN weekly_revenue END) as revenue_2023,
        MAX(CASE WHEN year = 2024 THEN weekly_revenue END) as revenue_2024,
        MAX(CASE WHEN year = 2025 THEN weekly_revenue END) as revenue_2025
    FROM weekly_sales
    GROUP BY week_number, state_abbr
)
SELECT 
    week_number,
    state_abbr,
    revenue_2023,
    revenue_2024,
    revenue_2025,
    ROUND(
        (revenue_2024 - revenue_2023) / NULLIF(revenue_2023, 0) * 100, 2
    ) as yoy_2024_vs_2023_pct,
    ROUND(
        (revenue_2025 - revenue_2024) / NULLIF(revenue_2024, 0) * 100, 2
    ) as yoy_2025_vs_2024_pct
FROM yoy_comparison
WHERE revenue_2023 IS NOT NULL AND revenue_2024 IS NOT NULL
ORDER BY week_number, state_abbr;

-- =====================================================
-- USE CASE 2: HISTORIC EVENT IMPACT (CYCLONE ALFRED)
-- =====================================================

-- Query 3.1: Cyclone Impact Overview
-- Shows the overall impact across Pre, During, and Post periods
SELECT 
    period,
    COUNT(DISTINCT store_id) as affected_stores,
    ROUND(SUM(daily_revenue), 2) as total_revenue,
    ROUND(SUM(daily_profit), 2) as total_profit,
    ROUND(AVG(daily_revenue), 2) as avg_daily_revenue,
    ROUND(AVG(daily_profit), 2) as avg_daily_profit,
    COUNT(DISTINCT sale_date) as days_in_period
FROM V_CYCLONE_IMPACT
GROUP BY period
ORDER BY 
    CASE period
        WHEN 'Pre-Cyclone' THEN 1
        WHEN 'During Cyclone' THEN 2
        WHEN 'Post-Cyclone' THEN 3
    END;

-- Query 3.2: Product Category Impact During Cyclone
-- Shows what people were buying during the cyclone
SELECT 
    p.category,
    p.product_name,
    COUNT(DISTINCT f.store_id) as stores_selling,
    ROUND(SUM(f.gross_revenue), 2) as total_revenue,
    ROUND(SUM(f.gross_profit), 2) as total_profit,
    ROUND(AVG(f.gross_revenue), 2) as avg_revenue_per_sale,
    ROUND(SUM(f.quantity_sold), 0) as total_quantity_sold
FROM FACT_DAILY_SALES f
JOIN DIM_PRODUCT p ON f.product_id = p.product_id
JOIN DIM_STORE s ON f.store_id = s.store_id
WHERE s.state_abbr = 'QLD' 
    AND f.sale_date BETWEEN '2024-02-01' AND '2024-02-15'
GROUP BY p.category, p.product_name
ORDER BY total_revenue DESC;

-- Query 3.3: Geographic Impact Analysis
-- Shows impact by specific locations (postcodes)
SELECT 
    s.postcode,
    s.store_name,
    s.division,
    ROUND(SUM(CASE WHEN f.sale_date < '2024-02-01' THEN f.gross_revenue ELSE 0 END), 2) as pre_cyclone_revenue,
    ROUND(SUM(CASE WHEN f.sale_date BETWEEN '2024-02-01' AND '2024-02-15' THEN f.gross_revenue ELSE 0 END), 2) as during_cyclone_revenue,
    ROUND(SUM(CASE WHEN f.sale_date > '2024-02-15' THEN f.gross_revenue ELSE 0 END), 2) as post_cyclone_revenue,
    ROUND(
        (SUM(CASE WHEN f.sale_date BETWEEN '2024-02-01' AND '2024-02-15' THEN f.gross_revenue ELSE 0 END) - 
         SUM(CASE WHEN f.sale_date < '2024-02-01' THEN f.gross_revenue ELSE 0 END)) / 
        NULLIF(SUM(CASE WHEN f.sale_date < '2024-02-01' THEN f.gross_revenue ELSE 0 END), 0) * 100, 2
    ) as revenue_change_pct
FROM DIM_STORE s
JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
WHERE s.state_abbr = 'QLD' 
    AND f.sale_date BETWEEN '2024-01-15' AND '2024-03-15'
GROUP BY s.postcode, s.store_name, s.division
ORDER BY revenue_change_pct;

-- Query 3.4: External Data Integration - Weather Impact
-- Shows correlation between weather conditions and sales
SELECT 
    w.weather_condition,
    w.severity_level,
    COUNT(DISTINCT f.store_id) as affected_stores,
    ROUND(SUM(f.gross_revenue), 2) as total_revenue,
    ROUND(SUM(f.gross_profit), 2) as total_profit,
    ROUND(AVG(f.gross_revenue), 2) as avg_daily_revenue,
    COUNT(DISTINCT f.sale_date) as days_with_condition
FROM FACT_DAILY_SALES f
JOIN DIM_STORE s ON f.store_id = s.store_id
JOIN WEATHER_DATA w ON f.sale_date = w.date AND s.postcode = w.postcode
WHERE s.state_abbr = 'QLD' 
    AND f.sale_date BETWEEN '2024-01-15' AND '2024-03-15'
GROUP BY w.weather_condition, w.severity_level
ORDER BY total_revenue DESC;

-- Query 3.5: Financial Quantification of Cyclone Impact
-- Estimates the dollar value of the cyclone impact
WITH pre_cyclone_avg AS (
    SELECT 
        s.store_id,
        s.division,
        AVG(f.gross_revenue) as avg_daily_revenue,
        AVG(f.gross_profit) as avg_daily_profit
    FROM DIM_STORE s
    JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
    WHERE s.state_abbr = 'QLD' 
        AND f.sale_date BETWEEN '2024-01-15' AND '2024-01-31'
    GROUP BY s.store_id, s.division
),
cyclone_period AS (
    SELECT 
        s.store_id,
        s.division,
        SUM(f.gross_revenue) as actual_revenue,
        SUM(f.gross_profit) as actual_profit,
        COUNT(DISTINCT f.sale_date) as days_affected
    FROM DIM_STORE s
    JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
    WHERE s.state_abbr = 'QLD' 
        AND f.sale_date BETWEEN '2024-02-01' AND '2024-02-15'
    GROUP BY s.store_id, s.division
)
SELECT 
    pca.division,
    COUNT(*) as stores_affected,
    ROUND(SUM(pca.avg_daily_revenue * cp.days_affected), 2) as expected_revenue,
    ROUND(SUM(cp.actual_revenue), 2) as actual_revenue,
    ROUND(SUM(pca.avg_daily_revenue * cp.days_affected) - SUM(cp.actual_revenue), 2) as revenue_impact,
    ROUND(SUM(pca.avg_daily_profit * cp.days_affected), 2) as expected_profit,
    ROUND(SUM(cp.actual_profit), 2) as actual_profit,
    ROUND(SUM(pca.avg_daily_profit * cp.days_affected) - SUM(cp.actual_profit), 2) as profit_impact
FROM pre_cyclone_avg pca
JOIN cyclone_period cp ON pca.store_id = cp.store_id
GROUP BY pca.division
ORDER BY profit_impact DESC;

-- =====================================================
-- OUTLIER ANALYSIS - CYCLONE IMPACT BY POSTCODE
-- =====================================================

-- Query 3.6: Outlier Analysis - Cyclone Impact by Postcode Severity
-- Shows how different postcodes were affected differently during the cyclone
SELECT 
    s.postcode,
    s.store_name,
    s.division,
    COUNT(DISTINCT f.sale_date) as days_affected,
    ROUND(SUM(f.gross_revenue), 2) as total_revenue_during_cyclone,
    ROUND(SUM(f.gross_profit), 2) as total_profit_during_cyclone,
    ROUND(AVG(f.gross_revenue), 2) as avg_daily_revenue,
    ROUND(AVG(f.gross_profit), 2) as avg_daily_profit,
    CASE 
        WHEN s.postcode IN ('4000', '4001', '4217', '4218') THEN 'High Impact - Severe Disruption'
        WHEN s.postcode IN ('4870', '4871') THEN 'Medium Impact - Moderate Disruption'
        ELSE 'Low Impact - Minimal Disruption'
    END as impact_severity
FROM DIM_STORE s
JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
WHERE s.state_abbr = 'QLD' 
    AND f.sale_date BETWEEN '2024-02-01' AND '2024-02-15'
GROUP BY s.postcode, s.store_name, s.division
ORDER BY total_revenue_during_cyclone DESC;

-- Query 3.7: Outlier Detection - Stores with Extreme Revenue Changes
-- Identifies stores with the most extreme revenue changes during cyclone
WITH pre_cyclone_avg AS (
    SELECT 
        s.store_id,
        s.postcode,
        s.store_name,
        s.division,
        AVG(f.gross_revenue) as avg_daily_revenue,
        AVG(f.gross_profit) as avg_daily_profit
    FROM DIM_STORE s
    JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
    WHERE s.state_abbr = 'QLD' 
        AND f.sale_date BETWEEN '2024-01-15' AND '2024-01-31'
    GROUP BY s.store_id, s.postcode, s.store_name, s.division
),
cyclone_period AS (
    SELECT 
        s.store_id,
        s.postcode,
        s.store_name,
        s.division,
        AVG(f.gross_revenue) as avg_daily_revenue,
        AVG(f.gross_profit) as avg_daily_profit,
        COUNT(DISTINCT f.sale_date) as days_affected
    FROM DIM_STORE s
    JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
    WHERE s.state_abbr = 'QLD' 
        AND f.sale_date BETWEEN '2024-02-01' AND '2024-02-15'
    GROUP BY s.store_id, s.postcode, s.store_name, s.division
)
SELECT 
    cp.postcode,
    cp.store_name,
    cp.division,
    ROUND(pca.avg_daily_revenue, 2) as pre_cyclone_avg_revenue,
    ROUND(cp.avg_daily_revenue, 2) as cyclone_avg_revenue,
    ROUND(cp.avg_daily_revenue - pca.avg_daily_revenue, 2) as revenue_change,
    ROUND((cp.avg_daily_revenue - pca.avg_daily_revenue) / pca.avg_daily_revenue * 100, 2) as revenue_change_pct,
    ROUND(pca.avg_daily_profit, 2) as pre_cyclone_avg_profit,
    ROUND(cp.avg_daily_profit, 2) as cyclone_avg_profit,
    ROUND(cp.avg_daily_profit - pca.avg_daily_profit, 2) as profit_change,
    ROUND((cp.avg_daily_profit - pca.avg_daily_profit) / pca.avg_daily_profit * 100, 2) as profit_change_pct,
    CASE 
        WHEN (cp.avg_daily_revenue - pca.avg_daily_revenue) / pca.avg_daily_revenue > 1.0 THEN 'Extreme Surge (>100% increase)'
        WHEN (cp.avg_daily_revenue - pca.avg_daily_revenue) / pca.avg_daily_revenue > 0.5 THEN 'High Surge (50-100% increase)'
        WHEN (cp.avg_daily_revenue - pca.avg_daily_revenue) / pca.avg_daily_revenue > 0.0 THEN 'Moderate Increase (0-50% increase)'
        WHEN (cp.avg_daily_revenue - pca.avg_daily_revenue) / pca.avg_daily_revenue > -0.5 THEN 'Moderate Decrease (0-50% decrease)'
        WHEN (cp.avg_daily_revenue - pca.avg_daily_revenue) / pca.avg_daily_revenue > -0.8 THEN 'High Decrease (50-80% decrease)'
        ELSE 'Extreme Decrease (>80% decrease)'
    END as outlier_category
FROM pre_cyclone_avg pca
JOIN cyclone_period cp ON pca.store_id = cp.store_id
ORDER BY revenue_change_pct DESC;

-- =====================================================
-- COMBINED ANALYSIS QUERIES
-- =====================================================

-- Query 3.1: State Performance vs Event Impact
-- Combines both use cases to show which states are most affected by events
SELECT 
    sp.state_abbr,
    sp.division,
    COUNT(*) as store_count,
    ROUND(SUM(sp.total_profit), 2) as ytd_profit,
    ROUND(AVG(sp.profit_margin) * 100, 2) as avg_profit_margin_pct,
    COUNT(CASE WHEN e.event_type = 'Cyclone Alfred' THEN 1 END) as cyclone_affected_days,
    ROUND(SUM(CASE WHEN e.event_type = 'Cyclone Alfred' THEN 1 ELSE 0 END) / COUNT(DISTINCT sp.store_id), 2) as avg_cyclone_days_per_store
FROM V_STORE_PERFORMANCE sp
LEFT JOIN DIM_STORE s ON sp.store_id = s.store_id
LEFT JOIN EVENTS_DATA e ON s.postcode = e.postcode AND e.date BETWEEN '2024-02-01' AND '2024-02-15'
GROUP BY sp.state_abbr, sp.division
ORDER BY ytd_profit DESC;

-- =====================================================
-- DATA QUALITY AND VALIDATION QUERIES
-- =====================================================

-- Query 4.1: Data Completeness Check
SELECT 
    'FACT_DAILY_SALES' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT sale_date) as unique_dates,
    COUNT(DISTINCT store_id) as unique_stores,
    COUNT(DISTINCT product_id) as unique_products,
    MIN(sale_date) as earliest_date,
    MAX(sale_date) as latest_date
FROM FACT_DAILY_SALES
UNION ALL
SELECT 
    'WEATHER_DATA',
    COUNT(*),
    COUNT(DISTINCT date),
    COUNT(DISTINCT postcode),
    NULL,
    MIN(date),
    MAX(date)
FROM WEATHER_DATA
UNION ALL
SELECT 
    'EVENTS_DATA',
    COUNT(*),
    COUNT(DISTINCT date),
    COUNT(DISTINCT postcode),
    NULL,
    MIN(date),
    MAX(date)
FROM EVENTS_DATA;

-- Query 4.2: Revenue and Profit Validation
SELECT 
    'Revenue Validation' as check_type,
    ROUND(SUM(gross_revenue), 2) as total_revenue,
    ROUND(AVG(gross_revenue), 2) as avg_revenue,
    ROUND(MIN(gross_revenue), 2) as min_revenue,
    ROUND(MAX(gross_revenue), 2) as max_revenue,
    COUNT(CASE WHEN gross_revenue <= 0 THEN 1 END) as zero_or_negative_revenue
FROM FACT_DAILY_SALES
UNION ALL
SELECT 
    'Profit Validation',
    ROUND(SUM(gross_profit), 2),
    ROUND(AVG(gross_profit), 2),
    ROUND(MIN(gross_profit), 2),
    ROUND(MAX(gross_profit), 2),
    COUNT(CASE WHEN gross_profit <= 0 THEN 1 END)
FROM FACT_DAILY_SALES;
