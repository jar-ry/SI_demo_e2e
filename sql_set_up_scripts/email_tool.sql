
-- Snowflake Email Tool Setup 
-- This script contains all the necessary steps to set up the email tool.

--Notes!
-- This is to send an Email containing a body with Natural Language. The body will come from the previous response provided by Snowflake Intelligence. 
-- It has currently not been set up to send an email with a table. This should be created as it's own stored proc/tool 

-- Step 1: Set the context
-- Sets the current database and schema for the session.
-- Make sure to replace 'my_database' with your database name.
USE ROLE ACCOUNTADMIN;
USE DATABASE RETAIL_SI_DEMO_V2;
USE SCHEMA RETAIL_SI_DEMO_V2;
USE WAREHOUSE RETAIL_SI_DEMO_WH_V2; 

-- Step 2: Create a Notification Integration
-- This integration is required for Snowflake to send emails.Emails can only be those that are attached to a Snowflake account
CREATE OR REPLACE NOTIFICATION INTEGRATION my_email_integration
  TYPE=EMAIL
  ENABLED=TRUE
  ALLOWED_RECIPIENTS=('jarry.chen@snowflake.com');

-- Step 3: Grant Privileges
-- The following grants are necessary for the role to create and execute the procedure.
-- This section should be run by a user with ACCOUNTADMIN role or equivalent privileges.

-- Grant usage on the database to your role
--GRANT USAGE ON DATABASE my_database TO ROLE my_role;

-- Grant usage on the schema to your role
--GRANT USAGE ON SCHEMA my_database.PUBLIC TO ROLE my_role;

-- Grant the ability to create procedures in the schema to your role
--GRANT CREATE PROCEDURE ON SCHEMA my_database.PUBLIC TO ROLE my_role;

-- Grant usage on the integration to the role that will execute the procedure
-- The roles with the privilege must be used when creating the tool.
GRANT USAGE ON INTEGRATION my_email_integration TO ROLE ACCOUNTADMIN;
-- GRANT USAGE ON INTEGRATION my_email_integration TO ROLE linfox_analyst;



-- Step 3: Create the Stored Procedure
-- This procedure takes a recipient, subject, and the email body as string inputs and sends the email.
CREATE OR REPLACE PROCEDURE send_email(recipient_email VARCHAR, subject VARCHAR, email_body VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
  full_email_body_html VARCHAR;
  formatted_body VARCHAR;
  unique_marker VARCHAR;
BEGIN
  -- Create a unique, invisible marker. This prevents email clients like Gmail
  -- from collapsing the email body because it sees each email as unique.
  unique_marker := '<!-- ' || UUID_STRING() || ' -->';

  -- Sanitize the input body for HTML by replacing all types of newlines with <br> tags.
  formatted_body := REPLACE(REPLACE(:email_body, '\r\n', '\n'), '\n', '<br>');

  -- Construct a structured HTML body.
  full_email_body_html := '<html><body>' ||
                        '<p>Hello, this is an email sent from Snowflake Intelligence</p>' ||
                        '<p>' || formatted_body || '</p>' ||
                        '<p>Best regards,<br><b>Snowflake Intelligence</b></p>' ||
                        unique_marker ||
                        '</body></html>';

  CALL SYSTEM$SEND_EMAIL(
    'my_email_integration',
    :recipient_email,
    :subject,
    :full_email_body_html,
    'text/html' -- Specify the MIME type as HTML
  );

  RETURN 'Email sent successfully to ' || :recipient_email;
END;
$$;
-- Step 4: Example Usage
-- In Snowflake Intelligence, the agent would generate the 'email_body' text and ask for the email sent to. 
-- You can test it directly like this:


CALL send_email(
  'jarry.chen@snowflake.com',
  'Top Customers Report - Test',
  'Based on the delivery data from 2024, here are the top 5 customers who received the most deliveries last year:\n\n' ||
  'Woolworths Group - 32,834 deliveries\n' ||
  'Coles Supermarkets - 27,093 deliveries\n' ||
  'Kmart - 14,733 deliveries\n' ||
  'Pfizer Australia - 7,532 deliveries\n\n' ||
  'Note that only 4 customers are shown in the results, indicating these were the only customers with deliveries in 2024, or the data may be limited to these major customers. ' ||
  'The ranking is based on the total number of delivered shipments each customer received throughout 2024.'
);





-- End of script
