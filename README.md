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

### SQL Setup Scripts (run in order)
1. **`sql_set_up_scripts/create_demo_data_v2.sql`**: Creates the Retail_SI_Demo_v2 database and populates all tables with realistic data
2. **`sql_set_up_scripts/cortex_analyst_semantic_objects_v2.sql`**: Sets up the semantic model structure for Cortex Analyst
3. **`sql_set_up_scripts/email_tool.sql`**: Creates the email functionality for the agent
4. **`sql_set_up_scripts/ml_forecast_tool.sql`**: Creates the ML forecasting functionality for the agent

### Configuration Files
- **`agent_configs/semantic_model.yml`**: Semantic model configuration
- **`agent_configs/agent.yml`**: Agent orchestrator and response prompts
- **`agent_configs/cortex_analyst_tooL_description.yml`**: Cortex Analyst tool description
- **`agent_configs/email_tool_description.yml`**: Email tool description
- **`agent_configs/forecast_tool_description.yml`**: Forecast tool description

### Documentation
- **`README.md`**: This documentation file
- **`CORTEX_ANALYST_GUIDE.md`**: Guide for using Cortex Analyst with natural language queries

## Getting Started

### Prerequisites
- Snowflake account with appropriate permissions
- Access to create databases and schemas
- Access to create Cortex Analyst semantic models and agents

### Setup Instructions

**IMPORTANT**: Run the SQL setup scripts in the following order:

1. **Create demo data**:
   ```sql
   -- Execute sql_set_up_scripts/create_demo_data_v2.sql
   -- This will create the Retail_SI_Demo_v2 database and populate all tables
   ```

2. **Create Cortex Analyst semantic objects**:
   ```sql
   -- Execute sql_set_up_scripts/cortex_analyst_semantic_objects_v2.sql
   -- This sets up the semantic model structure for Cortex Analyst
   ```

3. **Set up email tool**:
   ```sql
   -- Execute sql_set_up_scripts/email_tool.sql
   -- This creates the email functionality for the agent
   ```

4. **Set up forecast tool**:
   ```sql
   -- Execute sql_set_up_scripts/ml_forecast_tool.sql
   -- This creates the ML forecasting functionality for the agent
   ```

5. **Configure semantic model and agents**:
   - Use the configuration files in the `agent_configs/` folder:
     - `semantic_model.yml` - Configure the semantic model
     - `agent.yml` - Configure the agent orchestrator and response prompts
     - `cortex_analyst_tooL_description.yml` - Cortex Analyst tool description
     - `email_tool_description.yml` - Email tool description
     - `forecast_tool_description.yml` - Forecast tool description

6. **Verify setup**:
   ```sql
   -- Check that all tables were created and populated
   USE DATABASE Retail_SI_Demo_v2;
   USE SCHEMA Retail_SI_Demo_v2;
   
   -- Verify semantic objects and tools are created
   -- Check that Cortex views are available:
   SELECT * FROM cortex_store_performance LIMIT 10;
   SELECT * FROM cortex_event_impact LIMIT 10;
   SELECT * FROM cortex_pareto_analysis LIMIT 10;
   ```

7. **Test with Cortex Analyst**:
   - Use natural language queries through Cortex Analyst
   - See `CORTEX_ANALYST_GUIDE.md` for example queries and best practices
   - Try queries like "Show me store performance by state" or "Compare pre vs during cyclone performance"

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
