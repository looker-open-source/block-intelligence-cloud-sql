# Fleet Operational Intelligence for Cloud SQL Looker Block

The **Fleet Operational Intelligence for Cloud SQL Looker Block** is an enterprise-grade, out-of-the-box monitoring, diagnostic, and alerting solution designed for database administrators, Site Reliability Engineers (SREs), and platform engineering teams managing relational database fleets on Google Cloud SQL (MySQL and PostgreSQL).

By querying database system catalogs directly (`performance_schema` for MySQL and `pg_stat_statements` / `pg_stat_activity` for PostgreSQL), this block translates raw engine telemetry into actionable operational insights. It empowers teams to evaluate fleet health in real time, detect connection pool saturation, identify unauthorized access attempts, optimize slow queries, and prevent full table scan bottlenecks.

---

## Architectural Highlights

* **Dual-Engine Model Architecture:** Built with native multi-dialect support. A single Looker project provides dedicated models for MySQL (`mysql_observability`) and PostgreSQL (`postgres_observability`), sharing normalized views and explores.
* **Dialect-Agnostic Routing:** Leverages Looker Liquid templating to dynamically adapt table names, column mappings, and execution time units (picoseconds vs. milliseconds) based on the active connection dialect.
* **Database & Schema Filtering:** Universal `database_name` dimension and global header filter across all dashboards and explores, enabling isolated query diagnostics for specific applications (e.g., `app_db`, `production_db`) while filtering out internal administrative catalogues.
* **Buffer Cache Hit Ratio (Cloud SQL SRE Benchmark):** Dialect-normalized memory read efficiency tracking (`Innodb_buffer_pool` on MySQL and `shared_buffers` on PostgreSQL), benchmarking memory cache hit percentages against physical disk I/O.
* **Fleet Historical Trends (Persistent 14-Day / 336-Hour Telemetry):** Materialized hourly statement performance snapshots capturing throughput curves, latency drift, and comparative workload distribution between MySQL and PostgreSQL across a rolling 14-day window (336 hours).
* **Synchronized Hourly Caching Policy:** Automated datagroup triggers (`hourly_telemetry_datagroup`) aligning explore caching and dashboard refreshes on a strict 1-hour cadence via `SELECT EXTRACT(HOUR FROM CURRENT_TIMESTAMP)`.
* **Cross-Dashboard Navigation Bar:** Unified header navigation pills connecting the consolidated fleet dashboard with dedicated deep dive dashboards for MySQL and PostgreSQL.
* **Automated Instance Health & Alerting Engine:** Real-time composite scoring that evaluates connection saturation and memory buffer cache hit ratios, rendering prominent visual operational health badges (`HEALTHY`, `WARNING`, `CRITICAL`).
* **Visual Drilling Engine (Looker Architect Standard):** Centralized Liquid visualization templates in `manifest.lkml` providing one-click interactive drills into horizontal bar charts, stacked columns, donut distributions, and forensic grid tables.
* **Period-over-Period (PoP) Analytics (Method 7):** Standardized on Google Developer Community Method 7 (Arbitrary Period and Directly Previous Period), allowing dynamic comparative benchmarking (such as 7 days vs previous 7 days) across all primary KPI metrics.
* **Persistent Derived Table (PDT) Engine via `create_process`:** Custom DDL materialization designed for Google Cloud SQL, overcoming GTID binary logging restrictions on MySQL and persisting hourly snapshots in the administrator-configured scratch schema (dynamically resolved via `${SQL_TABLE_NAME}`, e.g. `looker_scratch`) with B-Tree indexes for sub-second dashboard rendering.

---

## Packaged Dashboards & Cross-Dashboard Navigation

This block packages three operational dashboards connected via a unified header navigation bar:

> **Header Navigation:** `[ Fleet Observability ]` &nbsp;|&nbsp; `[ MySQL ]` &nbsp;|&nbsp; `[ PostgreSQL ]`

### Dashboard Suite Details

| Dashboard | Looker Dashboard Identifier | Description | Default Tab Views |
| :--- | :--- | :--- | :--- |
| **Fleet Observability** | `operational_intelligence_cloud_sql::database_observability` | **Unified Fleet Hub (Macro):** Consolidated multi-engine observability across both MySQL and PostgreSQL fleets, including live telemetry and long-term comparative trends. | MySQL Observability, PostgreSQL Observability, **Fleet Historical Trends** |
| **MySQL** | `mysql_observability::mysql_database_observability` | **MySQL Deep Dive (Micro):** Dedicated instance telemetry, thread pool concurrency, and SQL digest profiling. | Fleet Overview, Instance Deep Dive, Query Optimization |
| **PostgreSQL** | `postgres_observability::postgres_database_observability` | **PostgreSQL Deep Dive (Micro):** Dedicated backend session monitoring, client host listings, and statement analysis. | Fleet Overview, Instance Deep Dive, Query Optimization |

---

## Instance Health & Alerting Engine

The top row of the Fleet Observability dashboard features an automated **Instance Health** assessment badge paired with transparent diagnostic scorecards:

| Scorecard Tile | Diagnostic Focus | Target / Operational Benchmark |
| :--- | :--- | :--- |
| **Instance Health** | Real-time composite operational status | `HEALTHY` (Green badge) |
| **Buffer Cache Hit %** | Memory cache efficiency vs. physical disk reads | `> 95.0%` in RAM |
| **Active Connections** | Real-time connection pool load (`Threads_connected`) | `< 40` connections |
| **Aborted Connections**| Cumulative client connection drop counter | `0` nominal |
| **Total Executions** | Query volume and throughput cadence | Workload baseline |
| **Connected Hosts** | Distinct client endpoints and application daemons | Host inventory |

### Health Evaluation Matrix

| Status Level | Badge Formatting | Active Connections (`Threads_connected`) | Buffer Cache Hit % (`buffer_cache_hit_ratio`) | Operational Meaning |
| :--- | :--- | :--- | :--- | :--- |
| **`HEALTHY`** | Green (`#137333` on `#E6F4EA`) | `< 40` connections | `> 95.0%` in RAM | Fleet operating within nominal parameters. Sufficient memory caching and normal connection pool load. |
| **`WARNING`** | Amber (`#B06000` on `#FEF7E0`) | `40 - 80` connections | `90.0% - 95.0%` | Elevated connection pressure or memory read misses beginning to hit physical storage. |
| **`CRITICAL`** | Red (`#EA4335` on `#FCE8E6`) | `> 80` connections | `< 90.0%` | **Immediate Alert:** Risk of connection exhaustion (`Too many connections`) or severe disk I/O thrashing. |

---

## Historical Telemetry & Persistent Derived Table (PDT) Architecture

The **Fleet Historical Trends** tab provides long-term operational analytics across MySQL and PostgreSQL fleets across a rolling 14-day window (336 hours):

| Dashboard Section | Analytical Visualizations & Metrics |
| :--- | :--- |
| **Historical Scorecards** | `Unique Statements Tracked` \| `Total Historical Executions` \| `Fleet Average Latency` \| `Lock Wait Time` |
| **14-Day Dual-Engine Trends** | `Hourly Statement Execution Throughput` (Pivoted by Engine) \| `Hourly Average Latency Evolution` (Pivoted by Engine) |
| **Forensic Diagnostics** | `Top Latency Bottleneck Statements` (Grid Table) \| `Execution Throughput by Engine` (Column Chart) |

### Technical Implementation Details:
* **Raw View (`views/raw/statement_history_snapshot.view.lkml`):** Persistent Derived Table materialized via `create_process` with custom DDL (`CREATE TABLE` + `INSERT INTO`). Overcomes Google Cloud SQL MySQL's GTID replication constraint (`enforce_gtid_consistency = ON`), which disallows standard `CREATE TABLE AS SELECT` (CTAS) operations.
* **Dialect Routing:** Evaluates connection dialect dynamically via Liquid (`{% if _dialect._name == 'google_cloud_postgres' %}`), routing PostgreSQL models to `pg_stat_statements` with `generate_series(0, 335)` and MySQL models to `events_statements_summary_by_digest` with `WITH RECURSIVE hours`.
* **Multi-Engine Representation:** In the consolidated fleet model (`operational_intelligence_cloud_sql`), incorporates unified PostgreSQL workload representation via `UNION ALL`, enabling cross-engine comparisons on the primary fleet dashboard.
* **Refined View (`views/refined/statement_history_snapshot_rfn.view.lkml`):** Implements Google Developer Community PoP Method 7 (Arbitrary Period and Directly Previous Period). Defines period-filtered measures (`is_current_period: "yes"` and `is_previous_period: "yes"`) for instant aggregate computation across date filter modifications (e.g. 7 days vs previous 7 days).
* **Explore (`explores/statement_history_snapshot.explore.lkml`):** Conditionally restricts query scans via `sql_always_where` whenever `pop_date_filter` is applied, joins `instance_dimension_lookup`, and supports join pruning.
* **Global Engine Filter & Grid Column:** Includes root dashboard filter `engine_type` ("Database Engine") and explicit `Engine Type` identification column in the latency bottleneck table.
* **Side-by-Side Engine Comparison:** Both hourly throughput and hourly average latency trend lines pivot on `statement_history_snapshot.engine_type`, providing comparative dual-engine curves (MySQL in Google Blue `#1A73E8`, PostgreSQL in Red `#EA4335`).
* **Caching Alignment:** In all models, `hourly_telemetry_datagroup` triggers every hour on the hour (`SELECT EXTRACT(HOUR FROM CURRENT_TIMESTAMP)`) with `max_cache_age: "1 hour"`, ensuring tables rebuild in background without blocking end users.

---

## Full Architectural Breakdown & Mapping Matrix

### View Layer: Raw vs. Refined Separation
The block enforces the **Looker Architect Refinements** standard, strictly separating raw database catalog mapping from business intelligence modeling:

* **Raw Views (`views/raw/*.view.lkml`):** Map directly to database system tables (`sql_table_name`) or define base derived tables (`derived_table`). Contain primary keys, base dimensions, and dialect-specific type conversions (`CAST`).
* **Refined Views (`views/refined/*_rfn.view.lkml`):** Extend raw views via LookML refinements (`view: +view_name`). Contain Period-over-Period (PoP Method 7) filtered measures, conditional HTML formatting, and interactive visual drill templates (`manifest.lkml`).

| View | Native Engine Table (MySQL) | Native Engine Table (PostgreSQL) | Raw Layer Responsibility | Refined Layer Additions |
| :--- | :--- | :--- | :--- | :--- |
| `global_status` | `performance_schema.global_status` | Inline query over `pg_stat_activity` + `pg_stat_database` | Ingests raw key/value variables (`VARIABLE_NAME`, `VARIABLE_VALUE`). | `buffer_cache_hit_ratio`, `pop_active_connections_current`, `total_aborted_connects`, `instance_health_score`. |
| `threads` | `performance_schema.threads` | `pg_stat_activity` | Exposes connection threads, backend PIDs, users, host IPs, and execution states. | Thread concurrency measures, execution time deltas, connection duration averages. |
| `host_cache` | Subquery on `threads.PROCESSLIST_HOST` | Subquery on `pg_stat_activity.client_addr` | Normalizes and groups unique client IP addresses and hostnames. | `connected_hosts` distinct count measure and client forensic grid links. |
| `events_statements_summary_by_digest` | `performance_schema.events_statements_summary_by_digest` | `@{POSTGRES_EXTENSION_SCHEMA}.pg_stat_statements` | Maps query digests, statement SQL, execution counts, timers, and row metrics. | Performance measures: `average_latency`, `total_queries_no_index`, `total_tmp_disk_tables`, scan ratios. |
| `instance_dimension_lookup` | In-memory `derived_table` | In-memory `derived_table` | Hardcoded static metadata catalog (`machine_type`, `region`, `zone`, `version`). | Dimensional enrichment joined into statement history explores. |
| `statement_history_snapshot` | Hourly recursive CTE over `events_statements_summary_by_digest` + PostgreSQL union | `generate_series(0, 335)` over `pg_stat_statements` | Persistent Derived Table (`create_process`) generating 14-day (336h) hourly telemetry. | PoP Method 7 measures (`pop_unique_queries_current`, `pop_executions_current`, `pop_avg_latency_current`, `pop_lock_time_current`). |

---

### Multi-Engine Routing & Dialect Resolution Hierarchy

A common architectural question is: **How does Looker choose between MySQL and PostgreSQL engines at the Explore and Dashboard levels, and are there hidden filters?**

There are **no hidden filters at the explore level** (e.g., no `sql_always_where` filtering on engine type). Instead, Looker determines the target database engine strictly via its native hierarchical resolution chain:

```text
Looker Physical Connections
|-- MySQL ("@{MYSQL_CONNECTION_NAME}")
`-- PostgreSQL ("@{POSTGRES_CONNECTION_NAME}")
      |
      v
LookML Model Layer
|-- mysql_observability.model.lkml
`-- postgres_observability.model.lkml
      |
      +--> Shared Explores & Views
      |    - Zero explore-level engine filters
      |    - Dynamic Liquid: _dialect._name
      |
      `--> Dashboard Tiles
           - Tab 1: model: mysql_observability
           - Tab 2: model: postgres_observability
           - Tab 3: model: operational_intelligence...
```

| Architecture Layer | MySQL Fleet Resolution | PostgreSQL Fleet Resolution | Resolution Mechanism |
| :--- | :--- | :--- | :--- |
| **Looker Connection** | `@{MYSQL_CONNECTION_NAME}` | `@{POSTGRES_CONNECTION_NAME}` | Database dialect & host binding |
| **LookML Model** | `mysql_observability.model` | `postgres_observability.model` | Declares active `connection:` |
| **Explores** | Shared `/explores/*.explore` | Shared `/explores/*.explore` | Inherits model connection context |
| **Views** | Shared `/views/refined/*.view` | Shared `/views/refined/*.view` | Liquid `_dialect._name` compiles SQL |
| **Dashboard Tiles** | Tile specifies `model:` | Tile specifies `model:` | Routed per-tile to target engine |

#### Explore Menu Routing: Direct Model Context (No Explore-Level Filters)
In Looker's top-level **Explore** menu, explores are grouped under each model header:
* **Under `Cloud SQL Observability (MySQL)` (`mysql_observability.model.lkml`):**
  Navigating to an explore opens the URL `/explore/mysql_observability/<explore_name>`. Looker binds the query context to `@{MYSQL_CONNECTION_NAME}`. At compilation time, Looker sets `_dialect._name = 'googlecloudsql'`. The polymorphic view resolves to `performance_schema` tables, executing queries exclusively on the MySQL instance.
* **Under `Cloud SQL Observability (PostgreSQL)` (`postgres_observability.model.lkml`):**
  Navigating to the same explore opens `/explore/postgres_observability/<explore_name>`. Looker binds the query context to `@{POSTGRES_CONNECTION_NAME}`. Looker sets `_dialect._name = 'google_cloud_postgres'`. The polymorphic view resolves to `@{POSTGRES_EXTENSION_SCHEMA}.pg_stat_statements` or `pg_stat_activity`, executing queries exclusively on the PostgreSQL instance.

#### Dashboard Tile Model Targeting
Looker allows individual tiles within the same dashboard to query different models and connections:
* **Consolidated Fleet Dashboard (`database_observability.dashboard.lookml`):**
  * **Tab 1 (MySQL Observability):** Every tile explicitly specifies `model: mysql_observability`, routing all queries directly to MySQL's `performance_schema`.
  * **Tab 2 (PostgreSQL Observability):** Every tile explicitly specifies `model: postgres_observability`, routing all queries directly to PostgreSQL's `@{POSTGRES_EXTENSION_SCHEMA}.pg_stat_statements`.
  * **Tab 3 (Fleet Historical Trends):** Tiles specify `model: operational_intelligence_cloud_sql` to query the consolidated PDT (`statement_history_snapshot`). Comparative trend charts pivot by `statement_history_snapshot.engine_type` to render both engine curves concurrently without cross-database joins.
* **Dedicated Deep Dive Dashboards (`mysql_observability` and `postgres_observability`):**
  All live operational tiles point strictly to their respective model (`model: mysql_observability` or `model: postgres_observability`). In Tab 4 (Historical Trends), tiles query `statement_history_snapshot` with an explicit tile-level filter (`statement_history_snapshot.engine_type: "MySQL"` or `"PostgreSQL"`) to display only that engine's historical telemetry.

#### Polymorphic View Compilation
Because models control the active dialect, views remain 100% reusable and DRY (Don't Repeat Yourself). Looker dynamically compiles the appropriate dialect branch at runtime:

```lookml
view: events_statements_summary_by_digest {
  sql_table_name:
    {% if _dialect._name == 'google_cloud_postgres' or _dialect._name == 'postgres' %}
      @{POSTGRES_EXTENSION_SCHEMA}.pg_stat_statements
    {% else %}
      performance_schema.events_statements_summary_by_digest
    {% endif %} ;;
}
```

* In `mysql_observability` and `operational_intelligence_cloud_sql` (Connection: `@{MYSQL_CONNECTION_NAME}`), `_dialect._name` evaluates to `googlecloudsql`, querying MySQL's `performance_schema`.
* In `postgres_observability` (Connection: `@{POSTGRES_CONNECTION_NAME}`), `_dialect._name` evaluates to `google_cloud_postgres`, querying PostgreSQL's `@{POSTGRES_EXTENSION_SCHEMA}.pg_stat_statements` and `pg_stat_activity`.

---

### PDT Physical Materialization & Storage Strategy
* **Dynamic Scratch Schema Macro:** The LookML derived table definitions leverage Looker's `${SQL_TABLE_NAME}` macro within custom DDL `create_process` routines. At runtime, Looker dynamically prepends the customer-configured temporary database or scratch schema specified in the Looker Connection settings. The LookML code contains zero hardcoded database or schema names.
* **MySQL PDT Storage:** Persisted in Cloud SQL MySQL within the administrator-designated temporary database (e.g., `looker_scratch`) as a physical table with B-Tree indexes (`idx_snapshot_ts`, `idx_instance_engine`).
* **PostgreSQL PDT Storage:** Persisted in Cloud SQL PostgreSQL within the administrator-designated scratch schema (e.g., `looker_scratch` or `public`) as a physical table.
* **Rebuild Schedule:** Both tables are rebuilt asynchronously in the background every 60 minutes via `hourly_telemetry_datagroup` (`SELECT EXTRACT(HOUR FROM CURRENT_TIMESTAMP)`), ensuring sub-second dashboard query resolution.

---

### Dashboard, Tab & KPI Mapping Matrix

| Dashboard | Tab View | Tile Name | View / Explore Source | Primary Measure / Logic |
| :--- | :--- | :--- | :--- | :--- |
| **All Dashboards** | Top Header Row | **Instance Health** | `global_status` | `instance_health_score` (HEALTHY, WARNING, CRITICAL) |
| **All Dashboards** | Top Header Row | **Buffer Cache Hit %** | `global_status` | `buffer_cache_hit_ratio` (RAM read % vs disk) |
| **All Dashboards** | Top Header Row | **Active Connections** | `global_status` | `pop_active_connections_current`, `% Change` |
| **All Dashboards** | Top Header Row | **Aborted Connections** | `global_status` | `total_aborted_connects` |
| **All Dashboards** | Top Header Row | **Total Executions** | `events_statements_summary_by_digest` | `total_executions` |
| **All Dashboards** | Top Header Row | **Connected Hosts** | `host_cache` | `connected_hosts` (unique client endpoints) |
| `database_observability` | Tab 1: MySQL | Active Threads & Latency | `threads`, `global_status`, `events_statements...` | Real-time MySQL `performance_schema` tiles |
| `database_observability` | Tab 2: PostgreSQL | Active Sessions & Statements | `threads`, `global_status`, `events_statements...` | Real-time PostgreSQL `pg_stat_statements` tiles |
| `database_observability` | Tab 3: Historical Trends | **Unique Statements Tracked** | `statement_history_snapshot` (PDT) | `pop_unique_queries_current` (PoP Method 7) |
| `database_observability` | Tab 3: Historical Trends | **Total Historical Executions**| `statement_history_snapshot` (PDT) | `pop_executions_current`, `pop_executions_change` |
| `database_observability` | Tab 3: Historical Trends | **Fleet Average Latency** | `statement_history_snapshot` (PDT) | `pop_avg_latency_current`, `pop_avg_latency_change` |
| `database_observability` | Tab 3: Historical Trends | **Total Lock Wait Time** | `statement_history_snapshot` (PDT) | `pop_lock_time_current` |
| `database_observability` | Tab 3: Historical Trends | **Hourly Execution Throughput** | `statement_history_snapshot` (PDT) | `total_executions` pivoted by `engine_type` |
| `database_observability` | Tab 3: Historical Trends | **Hourly Average Latency** | `statement_history_snapshot` (PDT) | `average_latency` pivoted by `engine_type` |
| `database_observability` | Tab 3: Historical Trends | **Top Latency Bottlenecks** | `statement_history_snapshot` (PDT) | `engine_type`, `query_text`, `database_name`, `total_latency` |
| `database_observability` | Tab 3: Historical Trends | **Throughput by Engine** | `statement_history_snapshot` (PDT) | `total_executions` grouped by `engine_type` |
| `mysql_observability` | Tab 1-3: Deep Dive | Thread Concurrency & Digest | `threads`, `events_statements...` | Dedicated MySQL connection inspection |
| `mysql_observability` | Tab 4: Historical Trends | MySQL Historical Telemetry | `statement_history_snapshot` (PDT) | Filtered strictly for `engine_type = 'MySQL'` |
| `postgres_observability`| Tab 1-3: Deep Dive | Backend Sessions & Activity | `threads`, `events_statements...` | Dedicated PostgreSQL connection inspection |
| `postgres_observability`| Tab 4: Historical Trends | PostgreSQL Historical Telemetry | `statement_history_snapshot` (PDT) | Filtered strictly for `engine_type = 'PostgreSQL'` |

---

## Operational Telemetry Interpretation & FAQ

### Why Instance Health Was Previously Marked CRITICAL
* **Root Cause:** In earlier versions, health logic incorporated MySQL `Aborted_connects` with a static threshold (`> 5`). In MySQL's `performance_schema.global_status`, `Aborted_connects` is a **cumulative lifetime counter** that increments whenever a client fails authentication, times out during handshake, or disconnects improperly (for example, during a credential rotation, password update, or firewall transition). Because this counter never decrements automatically, any past incident caused the badge to remain locked in `CRITICAL`.
* **Resolution in Current Release:** Fleet health evaluation was upgraded to track **real-time gauge metrics** reflecting active system state:
  1. Concurrency pressure: `Threads_connected` (active connection pool load).
  2. Memory efficiency: `buffer_cache_hit_ratio` (InnoDB buffer pool read hits vs. physical disk reads).
* **Resetting Cumulative Counters:** If administrative operational hygiene requires resetting `Aborted_connects` on the database instance, run:
  ```sql
  FLUSH STATUS;
  ```

---

### Origin of Active Connections and Client Hosts
Operational telemetry numbers reported on the scorecards represent standard infrastructure components:
* **Looker JDBC Connection Pool (Worker Threads):** Looker maintains pooled persistent connections per datagroup and model to execute exploratory queries, health checks, and dashboard tile rendering concurrently.
* **Application Services & Daemons:** Production applications, background worker pools, microservices, and ETL jobs executing queries against business databases (e.g., `production_db`, `app_db`).
* **Cloud SQL Platform Management Agents:** Cloud SQL automated internal health probes and monitoring agents communicating via internal database socket and proxy interfaces.
* **Client Host Endpoints:**
  - Looker instance egress IP nodes.
  - Application server and compute cluster endpoints.
  - Local database proxy and sidecar interfaces.

---

### Key Cloud SQL SRE Key Performance Indicators (KPIs)
* **Buffer Cache Hit Ratio:**
  - **Formula:** `(Buffer Read Requests - Buffer Physical Reads) / Buffer Read Requests * 100`
  - **Thresholds:** Targets `> 99.0%` for online transactional workloads (OLTP). A ratio below `95.0%` signals memory starvation, leading to increased physical disk IOPS and higher latency.
* **Database & Schema Filtering:**
  - Standard database catalogs (`performance_schema`, `information_schema`, `sys`, `postgres`) process heavy internal metadata queries. Filtering by `database_name` (e.g. `app_db`, `production_db`) allows engineers to isolate application queries from infrastructure overhead.
* **Execution Latency & Lock Waits:**
  - Microsecond and picosecond execution telemetry surfaced in `events_statements_summary_by_digest` and `pg_stat_statements` helps differentiate CPU execution time from lock contention (`SUM_TIMER_WAIT` vs `SUM_LOCK_TIME`).

---

## Marketplace Installation Journey & Parameterization

When installing the **Fleet Operational Intelligence for Cloud SQL Looker Block** from the Looker Marketplace, Looker automates the deployment process through interactive parameter prompts declared in `manifest.lkml`.

### End-to-End User Journey

```text
Step 1: Database Setup
Configure monitoring users and scratch databases in Cloud SQL (MySQL & PostgreSQL)
       |
       v
Step 2: Looker Connection Configuration
Create or verify Looker database connections with PDTs enabled in Admin > Connections
       |
       v
Step 3: Marketplace Installation Prompt
Provide Looker connection names and PostgreSQL extension schema in Marketplace modal
       |
       v
Step 4: Automated LookML Dynamic Binding
Models compile with parameterized connections; PDTs leverage ${SQL_TABLE_NAME}
       |
       v
Step 5: Instant Dashboards & Auto-Discovery
Open Fleet Observability dashboard; application databases are auto-discovered dynamically
```

### Marketplace Configuration Parameters

Upon clicking **Install** in Looker Marketplace, the administrator is prompted with the following deployment constants:

| Constant Name | Type / Requirement | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `MYSQL_CONNECTION_NAME` | Optional (`override_optional`) | `mysql` | The exact name of your Looker connection configured for Cloud SQL MySQL in **Admin > Connections** (e.g., `cloudsql_mysql_prod`). |
| `POSTGRES_CONNECTION_NAME` | Optional (`override_optional`) | `looker-block-test` | The exact name of your Looker connection configured for Cloud SQL PostgreSQL in **Admin > Connections** (e.g., `cloudsql_postgres_prod`). |
| `POSTGRES_EXTENSION_SCHEMA`| Optional (`override_optional`) | `public` | The database schema where the `pg_stat_statements` extension is installed in PostgreSQL (e.g., `public` or `extensions`). |
| `SQL_ENGINE_TYPE` | Optional (`override_optional`) | `mysql` | Primary default engine family for initial dialect compilation context. |

### How Modularization Operates

1. **Connection Binding:** Looker injects the administrator's inputs directly into `manifest.lkml`. The models reference these via `connection: "@{MYSQL_CONNECTION_NAME}"` and `connection: "@{POSTGRES_CONNECTION_NAME}"`, guaranteeing zero hardcoded connection names.
2. **Dynamic Database Auto-Discovery:** Customers do not need to configure their business database names (e.g., `app_db`, `payments_prod`). Because this block reads engine system catalogs (`performance_schema` and `pg_database`), Looker discovers all databases on the fleet automatically and populates the dashboard filters dynamically.
3. **Connection-Managed Scratch Schemas:** Persistent Derived Tables (PDTs) use Looker's native `${SQL_TABLE_NAME}` macro. The scratch database or schema name is managed entirely within Looker Admin connection settings, requiring zero code adjustments during migration across environments.

### Single-Engine Deployment (MySQL-Only or PostgreSQL-Only Environments)

Because all constants in `manifest.lkml` are defined as `export: override_optional`, this block natively supports single-engine environments without requiring code modifications or disabling models.

#### How the Looker Compiler and Liquid Engine Handle Single-Engine Setups
1. **Model Connection Validation:** Looker validates that every `.model.lkml` file points to an existing connection name in **Admin > Connections**. If a field is left blank or points to a connection name that does not exist on the customer's server, Looker reports a model validation error (`Connection does not exist`). To prevent this when using only one engine, simply enter your single existing connection name into **both** `MYSQL_CONNECTION_NAME` and `POSTGRES_CONNECTION_NAME`.
2. **Dynamic Dialect Compilation (`_dialect._name`):** Looker does not determine SQL syntax based on the model's filename (`mysql_observability` vs. `postgres_observability`). Instead, Looker inspects the **database driver** of the assigned connection and sets `_dialect._name` (`googlecloudsql` for MySQL, `google_cloud_postgres` for PostgreSQL).
3. **Pure Native SQL Sent to Database:** The Liquid `{% if _dialect._name == 'google_cloud_postgres' %}` condition is evaluated on the Looker server **before** any query is transmitted. The database never sees Liquid syntax or tables belonging to the other engine—it receives 100% pure native SQL (`performance_schema` for MySQL or `pg_stat_statements` for PostgreSQL).

#### Deployment Configuration Matrix by Environment

| Customer Environment | Marketplace Input Values | Looker Compiler Behavior | SQL Sent to Database |
| :--- | :--- | :--- | :--- |
| **Dual-Engine (MySQL + PostgreSQL)** | `MYSQL_CONNECTION_NAME` = `<your_mysql_conn>`<br>`POSTGRES_CONNECTION_NAME` = `<your_pg_conn>` | MySQL models compile MySQL branch; PostgreSQL model compiles Postgres branch. | MySQL receives `performance_schema` queries; PostgreSQL receives `pg_stat_statements` queries. |
| **MySQL-Only (No PostgreSQL)** | `MYSQL_CONNECTION_NAME` = `<your_mysql_conn>`<br>`POSTGRES_CONNECTION_NAME` = `<your_mysql_conn>` | Both models resolve `_dialect._name = googlecloudsql` and compile the MySQL branch. | MySQL receives exclusively `performance_schema` queries across all models (0 errors). |
| **PostgreSQL-Only (No MySQL)** | `MYSQL_CONNECTION_NAME` = `<your_pg_conn>`<br>`POSTGRES_CONNECTION_NAME` = `<your_pg_conn>`<br>`SQL_ENGINE_TYPE` = `postgres` | All models and PDTs resolve `_dialect._name = google_cloud_postgres` and compile the Postgres branch. | PostgreSQL receives exclusively `pg_stat_statements` and `pg_stat_activity` queries (0 errors). |

---

## Prerequisites & Database Configuration

### Cloud SQL for MySQL Setup
* **Database Flag:** Ensure `performance_schema = on` is enabled on your Cloud SQL MySQL instance.
* **Network Security:** Restrict Authorized Networks strictly to authorized application and Looker egress IP ranges.
* **User Privileges & Scratch Database (for PDT Materialization):**
  Connect as administrative user (`root` or admin) and execute (replacing `looker_scratch` with your organization's designated temporary database name if different):
  ```sql
  -- 1. Create monitoring user
  CREATE USER IF NOT EXISTS 'looker_monitor'@'%' IDENTIFIED BY '<PASSWORD>';

  -- 2. Grant read-only access to performance telemetry
  GRANT SELECT ON performance_schema.events_statements_summary_by_digest TO 'looker_monitor'@'%';
  GRANT SELECT ON performance_schema.global_status TO 'looker_monitor'@'%';
  GRANT SELECT ON performance_schema.threads TO 'looker_monitor'@'%';
  GRANT SELECT ON performance_schema.host_cache TO 'looker_monitor'@'%';
  GRANT PROCESS, REPLICATION CLIENT, SHOW DATABASES ON *.* TO 'looker_monitor'@'%';

  -- 3. Create dedicated scratch database for PDT materialization (e.g. looker_scratch)
  CREATE DATABASE IF NOT EXISTS looker_scratch;

  -- 4. Grant DDL and DML privileges on scratch database
  GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, CREATE TEMPORARY TABLES, SHOW VIEW ON looker_scratch.* TO 'looker_monitor'@'%';
  GRANT CREATE TEMPORARY TABLES ON *.* TO 'looker_monitor'@'%';

  FLUSH PRIVILEGES;
  ```
* **Looker Admin Connection Configuration:**
  - Go to **Admin > Connections > Edit MySQL Connection** (`@{MYSQL_CONNECTION_NAME}`).
  - Enable **Persistent Derived Tables (PDTs)**: `ON`.
  - Set **Temp Database / Scratch Schema**: The temporary database created above (e.g., `looker_scratch`).
  - Set **Max PDT Builder Connections**: `2` (or per organizational policy).

---

### Cloud SQL for PostgreSQL Setup
* **Database Flags:** Configure `shared_preload_libraries = pg_stat_statements` and `pg_stat_statements.track = ALL`.
* **User Privileges & Scratch Schema (for PDT Materialization):**
  Connect as `postgres` superuser on database `postgres` and run (replacing `looker_scratch` with your organization's designated temporary schema name if different):
  ```sql
  -- 1. Enable extension and create user
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
  CREATE USER looker_monitor WITH PASSWORD '<PASSWORD>';

  -- 2. Grant read-only access to PostgreSQL performance statistics
  GRANT pg_read_all_stats TO looker_monitor;
  GRANT SELECT ON pg_stat_statements TO looker_monitor;
  GRANT SELECT ON pg_stat_activity TO looker_monitor;
  GRANT SELECT ON pg_stat_database TO looker_monitor;

  -- 3. Create dedicated scratch schema for PDT materialization (e.g. looker_scratch)
  CREATE SCHEMA IF NOT EXISTS looker_scratch;

  -- 4. Grant DDL and DML privileges on scratch schema
  GRANT USAGE, CREATE ON SCHEMA looker_scratch TO looker_monitor;
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA looker_scratch TO looker_monitor;
  ALTER DEFAULT PRIVILEGES IN SCHEMA looker_scratch GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO looker_monitor;
  ```
* **Looker Admin Connection Configuration:**
  - Go to **Admin > Connections > Edit PostgreSQL Connection** (`@{POSTGRES_CONNECTION_NAME}`).
  - Enable **Persistent Derived Tables (PDTs)**: `ON`.
  - Set **Temp Database / Scratch Schema**: The temporary schema created above (e.g., `looker_scratch`).
  - Set **Max PDT Builder Connections**: `2` (or per organizational policy).

---

## License

This Looker Block is released under the [MIT License](LICENSE.md).
