-- =====================================================
-- Retail Store Performance Monitoring Demo Data
-- =====================================================
-- This script creates and populates all tables needed for:
-- 1. Store Performance & Pareto Analysis
-- 2. Historic Event Impact Analysis (Cyclone Alfred, AFL Grand Finals)
-- =====================================================

-- Create demo warehouse with appropriate sizing for analytics
CREATE WAREHOUSE IF NOT EXISTS RETAIL_SI_DEMO_WH
WITH 
    WAREHOUSE_SIZE = 'MEDIUM'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 60              -- Auto-suspend after 1 minute of inactivity
    AUTO_RESUME = TRUE             -- Auto-resume on query
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    SCALING_POLICY = 'STANDARD'
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for Retail SI Demo - Store Performance & Event Impact Analysis';

-- Use the demo warehouse
USE WAREHOUSE RETAIL_SI_DEMO_WH;

-- Create database and schema
CREATE OR REPLACE DATABASE Retail_SI_Demo;
USE DATABASE Retail_SI_Demo;
CREATE OR REPLACE SCHEMA Retail_SI_Demo;
USE SCHEMA Retail_SI_Demo;

-- =====================================================
-- DIMENSION TABLES
-- =====================================================

-- DIM_STORE: Store information with geographic data
CREATE OR REPLACE TABLE DIM_STORE (
    STORE_ID INTEGER PRIMARY KEY,
    DIVISION VARCHAR(50),
    STATE_ABBR VARCHAR(3),
    POSTCODE VARCHAR(4),
    LATITUDE DECIMAL(9, 6),
    LONGITUDE DECIMAL(9, 6),
    STORE_NAME VARCHAR(100)
);

-- DIM_PRODUCT: Product categories for analysis
CREATE OR REPLACE TABLE DIM_PRODUCT (
    PRODUCT_ID INTEGER PRIMARY KEY,
    CATEGORY VARCHAR(50),
    PRODUCT_NAME VARCHAR(100),
    BRAND VARCHAR(50)
);

-- =====================================================
-- FACT TABLE
-- =====================================================

-- FACT_DAILY_SALES: Core transactional data
CREATE OR REPLACE TABLE FACT_DAILY_SALES (
    SALE_DATE DATE,
    STORE_ID INTEGER,
    PRODUCT_ID INTEGER,
    GROSS_REVENUE DECIMAL(10, 2),
    GROSS_PROFIT DECIMAL(10, 2),
    QUANTITY_SOLD INTEGER,
    PRIMARY KEY (SALE_DATE, STORE_ID, PRODUCT_ID),
    FOREIGN KEY (STORE_ID) REFERENCES DIM_STORE(STORE_ID),
    FOREIGN KEY (PRODUCT_ID) REFERENCES DIM_PRODUCT(PRODUCT_ID)
);

-- =====================================================
-- EXTERNAL DATA TABLES (Simulating Marketplace Data)
-- =====================================================

-- WEATHER_DATA: Simulating external weather data
CREATE OR REPLACE TABLE WEATHER_DATA (
    DATE DATE,
    POSTCODE VARCHAR(4),
    WEATHER_CONDITION VARCHAR(50),
    TEMPERATURE DECIMAL(5, 2),
    WIND_SPEED DECIMAL(5, 2),
    PRECIPITATION DECIMAL(5, 2),
    SEVERITY_LEVEL VARCHAR(20)
);

-- EVENTS_DATA: Simulating external events data
CREATE OR REPLACE TABLE EVENTS_DATA (
    DATE DATE,
    POSTCODE VARCHAR(4),
    EVENT_TYPE VARCHAR(50),
    EVENT_DESCRIPTION VARCHAR(200),
    IMPACT_RADIUS_KM DECIMAL(5, 2),
    SEVERITY_SCORE INTEGER
);

-- =====================================================
-- POPULATE DIMENSION TABLES
-- =====================================================

-- Insert stores across different states with realistic data
INSERT INTO DIM_STORE VALUES
-- Queensland stores (for Cyclone Alfred impact)
(1, 'KShop', 'QLD', '4000', -27.4698, 153.0251, 'Brisbane Central'),
(2, 'Hardware Shop', 'QLD', '4000', -27.4698, 153.0251, 'Brisbane Central'),
(3, 'KShop', 'QLD', '4217', -27.9556, 153.3844, 'Gold Coast'),
(4, 'Hardware Shop', 'QLD', '4217', -27.9556, 153.3844, 'Gold Coast'),
(5, 'KShop', 'QLD', '4870', -16.9186, 145.7781, 'Cairns'),
(6, 'Hardware Shop', 'QLD', '4870', -16.9186, 145.7781, 'Cairns'),
(21, 'KShop', 'QLD', '4001', -27.4698, 153.0251, 'Brisbane North'),
(22, 'Hardware Shop', 'QLD', '4001', -27.4698, 153.0251, 'Brisbane North'),
(23, 'KShop', 'QLD', '4218', -27.9556, 153.3844, 'Gold Coast South'),
(24, 'Hardware Shop', 'QLD', '4218', -27.9556, 153.3844, 'Gold Coast South'),
(25, 'KShop', 'QLD', '4871', -16.9186, 145.7781, 'Cairns North'),
(26, 'Hardware Shop', 'QLD', '4871', -16.9186, 145.7781, 'Cairns North'),

-- New South Wales stores (for comparison)
(7, 'KShop', 'NSW', '2000', -33.8688, 151.2093, 'Sydney Central'),
(8, 'Hardware Shop', 'NSW', '2000', -33.8688, 151.2093, 'Sydney Central'),
(9, 'KShop', 'NSW', '2001', -33.8688, 151.2093, 'Sydney North'),
(10, 'Hardware Shop', 'NSW', '2001', -33.8688, 151.2093, 'Sydney North'),
(11, 'KShop', 'NSW', '2002', -33.8688, 151.2093, 'Sydney South'),
(12, 'Hardware Shop', 'NSW', '2002', -33.8688, 151.2093, 'Sydney South'),
(13, 'KShop', 'NSW', '2003', -33.8688, 151.2093, 'Sydney East'),
(14, 'Hardware Shop', 'NSW', '2003', -33.8688, 151.2093, 'Sydney East'),
(15, 'KShop', 'NSW', '2004', -33.8688, 151.2093, 'Sydney West'),
(16, 'Hardware Shop', 'NSW', '2004', -33.8688, 151.2093, 'Sydney West'),
(35, 'KShop', 'NSW', '2005', -33.8688, 151.2093, 'Sydney CBD'),
(36, 'Hardware Shop', 'NSW', '2005', -33.8688, 151.2093, 'Sydney CBD'),

-- Victoria stores
(17, 'KShop', 'VIC', '3000', -37.8136, 144.9631, 'Melbourne Central'),
(18, 'Hardware Shop', 'VIC', '3000', -37.8136, 144.9631, 'Melbourne Central'),
(19, 'KShop', 'VIC', '3056', -37.8136, 144.9631, 'Melbourne North'),
(20, 'Hardware Shop', 'VIC', '3056', -37.8136, 144.9631, 'Melbourne North'),
(21, 'KShop', 'VIC', '3002', -37.8136, 144.9631, 'Melbourne South'),
(22, 'Hardware Shop', 'VIC', '3002', -37.8136, 144.9631, 'Melbourne South'),
(37, 'KShop', 'VIC', '3103', -37.8136, 144.9631, 'Melbourne East'),
(38, 'Hardware Shop', 'VIC', '3103', -37.8136, 144.9631, 'Melbourne East'),
(39, 'KShop', 'VIC', '3032', -37.8136, 144.9631, 'Melbourne West'),
(40, 'Hardware Shop', 'VIC', '3032', -37.8136, 144.9631, 'Melbourne West'),
(41, 'KShop', 'VIC', '3005', -37.8136, 144.9631, 'Melbourne CBD'),
(42, 'Hardware Shop', 'VIC', '3005', -37.8136, 144.9631, 'Melbourne CBD');

-- Insert product categories
INSERT INTO DIM_PRODUCT VALUES
(1, 'Hardware', 'Building Supplies', 'Generic'),
(2, 'Hardware', 'Protective Materials', 'Generic'),
(3, 'Hardware', 'Safety Gear', 'Generic'),
(4, 'Hardware', 'Tools', 'Generic'),
(5, 'Apparel', 'T-Shirt', 'Generic'),
(6, 'Apparel', 'Jeans', 'Generic'),
(7, 'Apparel', 'Jacket', 'Generic'),
(8, 'Apparel', 'Shoes', 'Generic'),
(9, 'Home', 'Bedding', 'Generic'),
(10, 'Home', 'Kitchenware', 'Generic'),
(11, 'Home', 'Furniture', 'Generic'),
(12, 'Home', 'Decor', 'Generic'),
(13, 'Electronics', 'Phone', 'Generic'),
(14, 'Electronics', 'Laptop', 'Generic'),
(15, 'Electronics', 'Headphones', 'Generic'),
(16, 'Electronics', 'Camera', 'Generic'),
(17, 'Food', 'Canned Goods', 'Generic'),
(18, 'Food', 'Snacks', 'Generic'),
(19, 'Food', 'Beverages', 'Generic'),
(20, 'Food', 'Frozen', 'Generic');

-- =====================================================
-- POPULATE FACT TABLE WITH REALISTIC SALES DATA
-- =====================================================

-- Generate sales data from 2024-01-01 through first week of October 2025
-- This will include normal patterns, Cyclone Alfred impact, and AFL Grand Finals impact

INSERT INTO FACT_DAILY_SALES
WITH date_series AS (
    SELECT DATEADD(day, seq4(), '2024-01-01'::DATE) as sale_date
    FROM TABLE(GENERATOR(ROWCOUNT => 650)) -- Generate enough days to cover through 12th of Oct 2025
    WHERE DATEADD(day, seq4(), '2024-01-01'::DATE) <= '2025-10-12'::DATE -- Include data through end of first week of October 2025
),
store_product_combinations AS (
    SELECT s.store_id, p.product_id, s.state_abbr, s.division, s.postcode
    FROM DIM_STORE s
    CROSS JOIN DIM_PRODUCT p
),
base_sales AS (
    -- Revenue Stability Logic:
    -- During NORMAL periods: 80% less variance (0.20 multiplier) to show stable, predictable baseline
    -- During EVENT periods: Full variance (1.0 multiplier) to show natural volatility and impact
    -- This creates clear contrast between stable operations and event-driven disruptions
    SELECT 
        ds.sale_date,
        spc.store_id,
        spc.product_id,
        spc.state_abbr,
        spc.division,
        spc.postcode,
        -- Base revenue with stability adjustment: Consistent baseline during normal periods, natural variance during events
        (CASE 
            WHEN spc.division = 'Hardware Shop' AND spc.product_id <= 4 THEN 
                -- Fixed base + (variance * stability_factor)
                10000 + (UNIFORM(0, 1, RANDOM()) * 10000 * 
                    CASE WHEN (ds.sale_date BETWEEN '2024-01-15' AND '2024-03-15') 
                            OR (ds.sale_date BETWEEN '2025-09-19' AND '2025-10-01') 
                         THEN 1.0 ELSE 0.20 END)  -- 80% less variance in normal periods
            WHEN spc.division = 'KShop' AND spc.product_id > 4 AND spc.product_id <= 8 THEN 
                5500 + (UNIFORM(0, 1, RANDOM()) * 5000 * 
                    CASE WHEN (ds.sale_date BETWEEN '2024-01-15' AND '2024-03-15') 
                            OR (ds.sale_date BETWEEN '2025-09-19' AND '2025-10-01') 
                         THEN 1.0 ELSE 0.20 END)
            WHEN spc.division = 'KShop' AND spc.product_id > 8 AND spc.product_id <= 12 THEN 
                7000 + (UNIFORM(0, 1, RANDOM()) * 6000 * 
                    CASE WHEN (ds.sale_date BETWEEN '2024-01-15' AND '2024-03-15') 
                            OR (ds.sale_date BETWEEN '2025-09-19' AND '2025-10-01') 
                         THEN 1.0 ELSE 0.20 END)
            WHEN spc.division = 'KShop' AND spc.product_id > 12 AND spc.product_id <= 16 THEN 
                20000 + (UNIFORM(0, 1, RANDOM()) * 20000 * 
                    CASE WHEN (ds.sale_date BETWEEN '2024-01-15' AND '2024-03-15') 
                            OR (ds.sale_date BETWEEN '2025-09-19' AND '2025-10-01') 
                         THEN 1.0 ELSE 0.20 END)
            WHEN spc.division = 'KShop' AND spc.product_id > 16 THEN 
                3500 + (UNIFORM(0, 1, RANDOM()) * 3000 * 
                    CASE WHEN (ds.sale_date BETWEEN '2024-01-15' AND '2024-03-15') 
                            OR (ds.sale_date BETWEEN '2025-09-19' AND '2025-10-01') 
                         THEN 1.0 ELSE 0.20 END)
            ELSE 
                5000 + (UNIFORM(0, 1, RANDOM()) * 5000 * 
                    CASE WHEN (ds.sale_date BETWEEN '2024-01-15' AND '2024-03-15') 
                            OR (ds.sale_date BETWEEN '2025-09-19' AND '2025-10-01') 
                         THEN 1.0 ELSE 0.20 END)
        END) * 
        -- State-specific revenue adjustments with trends
        CASE 
            WHEN spc.state_abbr = 'QLD' THEN 
                -- QLD: Base revenue with slight upward trend over time
                1.0 + (DATEDIFF(day, '2024-01-01'::DATE, ds.sale_date) * 0.0002) -- 0.02% increase per day
            WHEN spc.state_abbr = 'VIC' THEN 
                -- VIC: Lower revenue than QLD but same upward trend
                0.85 + (DATEDIFF(day, '2024-01-01'::DATE, ds.sale_date) * 0.0002) -- 15% lower than QLD, same trend
            WHEN spc.state_abbr = 'NSW' THEN 
                -- NSW: Same base revenue but trending downwards
                1.3 - (DATEDIFF(day, '2024-01-01'::DATE, ds.sale_date) * 0.0002) -- 0.02% decrease per day
            ELSE 1.0  -- Other states: no adjustment
        END as base_revenue,
        -- Profit margin varies by category and state with trends
        CASE 
            WHEN spc.product_id <= 4 THEN 0.25  -- Garden: 25% margin
            WHEN spc.product_id > 4 AND spc.product_id <= 8 THEN 0.40  -- Apparel: 40% margin
            WHEN spc.product_id > 8 AND spc.product_id <= 12 THEN 0.35  -- Home: 35% margin
            WHEN spc.product_id > 12 AND spc.product_id <= 16 THEN 0.20  -- Electronics: 20% margin
            ELSE 0.30  -- Food: 30% margin
        END * 
        -- State-specific margin adjustments with trends
        CASE 
            WHEN spc.state_abbr = 'QLD' THEN 
                -- QLD: Base margins with slight upward trend over time
                1.0 + (DATEDIFF(day, '2024-01-01'::DATE, ds.sale_date) * 0.0002) -- 0.02% increase per day
            WHEN spc.state_abbr = 'VIC' THEN 
                -- VIC: Lower margins than QLD but same upward trend
                0.85 + (DATEDIFF(day, '2024-01-01'::DATE, ds.sale_date) * 0.0002) -- 15% lower than QLD, same trend
            WHEN spc.state_abbr = 'NSW' THEN 
                -- NSW: Same base margins but trending downwards
                1.3 - (DATEDIFF(day, '2024-01-01'::DATE, ds.sale_date) * 0.0002) -- 0.02% decrease per day
            ELSE 1.0  -- Other states: no adjustment
        END as profit_margin
    FROM date_series ds
    CROSS JOIN store_product_combinations spc
    WHERE MOD(ABS(HASH(ds.sale_date, spc.store_id, spc.product_id)), 100) < 70 -- 70% of combinations have sales
),
cyclone_impact AS (
    SELECT 
        sale_date,
        store_id,
        product_id,
        state_abbr,
        division,
        postcode,
        base_revenue,
        profit_margin,
        -- Event impacts: Cyclone Alfred and AFL Grand Finals
        CASE 
            -- Cyclone Alfred impact: Feb 1-28, 2024, affects ONLY stores in specific impacted postcodes
            WHEN (sale_date BETWEEN '2024-02-01' AND '2024-02-28') AND (postcode IN ('4000', '4001', '4217', '4218', '4870', '4871')) THEN
                CASE 
                    -- High impact postcodes (Brisbane 4000, 4001, Gold Coast 4217, 4218) - SEVERE disruption
                    WHEN postcode IN ('4000', '4001', '4217', '4218') THEN
                        CASE 
                            WHEN product_id <= 4 THEN base_revenue * (5 + UNIFORM(0, 1, RANDOM()) * 2.0) -- Hardware items surge 500-700%
                            WHEN product_id > 16 THEN base_revenue * (4 + UNIFORM(0, 1, RANDOM()) * 1.0) -- Food items surge 400-500%
                            ELSE base_revenue * (0.25 + UNIFORM(0, 1, RANDOM()) * 0.15) -- Other items drop 60-75%
                        END
                    -- Medium impact postcodes (Cairns 4870, 4871) - moderate disruption
                    WHEN postcode IN ('4870', '4871') THEN
                        CASE 
                            WHEN product_id <= 4 THEN base_revenue * (2.2 + UNIFORM(0, 1, RANDOM()) * 0.8) -- Hardware items increase 220-300%
                            WHEN product_id > 16 THEN base_revenue * (1.8 + UNIFORM(0, 1, RANDOM()) * 0.4) -- Food items increase 180-220%
                            ELSE base_revenue * (0.5 + UNIFORM(0, 1, RANDOM()) * 0.3) -- Other items drop 20-50%
                        END
                END
            -- AFL Grand Finals Melbourne: Sept 26-27, 2025, affects all Victoria stores
            WHEN (sale_date BETWEEN '2025-09-26' AND '2025-09-27') AND (postcode LIKE '3%') THEN
                CASE 
                    -- Public holiday (Sept 26): Clothes and food surge
                    WHEN sale_date = '2025-09-26' THEN
                        CASE 
                            WHEN product_id > 4 AND product_id <= 8 THEN base_revenue * (1.3 + UNIFORM(0, 1, RANDOM()) * 0.4) -- Apparel surge 130-170%
                            WHEN product_id > 16 THEN base_revenue * (1.2 + UNIFORM(0, 1, RANDOM()) * 0.3) -- Food surge 120-150%
                            ELSE base_revenue * (1.1 + UNIFORM(0, 1, RANDOM()) * 0.2) -- Other items slight increase 110-130%
                        END
                    -- Grand Finals day (Sept 27): Clothes and food surge
                    WHEN sale_date = '2025-09-27' THEN
                        CASE 
                            WHEN product_id > 4 AND product_id <= 8 THEN base_revenue * (1.4 + UNIFORM(0, 1, RANDOM()) * 0.5) -- Apparel surge 140-190%
                            WHEN product_id > 16 THEN base_revenue * (1.3 + UNIFORM(0, 1, RANDOM()) * 0.4) -- Food surge 130-170%
                            ELSE base_revenue * (1.1 + UNIFORM(0, 1, RANDOM()) * 0.2) -- Other items slight increase 110-130%
                        END
                    -- After concert (Sept 28-30): Tech surge
                    WHEN sale_date IN ('2025-09-28', '2025-09-29', '2025-09-30') THEN
                        CASE 
                            WHEN product_id > 12 AND product_id <= 16 THEN base_revenue * (1.2 + UNIFORM(0, 1, RANDOM()) * 0.3) -- Electronics surge 120-150%
                            ELSE base_revenue * (1.05 + UNIFORM(0, 1, RANDOM()) * 0.1) -- Other items slight increase 105-115%
                        END
                END
            -- All other stores and dates remain unaffected
            ELSE base_revenue
        END as adjusted_revenue
    FROM base_sales
)
SELECT 
    sale_date,
    store_id,
    product_id,
    ROUND(adjusted_revenue, 2) as gross_revenue,
    ROUND(adjusted_revenue * profit_margin, 2) as gross_profit,
    GREATEST(1, FLOOR(adjusted_revenue / 2500)) as quantity_sold
FROM cyclone_impact
WHERE adjusted_revenue > 0;

-- =====================================================
-- PRODUCT SALES BREAKDOWN TABLE
-- =====================================================

-- Create a comprehensive product sales breakdown table
CREATE OR REPLACE TABLE PRODUCT_SALES_BREAKDOWN AS
SELECT 
    f.sale_date,
    s.store_id,
    s.store_name,
    s.division,
    s.state_abbr,
    s.postcode,
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    f.gross_revenue,
    f.gross_profit,
    f.quantity_sold,
    ROUND(f.gross_profit / NULLIF(f.gross_revenue, 0) * 100, 2) as profit_margin_pct,
    -- Time period classifications
    CASE 
        WHEN f.sale_date < '2024-02-01' THEN 'Pre-Cyclone'
        WHEN f.sale_date BETWEEN '2024-02-01' AND '2024-02-15' THEN 'During Cyclone'
        WHEN f.sale_date > '2024-02-15' THEN 'Post-Cyclone'
        ELSE 'Normal Period'
    END as cyclone_period,
    -- General time period classifications for broader analysis
    CASE 
        WHEN f.sale_date BETWEEN '2024-01-01' AND '2024-03-31' THEN 'Q1 2024'
        WHEN f.sale_date BETWEEN '2024-04-01' AND '2024-06-30' THEN 'Q2 2024'
        WHEN f.sale_date BETWEEN '2024-07-01' AND '2024-09-30' THEN 'Q3 2024'
        WHEN f.sale_date BETWEEN '2024-10-01' AND '2024-12-31' THEN 'Q4 2024'
        WHEN f.sale_date BETWEEN '2025-01-01' AND '2025-03-31' THEN 'Q1 2025'
        WHEN f.sale_date BETWEEN '2025-04-01' AND '2025-06-30' THEN 'Q2 2025'
        WHEN f.sale_date BETWEEN '2025-07-01' AND '2025-09-30' THEN 'Q3 2025'
        WHEN f.sale_date BETWEEN '2025-10-01' AND '2025-12-31' THEN 'Q4 2025'
        ELSE 'Other Period'
    END as quarter_period,
    -- Impact status
    CASE 
        WHEN s.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 'Impacted Postcode'
        ELSE 'Non-Impacted Postcode'
    END as impact_status,
    -- Business categories for analysis
    CASE 
        WHEN p.category = 'Hardware' THEN 'Hardware & Tools'
        WHEN p.category = 'Apparel' THEN 'Clothing & Fashion'
        WHEN p.category = 'Home' THEN 'Home & Living'
        WHEN p.category = 'Electronics' THEN 'Technology'
        WHEN p.category = 'Food' THEN 'Food & Beverages'
        ELSE 'Other'
    END as business_category,
    -- Time dimensions
    EXTRACT(YEAR FROM f.sale_date) as year,
    EXTRACT(QUARTER FROM f.sale_date) as quarter,
    EXTRACT(MONTH FROM f.sale_date) as month,
    EXTRACT(DAYOFWEEK FROM f.sale_date) as day_of_week,
    EXTRACT(WEEK FROM f.sale_date) as week_number
FROM FACT_DAILY_SALES f
JOIN DIM_STORE s ON f.store_id = s.store_id
JOIN DIM_PRODUCT p ON f.product_id = p.product_id;

-- =====================================================
-- POPULATE EXTERNAL DATA TABLES
-- =====================================================

-- Weather data from 2024-01-01 through 12th of October 2025
INSERT INTO WEATHER_DATA
WITH date_series AS (
    SELECT DATEADD(day, seq4(), '2024-01-01'::DATE) as weather_date
    FROM TABLE(GENERATOR(ROWCOUNT => 650)) -- Generate enough days to cover through 12th of Oct 2025
    WHERE DATEADD(day, seq4(), '2024-01-01'::DATE) <= '2025-10-12'::DATE -- Include data through end of first week of October 2025
),
postcodes AS (
    SELECT DISTINCT postcode FROM DIM_STORE
),
weather_conditions AS (
    SELECT 
        ds.weather_date,
        p.postcode,
        CASE 
            WHEN ds.weather_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 'Cyclone'
            WHEN MOD(ABS(HASH(ds.weather_date, p.postcode)), 121) < 20 THEN 'Rain'
            WHEN MOD(ABS(HASH(ds.weather_date, p.postcode)), 121) < 40 THEN 'Cloudy'
            WHEN MOD(ABS(HASH(ds.weather_date, p.postcode)), 121) < 60 THEN 'Sunny'
            ELSE 'Partly Cloudy'
        END as condition,
        CASE 
            WHEN ds.weather_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 25 + UNIFORM(0, 1, RANDOM()) * 10
            ELSE 15 + UNIFORM(0, 1, RANDOM()) * 20
        END as temp,
        CASE 
            WHEN ds.weather_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 80 + UNIFORM(0, 1, RANDOM()) * 20
            ELSE 5 + UNIFORM(0, 1, RANDOM()) * 15
        END as wind_speed,
        CASE 
            WHEN ds.weather_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 50 + UNIFORM(0, 1, RANDOM()) * 30
            ELSE UNIFORM(0, 1, RANDOM()) * 10
        END as precipitation,
        CASE 
            WHEN ds.weather_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 'Extreme'
            WHEN MOD(ABS(HASH(ds.weather_date, p.postcode)), 121) < 10 THEN 'High'
            WHEN MOD(ABS(HASH(ds.weather_date, p.postcode)), 121) < 30 THEN 'Medium'
            ELSE 'Low'
        END as severity
    FROM date_series ds
    CROSS JOIN postcodes p
)
SELECT 
    weather_date as date,
    postcode,
    condition as weather_condition,
    ROUND(temp, 2) as temperature,
    ROUND(wind_speed, 2) as wind_speed,
    ROUND(precipitation, 2) as precipitation,
    severity as severity_level
FROM weather_conditions;

-- Events data from 2024-01-01 through 12th of October 2025
INSERT INTO EVENTS_DATA
WITH date_series AS (
    SELECT DATEADD(day, seq4(), '2024-01-01'::DATE) as event_date
    FROM TABLE(GENERATOR(ROWCOUNT => 650)) -- Generate enough days to cover through 12th of Oct 2025
    WHERE DATEADD(day, seq4(), '2024-01-01'::DATE) <= '2025-10-12'::DATE -- Include data through end of first week of October 2025
),
postcodes AS (
    SELECT DISTINCT postcode FROM DIM_STORE
),
events AS (
    SELECT 
        ds.event_date,
        p.postcode,
        CASE 
            WHEN ds.event_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 'Cyclone Alfred'
            WHEN ds.event_date BETWEEN '2025-09-26' AND '2025-09-27' AND p.postcode LIKE '3%' THEN 'AFL Grand Finals'
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 15 THEN 'Public Holiday'
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 25 THEN 'Festival'
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 35 THEN 'Sporting Event'
            ELSE 'Normal Day'
        END as event_type,
        CASE 
            WHEN ds.event_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 'Category 3 Cyclone with severe weather conditions'
            WHEN ds.event_date BETWEEN '2025-09-26' AND '2025-09-27' AND p.postcode LIKE '3%' THEN 'AFL Grand Finals - Public holiday on 26th, Grand Finals on 27th September 2025'
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 15 THEN 'Public holiday affecting store hours'
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 25 THEN 'Local festival increasing foot traffic'
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 35 THEN 'Major sporting event in area'
            ELSE 'Regular business day'
        END as description,
        CASE 
            WHEN ds.event_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 200 + UNIFORM(0, 1, RANDOM()) * 100
            WHEN ds.event_date BETWEEN '2025-09-26' AND '2025-09-27' AND p.postcode LIKE '3%' THEN 20 + UNIFORM(0, 1, RANDOM()) * 10
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 15 THEN 50 + UNIFORM(0, 1, RANDOM()) * 25
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 25 THEN 30 + UNIFORM(0, 1, RANDOM()) * 20
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 35 THEN 40 + UNIFORM(0, 1, RANDOM()) * 30
            ELSE 0
        END as impact_radius,
        CASE 
            WHEN ds.event_date BETWEEN '2024-02-01' AND '2024-02-28' AND p.postcode IN ('4000', '4001', '4217', '4218', '4870', '4871') THEN 9 + UNIFORM(0, 1, RANDOM())
            WHEN ds.event_date BETWEEN '2025-09-26' AND '2025-09-27' AND p.postcode LIKE '3%' THEN 7 + UNIFORM(0, 1, RANDOM()) * 1
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 15 THEN 6 + UNIFORM(0, 1, RANDOM()) * 2
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 25 THEN 4 + UNIFORM(0, 1, RANDOM()) * 2
            WHEN MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 35 THEN 5 + UNIFORM(0, 1, RANDOM()) * 2
            ELSE 1
        END as severity_score
    FROM date_series ds
    CROSS JOIN postcodes p
    WHERE MOD(ABS(HASH(ds.event_date, p.postcode)), 121) < 20 -- Only 20% of days have events
)
SELECT 
    event_date as date,
    postcode,
    event_type,
    description as event_description,
    ROUND(impact_radius, 2) as impact_radius_km,
    FLOOR(severity_score) as severity_score
FROM events;


-- =====================================================
-- DATA VALIDATION QUERIES
-- =====================================================

-- Check data counts
SELECT 'DIM_STORE' as table_name, COUNT(*) as record_count FROM DIM_STORE
UNION ALL
SELECT 'DIM_PRODUCT', COUNT(*) FROM DIM_PRODUCT
UNION ALL
SELECT 'FACT_DAILY_SALES', COUNT(*) FROM FACT_DAILY_SALES
UNION ALL
SELECT 'WEATHER_DATA', COUNT(*) FROM WEATHER_DATA
UNION ALL
SELECT 'EVENTS_DATA', COUNT(*) FROM EVENTS_DATA;

-- Check date ranges
SELECT 
    'FACT_DAILY_SALES' as table_name,
    MIN(sale_date) as min_date,
    MAX(sale_date) as max_date
FROM FACT_DAILY_SALES
UNION ALL
SELECT 
    'WEATHER_DATA',
    MIN(date),
    MAX(date)
FROM WEATHER_DATA
UNION ALL
SELECT 
    'EVENTS_DATA',
    MIN(date),
    MAX(date)
FROM EVENTS_DATA;


-- =====================================================
-- ADMIN ROLE SETUP
-- =====================================================

-- Create demo admin role with full database access
CREATE ROLE IF NOT EXISTS RETAIL_SI_DEMO_ADMIN;

-- Grant database and schema privileges
GRANT ALL PRIVILEGES ON DATABASE Retail_SI_Demo TO ROLE RETAIL_SI_DEMO_ADMIN;
GRANT ALL PRIVILEGES ON SCHEMA Retail_SI_Demo.Retail_SI_Demo TO ROLE RETAIL_SI_DEMO_ADMIN;

-- Grant privileges on all existing tables and views
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Retail_SI_Demo.Retail_SI_Demo TO ROLE RETAIL_SI_DEMO_ADMIN;
GRANT ALL PRIVILEGES ON ALL VIEWS IN SCHEMA Retail_SI_Demo.Retail_SI_Demo TO ROLE RETAIL_SI_DEMO_ADMIN;

-- Grant privileges on all future tables and views
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA Retail_SI_Demo.Retail_SI_Demo TO ROLE RETAIL_SI_DEMO_ADMIN;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN SCHEMA Retail_SI_Demo.Retail_SI_Demo TO ROLE RETAIL_SI_DEMO_ADMIN;

-- Grant usage on demo warehouse
GRANT USAGE ON WAREHOUSE RETAIL_SI_DEMO_WH TO ROLE RETAIL_SI_DEMO_ADMIN;
GRANT OPERATE ON WAREHOUSE RETAIL_SI_DEMO_WH TO ROLE RETAIL_SI_DEMO_ADMIN;
GRANT MODIFY ON WAREHOUSE RETAIL_SI_DEMO_WH TO ROLE RETAIL_SI_DEMO_ADMIN;

-- Optional: Grant the role to specific users
-- GRANT ROLE RETAIL_SI_DEMO_ADMIN TO USER <username>;

-- Optional: Set as default role for convenience
-- ALTER USER <username> SET DEFAULT_ROLE = RETAIL_SI_DEMO_ADMIN;

SELECT 'Demo admin role created successfully! Role: RETAIL_SI_DEMO_ADMIN' as status;


-- =====================================================
-- END OF SCRIPT
-- =====================================================

SELECT 'Data generation completed successfully!' as status;
