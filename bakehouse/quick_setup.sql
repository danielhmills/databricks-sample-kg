
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

SPARQL LOAD <https://raw.githubusercontent.com/danielhmills/databricks-sample-kg/refs/heads/main/bakehouse/r2rml.ttl> INTO <urn:databricks:bakehouse:r2rml>;
SPARQL LOAD <https://raw.githubusercontent.com/danielhmills/databricks-sample-kg/refs/heads/main/bakehouse/ontology.ttl> INTO <http://www.databricks.com/bakehouse#>;

EXEC ('SPARQL ' ||
 DB.DBA.R2RML_MAKE_QM_FROM_G(
            'urn:databricks:bakehouse:r2rml')
);

-- Virtual directories for instance data
DB.DBA.URLREWRITE_CREATE_REGEX_RULE (
'databricks_bakehouse_rule2',
1,
'(/databricks/bakehouse/[^#]*)',
vector('path'),
1,
'/sparql?query=DESCRIBE+%%3Chttp%%3A//^{URIQADefaultHost}^%U%%23this%%3E+FROM+%%3Chttp%%3A//^{URIQADefaultHost}^/databricks-bakehouse-r2rml%%23%%3E&format=%U',
vector('path', '*accept*'),
null,
'(text/rdf.n3)|(application/rdf.xml)|(text/n3)|(application/json)|(text/turtle)',
2,
null
);

DB.DBA.URLREWRITE_CREATE_REGEX_RULE (
'databricks_bakehouse_rule4',
1,
'/databricks/bakehouse/stat([^#]*)',
vector('path'),
1,
'/sparql?query=DESCRIBE+%%3Chttp%%3A//^{URIQADefaultHost}^/databricks/bakehouse/stat%%23%%3E+%%3Fo+FROM+%%3Chttp%%3A//^{URIQADefaultHost}^/databricks-bakehouse-r2rml%%23%%3E+WHERE+{+%%3Chttp%%3A//^{URIQADefaultHost}^/databricks/bakehouse/stat%%23%%3E+%%3Fp+%%3Fo+}&format=%U',
vector('*accept*'),
null,
'(text/rdf.n3)|(application/rdf.xml)|(text/n3)|(application/json)|(text/turtle)',
2,
null
);

DB.DBA.URLREWRITE_CREATE_REGEX_RULE (
'databricks_bakehouse_rule6',
1,
'/databricks/bakehouse/objects/([^#]*)',
vector('path'),
1,
'/sparql?query=DESCRIBE+%%3Chttp%%3A//^{URIQADefaultHost}^/databricks/bakehouse/objects/%U%%3E+FROM+%%3Chttp%%3A//^{URIQADefaultHost}^/databricks-bakehouse-r2rml%%23%%3E&format=%U',
vector('path', '*accept*'),
null,
'(text/rdf.n3)|(application/rdf.xml)|(text/n3)|(application/json)|(text/turtle)',
2,
null
);

DB.DBA.URLREWRITE_CREATE_REGEX_RULE (
'databricks_bakehouse_rule1',
1,
'(/databricks/bakehouse/[^#]*)',
vector('path'),
1,
'/describe/?url=http%%3A//^{URIQADefaultHost}^%U%%23this&graph=http%%3A//^{URIQADefaultHost}^/databricks-bakehouse-r2rml%%23&distinct=0',
vector('path'),
null,
null,
2,
303
);

DB.DBA.URLREWRITE_CREATE_REGEX_RULE (
'databricks_bakehouse_rule7',
1,
'/databricks/bakehouse/stat([^#]*)',
vector('path'),
1,
'/describe/?url=http%%3A//^{URIQADefaultHost}^/databricks/bakehouse/stat%%23&graph=http%%3A//^{URIQADefaultHost}^/databricks-bakehouse-r2rml%%23',
vector('path'),
null,
null,
2,
303
);

DB.DBA.URLREWRITE_CREATE_REGEX_RULE (
'databricks_bakehouse_rule5',
1,
'/databricks/bakehouse/objects/(.*)',
vector('path'),
1,
'/services/rdf/object.binary?path=%%2Fdatabricks%%2Fbakehouse%%2Fobjects%%2F%U&accept=%U',
vector('path', '*accept*'),
null,
null,
2,
null
);

DB.DBA.URLREWRITE_CREATE_RULELIST ( 
'databricks_bakehouse_rule_list1', 
1, 
vector ( 
'databricks_bakehouse_rule1', 
'databricks_bakehouse_rule7', 
'databricks_bakehouse_rule5', 
'databricks_bakehouse_rule2', 
'databricks_bakehouse_rule4', 
'databricks_bakehouse_rule6'
)
);

DB.DBA.VHOST_REMOVE (lpath=>'/databricks/bakehouse');

DB.DBA.VHOST_DEFINE (
lpath=>'/databricks/bakehouse', 
ppath=>'/', 
vsp_user=>'dba', 
is_dav=>0,
is_brws=>0, 
opts=>vector ('url_rewrite', 'databricks_bakehouse_rule_list1')
);
