
-- Attach Databricks Tables for Bakehouse

ATTACH TABLE "bakehouse"."sales_customers" 
PRIMARY KEY(customerID)
AS "databricks"."bakehouse"."sales_customers"
FROM 'databricks_odbc';

vdd_disconnect_data_source('databricks_odbc');

GRANT SELECT ON "databricks"."bakehouse"."sales_customers" TO SPARQL_SELECT;

ATTACH TABLE "bakehouse"."media_customer_reviews" 
PRIMARY KEY(new_id)
AS "databricks"."bakehouse"."media_customer_reviews"
FROM 'databricks_odbc';

vdd_disconnect_data_source('databricks_odbc');

GRANT SELECT ON "databricks"."bakehouse"."media_customer_reviews" TO SPARQL_SELECT;

ATTACH TABLE "bakehouse"."sales_franchises" 
PRIMARY KEY(franchiseID)
AS "databricks"."bakehouse"."sales_franchises"
FROM 'databricks_odbc';

vdd_disconnect_data_source('databricks_odbc');

GRANT SELECT ON "databricks"."bakehouse"."sales_franchises" TO SPARQL_SELECT;

ATTACH TABLE "bakehouse"."sales_suppliers" 
PRIMARY KEY(supplierID)
AS "databricks"."bakehouse"."sales_suppliers"
FROM 'databricks_odbc';

vdd_disconnect_data_source('databricks_odbc');

GRANT SELECT ON "databricks"."bakehouse"."sales_suppliers" TO SPARQL_SELECT;

ATTACH TABLE "bakehouse"."sales_transactions" 
PRIMARY KEY(transactionID)
AS "databricks"."bakehouse"."sales_transactions"
FROM 'databricks_odbc';

vdd_disconnect_data_source('databricks_odbc');

GRANT SELECT ON "databricks"."bakehouse"."sales_transactions" TO SPARQL_SELECT;
