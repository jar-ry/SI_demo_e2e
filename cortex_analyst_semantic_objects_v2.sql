-- =====================================================
-- Snowflake Cortex Analyst Semantic Layer Objects V2
-- =====================================================
-- This script creates semantic objects for Cortex Analyst
-- Maps physical tables to business-friendly semantic objects
-- =====================================================
-- NOTE: Run create_demo_data_v2.sql first to create:
--   - RETAIL_SI_DEMO_ADMIN_V2 role
--   - RETAIL_SI_DEMO_WH_V2 warehouse
--   - Retail_SI_Demo_v2 database and schema
--   - All base tables
-- =====================================================

-- Use the admin role to create all views
USE ROLE RETAIL_SI_DEMO_ADMIN_V2;
USE WAREHOUSE RETAIL_SI_DEMO_WH_V2;
USE DATABASE Retail_SI_Demo_v2;
USE SCHEMA Retail_SI_Demo_v2;

-- =====================================================
-- SEMANTIC MODELS (Using Views Instead)
-- =====================================================

-- Note: Snowflake doesn't have SEMANTIC MODEL syntax
-- Using views and semantic objects instead

-- =====================================================
-- BUSINESS VIEWS (Business-Friendly Names)
-- =====================================================

-- =====================================================
-- CORTEX ANALYST FRIENDLY VIEWS
-- =====================================================

-- 1. Store Performance View - Daily store-level metrics (can be filtered by state)
CREATE OR REPLACE VIEW cortex_store_performance AS
SELECT 
    s.store_id,
    s.store_name,
    s.division,
    s.state_abbr,
    s.postcode,
    f.sale_date,
    ROUND(SUM(f.gross_revenue), 2) as daily_revenue,
    ROUND(SUM(f.gross_profit), 2) as daily_profit,
    ROUND(SUM(f.gross_profit) / NULLIF(SUM(f.gross_revenue), 0) * 100, 2) as profit_margin_pct,
    SUM(f.quantity_sold) as daily_quantity_sold,
    EXTRACT(YEAR FROM f.sale_date) as year,
    EXTRACT(QUARTER FROM f.sale_date) as quarter,
    EXTRACT(MONTH FROM f.sale_date) as month,
    EXTRACT(WEEK FROM f.sale_date) as week_number
FROM DIM_STORE s
LEFT JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
WHERE f.sale_date >= '2024-01-01'
GROUP BY s.store_id, s.store_name, s.division, s.state_abbr, s.postcode, f.sale_date;

-- 2. Event Impact Analysis View - Shows impact of Cyclone Alfred and AFL Grand Finals
CREATE OR REPLACE VIEW cortex_event_impact AS
SELECT 
    'Event Impact' as analysis_type,
    s.store_id,
    s.store_name,
    s.division,
    s.state_abbr,
    s.postcode,
    f.sale_date,
    ROUND(SUM(f.gross_revenue), 2) as daily_revenue,
    ROUND(SUM(f.gross_profit), 2) as daily_profit,
    ROUND(SUM(f.gross_profit) / NULLIF(SUM(f.gross_revenue), 0) * 100, 2) as profit_margin_pct,
    SUM(f.quantity_sold) as daily_quantity_sold,
    -- Event classification (includes pre, during, and post periods)
    CASE 
        WHEN f.sale_date BETWEEN '2024-01-15' AND '2024-03-15' THEN 'Cyclone Alfred'
        WHEN f.sale_date BETWEEN '2025-09-19' AND '2025-10-01' THEN 'AFL Grand Finals'
        ELSE 'Normal Period'
    END as event_name,
    -- Event period classification
    CASE 
        -- Cyclone Alfred periods
        WHEN f.sale_date BETWEEN '2024-01-15' AND '2024-01-31' THEN 'Pre-Event'
        WHEN f.sale_date BETWEEN '2024-02-01' AND '2024-02-15' THEN 'During Event'
        WHEN f.sale_date BETWEEN '2024-02-16' AND '2024-03-15' THEN 'Post-Event'
        -- AFL Grand Finals periods
        WHEN f.sale_date BETWEEN '2025-09-19' AND '2025-09-25' THEN 'Pre-Event'
        WHEN f.sale_date BETWEEN '2025-09-26' AND '2025-09-27' THEN 'During Event'
        WHEN f.sale_date BETWEEN '2025-09-28' AND '2025-10-01' THEN 'Post-Event'
        ELSE 'Normal Period'
    END as event_period,
    EXTRACT(YEAR FROM f.sale_date) as year,
    EXTRACT(MONTH FROM f.sale_date) as month,
    EXTRACT(WEEK FROM f.sale_date) as week_number
FROM DIM_STORE s
JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
WHERE f.sale_date >= '2024-01-01'
GROUP BY s.store_id, s.store_name, s.division, s.state_abbr, s.postcode, f.sale_date;

-- 3. Pareto Analysis View - Shows 80/20 distribution of store performance
CREATE OR REPLACE VIEW cortex_pareto_analysis AS
SELECT 
    'Pareto Analysis' as analysis_type,
    s.state_abbr,
    s.store_id,
    s.store_name,
    s.division,
    EXTRACT(YEAR FROM f.sale_date) as year,
    ROUND(SUM(f.gross_revenue), 2) as total_revenue,
    ROUND(SUM(f.gross_profit), 2) as total_profit,
    ROUND(SUM(f.gross_profit) / NULLIF(SUM(f.gross_revenue), 0) * 100, 2) as profit_margin_pct,
    ROUND(SUM(SUM(f.gross_profit)) OVER (PARTITION BY s.state_abbr, EXTRACT(YEAR FROM f.sale_date) ORDER BY SUM(f.gross_profit) DESC), 2) as running_total_profit,
    ROUND(SUM(SUM(f.gross_profit)) OVER (PARTITION BY s.state_abbr, EXTRACT(YEAR FROM f.sale_date)), 2) as state_total_profit,
    ROUND(SUM(SUM(f.gross_profit)) OVER (PARTITION BY s.state_abbr, EXTRACT(YEAR FROM f.sale_date) ORDER BY SUM(f.gross_profit) DESC) / 
          NULLIF(SUM(SUM(f.gross_profit)) OVER (PARTITION BY s.state_abbr, EXTRACT(YEAR FROM f.sale_date)), 0) * 100, 2) as cumulative_percentage,
    CASE 
        WHEN ROUND(SUM(SUM(f.gross_profit)) OVER (PARTITION BY s.state_abbr, EXTRACT(YEAR FROM f.sale_date) ORDER BY SUM(f.gross_profit) DESC) / 
                  NULLIF(SUM(SUM(f.gross_profit)) OVER (PARTITION BY s.state_abbr, EXTRACT(YEAR FROM f.sale_date)), 0) * 100, 2) <= 80 THEN 'Top Performers (80%)'
        ELSE 'Underperformers (20%)'
    END as performance_tier
FROM DIM_STORE s
LEFT JOIN FACT_DAILY_SALES f ON s.store_id = f.store_id
WHERE f.sale_date >= '2024-01-01'
GROUP BY s.state_abbr, s.store_id, s.store_name, s.division, EXTRACT(YEAR FROM f.sale_date);

-- 4. Weather Data View - Shows weather conditions for event correlation
CREATE OR REPLACE VIEW cortex_weather_data AS
SELECT 
    'Weather Data' as analysis_type,
    w.date as weather_date,
    w.postcode,
    w.weather_condition,
    ROUND(w.temperature, 1) as temperature_celsius,
    ROUND(w.wind_speed, 1) as wind_speed_kmh,
    ROUND(w.precipitation, 1) as precipitation_mm,
    w.severity_level,
    EXTRACT(YEAR FROM w.date) as year,
    EXTRACT(MONTH FROM w.date) as month,
    EXTRACT(WEEK FROM w.date) as week_number,
    -- Weather category for easier analysis
    CASE 
        WHEN w.weather_condition = 'Cyclone' THEN 'Severe Weather'
        WHEN w.weather_condition = 'Rain' THEN 'Wet Weather'
        WHEN w.weather_condition IN ('Sunny', 'Partly Cloudy') THEN 'Clear Weather'
        ELSE 'Moderate Weather'
    END as weather_category
FROM WEATHER_DATA w
WHERE w.date >= '2024-01-01';

-- 5. Events Data View - Shows events for impact analysis
CREATE OR REPLACE VIEW cortex_events_data AS
SELECT 
    'Events Data' as analysis_type,
    e.date as event_date,
    e.postcode,
    e.event_type,
    e.event_description,
    ROUND(e.impact_radius_km, 1) as impact_radius_km,
    e.severity_score,
    EXTRACT(YEAR FROM e.date) as year,
    EXTRACT(MONTH FROM e.date) as month,
    EXTRACT(WEEK FROM e.date) as week_number,
    -- Event category for easier analysis
    CASE 
        WHEN e.event_type = 'Cyclone Alfred' THEN 'Natural Disaster'
        WHEN e.event_type = 'AFL Grand Finals' THEN 'Major Sporting Event'
        WHEN e.event_type = 'Sporting Event' THEN 'Sporting Event'
        WHEN e.event_type = 'Public Holiday' THEN 'Public Holiday'
        WHEN e.event_type = 'Festival' THEN 'Cultural Event'
        ELSE 'Other Event'
    END as event_category
FROM EVENTS_DATA e
WHERE e.date >= '2024-01-01'
    AND e.event_type != 'Normal Day';

-- 6. Product Performance View - Shows product sales by category
CREATE OR REPLACE VIEW cortex_product_performance AS
SELECT 
    'Product Performance' as analysis_type,
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    s.state_abbr,
    s.division,
    f.sale_date,
    ROUND(SUM(f.gross_revenue), 2) as daily_revenue,
    ROUND(SUM(f.gross_profit), 2) as daily_profit,
    ROUND(SUM(f.gross_profit) / NULLIF(SUM(f.gross_revenue), 0) * 100, 2) as profit_margin_pct,
    SUM(f.quantity_sold) as daily_quantity_sold,
    EXTRACT(YEAR FROM f.sale_date) as year,
    EXTRACT(QUARTER FROM f.sale_date) as quarter,
    EXTRACT(MONTH FROM f.sale_date) as month,
    -- Business-friendly category names
    CASE 
        WHEN p.category = 'Hardware' THEN 'Hardware & Tools'
        WHEN p.category = 'Apparel' THEN 'Clothing & Fashion'
        WHEN p.category = 'Home' THEN 'Home & Living'
        WHEN p.category = 'Electronics' THEN 'Technology'
        WHEN p.category = 'Food' THEN 'Food & Beverages'
        ELSE 'Other'
    END as business_category
FROM DIM_PRODUCT p
LEFT JOIN FACT_DAILY_SALES f ON p.product_id = f.product_id
LEFT JOIN DIM_STORE s ON f.store_id = s.store_id
WHERE f.sale_date >= '2024-01-01'
GROUP BY p.product_id, p.product_name, p.category, p.brand, s.state_abbr, s.division, f.sale_date;

-- =====================================================
-- CORTEX ANALYST QUERY EXAMPLES
-- =====================================================

-- Example queries that work well with Cortex Analyst:

-- 1. "Show me YTD revenue by state for 2024"
-- SELECT state_abbr, division, SUM(daily_revenue) as ytd_revenue, SUM(daily_profit) as ytd_profit
-- FROM cortex_store_performance 
-- WHERE year = 2024 
-- GROUP BY state_abbr, division;

-- 2. "Which stores are in the top 20% of performers in Victoria?"
-- SELECT store_name, division, total_profit, cumulative_percentage
-- FROM cortex_pareto_analysis 
-- WHERE state_abbr = 'VIC' AND year = 2024 AND cumulative_percentage <= 80;

-- 3. "Show me the impact of the AFL Grand Finals on Victoria stores"
-- SELECT event_name, event_period, AVG(daily_revenue) as avg_revenue, SUM(daily_profit) as total_profit
-- FROM cortex_event_impact
-- WHERE state_abbr = 'VIC' AND event_name = 'AFL Grand Finals'
-- GROUP BY event_name, event_period;

-- 3b. "Compare pre-AFL vs during AFL performance in Victoria"
-- SELECT 
--     event_period,
--     COUNT(DISTINCT store_id) as store_count,
--     AVG(daily_revenue) as avg_daily_revenue,
--     SUM(daily_profit) as total_profit,
--     AVG(profit_margin_pct) as avg_profit_margin
-- FROM cortex_event_impact
-- WHERE state_abbr = 'VIC' 
--     AND event_name = 'AFL Grand Finals'
--     AND event_period IN ('Pre-Event', 'During Event')
-- GROUP BY event_period
-- ORDER BY CASE event_period 
--     WHEN 'Pre-Event' THEN 1 
--     WHEN 'During Event' THEN 2 
-- END;

-- 3c. "Show revenue change from pre-AFL to during AFL by store"
-- WITH pre_afl AS (
--     SELECT store_id, store_name, AVG(daily_revenue) as pre_revenue
--     FROM cortex_event_impact
--     WHERE state_abbr = 'VIC' AND event_name = 'AFL Grand Finals' AND event_period = 'Pre-Event'
--     GROUP BY store_id, store_name
-- ),
-- during_afl AS (
--     SELECT store_id, store_name, AVG(daily_revenue) as during_revenue
--     FROM cortex_event_impact
--     WHERE state_abbr = 'VIC' AND event_name = 'AFL Grand Finals' AND event_period = 'During Event'
--     GROUP BY store_id, store_name
-- )
-- SELECT 
--     p.store_name,
--     ROUND(p.pre_revenue, 2) as pre_afl_avg_revenue,
--     ROUND(d.during_revenue, 2) as during_afl_avg_revenue,
--     ROUND(d.during_revenue - p.pre_revenue, 2) as revenue_change,
--     ROUND((d.during_revenue - p.pre_revenue) / p.pre_revenue * 100, 2) as pct_change
-- FROM pre_afl p
-- JOIN during_afl d ON p.store_id = d.store_id
-- ORDER BY pct_change DESC;

-- 4. "What products sold best during Cyclone Alfred?"
-- SELECT business_category, SUM(daily_revenue) as total_revenue
-- FROM cortex_product_performance
-- WHERE state_abbr = 'QLD' AND sale_date BETWEEN '2024-02-01' AND '2024-02-15'
-- GROUP BY business_category
-- ORDER BY total_revenue DESC;

-- 5. "Show me weather conditions during the cyclone"
-- SELECT weather_date, postcode, weather_condition, temperature_celsius, wind_speed_kmh
-- FROM cortex_weather_data
-- WHERE weather_condition = 'Cyclone'
-- ORDER BY weather_date;

-- 6. "What major events happened in 2024 and 2025?"
-- SELECT event_date, postcode, event_type, event_category, event_description
-- FROM cortex_events_data
-- WHERE event_category IN ('Natural Disaster', 'Major Sporting Event')
-- ORDER BY event_date;

-- 7. "Compare store performance during normal periods vs event periods"
-- SELECT event_period, AVG(daily_revenue) as avg_revenue, SUM(daily_profit) as total_profit
-- FROM cortex_event_impact
-- GROUP BY event_period
-- ORDER BY event_period;


-- Grant privileges on all views to the admin role
GRANT ALL PRIVILEGES ON ALL VIEWS IN SCHEMA Retail_SI_Demo_v2.Retail_SI_Demo_v2 TO ROLE RETAIL_SI_DEMO_ADMIN_V2;

-- =====================================================
-- END OF SEMANTIC LAYER SETUP
-- =====================================================

SELECT 'Semantic layer objects created successfully for Cortex Analyst V2!' as status;
SELECT 'All views granted to RETAIL_SI_DEMO_ADMIN_V2 role!' as role_status;

