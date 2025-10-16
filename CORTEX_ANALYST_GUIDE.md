# Snowflake Cortex Analyst Integration Guide

This guide explains how to use the retail demo data with Snowflake Cortex Analyst for natural language queries and analysis.

## 🎯 **Key Tables/Views for Cortex Analyst**

### **Primary Views (Recommended for Cortex Analyst)**

1. **`cortex_store_performance`** - Main store performance data
2. **`cortex_cyclone_impact`** - Cyclone impact analysis
3. **`cortex_pareto_analysis`** - Pareto analysis for 80/20 rule

### **Supporting Tables**
- **`DIM_STORE`** - Store information
- **`DIM_PRODUCT`** - Product categories
- **`FACT_DAILY_SALES`** - Core sales transactions
- **`WEATHER_DATA`** - External weather data
- **`EVENTS_DATA`** - External events data

## 🚀 **Setup Instructions**

### 1. Run the Semantic Layer Script
```sql
-- Execute the semantic layer setup
-- This creates business-friendly views optimized for Cortex Analyst
```

### 2. Grant Cortex Analyst Access
```sql
-- Grant access to Cortex Analyst
GRANT USAGE ON DATABASE Retail_SI_Demo TO ROLE CORTEX_ANALYST_ROLE;
GRANT USAGE ON SCHEMA Retail_SI_Demo TO ROLE CORTEX_ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA Retail_SI_Demo TO ROLE CORTEX_ANALYST_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA Retail_SI_Demo TO ROLE CORTEX_ANALYST_ROLE;
```

## 💬 **Natural Language Query Examples**

### **Use Case 1: Store Performance & Pareto Analysis**

#### **State Performance Questions:**
- "Show me store performance by state"
- "Which state has the highest revenue?"
- "Compare KShop vs Hardware Shop performance across states"
- "What's the average profit margin by state?"

#### **Pareto Analysis Questions:**
- "Show me the top 20% performing stores in each state"
- "Which stores are underperforming in Queensland?"
- "What percentage of stores generate 80% of profits?"
- "Identify stores that need improvement"

#### **Division Analysis Questions:**
- "How do KShop stores compare to Hardware Shop stores?"
- "Which division performs better in Victoria?"
- "Show me revenue by division and state"

### **Use Case 2: Cyclone Impact Analysis**

#### **Cyclone Impact Questions:**
- "Show me QLD store performance before, during, and after the cyclone"
- "Which stores were most affected by Cyclone Alfred?"
- "What products sold best during the cyclone?"
- "How did weather conditions affect sales?"

#### **Geographic Impact Questions:**
- "Compare Brisbane vs Gold Coast vs Cairns during the cyclone"
- "Which postcodes had the biggest revenue drop?"
- "Show me stores with extreme revenue changes"

#### **Product Impact Questions:**
- "What did people buy during the cyclone?"
- "Which product categories surged during the cyclone?"
- "How did garden products perform during the cyclone?"

## 📊 **Key Metrics Available**

### **Store Performance Metrics:**
- `total_revenue` - Total revenue per store
- `total_profit` - Total profit per store
- `avg_daily_revenue` - Average daily revenue
- `avg_daily_profit` - Average daily profit
- `profit_margin_pct` - Profit margin percentage
- `days_with_sales` - Number of days with sales

### **Cyclone Impact Metrics:**
- `daily_revenue` - Daily revenue during cyclone period
- `daily_profit` - Daily profit during cyclone period
- `period` - Pre-Cyclone, During Cyclone, Post-Cyclone
- `weather_condition` - Weather conditions
- `temperature` - Temperature readings
- `wind_speed` - Wind speed data
- `precipitation` - Precipitation levels

### **Pareto Analysis Metrics:**
- `total_profit` - Store profit
- `running_total_profit` - Cumulative profit
- `cumulative_percentage` - Percentage of total state profit
- `performance_tier` - Top Performers vs Underperformers

## 🔍 **Advanced Query Patterns**

### **Time-Based Analysis:**
- "Show me monthly revenue trends for 2024"
- "Compare Q1 vs Q2 performance"
- "What was the best performing month?"

### **Geographic Analysis:**
- "Show me performance by postcode"
- "Which cities have the most stores?"
- "Compare urban vs suburban performance"

### **Product Analysis:**
- "Which product categories are most profitable?"
- "Show me seasonal trends by product category"
- "What's the average revenue per product?"

### **Outlier Detection:**
- "Show me stores with extreme revenue changes"
- "Identify stores that are outliers"
- "Which stores had the biggest impact from the cyclone?"

## 🎯 **Cortex Analyst Best Practices**

### **1. Use Business-Friendly Language:**
- ✅ "Show me store performance"
- ✅ "Compare states"
- ✅ "Which stores are underperforming?"
- ❌ "SELECT store_id, revenue FROM..."

### **2. Be Specific About Time Periods:**
- ✅ "Show me 2024 performance"
- ✅ "Compare before and during the cyclone"
- ✅ "Show me monthly trends"

### **3. Use Natural Grouping:**
- ✅ "Group by state"
- ✅ "Show me by division"
- ✅ "Compare by product category"

### **4. Ask for Comparisons:**
- ✅ "Compare QLD vs NSW"
- ✅ "Show me KShop vs Hardware Shop"
- ✅ "Compare pre vs during cyclone"

## 📈 **Sample Cortex Analyst Queries**

### **Store Performance Analysis:**
```
"Show me the top 10 performing stores by revenue in 2024"
"Compare store performance between Queensland and Victoria"
"Which division has better profit margins - KShop or Hardware Shop?"
"Show me stores that need improvement in New South Wales"
```

### **Cyclone Impact Analysis:**
```
"Show me how Queensland stores performed before, during, and after the cyclone"
"Which products sold best during Cyclone Alfred?"
"Compare Brisbane vs Gold Coast during the cyclone"
"Show me the financial impact of the cyclone on each store"
```

### **Pareto Analysis:**
```
"Show me the 80/20 rule for stores in each state"
"Which stores contribute to 80% of profits in Victoria?"
"Identify underperforming stores that need attention"
"Show me the distribution of store performance"
```

## 🔧 **Troubleshooting**

### **Common Issues:**
1. **"No data found"** - Check if you're using the correct view names
2. **"Column not found"** - Use the business-friendly column names from the views
3. **"Permission denied"** - Ensure Cortex Analyst role has proper access

### **Performance Tips:**
1. Use the `cortex_*` views for better performance
2. Specify time periods to limit data scope
3. Use filters to focus on specific states or divisions

## 📚 **Additional Resources**

- **Snowflake Cortex Analyst Documentation**: [Link to official docs]
- **Semantic Layer Best Practices**: [Link to best practices]
- **Natural Language Query Examples**: [Link to examples]

## 🎯 **Next Steps**

1. Run the semantic layer setup script
2. Test with simple queries like "Show me store performance"
3. Try the cyclone impact analysis queries
4. Experiment with Pareto analysis questions
5. Create custom dashboards based on your findings

This setup provides a comprehensive foundation for using Cortex Analyst with your retail demo data!
