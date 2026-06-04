# Databricks Sample Knowledge Graph

This repository demonstrates how to connect a [Virtuoso Universal Server](https://virtuoso.openlinksw.com/) instance to a [Databricks](https://www.databricks.com/) warehouse via the **Databricks ODBC Driver**, attach the remote tables locally, and expose them as a SPARQL-queryable Knowledge Graph using [R2RML](https://www.w3.org/TR/r2rml/) mappings.

The example dataset is the public **`samples.bakehouse`** schema from Databricks, which contains tables for a fictional bakery chain.

---

## Prerequisites

Before you begin, make sure you have:

- A running **Virtuoso Universal Server** (Enterprise Edition) with the **Virtual Database** (VDB) and **SPARQL** modules enabled.
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

Run the `bakehouse/quick_setup.sql` script in Virtuoso's `isql`. This script will:

1. Attach each table from Databricks into Virtuoso's local catalog.
2. Disconnect and reconnect the data source after each attach.
3. Grant `SPARQL_SELECT` privileges on each attached table.
4. Load the R2RML mapping from the repository.
5. Convert the R2RML mapping into Virtuoso's internal Quad Map (QM) representation, enabling SPARQL access.

```bash
isql 1111 dba dba < bakehouse/quick_setup.sql
```

> Replace `1111`, `dba`, and `dba` with your Virtuoso port, username, and password if different.

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

## Step 5: Query the Knowledge Graph

Once the setup is complete, you can query the Databricks tables as RDF via SPARQL. For example:

```sparql
SELECT *
FROM <urn:databricks:bakehouse:r2rml>
WHERE { ?s ?p ?o }
LIMIT 10
```

Or use the Virtuoso Faceted Browser or SPARQL endpoint to explore the data.

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

- **Connection refused / timeout:** Verify your Databricks host, HTTP path, and token. Ensure your SQL warehouse is running and accessible.
- **Driver not found:** Double-check the `Driver` path in `odbc.ini` and `odbcinst.ini`.
- **Table attach fails:** Make sure the data source is registered in Virtuoso (`vds_connect_data_source`) and the `Schema` and `Catalog` in `odbc.ini` match the Databricks target (`bakehouse` / `samples`).
- **SPARQL returns no results:** Ensure the R2RML mapping was loaded correctly and `R2RML_MAKE_QM_FROM_G` executed without errors.

---

## License

See [LICENSE](./LICENSE).
