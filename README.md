# Databricks Sample Knowledge Graph

Modern AI and analytics workloads increasingly demand graph reasoning capabilities—the ability to traverse relationships, discover patterns across connected data, and answer multi-hop questions that flat tables and vector searches cannot address efficiently. Yet most enterprise data remains locked in relational warehouses and lakehouses, where relationships are modeled using implicit coarse-grained foreign keys rather than fine-grained entity relationships defined by machine-computable relationship type semantics described in an ontology. In addition, these relationships and the entities they connect aren't named using hyperlinks which impedes intelligent navigation across instance boundaries, as and when required.

This guide demonstrates how to unlock machine-computable entity relationships across your existing Databricks data without migration, duplication, or platform lock-in.

Using open standards—including RDF for expressing entity relationships, SPARQL for graph-oriented query and reasoning, and R2RML for exposing relational data as graphs—you can transform existing warehouse tables into a navigable web of linked entities without moving the underlying data.

At the heart of this approach are hyperlinks (IRIs), which provide globally unique identifiers for the entities, relationships, and data spaces represented in your data. These hyperlinks enable data from disparate systems to be connected, referenced, explored, and reasoned over as a coherent whole.

The result is a Knowledge Graph that extends beyond the boundaries of any single database, platform, or application. Rather than creating another data silo, it establishes a loosely coupled semantic layer in which identities, relationships, and meanings become explicitly computable and interoperable across both enterprise and public data spaces.

By virtualizing graph structures over existing data assets, organizations can create a foundation for AI agents, analytics, automation, and knowledge-driven applications that operate over a web of linked entities and relationships while preserving existing investments in data infrastructure.

## What You Get

- **Graph reasoning on data you already have:** Query relationships, traverse paths, and discover patterns across your Databricks tables using SPARQL, without moving data out of your governance perimeter.
- **Standards-based interoperability:** RDF and SPARQL are W3C standards supported across hundreds of tools, triple stores, and semantic web platforms. Your graph isn't locked to a single vendor's query language or data model.
- **Zero data movement:** Virtuoso's Virtual Database architecture attaches to Databricks via ODBC, leaving your source data in place while exposing it through a live, queryable RDF layer.
- **Semantic enrichment:** R2RML mappings let you define rich ontologies, infer relationships that aren't explicit in your schema, and integrate external vocabularies for cross-domain reasoning.
- **Production-grade infrastructure:** Virtuoso has powered enterprise Knowledge Graphs for decades, with proven scalability, ACID compliance, and full support for federated SPARQL queries across heterogeneous data sources.

This approach is ideal when you need graph capabilities over analytical data that lives in a warehouse, when governance or scale requires data to stay where it is, or when you want to test the value of graph patterns before committing to a parallel graph stack. For workloads requiring millisecond-latency traversals or high-frequency writes, a native graph store remains the better fit—but for batch reasoning, GraphRAG over reference data, or exploratory graph analytics, this standards-based virtualization layer delivers graph power without the operational overhead.

**Use case:** We'll use the public `samples.bakehouse` dataset from Databricks—a fictional bakery chain with customers, franchises, suppliers, transactions, and reviews—to demonstrate how relational tables become a navigable, SPARQL-queryable Knowledge Graph in minutes.

---

## Prerequisites

Before you begin, make sure you have:

- A running **Virtuoso Universal Server** ([Commercial Edition](https://shop.openlinksw.com/c/2ELnq9iexd) - free 30-day trial available) with the **Virtual Database** (VDB) and **SPARQL** modules enabled.
- The **Databricks ODBC Driver** installed on the same machine as Virtuoso.
- A **Databricks account** and a running SQL warehouse or cluster.
- Your Databricks **Host**, **HTTP Path**, and a **Personal Access Token**.

---

## Step 1: Install the Databricks ODBC Driver

1. Download the **Databricks ODBC Driver** from the [Databricks drivers page](https://www.databricks.com/spark/odbc-driver-download).
2. Install it on the machine where Virtuoso is running.
3. Note the path to the driver shared library (e.g. `/opt/simba/spark/lib/libdatabricksodbc64.so` on Linux).

---

## Step 2: Configure ODBC

### 2a. Copy the example files

```bash
cp odbcinst.ini.example odbcinst.ini
cp odbc.ini.example odbc.ini
```

### 2b. Edit `odbcinst.ini`

Update the path to your Databricks ODBC driver library:

```ini
[databricks_odbc_driver]
Driver = /path/to/libdatabricksodbc64.so
```

### 2c. Edit `odbc.ini`

Fill in your Databricks connection details:

```ini
[databricks_odbc]
Driver          = /path/to/libdatabricksodbc64.so
Host            = your-workspace.cloud.databricks.com
Port            = 443
HTTPPath        = /sql/1.0/warehouses/your-warehouse-id
SSL             = 1
AuthMech        = 3
UID             = token
PWD             = dapiYOURTOKENHERE
ThriftTransport = 2
Schema          = bakehouse
Catalog         = samples
```

> Replace `Host`, `HTTPPath`, and `PWD` with your actual Databricks workspace host, SQL warehouse HTTP path, and personal access token.

### 2d. Place the `.ini` files

Move (or symlink) these files to the standard ODBC configuration directory on your system:

- **Linux/macOS:**
  - `odbcinst.ini` → `/etc/odbcinst.ini` (or `~/.odbcinst.ini` for user-only installs)
  - `odbc.ini` → `/etc/odbc.ini` (or `~/.odbc.ini`)

- **Verify the connection** with `isql` (if available):

```bash
isql databricks_odbc -v
```

If the connection is successful, you should see a SQL prompt.

---

## Step 3: Register the DSN in Virtuoso

Virtuoso needs to know about the ODBC data source. You can register it via the **Virtuoso Conductor** web UI or by executing the following SQL in Virtuoso's `isql` command-line interface:

```sql
vds_connect_data_source('databricks_odbc');
```

Or, register it permanently:

```sql
DB.DBA.vds_register_data_source('databricks_odbc');
```

---

## Step 4: Attach the Databricks Tables

You now have two options:

### Option A: Quick Setup (Recommended)

Run the `bakehouse/quick_setup.sql` script in Virtuoso's `isql`:

```bash
isql 1111 dba dba < bakehouse/quick_setup.sql
```

> Replace `1111`, `dba`, and `dba` with your Virtuoso port, username, and password if different.

#### What the Script Does

**1. Attach Remote Tables**

The script attaches each Databricks table to Virtuoso's local catalog, making them queryable via SQL:

```sql
ATTACH TABLE "bakehouse"."sales_customers" 
PRIMARY KEY(customerID)
AS "databricks"."bakehouse"."sales_customers"
FROM 'databricks_odbc';

vdd_disconnect_data_source('databricks_odbc');
```

This creates a local reference to the remote table without copying data. The `vdd_disconnect_data_source` call releases the connection after each attach operation.

**2. Grant SPARQL Access**

Each attached table receives SPARQL query privileges:

```sql
GRANT SELECT ON "databricks"."bakehouse"."sales_customers" TO SPARQL_SELECT;
```

This allows the SPARQL engine to query the attached tables when generating RDF views.

**3. Load R2RML Mappings and Ontology**

The script loads the R2RML mapping definitions and ontology vocabulary into named graphs:

```sql
SPARQL LOAD <https://raw.githubusercontent.com/danielhmills/databricks-sample-kg/refs/heads/main/bakehouse/r2rml.ttl> 
INTO <urn:databricks:bakehouse:r2rml>;

SPARQL LOAD <https://raw.githubusercontent.com/danielhmills/databricks-sample-kg/refs/heads/main/bakehouse/ontology.ttl> 
INTO <http://www.databricks.com/bakehouse#>;
```

The R2RML mapping defines how relational tables map to RDF triples (entities, properties, relationships).

**4. Generate Quad Maps**

The script converts R2RML mappings into Virtuoso's internal Quad Map format for efficient SPARQL query execution:

```sql
EXEC ('SPARQL ' ||
 DB.DBA.R2RML_MAKE_QM_FROM_G('urn:databricks:bakehouse:r2rml')
);
```

Quad Maps are Virtuoso's optimized representation of RDF views over relational data.

**5. Configure Linked Data Rewrite Rules**

The script sets up URL rewrite rules for content negotiation, enabling entity URIs to be dereferenceable:

```sql
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
```

These rules allow browsers to view entity descriptions and RDF clients to retrieve machine-readable data.

### Option B: Manual / Step-by-Step

1. Attach tables individually using `bakehouse/attach.sql`:

```bash
isql 1111 dba dba < bakehouse/attach.sql
```

2. Load the R2RML mapping into a named graph:

```sql
SPARQL LOAD <https://raw.githubusercontent.com/danielhmills/databricks-sample-kg/refs/heads/main/bakehouse/r2rml.ttl>
INTO <urn:databricks:bakehouse:r2rml>;
```

3. Generate the Quad Maps from the R2RML graph:

```sql
EXEC ('SPARQL ' || DB.DBA.R2RML_MAKE_QM_FROM_G('urn:databricks:bakehouse:r2rml'));
```

---

## Step 5: Verify the Knowledge Graph

Confirm that the Knowledge Graph is accessible by running the following SPARQL query in Virtuoso's `isql` or the SPARQL endpoint:

```sparql
SPARQL 
SELECT *
FROM <http://demo.openlinksw.com/databricks-bakehouse-r2rml#>
WHERE
{
  ?s a ?o
}
LIMIT 10
```

**Links:**
- [Query Definition](http://demo.openlinksw.com/sparql?default-graph-uri=&qtxt=SELECT+*%0D%0AFROM+%3Chttp%3A%2F%2Fdemo.openlinksw.com%2Fdatabricks-bakehouse-r2rml%23%3E%0D%0AWHERE%0D%0A%7B%0D%0A++%3Fs+a+%3Fo%0D%0A%7D%0D%0ALIMIT+10&should-sponge=&format=text%2Fhtml&CXML_redir_for_subjs=121&CXML_redir_for_hrefs=&timeout=0)
- [Query Results](http://demo.openlinksw.com/sparql?default-graph-uri=&query=SELECT+*%0D%0AFROM+%3Chttp%3A%2F%2Fdemo.openlinksw.com%2Fdatabricks-bakehouse-r2rml%23%3E%0D%0AWHERE%0D%0A%7B%0D%0A++%3Fs+a+%3Fo%0D%0A%7D%0D%0ALIMIT+10&should-sponge=&format=text%2Fhtml&timeout=0)

If successful, you should see RDF triples representing entities from the Databricks `bakehouse` schema (customers, franchises, suppliers, transactions, and reviews).

---

## Sample Query: Revenue by Franchise

This query demonstrates how to join data across multiple tables (Transaction and Franchise) using SPARQL to calculate total revenue by franchise and city:

```sparql
PREFIX : <http://www.databricks.com/bakehouse#>

SELECT
?franchise
?franchiseCity
SUM(?totalPrice) as ?revenue

FROM <http://demo.openlinksw.com/databricks-bakehouse-r2rml#>
WHERE
{
  #Transaction Table
  ?transaction a :Transaction;
   :franchise ?franchise;
   :totalPrice ?totalPrice.

  #Franchise Table
  ?franchise :city ?franchiseCity.   
}
GROUP BY ?franchise ?franchiseCity
ORDER BY DESC(?revenue)
LIMIT 10
```

**Links:**
- [Query Definition](https://demo.openlinksw.com/sparql?default-graph-uri=&qtxt=PREFIX%20%3A%20%3Chttp%3A%2F%2Fwww.databricks.com%2Fbakehouse%23%3E%0A%0ASELECT%0A%3Ffranchise%0A%3FfranchiseCity%0ASUM(%3FtotalPrice)%20as%20%3Frevenue%0A%0AFROM%20%3Chttp%3A%2F%2Fdemo.openlinksw.com%2Fdatabricks-bakehouse-r2rml%23%3E%0AWHERE%0A%7B%0A%20%20%23Transaction%20Table%0A%20%20%3Ftransaction%20a%20%3ATransaction%3B%0A%20%20%20%3Afranchise%20%3Ffranchise%3B%0A%20%20%20%3AtotalPrice%20%3FtotalPrice.%0A%0A%20%20%23Franchise%20Table%0A%20%20%3Ffranchise%20%3Acity%20%3FfranchiseCity.%20%20%20%0A%7D%0AGROUP%20BY%20%3Ffranchise%20%3FfranchiseCity%0AORDER%20BY%20DESC(%3Frevenue)%0ALIMIT%2010&should-sponge=&format=text%2Fhtml&CXML_redir_for_subjs=121&CXML_redir_for_hrefs=&timeout=0)
- [Query Results](https://demo.openlinksw.com/sparql?default-graph-uri=&query=PREFIX+%3A+%3Chttp%3A%2F%2Fwww.databricks.com%2Fbakehouse%23%3E%0D%0A%0D%0ASELECT%0D%0A%3Ffranchise%0D%0A%3FfranchiseCity%0D%0ASUM%28%3FtotalPrice%29+as+%3Frevenue%0D%0A%0D%0AFROM+%3Chttp%3A%2F%2Fdemo.openlinksw.com%2Fdatabricks-bakehouse-r2rml%23%3E%0D%0AWHERE%0D%0A%7B%0D%0A++%23Transaction+Table%0D%0A++%3Ftransaction+a+%3ATransaction%3B%0D%0A+++%3Afranchise+%3Ffranchise%3B%0D%0A+++%3AtotalPrice+%3FtotalPrice.%0D%0A%0D%0A++%23Franchise+Table%0D%0A++%3Ffranchise+%3Acity+%3FfranchiseCity.+++%0D%0A%7D%0D%0AGROUP+BY+%3Ffranchise+%3FfranchiseCity%0D%0AORDER+BY+DESC%28%3Frevenue%29%0D%0ALIMIT+10&should-sponge=&format=text%2Fhtml&timeout=0)

![SPARQL Query Results](https://github.com/danielhmills/databricks-sample-kg/blob/main/bakehouse/sparql-query-results.png?raw=true)
*Query results showing revenue aggregated by franchise with clickable entity URIs*

Each franchise URI in the results (e.g., [http://demo.openlinksw.com/databricks/bakehouse/franchise-3000046#this](http://demo.openlinksw.com/databricks/bakehouse/franchise-3000046#this)) is clickable and navigates to a detailed entity description page.

![Entity Description from Query Results](https://github.com/danielhmills/databricks-sample-kg/blob/main/bakehouse/entity-description-from-query.png?raw=true)
*Clicking a franchise URI from query results navigates to its full entity description*

---

## Graph Visualization with SPARQLWorks

The Knowledge Graph can be visualized interactively using **[SPARQLWorks](https://github.com/danielhmills/sparqlworks/)**, a graph visualization tool that renders SPARQL query results as interactive node-link diagrams.

**Try it:** [View Transaction-Franchise Relationships](https://demo.openlinksw.com/sparqlworks/?urlfmt=default&q=PREFIX+%3A+%3Chttp%3A%2F%2Fwww.databricks.com%2Fbakehouse%23%3E%0A%0ACONSTRUCT%0A%7B%0A++%23Transaction+Table%0A++%3Ftransaction+a+%3ATransaction%3B%0A+++%3Afranchise+%3Ffranchise%3B%0A+++%3AtotalPrice+%3FtotalPrice.%0A%0A++%23Franchise+Table%0A++%3Ffranchise+%3Acity+%3FfranchiseCity.+++%0A%7D%0AWHERE%0A%7B%0A++GRAPH+%3Chttp%3A%2F%2Fdemo.openlinksw.com%2Fdatabricks-bakehouse-r2rml%23%3E%0A++%7B%0A++++%23Transaction+Table%0A++++%3Ftransaction+a+%3ATransaction%3B%0A+++++%3Afranchise+%3Ffranchise%3B%0A+++++%3AtotalPrice+%3FtotalPrice.%0A++%0A++++%23Franchise+Table%0A++++%3Ffranchise+%3Acity+%3FfranchiseCity.+++%0A++%7D%0A%7D%0ALIMIT+100&lang=en&labels=1&hideTypes=0&mode=advanced&custom=1&limit=5&service=https%3A%2F%2Fdemo.openlinksw.com%2Fsparql&chg=-600&ld=180&hover=1&annot=names&props=http%3A%2F%2Fwww.databricks.com%2Fbakehouse%23city%2Chttp%3A%2F%2Fwww.databricks.com%2Fbakehouse%23franchise%2Chttp%3A%2F%2Fwww.databricks.com%2Fbakehouse%23totalPrice&groups=external%2Cliteral)

This visualization uses a SPARQL CONSTRUCT query to extract a subgraph showing relationships between transactions, franchises, and cities:

```sparql
PREFIX : <http://www.databricks.com/bakehouse#>

CONSTRUCT
{
  #Transaction Table
  ?transaction a :Transaction;
   :franchise ?franchise;
   :totalPrice ?totalPrice.

  #Franchise Table
  ?franchise :city ?franchiseCity.   
}
WHERE
{
  GRAPH <http://demo.openlinksw.com/databricks-bakehouse-r2rml#>
  {
    #Transaction Table
    ?transaction a :Transaction;
     :franchise ?franchise;
     :totalPrice ?totalPrice.

    #Franchise Table
    ?franchise :city ?franchiseCity.   
  }
}
LIMIT 100
```

The interactive visualization allows you to:
- Explore entity relationships visually
- Click nodes to navigate to entity descriptions
- Zoom and pan to examine graph structure
- See property values on hover

![SPARQLWorks Visualization](https://github.com/danielhmills/databricks-sample-kg/blob/main/bakehouse/sparqlworks-visualization.png?raw=true)
*Interactive graph visualization showing transaction-franchise-city relationships*

Clicking on any entity node in the visualization navigates to its description page. **Try it:** [Franchise 3000024 Description](http://demo.openlinksw.com/describe/?url=http%3A//demo.openlinksw.com%2Fdatabricks%2Fbakehouse%2Ffranchise-3000024%23this&graph=http%3A//demo.openlinksw.com/databricks-bakehouse-r2rml%23&distinct=0#this)

---

## Linked Data: Navigable Entity URIs

One of the key benefits of this approach is that every entity in your Knowledge Graph has a dereferenceable HTTP URI. This means you can navigate directly to any customer, franchise, supplier, or transaction by visiting its URL in a browser.

**Try it:** [http://demo.openlinksw.com/databricks/bakehouse/franchise-3000046#this](http://demo.openlinksw.com/databricks/bakehouse/franchise-3000046#this)

### How It Works

When you visit an entity URI, Virtuoso's rewrite rules implement **content negotiation**:

**For browsers (requesting HTML):**
- The server returns a 303 redirect to a human-readable description page
- You see all the properties of the franchise: name, location, coordinates, supplier relationships, etc.
- Links to related entities (suppliers, cities, countries) are clickable, letting you navigate the graph

![Linked Data Hyperlink Navigation](https://github.com/danielhmills/databricks-sample-kg/blob/main/bakehouse/linked-data-hyperlink.png?raw=true)
*Clicking on hyperlinked entities in the graph visualization navigates to their Linked Data descriptions*

**For RDF clients (requesting RDF/XML, Turtle, JSON-LD):**
- The server executes a SPARQL DESCRIBE query against the Knowledge Graph
- Returns machine-readable RDF data about the entity in the requested format
- Perfect for automated agents, data integration, and semantic web applications

![Linked Data Entity Description](https://github.com/danielhmills/databricks-sample-kg/blob/main/bakehouse/linked-data-description.png?raw=true)
*Human-readable entity description page showing all properties and relationships*

This is the essence of **Linked Data**: every entity has a globally unique identifier (URI) that both humans and machines can dereference to discover what that entity is and how it relates to other entities. Your Databricks warehouse data becomes part of a navigable web of interconnected information, accessible through standard HTTP and queryable through standard SPARQL—without moving the data or changing your existing infrastructure.

---

## File Reference

| File | Description |
|------|-------------|
| `odbc.ini.example` | Example ODBC DSN configuration for Databricks |
| `odbcinst.ini.example` | Example ODBC driver registration |
| `bakehouse/attach.sql` | SQL to attach each Databricks table to Virtuoso |
| `bakehouse/quick_setup.sql` | One-shot setup script (attach + R2RML load + QM generation) |
| `bakehouse/r2rml.ttl` | R2RML mapping for the `bakehouse` schema |
| `bakehouse/ontology.ttl` | Ontology / vocabulary used in the R2RML mappings |

---

## Troubleshooting

- **DSN not found:** Verify ODBC configuration files are in the correct location and the DSN name matches exactly (`databricks_odbc`)
- **Connection fails:** Check Databricks credentials, ensure the SQL warehouse is running, and verify network connectivity
- **No SPARQL results:** Confirm the R2RML mapping loaded successfully and `R2RML_MAKE_QM_FROM_G` executed without errors
- **Permission errors:** Ensure `SPARQL_SELECT` grants were applied to all attached tables

---

## License

See [LICENSE](./LICENSE).
