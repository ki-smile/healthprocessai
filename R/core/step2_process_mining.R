# HealthProcessAI - R Step 2: Process Mining Analysis  
# ===================================================
#
# STEP 2: PROCESS MINING ANALYSIS
# ================================
# This module handles the core process mining analysis using bupaR library.
# It converts prepared data into process mining formats and discovers process models.
#
# Learning Goals:
# - Understand bupaR event log format requirements
# - Learn different process discovery algorithms in R  
# - Generate process maps and performance metrics
# - Export results for visualization
#
# Key Concepts:
# - Event logs in bupaR use specific column naming conventions
# - Process maps show activity sequences and frequencies
# - Trace variants represent different patient pathways
# - Performance analysis reveals timing bottlenecks
#
# Technology Mapping:
# - Python PM4PY -> R bupaR/edeaR/processmapR
# - Python DFG -> R process_map()
# - Python variants -> R trace_explorer()
# - Python metrics -> R process statistics
#
# Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments),
# Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(bupaR)
  library(edeaR)
  library(processmapR)
  library(processmonitR)
  library(lubridate)
  library(glue)
  library(R6)
})

# ProcessMiner R6 Class
#' Process Mining Analysis for Healthcare Data
#' 
#' This class provides methods to:
#' 1. Convert tibbles to bupaR event logs
#' 2. Discover process models using various algorithms
#' 3. Calculate process metrics and statistics  
#' 4. Export results for visualization and reporting
#' 
#' @import R6
#' @import bupaR
#' @import edeaR
#' @import processmapR
#' @export
ProcessMiner <- R6::R6Class(
  classname = "ProcessMiner",
  
  # Public methods and fields
  public = list(
    
    # bupaR standard column mappings
    CASE_ID_KEY = "case_id",
    ACTIVITY_KEY = "activity_id", 
    TIMESTAMP_KEY = "timestamp",
    RESOURCE_KEY = "resource_id",
    LIFECYCLE_KEY = "lifecycle_id",
    
    # Instance variables
    event_log = NULL,
    process_map_freq = NULL,
    process_map_perf = NULL,
    process_matrix = NULL,
    variants = NULL,
    
    #' Initialize the ProcessMiner
    #' @return New ProcessMiner instance
    initialize = function() {
      message("✅ Initialized ProcessMiner with bupaR")
    },
    
    #' Convert a tibble to bupaR EventLog format
    #' 
    #' bupaR requires specific column names:
    #' - case_id for case ID
    #' - activity_id for activity
    #' - timestamp for timestamp
    #' - resource_id for resource (optional)
    #' - lifecycle_id for lifecycle (optional, defaults to "complete")
    #' 
    #' @param df tibble with columns: case, activity, timestamp
    #' @return bupaR eventlog object
    #' 
    #' @examples
    #' miner <- ProcessMiner$new()
    #' event_log <- miner$create_event_log(prepared_data)
    #' cat(glue::glue("Created event log with {n_cases(event_log)} cases"))
    create_event_log = function(df) {
      # Create a copy to avoid modifying original
      df_copy <- df
      
      # Ensure required columns exist
      required_cols <- c("case", "activity", "timestamp")
      missing_cols <- setdiff(required_cols, names(df_copy))
      if (length(missing_cols) > 0) {
        stop(glue::glue("Missing required columns: {paste(missing_cols, collapse = ', ')}"))
      }
      
      # Rename columns to bupaR format
      df_copy <- df_copy %>%
        dplyr::rename(
          !!self$CASE_ID_KEY := case,
          !!self$ACTIVITY_KEY := activity,
          !!self$TIMESTAMP_KEY := timestamp
        )
      
      # Add optional columns with proper names
      if ("resource" %in% names(df)) {
        df_copy <- df_copy %>%
          dplyr::rename(!!self$RESOURCE_KEY := resource)
      }
      
      # Add lifecycle if not present (bupaR requirement)
      if (!self$LIFECYCLE_KEY %in% names(df_copy)) {
        df_copy[[self$LIFECYCLE_KEY]] <- "complete"
      }
      
      # Ensure timestamp is POSIXct
      df_copy[[self$TIMESTAMP_KEY]] <- lubridate::as_datetime(df_copy[[self$TIMESTAMP_KEY]])
      
      # Create bupaR eventlog
      self$event_log <- df_copy %>%
        bupaR::eventlog(
          case_id = self$CASE_ID_KEY,
          activity_id = self$ACTIVITY_KEY,
          timestamp = self$TIMESTAMP_KEY,
          lifecycle_id = self$LIFECYCLE_KEY,
          resource_id = if(self$RESOURCE_KEY %in% names(df_copy)) self$RESOURCE_KEY else NULL
        )
      
      message(glue::glue("✅ Created event log with {bupaR::n_cases(self$event_log)} cases"))
      
      return(self$event_log)
    },
    
    #' Discover process map showing activity sequences and frequencies
    #' 
    #' Similar to Python's DFG (Directly-Follows Graph) but using bupaR's
    #' process map which shows activities and their transitions
    #' 
    #' @param type Type of process map: "frequency", "performance", or "custom"  
    #' @param render Whether to render the map (TRUE) or return data (FALSE)
    #' @return Process map object or data
    #' 
    #' @examples
    #' process_map <- miner$discover_process_map()
    #' perf_map <- miner$discover_process_map(type = "performance")
    discover_process_map = function(type = "frequency", render = FALSE) {
      if (is.null(self$event_log)) {
        stop("❌ No event log created. Call create_event_log() first.")
      }
      
      if (type == "frequency") {
        # Frequency-based process map (equivalent to DFG)
        self$process_map_freq <- self$event_log %>%
          processmapR::process_map(
            type = processmapR::frequency("absolute"),
            render = render
          )
        
        message(glue::glue("📊 Discovered frequency process map"))
        return(self$process_map_freq)
        
      } else if (type == "performance") {
        # Performance-based process map (shows timing)
        self$process_map_perf <- self$event_log %>%
          processmapR::process_map(
            type = processmapR::performance(mean, "hours"),
            render = render
          )
        
        message(glue::glue("⏱️  Discovered performance process map (hours)"))
        return(self$process_map_perf)
        
      } else {
        stop(glue::glue("❌ Unknown map type: {type}. Use 'frequency' or 'performance'"))
      }
    },
    
    #' Get start and end activities from the event log
    #' 
    #' @return list with start_activities and end_activities
    get_start_end_activities = function() {
      if (is.null(self$event_log)) {
        stop("❌ No event log created. Call create_event_log() first.")
      }
      
      # Start activities
      start_activities <- self$event_log %>%
        edeaR::start_activities("activity") %>%
        dplyr::arrange(desc(absolute)) %>%
        dplyr::mutate(percentage = round(relative * 100, 2))
      
      # End activities  
      end_activities <- self$event_log %>%
        edeaR::end_activities("activity") %>%
        dplyr::arrange(desc(absolute)) %>%
        dplyr::mutate(percentage = round(relative * 100, 2))
      
      message(glue::glue("🚀 Found {nrow(start_activities)} start activities"))
      message(glue::glue("🏁 Found {nrow(end_activities)} end activities"))
      
      return(list(
        start_activities = start_activities,
        end_activities = end_activities
      ))
    },
    
    #' Create a process matrix showing transitions between activities
    #' 
    #' Similar to Python's process matrix but using edeaR functions
    #' 
    #' @return tibble representing the process transition matrix
    create_process_matrix = function() {
      if (is.null(self$event_log)) {
        stop("❌ No event log created. Call create_event_log() first.")
      }
      
      # Get precedence matrix (activity transitions)
      self$process_matrix <- self$event_log %>%
        edeaR::precedence_matrix("activity", type = "absolute")
      
      message(glue::glue("📊 Created process matrix of size {nrow(self$process_matrix)} × {ncol(self$process_matrix)}"))
      
      return(self$process_matrix)
    },
    
    #' Discover the most common process variants (traces)
    #' 
    #' A variant is a unique sequence of activities that cases follow
    #' 
    #' @param top_k Number of top variants to return
    #' @return tibble with variant information
    #' 
    #' @examples
    #' variants <- miner$discover_variants(top_k = 5)
    #' print(variants)
    discover_variants = function(top_k = 10) {
      if (is.null(self$event_log)) {
        stop("❌ No event log created. Call create_event_log() first.")
      }
      
      # Get trace variants
      self$variants <- self$event_log %>%
        edeaR::traces("case", output_traces = TRUE) %>%
        dplyr::arrange(desc(absolute)) %>%
        dplyr::head(top_k) %>%
        dplyr::mutate(
          percentage = round(relative * 100, 2),
          activities = stringr::str_count(trace, ",") + 1
        ) %>%
        dplyr::select(trace, cases = absolute, percentage, activities)
      
      message(glue::glue("🔍 Found {nrow(self$variants)} top variants"))
      message(glue::glue("📈 Top variant covers {self$variants$percentage[1]}% of cases"))
      
      return(self$variants)
    },
    
    #' Calculate comprehensive process metrics and KPIs
    #' 
    #' @return list containing various process metrics
    calculate_process_metrics = function() {
      if (is.null(self$event_log)) {
        stop("❌ No event log created. Call create_event_log() first.")
      }
      
      metrics <- list()
      
      # Basic counts
      metrics$num_cases <- bupaR::n_cases(self$event_log)
      metrics$num_events <- bupaR::n_events(self$event_log) 
      metrics$num_activities <- bupaR::n_activities(self$event_log)
      metrics$num_resources <- bupaR::n_resources(self$event_log)
      
      # Case duration metrics
      duration_stats <- self$event_log %>%
        edeaR::throughput_time("case", units = "hours") %>%
        dplyr::summarise(
          avg_duration_hours = round(mean(throughput_time, na.rm = TRUE), 2),
          median_duration_hours = round(median(throughput_time, na.rm = TRUE), 2), 
          min_duration_hours = round(min(throughput_time, na.rm = TRUE), 2),
          max_duration_hours = round(max(throughput_time, na.rm = TRUE), 2),
          std_duration_hours = round(sd(throughput_time, na.rm = TRUE), 2)
        )
      
      metrics <- c(metrics, as.list(duration_stats))
      
      # Activity frequency
      activity_freq <- self$event_log %>%
        edeaR::activities("activity") %>%
        dplyr::arrange(desc(absolute))
      
      metrics$most_frequent_activity <- activity_freq$activity_id[1]
      metrics$most_frequent_activity_count <- activity_freq$absolute[1]
      
      # Trace complexity
      trace_length <- self$event_log %>%
        edeaR::trace_length("case") %>%
        dplyr::summarise(
          avg_trace_length = round(mean(trace_length, na.rm = TRUE), 2),
          median_trace_length = round(median(trace_length, na.rm = TRUE), 2),
          max_trace_length = max(trace_length, na.rm = TRUE),
          min_trace_length = min(trace_length, na.rm = TRUE)
        )
      
      metrics <- c(metrics, as.list(trace_length))
      
      # Resource workload (if available)
      if (bupaR::n_resources(self$event_log) > 1) {
        resource_freq <- self$event_log %>%
          edeaR::resource_frequency("resource") %>%
          dplyr::arrange(desc(absolute))
        
        metrics$most_active_resource <- resource_freq$employee[1]
        metrics$most_active_resource_events <- resource_freq$absolute[1]
      }
      
      message(glue::glue("📊 Calculated {length(metrics)} process metrics"))
      
      return(metrics)
    },
    
    #' Compare different process discovery approaches
    #' 
    #' @return list containing comparison results
    compare_discovery_methods = function() {
      if (is.null(self$event_log)) {
        stop("❌ No event log created. Call create_event_log() first.")
      }
      
      results <- list()
      
      # 1. Frequency-based process map
      tryCatch({
        freq_map <- self$discover_process_map(type = "frequency", render = FALSE)
        results$frequency_map <- list(
          type = "frequency_process_map",
          status = "success"
        )
      }, error = function(e) {
        results$frequency_map <- list(type = "frequency_process_map", error = e$message)
      })
      
      # 2. Performance-based process map
      tryCatch({
        perf_map <- self$discover_process_map(type = "performance", render = FALSE)
        results$performance_map <- list(
          type = "performance_process_map", 
          status = "success"
        )
      }, error = function(e) {
        results$performance_map <- list(type = "performance_process_map", error = e$message)
      })
      
      # 3. Trace variant analysis
      tryCatch({
        variants <- self$discover_variants(top_k = 5)
        results$variants <- list(
          type = "trace_variants",
          num_variants = nrow(variants),
          top_variant_coverage = variants$percentage[1],
          status = "success"
        )
      }, error = function(e) {
        results$variants <- list(type = "trace_variants", error = e$message)
      })
      
      # 4. Process matrix
      tryCatch({
        matrix <- self$create_process_matrix()
        results$process_matrix <- list(
          type = "precedence_matrix",
          dimensions = paste(dim(matrix), collapse = " x "),
          status = "success"
        )
      }, error = function(e) {
        results$process_matrix <- list(type = "precedence_matrix", error = e$message)
      })
      
      successful_methods <- sum(sapply(results, function(x) "status" %in% names(x) && x$status == "success"))
      message(glue::glue("🔄 Compared {successful_methods}/{length(results)} discovery methods successfully"))
      
      return(results)
    },
    
    #' Export process mining results for reporting
    #' 
    #' @param output_dir Directory to save results
    #' @return list of exported file paths
    export_results = function(output_dir = "process_mining_results") {
      if (is.null(self$event_log)) {
        stop("❌ No event log created. Call create_event_log() first.")
      }
      
      # Create output directory
      if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
      }
      
      exported_files <- list()
      
      # Export process maps if available
      if (!is.null(self$process_map_freq)) {
        freq_file <- file.path(output_dir, "frequency_process_map.png")
        # Note: In practice, you'd use ggsave() or similar for processmapR objects
        message(glue::glue("📁 Frequency map ready for export to {freq_file}"))
        exported_files$frequency_map <- freq_file
      }
      
      if (!is.null(self$process_map_perf)) {
        perf_file <- file.path(output_dir, "performance_process_map.png")
        message(glue::glue("📁 Performance map ready for export to {perf_file}"))
        exported_files$performance_map <- perf_file
      }
      
      # Export process matrix
      if (!is.null(self$process_matrix)) {
        matrix_file <- file.path(output_dir, "process_matrix.csv")
        readr::write_csv(self$process_matrix, matrix_file)
        message(glue::glue("📁 Process matrix exported to {matrix_file}"))
        exported_files$process_matrix <- matrix_file
      }
      
      # Export variants
      if (!is.null(self$variants)) {
        variants_file <- file.path(output_dir, "process_variants.csv")
        readr::write_csv(self$variants, variants_file)
        message(glue::glue("📁 Process variants exported to {variants_file}"))
        exported_files$variants <- variants_file
      }
      
      # Export metrics
      metrics <- self$calculate_process_metrics()
      metrics_file <- file.path(output_dir, "process_metrics.json")
      jsonlite::write_json(metrics, metrics_file, pretty = TRUE)
      message(glue::glue("📁 Process metrics exported to {metrics_file}"))
      exported_files$metrics <- metrics_file
      
      message(glue::glue("✅ Exported {length(exported_files)} result files to {output_dir}/"))
      
      return(exported_files)
    }
  )
)

# Convenience functions for quick analysis (functional interface)

#' Quick process map creation (functional interface)
#' 
#' @param event_log bupaR eventlog object
#' @param type Type of map: "frequency" or "performance"
#' @return Process map object
#' @export
create_process_map <- function(event_log, type = "frequency") {
  if (type == "frequency") {
    return(event_log %>% processmapR::process_map(type = processmapR::frequency("absolute")))
  } else if (type == "performance") {
    return(event_log %>% processmapR::process_map(type = processmapR::performance(mean, "hours")))
  } else {
    stop("Type must be 'frequency' or 'performance'")
  }
}

#' Quick process analysis (functional interface)
#' 
#' @param df tibble with event log data
#' @return list with basic process analysis results
#' @export
analyze_process <- function(df) {
  miner <- ProcessMiner$new()
  event_log <- miner$create_event_log(df)
  
  results <- list(
    event_log = event_log,
    process_map = miner$discover_process_map(type = "frequency", render = FALSE),
    variants = miner$discover_variants(top_k = 5),
    metrics = miner$calculate_process_metrics()
  )
  
  return(results)
}

# Print module information
cat("📊 HealthProcessAI R - Step 2: Process Mining\n")
cat("===========================================\n") 
cat("✅ ProcessMiner R6 class available\n")
cat("✅ create_process_map() function available\n")
cat("✅ analyze_process() function available\n")
cat("📚 Uses: bupaR, edeaR, processmapR\n\n")
cat("Example usage:\n")
cat('  miner <- ProcessMiner$new()\n')
cat("  event_log <- miner$create_event_log(prepared_data)\n")
cat("  process_map <- miner$discover_process_map()\n")
cat("  metrics <- miner$calculate_process_metrics()\n\n")