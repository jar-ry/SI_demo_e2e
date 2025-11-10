-- This is your Cortex Project.
-----------------------------------------------------------
-- SETUP
-----------------------------------------------------------
use role ACCOUNTADMIN;
use warehouse RETAIL_SI_DEMO_WH_V2;
use database RETAIL_SI_DEMO_V2;
use schema RETAIL_SI_DEMO_V2;

-- Prepare your training data. Timestamp_ntz is a required format. Also, only include select columns.
CREATE OR REPLACE VIEW DAILY_REVENUE_TS_v1 AS SELECT
    to_timestamp_ntz(SALE_DATE) as SALE_DATE_v1,
    TOTAL_REVENUE,
    STATE_ABBR
FROM DAILY_REVENUE_TS;

-----------------------------------------------------------
-- CREATE PREDICTIONS
-----------------------------------------------------------
-- Create your model.
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST Retail_SI_Sales_Forecast(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'DAILY_REVENUE_TS_v1'),
    SERIES_COLNAME => 'STATE_ABBR',
    TIMESTAMP_COLNAME => 'SALE_DATE_v1',
    TARGET_COLNAME => 'TOTAL_REVENUE',
    CONFIG_OBJECT => { 'ON_ERROR': 'SKIP' }
);

CREATE OR REPLACE PROCEDURE 
RETAIL_SI_SALES_FORECAST("FORECASTING_PERIODS" NUMBER(38,0)) RETURNS VARCHAR 
LANGUAGE SQL 
EXECUTE AS OWNER 
AS 
$$ 
DECLARE 
result_set RESULTSET; 
sql_query VARCHAR; 
json_result VARCHAR; 
BEGIN 
sql_query := ' 
SELECT ARRAY_AGG( 
OBJECT_CONSTRUCT( 
''series'', series::VARCHAR,
''TS'', TS::TIMESTAMP, 
''FORECAST'', FORECAST::NUMBER
) 
) as json_array 
FROM TABLE(Retail_SI_Sales_Forecast!FORECAST(FORECASTING_PERIODS => ' || :forecasting_periods || '))'; 
result_set := (EXECUTE IMMEDIATE :sql_query); 
LET c1 CURSOR FOR result_set; 
FOR record IN c1 DO 
json_result := record.json_array::VARCHAR; 
END FOR;
RETURN json_result; 
END; 
$$; 

CALL RETAIL_SI_SALES_FORECAST(30);