# Retail Store Performance Monitoring Demo

This project demonstrates a comprehensive retail store performance monitoring system using Snowflake, designed for CFOs and non-technical stakeholders. The demo showcases two main use cases with secure external data integration and auditable results.

## Use Cases

### 1. Store Performance & Pareto Analysis
- **Objective**: Identify state-by-state variance and underperformance
- **Analysis**: YTD performance across states → Compare performance → Show Pareto (80/20) curve
- **Financial Insight**: Define "flat Pareto" (underperformance) vs "steep Pareto" (good performance)

### 2. Historic Event Impact (Cyclone Alfred)
- **Objective**: Quantify the financial impact of major events
- **Analysis**: Pre, During, and Post event analysis using external data
- **Financial Insight**: Quantify dollar value of impact (lost sales, inventory surge)

## Database Schema

### Core Tables
- **FACT_DAILY_SALES**: Transactional data with revenue, profit, and quantity
- **DIM_STORE**: Store information with geographic data (lat/long, postcode)
- **DIM_PRODUCT**: Product categories and details

### External Data (Simulated Marketplace)
- **WEATHER_DATA**: Weather conditions by date and postcode
- **EVENTS_DATA**: Events and their impact by date and postcode

## Files

1. **`create_demo_data.sql`**: Main script that creates all tables and populates them with realistic data
2. **`demo_queries.sql`**: Sample queries demonstrating both use cases
3. **`README.md`**: This documentation file

## Getting Started

### Prerequisites
- Snowflake account with appropriate permissions
- Access to create databases and schemas

### Setup Instructions

1. **Run the main data creation script**:
   ```sql
   -- Execute the entire create_demo_data.sql script
   -- This will create the Retail_SI_Demo database and populate all tables
   ```

2. **Verify data creation**:
   ```sql
   -- Check that all tables were created and populated
   USE DATABASE Retail_SI_Demo;
   USE SCHEMA Retail_SI_Demo;
   
   -- Run the validation queries at the end of create_demo_data.sql
   ```

3. **Run demo queries**:
   ```sql
   -- Execute queries from demo_queries.sql to see the analysis
   -- Start with the basic performance queries, then move to cyclone impact
   ```

## Key Features

### Data Privacy & Security
- All data remains within Snowflake
- No external data leaves the platform
- Secure data sharing simulation

### Realistic Data Generation
- Historical data from 2024-01-01 to today's date
- 60 stores across 5 Australian states
- 20 product categories across different divisions
- Cyclone Alfred impact simulation (Feb 1-15, 2024) with DRAMATIC impact

### Geographic Coverage
- **Queensland**: 12 stores - Brisbane, Gold Coast, Cairns (cyclone impact area)
- **New South Wales**: 16 stores - Sydney (Central, North, South, East, West, CBD, Inner West, Outer West)
- **Victoria**: 20 stores - Melbourne (Central, North, South, East, West, CBD, Inner North, Inner South, Outer East, Outer West)
- **Western Australia**: 10 stores - Perth (Central, North, South, East, West)
- **South Australia**: 8 stores - Adelaide (Central, North, South, East)

### Product Categories
- **Garden**: Tools, seeds, fertilizer (Hardware Shop focus)
- **Apparel**: Clothing items (KShop focus)
- **Home**: Furniture, decor, kitchenware
- **Electronics**: Phones, laptops, cameras
- **Food**: Canned goods, snacks, beverages

## Sample Analysis Queries

### Store Performance Analysis
```sql
-- State-by-state performance comparison
SELECT 
    state_abbr,
    division,
    COUNT(*) as store_count,
    SUM(total_revenue) as state_revenue,
    SUM(total_profit) as state_profit
FROM V_STORE_PERFORMANCE
GROUP BY state_abbr, division;
```

### Pareto Analysis
```sql
-- 80/20 analysis by state
SELECT 
    state_abbr,
    store_id,
    total_profit,
    cumulative_percentage
FROM (
    SELECT 
        state_abbr,
        store_id,
        total_profit,
        SUM(total_profit) OVER (PARTITION BY state_abbr ORDER BY total_profit DESC) as running_total,
        SUM(total_profit) OVER (PARTITION BY state_abbr) as state_total,
        ROUND(SUM(total_profit) OVER (PARTITION BY state_abbr ORDER BY total_profit DESC) / 
              SUM(total_profit) OVER (PARTITION BY state_abbr) * 100, 2) as cumulative_percentage
    FROM V_STORE_PERFORMANCE
) ranked_stores
ORDER BY state_abbr, total_profit DESC;
```

### Cyclone Impact Analysis
```sql
-- Pre, During, Post cyclone analysis
SELECT 
    period,
    COUNT(DISTINCT store_id) as affected_stores,
    SUM(daily_revenue) as total_revenue,
    SUM(daily_profit) as total_profit
FROM V_CYCLONE_IMPACT
GROUP BY period
ORDER BY 
    CASE period
        WHEN 'Pre-Cyclone' THEN 1
        WHEN 'During Cyclone' THEN 2
        WHEN 'Post-Cyclone' THEN 3
    END;
```

## Data Characteristics

### Sales Patterns
- **Normal Periods**: Consistent daily sales with seasonal variations
- **Cyclone Impact (DRAMATIC - SPECIFIC POSTCODES ONLY)**: 
  - Garden items surge (300-500% increase in high-impact areas)
  - Food items surge (250-350% increase in high-impact areas)
  - Other categories drop (5-20% of normal in high-impact areas)
  - **Only stores in impacted postcodes are affected** - all other stores remain normal
- **Profit Margins**: Vary by category (20-40%)

### Geographic Impact
- **Cyclone Alfred**: Affects specific postcodes 4000, 4001, 4217, 4218, 4870, 4871
- **High Impact**: Brisbane (4000, 4001) and Gold Coast (4217, 4218) - severe disruption
- **Medium Impact**: Cairns (4870, 4871) - moderate disruption
- **Duration**: February 1-15, 2024
- **All other postcodes and states remain unaffected**

## Business Insights

### Performance Metrics
- **Revenue per Store**: Varies by location and division
- **Profit Margins**: Category-specific margins
- **Geographic Variance**: State-by-state performance differences
- **Event Impact**: Quantifiable financial impact of external events

### Key Findings
1. **Pareto Distribution**: 20% of stores typically generate 80% of profits
2. **Geographic Variance**: Significant state-by-state performance differences
3. **Event Impact**: Cyclone Alfred caused measurable revenue/profit changes
4. **Product Mix**: Different categories respond differently to external events

## Customization

The scripts can be easily customized for:
- Different time periods
- Additional geographic regions
- More product categories
- Different external events
- Varying impact scenarios

## Support

For questions or issues with the demo data, refer to the validation queries in the scripts or check the data quality metrics provided in the demo queries.
