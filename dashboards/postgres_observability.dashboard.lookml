- dashboard: postgres_database_observability
  title: "Cloud SQL Observability (PostgreSQL)"
  layout: newspaper
  preferred_viewer: dashboards-next
  
  filters:
    - name: pop_date_filter
      title: "Comparison Date Range"
      type: date_filter
      default_value: "7 days"
      allow_multiple_values: false
      required: false
      ui_config:
        type: relative_timeframes
        display: inline


    - name: database_name
      title: "Database / Schema"
      type: field_filter
      default_value: ""
      allow_multiple_values: true
      required: false
      ui_config:
        type: dropdown_menu
        display: inline
      model: postgres_observability
      explore: events_statements_summary_by_digest
      field: events_statements_summary_by_digest.database_name

    - name: query_search
      title: "Query Contains"
      type: string_filter
      default_value: ""
      allow_multiple_values: false
      required: false
      ui_config:
        type: input
        display: inline

    - name: process_user
      title: "Process User"
      type: string_filter
      default_value: ""
      allow_multiple_values: false
      required: false
      ui_config:
        type: input
        display: inline

  tabs:
    - name: postgres_fleet_overview_tab
      label: "Fleet Overview (Macro)"
    - name: postgres_instance_deep_dive_tab
      label: "Instance Deep Dive (Micro)"
    - name: postgres_query_performance_tab
      label: "Query Optimization"
    - name: postgres_historical_trends_tab
      label: "Historical Telemetry"

  elements:
    # =========================================================================
    # TAB 1: FLEET OVERVIEW (MACRO)
    # =========================================================================
    - name: postgres_fleet_nav_banner
      type: text
      title_text: ""
      body_text: "<div style='display: flex; justify-content: space-between; align-items: center; padding: 4px 0 10px 0; border-bottom: 1px solid #E8EAED;'><div><div style='font-size: 20px; font-weight: 600; color: #1A73E8; margin-bottom: 2px;'>Cloud SQL Observability (PostgreSQL)</div><div style='font-size: 13px; color: #5F6368;'>Dedicated instance deep dive, backend sessions, and statement analysis for PostgreSQL fleets.</div></div><div style='display: flex; gap: 8px;'><a href='/dashboards/operational_intelligence_cloud_sql::database_observability' style='display: inline-block; background-color: #FFFFFF; color: #1A73E8; font-size: 12px; font-weight: 500; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #DADCE0;'>Fleet Observability</a><a href='/dashboards/mysql_observability::mysql_database_observability' style='display: inline-block; background-color: #FFFFFF; color: #1A73E8; font-size: 12px; font-weight: 500; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #DADCE0;'>MySQL</a><a href='/dashboards/postgres_observability::postgres_database_observability' style='display: inline-block; background-color: #1A73E8; color: #FFFFFF; font-size: 12px; font-weight: 600; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #1A73E8;'>PostgreSQL</a></div></div>"
      tab_name: postgres_fleet_overview_tab
      row: 0
      col: 0
      width: 24
      height: 2

    # --- ROW 1: HEALTH & PERFORMANCE SCORECARDS (5 TILES) ---
    - name: postgres_fleet_total_instances
      title: "Connected Hosts"
      subtitle: "Unique remote endpoints"
      model: postgres_observability
      explore: host_cache
      type: single_value
      fields: [host_cache.pop_total_instances_current, host_cache.pop_total_instances_change]
      listen:
        pop_date_filter: host_cache.pop_date_filter
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: false
      show_comparison_label: true
      comparison_label: "vs Prior Period"
      note_state: collapsed
      note_display: hover
      note_text: "Total number of unique client IP addresses connecting to PostgreSQL instances."
      tab_name: postgres_fleet_overview_tab
      row: 2
      col: 0
      width: 4
      height: 4

    - name: postgres_fleet_buffer_cache_hit
      title: "Buffer Cache Hit Ratio"
      subtitle: "Shared buffers efficiency"
      model: postgres_observability
      explore: global_status
      type: single_value
      fields: [global_status.buffer_cache_hit_ratio]
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Percentage of block reads served directly from PostgreSQL shared buffers without disk I/O."
      tab_name: postgres_fleet_overview_tab
      row: 2
      col: 4
      width: 5
      height: 4

    - name: postgres_fleet_connection_health
      title: "Active Connections"
      subtitle: "Connected client sessions"
      model: postgres_observability
      explore: global_status
      type: single_value
      fields: [global_status.pop_active_connections_current, global_status.pop_active_connections_change]
      listen:
        pop_date_filter: global_status.pop_date_filter
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: true
      show_comparison_label: true
      comparison_label: "vs Prior Period"
      note_state: collapsed
      note_display: hover
      note_text: "Current count of active client connections compared against the prior benchmark."
      tab_name: postgres_fleet_overview_tab
      row: 2
      col: 9
      width: 5
      height: 4

    - name: postgres_fleet_total_executions
      title: "Total Statement Calls"
      subtitle: "Aggregated statement executions"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: single_value
      fields: [events_statements_summary_by_digest.pop_total_executions_current, events_statements_summary_by_digest.pop_total_executions_change]
      listen:
        pop_date_filter: events_statements_summary_by_digest.pop_date_filter
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: false
      show_comparison_label: true
      comparison_label: "vs Prior Period"
      note_state: collapsed
      note_display: hover
      note_text: "Total number of statement calls tracked by pg_stat_statements."
      tab_name: postgres_fleet_overview_tab
      row: 2
      col: 14
      width: 5
      height: 4

    - name: postgres_fleet_active_threads
      title: "Active Worker Backends"
      subtitle: "Executing server backend processes"
      model: postgres_observability
      explore: threads
      type: single_value
      fields: [threads.pop_active_threads_current, threads.pop_active_threads_change]
      listen:
        pop_date_filter: threads.pop_date_filter
        process_user: threads.processlist_user
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: true
      show_comparison_label: true
      comparison_label: "vs Prior Period"
      note_state: collapsed
      note_display: hover
      note_text: "Total backend worker processes currently active in PostgreSQL."
      tab_name: postgres_fleet_overview_tab
      row: 2
      col: 19
      width: 5
      height: 4

    - name: postgres_fleet_connection_trends
      title: "Connection Saturation Trends"
      subtitle: "Connected sessions over time"
      model: postgres_observability
      explore: global_status
      type: looker_line
      fields: [global_status.variable_name, global_status.active_connections]
      filters:
        global_status.variable_name: "Threads_connected"
      note_state: collapsed
      note_display: hover
      note_text: "Monitors PostgreSQL backend connection patterns to detect connection surges."
      tab_name: postgres_fleet_overview_tab
      row: 6
      col: 0
      width: 12
      height: 6

    - name: postgres_fleet_error_summary
      title: "Fleet-wide Aborted Connections"
      subtitle: "Connection failure counts"
      model: postgres_observability
      explore: global_status
      type: looker_column
      fields: [global_status.variable_name, global_status.total_aborted_connects]
      filters:
        global_status.variable_name: "Aborted_connects"
      note_state: collapsed
      note_display: hover
      note_text: "Monitors dropped connections and connection failures across PostgreSQL instances."
      tab_name: postgres_fleet_overview_tab
      row: 6
      col: 12
      width: 12
      height: 6

    - name: postgres_fleet_needs_attention
      title: "Connected Client Host Inventory"
      subtitle: "Client endpoint listings"
      model: postgres_observability
      explore: host_cache
      type: looker_grid
      fields: [host_cache.host, host_cache.total_instances]
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Inventory of client IP addresses and hostnames actively connected to PostgreSQL."
      tab_name: postgres_fleet_overview_tab
      row: 12
      col: 0
      width: 12
      height: 8

    - name: postgres_fleet_slow_queries_preview
      title: "Top 10 Slowest Statements"
      subtitle: "Ranked by average latency"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: looker_grid
      fields: [events_statements_summary_by_digest.query_text, events_statements_summary_by_digest.database_name, events_statements_summary_by_digest.total_executions, events_statements_summary_by_digest.average_execution_time]
      sorts: [events_statements_summary_by_digest.average_execution_time desc]
      filters:
        events_statements_summary_by_digest.query_text: "-NULL"
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Ranks top slowest PostgreSQL statements by mean execution time from pg_stat_statements."
      tab_name: postgres_fleet_overview_tab
      row: 12
      col: 12
      width: 12
      height: 8

    # =========================================================================
    # TAB 2: INSTANCE DEEP DIVE (MICRO)
    # =========================================================================
    - name: postgres_dive_nav_banner
      type: text
      title_text: ""
      body_text: "<div style='display: flex; justify-content: space-between; align-items: center; padding: 4px 0 10px 0; border-bottom: 1px solid #E8EAED;'><div><div style='font-size: 20px; font-weight: 600; color: #1A73E8; margin-bottom: 2px;'>Cloud SQL Observability (PostgreSQL) - Deep Dive</div><div style='font-size: 13px; color: #5F6368;'>Dedicated instance deep dive, backend sessions, and statement analysis for PostgreSQL fleets.</div></div><div style='display: flex; gap: 8px;'><a href='/dashboards/operational_intelligence_cloud_sql::database_observability' style='display: inline-block; background-color: #FFFFFF; color: #1A73E8; font-size: 12px; font-weight: 500; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #DADCE0;'>Fleet Observability</a><a href='/dashboards/mysql_observability::mysql_database_observability' style='display: inline-block; background-color: #FFFFFF; color: #1A73E8; font-size: 12px; font-weight: 500; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #DADCE0;'>MySQL</a><a href='/dashboards/postgres_observability::postgres_database_observability' style='display: inline-block; background-color: #1A73E8; color: #FFFFFF; font-size: 12px; font-weight: 600; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #1A73E8;'>PostgreSQL</a></div></div>"
      tab_name: postgres_instance_deep_dive_tab
      row: 0
      col: 0
      width: 24
      height: 2

    - name: postgres_instance_active_threads
      title: "Active Backends"
      subtitle: "Executing server backend processes"
      model: postgres_observability
      explore: threads
      type: single_value
      fields: [threads.pop_active_threads_current, threads.pop_active_threads_change]
      listen:
        pop_date_filter: threads.pop_date_filter
        process_user: threads.processlist_user
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: true
      show_comparison_label: true
      comparison_label: "vs Prior Period"
      note_state: collapsed
      note_display: hover
      note_text: "Total active server backends handling connections in pg_stat_activity."
      tab_name: postgres_instance_deep_dive_tab
      row: 2
      col: 0
      width: 6
      height: 4

    - name: postgres_instance_running_threads
      title: "Running Backends"
      subtitle: "Actively executing queries"
      model: postgres_observability
      explore: threads
      type: single_value
      fields: [threads.running_threads_count]
      listen:
        process_user: threads.processlist_user
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Count of server backends currently executing SQL queries."
      tab_name: postgres_instance_deep_dive_tab
      row: 2
      col: 6
      width: 6
      height: 4

    - name: postgres_instance_background_threads
      title: "Background Backends"
      subtitle: "Internal system processes"
      model: postgres_observability
      explore: threads
      type: single_value
      fields: [threads.background_threads_count]
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Count of internal background workers (autovacuum, walwriter, checkpointer)."
      tab_name: postgres_instance_deep_dive_tab
      row: 2
      col: 12
      width: 6
      height: 4

    - name: postgres_instance_active_connections
      title: "Active Connections"
      subtitle: "Connected client sessions"
      model: postgres_observability
      explore: global_status
      type: single_value
      fields: [global_status.pop_active_connections_current, global_status.pop_active_connections_change]
      listen:
        pop_date_filter: global_status.pop_date_filter
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: true
      show_comparison_label: true
      comparison_label: "vs Prior Period"
      note_state: collapsed
      note_display: hover
      note_text: "Total active client connections tracked in pg_stat_activity."
      tab_name: postgres_instance_deep_dive_tab
      row: 2
      col: 18
      width: 6
      height: 4

    - name: postgres_instance_active_running_threads
      title: "Active vs. Running Worker Backends"
      subtitle: "Backend concurrency profile"
      model: postgres_observability
      explore: threads
      type: looker_line
      fields: [threads.type, threads.active_threads_count, threads.running_threads_count]
      listen:
        process_user: threads.processlist_user
      series_types:
        threads.running_threads_count: column
      y_axes:
        - label: "Total Backends"
          orientation: left
          series:
            - id: threads.active_threads_count
              name: "Active"
        - label: "Running"
          orientation: right
          series:
            - id: threads.running_threads_count
              name: "Running"
      note_state: collapsed
      note_display: hover
      note_text: "Compares total active sessions against sessions actively processing queries."
      tab_name: postgres_instance_deep_dive_tab
      row: 6
      col: 0
      width: 24
      height: 6

    - name: postgres_instance_cpu_memory_trends
      title: "Backend Load by Role"
      subtitle: "Resource allocation by role"
      model: postgres_observability
      explore: threads
      type: looker_column
      fields: [threads.processlist_user, threads.active_threads_count]
      filters:
        threads.processlist_user: "-NULL"
      listen:
        process_user: threads.processlist_user
      note_state: collapsed
      note_display: hover
      note_text: "Shows the proportion of backend processes associated with each PostgreSQL role."
      tab_name: postgres_instance_deep_dive_tab
      row: 12
      col: 0
      width: 12
      height: 8

    - name: postgres_instance_iops
      title: "Connections Profile"
      subtitle: "Connected sessions status"
      model: postgres_observability
      explore: global_status
      type: looker_column
      fields: [global_status.variable_name, global_status.active_connections]
      note_state: collapsed
      note_display: hover
      note_text: "Profile of active database connection variables."
      tab_name: postgres_instance_deep_dive_tab
      row: 12
      col: 12
      width: 12
      height: 8

    # =========================================================================
    # TAB 3: QUERY OPTIMIZATION
    # =========================================================================
    - name: postgres_query_nav_banner
      type: text
      title_text: ""
      body_text: "<div style='display: flex; justify-content: space-between; align-items: center; padding: 4px 0 10px 0; border-bottom: 1px solid #E8EAED;'><div><div style='font-size: 20px; font-weight: 600; color: #1A73E8; margin-bottom: 2px;'>Cloud SQL Observability (PostgreSQL) - Query Optimization</div><div style='font-size: 13px; color: #5F6368;'>Diagnostic profiling of latency, lock contention, missing indexes, storage scan ratios, and temporary disk block spills across PostgreSQL statements.</div></div><div style='display: flex; gap: 8px;'><a href='/dashboards/operational_intelligence_cloud_sql::database_observability' style='display: inline-block; background-color: #FFFFFF; color: #1A73E8; font-size: 12px; font-weight: 500; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #DADCE0;'>Fleet Observability</a><a href='/dashboards/mysql_observability::mysql_database_observability' style='display: inline-block; background-color: #FFFFFF; color: #1A73E8; font-size: 12px; font-weight: 500; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #DADCE0;'>MySQL</a><a href='/dashboards/postgres_observability::postgres_database_observability' style='display: inline-block; background-color: #1A73E8; color: #FFFFFF; font-size: 12px; font-weight: 600; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #1A73E8;'>PostgreSQL</a></div></div>"
      tab_name: postgres_query_performance_tab
      row: 0
      col: 0
      width: 24
      height: 2

    # --- ROW 1: 6 QUERY PERFORMANCE SCORECARDS (4 COLS EACH = 24 COLS) ---
    - name: postgres_total_executions_kpi
      title: "Total Statement Calls"
      subtitle: "Cumulative throughput (Server Uptime)"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: single_value
      fields: [events_statements_summary_by_digest.total_executions]
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Total statement executions recorded by pg_stat_statements across PostgreSQL instances since the server was started (cumulative uptime counters)."
      tab_name: postgres_query_performance_tab
      row: 2
      col: 0
      width: 4
      height: 4

    - name: postgres_avg_exec_time_kpi
      title: "Average Latency"
      subtitle: "Mean execution duration"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: single_value
      fields: [events_statements_summary_by_digest.average_execution_time]
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Average execution latency across all recorded PostgreSQL statements in pg_stat_statements."
      tab_name: postgres_query_performance_tab
      row: 2
      col: 4
      width: 4
      height: 4

    - name: postgres_peak_exec_time_kpi
      title: "Peak Latency Outlier"
      subtitle: "Worst-case execution time"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: single_value
      fields: [events_statements_summary_by_digest.max_execution_time]
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Maximum single execution duration recorded across all PostgreSQL statement calls."
      tab_name: postgres_query_performance_tab
      row: 2
      col: 8
      width: 4
      height: 4

    - name: postgres_total_lock_time_kpi
      title: "Total Lock Wait Time"
      subtitle: "Aggregated lock contention"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: single_value
      fields: [events_statements_summary_by_digest.total_lock_time]
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Total cumulative lock wait time across all queries."
      tab_name: postgres_query_performance_tab
      row: 2
      col: 12
      width: 4
      height: 4

    - name: postgres_scan_efficiency_kpi
      title: "Scan vs Returned Ratio"
      subtitle: "Index efficiency indicator"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: single_value
      fields: [events_statements_summary_by_digest.rows_examined_per_row_sent]
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Storage rows scanned divided by rows returned. Ratios above 100x indicate severe index starvation."
      tab_name: postgres_query_performance_tab
      row: 2
      col: 16
      width: 4
      height: 4

    - name: postgres_disk_spill_kpi
      title: "Temp Blocks on Disk"
      subtitle: "Disk I/O spill events"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: single_value
      fields: [events_statements_summary_by_digest.total_temp_disk_tables]
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Total temporary blocks written to disk storage (temp_blks_written) during statement execution."
      tab_name: postgres_query_performance_tab
      row: 2
      col: 20
      width: 4
      height: 4

    # --- ROW 2: LATENCY & FULL SCAN DIAGNOSTICS ---
    - name: postgres_top_10_slowest_queries
      title: "Top 10 Slowest Statements"
      subtitle: "Ranked by average latency"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: looker_grid
      fields: [events_statements_summary_by_digest.query_text, events_statements_summary_by_digest.database_name, events_statements_summary_by_digest.total_executions, events_statements_summary_by_digest.average_execution_time, events_statements_summary_by_digest.max_execution_time, events_statements_summary_by_digest.total_lock_time, events_statements_summary_by_digest.query_health_tier]
      sorts: [events_statements_summary_by_digest.average_execution_time desc]
      filters:
        events_statements_summary_by_digest.query_text: "-NULL"
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Top slowest SQL statements ranked by average execution latency, peak latency, and health tier."
      tab_name: postgres_query_performance_tab
      row: 6
      col: 0
      width: 14
      height: 8

    - name: postgres_query_no_index_scans
      title: "Statements Missing Indexes (Full Scans)"
      subtitle: "Top queries executing unindexed table scans"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: looker_bar
      fields: [events_statements_summary_by_digest.query_text, events_statements_summary_by_digest.total_queries_no_index]
      sorts: [events_statements_summary_by_digest.total_queries_no_index desc]
      filters:
        events_statements_summary_by_digest.query_text: "-NULL"
        events_statements_summary_by_digest.total_queries_no_index: ">0"
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Ranks top 10 statements with highest volume of unindexed full table scans causing storage engine overhead."
      tab_name: postgres_query_performance_tab
      row: 6
      col: 14
      width: 10
      height: 8

    # --- ROW 3: INDEX STARVATION & DISK SPILL HOTSPOTS ---
    - name: postgres_index_starvation_hotspots
      title: "Index Starvation Hotspots (High Scan-to-Sent Ratio)"
      subtitle: "Queries examining excessive rows per row returned"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: looker_grid
      fields: [events_statements_summary_by_digest.query_text, events_statements_summary_by_digest.database_name, events_statements_summary_by_digest.total_executions, events_statements_summary_by_digest.rows_examined_per_row_sent, events_statements_summary_by_digest.total_rows_examined, events_statements_summary_by_digest.total_rows_sent, events_statements_summary_by_digest.query_health_tier]
      sorts: [events_statements_summary_by_digest.rows_examined_per_row_sent desc]
      filters:
        events_statements_summary_by_digest.query_text: "-NULL"
        events_statements_summary_by_digest.total_executions: ">1"
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Isolates queries where the storage engine scanned significantly more rows than delivered to the client, identifying prime candidates for secondary index creation."
      tab_name: postgres_query_performance_tab
      row: 14
      col: 0
      width: 14
      height: 8

    - name: postgres_disk_spill_statements
      title: "Disk I/O Spill & Sort Operations"
      subtitle: "Statements creating on-disk temporary blocks"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: looker_grid
      fields: [events_statements_summary_by_digest.query_text, events_statements_summary_by_digest.total_executions, events_statements_summary_by_digest.total_temp_disk_tables, events_statements_summary_by_digest.total_sort_scans]
      sorts: [events_statements_summary_by_digest.total_temp_disk_tables desc]
      filters:
        events_statements_summary_by_digest.query_text: "-NULL"
        events_statements_summary_by_digest.total_temp_disk_tables: ">0"
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Identifies statements spilling temporary blocks to disk or performing full sort scans, causing heavy storage I/O."
      tab_name: postgres_query_performance_tab
      row: 14
      col: 14
      width: 10
      height: 8

    # --- ROW 4: LOCK CONTENTION & LATENCY DISTRIBUTION ---
    - name: postgres_query_high_lock_time
      title: "Lock Contention by Statement"
      subtitle: "Statements causing highest lock waits"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: looker_bar
      fields: [events_statements_summary_by_digest.query_text, events_statements_summary_by_digest.total_lock_time]
      sorts: [events_statements_summary_by_digest.total_lock_time desc]
      filters:
        events_statements_summary_by_digest.query_text: "-NULL"
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Identifies statements with highest cumulative lock wait times."
      tab_name: postgres_query_performance_tab
      row: 22
      col: 0
      width: 12
      height: 8

    - name: postgres_query_execution_distribution
      title: "Execution Latency Distribution"
      subtitle: "Latency vs execution frequency"
      model: postgres_observability
      explore: events_statements_summary_by_digest
      type: looker_scatter
      fields: [events_statements_summary_by_digest.total_executions, events_statements_summary_by_digest.average_execution_time]
      listen:
        query_search: events_statements_summary_by_digest.query_text
        database_name: events_statements_summary_by_digest.database_name
      note_state: collapsed
      note_display: hover
      note_text: "Correlates execution volume against average latency to pinpoint high-volume bottlenecks."
      tab_name: postgres_query_performance_tab
      row: 22
      col: 12
      width: 12
      height: 8

    # =========================================================================
    # TAB 4: HISTORICAL TELEMETRY (POP & TRENDS)
    # =========================================================================
    - name: postgres_hist_nav_banner
      type: text
      title_text: ""
      body_text: "<div style='display: flex; justify-content: space-between; align-items: center; padding: 4px 0 10px 0; border-bottom: 1px solid #E8EAED;'><div><div style='font-size: 20px; font-weight: 600; color: #1A73E8; margin-bottom: 2px;'>Cloud SQL Observability (PostgreSQL) - Historical Telemetry</div><div style='font-size: 13px; color: #5F6368;'>Hourly statement execution cadence, latency regressions, and Period-over-Period query throughput benchmarks for PostgreSQL.</div></div><div style='display: flex; gap: 8px;'><a href='/dashboards/operational_intelligence_cloud_sql::database_observability' style='display: inline-block; background-color: #FFFFFF; color: #1A73E8; font-size: 12px; font-weight: 500; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #DADCE0;'>Fleet Observability</a><a href='/dashboards/mysql_observability::mysql_database_observability' style='display: inline-block; background-color: #FFFFFF; color: #1A73E8; font-size: 12px; font-weight: 500; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #DADCE0;'>MySQL</a><a href='/dashboards/postgres_observability::postgres_database_observability' style='display: inline-block; background-color: #1A73E8; color: #FFFFFF; font-size: 12px; font-weight: 600; padding: 6px 16px; border-radius: 18px; text-decoration: none; border: 1.5px solid #1A73E8;'>PostgreSQL</a></div></div>"
      tab_name: postgres_historical_trends_tab
      row: 0
      col: 0
      width: 24
      height: 2

    # --- ROW 1: 4 SCORECARDS WITH POP COMPARISON (6 COLS EACH = 24 COLS) ---
    - name: postgres_hist_total_queries
      title: "Unique Statements Tracked"
      subtitle: "Distinct query fingerprints"
      model: postgres_observability
      explore: statement_history_snapshot
      type: single_value
      fields: [statement_history_snapshot.pop_unique_queries_current]
      filters:
        statement_history_snapshot.engine_type: "PostgreSQL"
      listen:
        pop_date_filter: statement_history_snapshot.pop_date_filter
        database_name: statement_history_snapshot.database_name
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Total unique normalized SQL statements tracked for PostgreSQL across historical snapshot intervals."
      tab_name: postgres_historical_trends_tab
      row: 2
      col: 0
      width: 6
      height: 4

    - name: postgres_hist_total_executions
      title: "Historical Calls"
      subtitle: "Period-over-Period call volume"
      model: postgres_observability
      explore: statement_history_snapshot
      type: single_value
      fields: [statement_history_snapshot.pop_executions_current, statement_history_snapshot.pop_executions_change]
      filters:
        statement_history_snapshot.engine_type: "PostgreSQL"
      listen:
        pop_date_filter: statement_history_snapshot.pop_date_filter
        database_name: statement_history_snapshot.database_name
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: false
      show_comparison_label: true
      comparison_label: "vs Prior Period"
      note_state: collapsed
      note_display: hover
      note_text: "Total PostgreSQL statement calls within the selected comparison window with period-over-period delta throughput."
      tab_name: postgres_historical_trends_tab
      row: 2
      col: 6
      width: 6
      height: 4

    - name: postgres_hist_avg_latency
      title: "Average Latency"
      subtitle: "Period-over-Period latency"
      model: postgres_observability
      explore: statement_history_snapshot
      type: single_value
      fields: [statement_history_snapshot.pop_avg_latency_current, statement_history_snapshot.pop_avg_latency_change]
      filters:
        statement_history_snapshot.engine_type: "PostgreSQL"
      listen:
        pop_date_filter: statement_history_snapshot.pop_date_filter
        database_name: statement_history_snapshot.database_name
      show_single_value_title: true
      show_comparison: true
      comparison_type: change
      comparison_reverse_colors: true
      show_comparison_label: true
      comparison_label: "vs Prior Period"
      note_state: collapsed
      note_display: hover
      note_text: "Average execution latency across PostgreSQL statements with period-over-period delta regression tracking."
      tab_name: postgres_historical_trends_tab
      row: 2
      col: 12
      width: 6
      height: 4

    - name: postgres_hist_lock_time
      title: "Total Lock Wait Time"
      subtitle: "Cumulative lock contention"
      model: postgres_observability
      explore: statement_history_snapshot
      type: single_value
      fields: [statement_history_snapshot.pop_lock_time_current]
      filters:
        statement_history_snapshot.engine_type: "PostgreSQL"
      listen:
        pop_date_filter: statement_history_snapshot.pop_date_filter
        database_name: statement_history_snapshot.database_name
      show_single_value_title: true
      note_state: collapsed
      note_display: hover
      note_text: "Total cumulative lock wait duration across PostgreSQL statements."
      tab_name: postgres_historical_trends_tab
      row: 2
      col: 18
      width: 6
      height: 4

    # --- ROW 2: HOURLY TREND LINES (12 COLS EACH = 24 COLS) ---
    - name: postgres_hist_hourly_execution_trend
      title: "Hourly Call Throughput"
      subtitle: "Execution volume evolution over last 24 hours"
      model: postgres_observability
      explore: statement_history_snapshot
      type: looker_line
      fields: [statement_history_snapshot.snapshot_hour, statement_history_snapshot.total_executions]
      sorts: [statement_history_snapshot.snapshot_hour asc]
      filters:
        statement_history_snapshot.engine_type: "PostgreSQL"
      listen:
        pop_date_filter: statement_history_snapshot.snapshot_date
        database_name: statement_history_snapshot.database_name
      x_axis_gridlines: false
      y_axis_gridlines: true
      show_view_names: false
      show_y_axis_labels: true
      show_y_axis_ticks: true
      show_x_axis_label: true
      show_x_axis_ticks: true
      legend_position: center
      point_style: circle
      interpolation: monotone
      note_state: collapsed
      note_display: hover
      note_text: "Hourly statement call cadence for PostgreSQL workloads."
      tab_name: postgres_historical_trends_tab
      row: 6
      col: 0
      width: 12
      height: 8

    - name: postgres_hist_hourly_latency_trend
      title: "Hourly Average Latency Evolution"
      subtitle: "Response time progression over last 24 hours"
      model: postgres_observability
      explore: statement_history_snapshot
      type: looker_line
      fields: [statement_history_snapshot.snapshot_hour, statement_history_snapshot.average_latency]
      sorts: [statement_history_snapshot.snapshot_hour asc]
      filters:
        statement_history_snapshot.engine_type: "PostgreSQL"
      listen:
        pop_date_filter: statement_history_snapshot.snapshot_date
        database_name: statement_history_snapshot.database_name
      x_axis_gridlines: false
      y_axis_gridlines: true
      show_view_names: false
      show_y_axis_labels: true
      show_y_axis_ticks: true
      show_x_axis_label: true
      show_x_axis_ticks: true
      legend_position: center
      point_style: circle
      interpolation: monotone
      note_state: collapsed
      note_display: hover
      note_text: "Hourly average statement call latency for PostgreSQL workloads."
      tab_name: postgres_historical_trends_tab
      row: 6
      col: 12
      width: 12
      height: 8

    # --- ROW 3: BOTTLENECKS & DISK SPILLS (14 COLS + 10 COLS = 24 COLS) ---
    - name: postgres_hist_top_latency_bottlenecks
      title: "Top Latency Bottleneck Statements"
      subtitle: "Statements with highest cumulative execution time"
      model: postgres_observability
      explore: statement_history_snapshot
      type: looker_grid
      fields: [statement_history_snapshot.query_text, statement_history_snapshot.database_name, statement_history_snapshot.total_executions, statement_history_snapshot.average_latency, statement_history_snapshot.total_latency]
      sorts: [statement_history_snapshot.total_latency desc]
      filters:
        statement_history_snapshot.query_text: "-NULL"
        statement_history_snapshot.engine_type: "PostgreSQL"
      listen:
        pop_date_filter: statement_history_snapshot.snapshot_date
        query_search: statement_history_snapshot.query_text
        database_name: statement_history_snapshot.database_name
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Ranks top PostgreSQL statements by total cumulative latency impact."
      tab_name: postgres_historical_trends_tab
      row: 14
      col: 0
      width: 14
      height: 8

    - name: postgres_hist_disk_spill_trends
      title: "Temporary Blocks Written to Disk Trends"
      subtitle: "Historical temporary block writes and rows examined"
      model: postgres_observability
      explore: statement_history_snapshot
      type: looker_grid
      fields: [statement_history_snapshot.query_text, statement_history_snapshot.total_executions, statement_history_snapshot.delta_rows_examined, statement_history_snapshot.delta_rows_sent, statement_history_snapshot.delta_tmp_disk_tables]
      sorts: [statement_history_snapshot.delta_tmp_disk_tables desc]
      filters:
        statement_history_snapshot.query_text: "-NULL"
        statement_history_snapshot.engine_type: "PostgreSQL"
      listen:
        pop_date_filter: statement_history_snapshot.snapshot_date
        query_search: statement_history_snapshot.query_text
        database_name: statement_history_snapshot.database_name
      limit: 10
      note_state: collapsed
      note_display: hover
      note_text: "Monitors statements generating on-disk temporary block writes and high rows examined."
      tab_name: postgres_historical_trends_tab
      row: 14
      col: 14
      width: 10
      height: 8
