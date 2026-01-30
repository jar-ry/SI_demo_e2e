-- =====================================================
-- Snowflake Cortex Search Service Setup
-- =====================================================
-- This script creates infrastructure for PDF document search
-- using Snowflake Cortex Search and AI_PARSE_DOCUMENT
-- =====================================================
-- NOTE: Run create_demo_data.sql first to create:
--   - RETAIL_SI_DEMO_ADMIN role
--   - RETAIL_SI_DEMO_WH warehouse
--   - Retail_SI_Demo database and schema
-- =====================================================

-- Use the admin role to create all objects
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE RETAIL_SI_DEMO_WH;
USE DATABASE Retail_SI_Demo;
USE SCHEMA Retail_SI_Demo;

-- =====================================================
-- Create Stage and Cortex Search Service for PDFs
-- For use with Snowflake Intelligence
-- =====================================================

-- Step 1: Create a stage for PDF uploads
CREATE OR REPLACE STAGE Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Step 2: Create a table to store parsed PDF content
CREATE OR REPLACE TABLE Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS (
    file_name VARCHAR,
    file_path VARCHAR,
    chunk_id INT,
    chunk_text VARCHAR,
    parsed_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Step 3: After uploading PDFs to the stage, run this to parse and load them
-- Use AI_PARSE_DOCUMENT to extract text from PDFs
INSERT INTO Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS (file_name, file_path, chunk_id, chunk_text)
SELECT
    RELATIVE_PATH AS file_name,
    '@Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS_STAGE/' || RELATIVE_PATH AS file_path,
    page.index AS chunk_id,
    page.value:content::VARCHAR AS chunk_text
FROM 
    DIRECTORY('@Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS_STAGE') d,
    LATERAL FLATTEN(
        input => AI_PARSE_DOCUMENT(
            TO_FILE('@Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS_STAGE', d.RELATIVE_PATH),
            {'mode': 'LAYOUT', 'page_split': true}
        ):pages
    ) page
WHERE RELATIVE_PATH LIKE '%.pdf';

-- Step 4: Create the Cortex Search Service over the parsed PDF content
CREATE OR REPLACE CORTEX SEARCH SERVICE Retail_SI_Demo.Retail_SI_Demo.PDF_SEARCH_SERVICE
    ON chunk_text
    ATTRIBUTES file_name, file_path
    WAREHOUSE = RETAIL_SI_DEMO_WH
    TARGET_LAG = '1 hour'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT
        file_name,
        file_path,
        chunk_id,
        chunk_text
    FROM Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS
);

-- Step 5: Grant usage to the admin role
GRANT USAGE ON CORTEX SEARCH SERVICE Retail_SI_Demo.Retail_SI_Demo.PDF_SEARCH_SERVICE TO ROLE RETAIL_SI_DEMO_ADMIN;
GRANT ALL PRIVILEGES ON STAGE Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS_STAGE TO ROLE RETAIL_SI_DEMO_ADMIN;
GRANT ALL PRIVILEGES ON TABLE Retail_SI_Demo.Retail_SI_Demo.PDF_DOCUMENTS TO ROLE RETAIL_SI_DEMO_ADMIN;
