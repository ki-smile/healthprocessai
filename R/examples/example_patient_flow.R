# HealthProcessAI - Patient Flow Analysis Example (R Implementation)
# ====================================================================
#
# EXAMPLE: PATIENT FLOW ANALYSIS
# ===============================
# This example demonstrates patient flow analysis using bupaR's native approach,
# showcasing the power of R's process mining ecosystem.
#
# Based on bupaR's patient flow examples, this shows:
# 1. Loading and exploring event logs
# 2. Calculating performance metrics
# 3. Discovering process variants
# 4. Visualizing patient journeys
#
# The sepsis patient flow represents real-life management from admission to discharge.
#
# Developed at SMAILE, Karolinska Institutet

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

#' Patient Flow Analyzer R6 Class
#' 
#' Analyzes patient flow through healthcare processes using bupaR.
#' 
#' @description
#' Focuses on:
#' - Patient journey mapping
#' - Performance metrics (throughput, waiting times)
#' - Resource utilization
#' - Process variant discovery
#' 
#' @import R6
#' @import bupaR
#' @export
PatientFlowAnalyzer <- R6::R6Class(
  classname = "PatientFlowAnalyzer",
  
  public = list(
    
    # Instance variables
    event_log_path = NULL,
    event_log = NULL,
    df = NULL,
    
    #' Initialize patient flow analyzer
    #' 
    #' @param event_log_path Path to event log CSV file
    initialize = function(event_log_path = NULL) {
      self$event_log_path <- event_log_path
      message("PatientFlowAnalyzer initialized")
    },
    
    #' Create sample sepsis patient flow data
    #' 
    #' @description
    #' Creates sample data similar to bupaR's sepsis dataset,
    #' representing real-life sepsis management from admission to discharge.
    #' 
    #' @return Data frame with sepsis patient events
    create_sample_sepsis_data = function() {
      message("Creating sample sepsis patient flow data (similar to bupaR dataset)...")
      
      # Define typical sepsis patient journey activities
      sepsis_activities <- tibble(
        activity = c(
          "ER Registration", "Triage", "Initial Assessment", "Blood Culture",
          "CBC Test", "Lactate Test", "Chest X-Ray", "IV Access",
          "Fluid Resuscitation", "Antibiotic Administration", "ICU Admission",
          "Vasopressor Start", "Continuous Monitoring", "Antibiotic Adjustment",
          "Clinical Improvement", "Transfer to Ward", "Ward Care",
          "Discharge Planning", "Discharge"
        ),
        dept = c(
          "Emergency", "Emergency", "Emergency", "Laboratory",
          "Laboratory", "Laboratory", "Radiology", "Emergency",
          "Emergency", "Emergency", "ICU",
          "ICU", "ICU", "ICU",
          "ICU", "Ward", "Ward",
          "Ward", "Ward"
        ),
        typical_duration = c(
          0.25, 0.5, 1, 0.5,
          0.5, 0.25, 0.75, 0.25,
          1, 0.5, 0.5,
          0.5, 24, 0.5,
          2, 0.5, 48,
          2, 0.5
        )
      )
      
      # Define common patient pathways (variants)
      pathways <- list(
        # Severe sepsis pathway (ICU required)
        severe = c(
          "ER Registration", "Triage", "Initial Assessment", "Blood Culture",
          "CBC Test", "Lactate Test", "IV Access", "Fluid Resuscitation",
          "Antibiotic Administration", "Chest X-Ray", "ICU Admission",
          "Vasopressor Start", "Continuous Monitoring", "Antibiotic Adjustment",
          "Clinical Improvement", "Transfer to Ward", "Ward Care",
          "Discharge Planning", "Discharge"
        ),
        # Moderate sepsis pathway (no ICU)
        moderate = c(
          "ER Registration", "Triage", "Initial Assessment", "Blood Culture",
          "CBC Test", "IV Access", "Antibiotic Administration",
          "Fluid Resuscitation", "Transfer to Ward", "Ward Care",
          "Discharge Planning", "Discharge"
        ),
        # Quick response pathway
        quick = c(
          "ER Registration", "Triage", "Blood Culture", "IV Access",
          "Antibiotic Administration", "Transfer to Ward", "Ward Care", "Discharge"
        ),
        # Complex case with complications
        complex = c(
          "ER Registration", "Triage", "Initial Assessment", "Blood Culture",
          "CBC Test", "Lactate Test", "Chest X-Ray", "IV Access",
          "Antibiotic Administration", "Fluid Resuscitation", "ICU Admission",
          "Vasopressor Start", "Continuous Monitoring", "Lactate Test",
          "Antibiotic Adjustment", "Continuous Monitoring", "Clinical Improvement",
          "Transfer to Ward", "Ward Care", "Discharge Planning", "Discharge"
        )
      )
      
      # Generate patient cases
      set.seed(42)  # For reproducibility
      n_cases <- 100
      pathway_weights <- c(0.3, 0.4, 0.2, 0.1)  # Severe, Moderate, Quick, Complex
      
      events <- list()
      base_time <- as.POSIXct("2024-01-01 00:00:00")
      
      for (case_id in 1:n_cases) {
        # Select pathway based on weights
        pathway_type <- sample(names(pathways), 1, prob = pathway_weights)
        pathway <- pathways[[pathway_type]]
        
        # Starting time for this case
        case_start <- base_time + days(runif(1, 0, 30))
        current_time <- case_start
        
        # Generate events for this pathway
        for (i in seq_along(pathway)) {
          activity <- pathway[i]
          activity_info <- sepsis_activities %>% 
            filter(activity == !!activity) %>% 
            slice(1)
          
          # Add variation to typical duration
          duration <- activity_info$typical_duration * runif(1, 0.7, 1.3)
          
          # Create event
          event <- tibble(
            case = glue::glue("Patient_{sprintf('%03d', case_id)}"),
            activity = activity,
            timestamp = current_time,
            complete_timestamp = current_time + hours(duration),
            resource = activity_info$dept,
            lifecycle = "complete",
            SepsisLabel = ifelse(grepl("ICU", activity), 1, 0),
            variant = pathway_type,
            variant_id = match(pathway_type, names(pathways))
          )
          
          events <- append(events, list(event))
          
          # Move to next activity with some waiting time
          waiting_time <- rexp(1, rate = 2)  # Random waiting between activities
          current_time <- event$complete_timestamp + hours(waiting_time)
        }
      }
      
      df <- bind_rows(events)
      message(glue::glue("Created {nrow(df)} events for {n_distinct(df$case)} patients"))
      
      return(df)
    },
    
    #' Load event log from DataFrame or file
    #' 
    #' @param df Data frame with event log data (if NULL, loads from file or creates sample)
    load_event_log = function(df = NULL) {
      if (!is.null(df)) {
        self$df <- df
      } else if (!is.null(self$event_log_path)) {
        self$df <- read_csv(self$event_log_path, show_col_types = FALSE)
        self$df$timestamp <- as.POSIXct(self$df$timestamp)
        if ("complete_timestamp" %in% names(self$df)) {
          self$df$complete_timestamp <- as.POSIXct(self$df$complete_timestamp)
        }
      } else {
        # Create sample data
        self$df <- self$create_sample_sepsis_data()
      }
      
      # Convert to bupaR event log
      self$event_log <- self$df %>%
        eventlog(
          case_id = "case",
          activity_id = "activity",
          activity_instance_id = "activity",
          timestamp = "timestamp",
          resource_id = "resource",
          lifecycle_id = "lifecycle"
        )
      
      message(glue::glue("Event log loaded: {n_cases(self$event_log)} cases"))
    },
    
    #' Describe the structure of the event log
    #' 
    #' @return List with log statistics
    describe_log_structure = function() {
      cat("\n", paste(rep("=", 60), collapse = ""), "\n")
      cat("EVENT LOG STRUCTURE\n")
      cat(paste(rep("=", 60), collapse = ""), "\n\n")
      
      structure <- list(
        n_cases = n_cases(self$event_log),
        n_events = n_events(self$event_log),
        n_activities = n_activities(self$event_log),
        n_resources = n_resources(self$event_log),
        activities = activity_labels(self$event_log),
        resources = resource_labels(self$event_log),
        time_range = list(
          start = min(self$df$timestamp),
          end = max(self$df$timestamp)
        )
      )
      
      # Print summary
      cat(glue::glue("Cases (patients): {structure$n_cases}\n"))
      cat(glue::glue("Events: {structure$n_events}\n"))
      cat(glue::glue("Activities: {structure$n_activities}\n"))
      cat(glue::glue("Resources (departments): {structure$n_resources}\n"))
      cat(glue::glue("Time range: {structure$time_range$start} to {structure$time_range$end}\n"))
      
      return(structure)
    },
    
    #' Calculate performance metrics
    #' 
    #' @description
    #' Calculates throughput time, waiting time, and other performance metrics
    #' using bupaR's native functions.
    #' 
    #' @return Data frame with performance metrics
    calculate_performance_metrics = function() {
      cat("\n", paste(rep("=", 60), collapse = ""), "\n")
      cat("PERFORMANCE METRICS\n")
      cat(paste(rep("=", 60), collapse = ""), "\n\n")
      
      # Calculate throughput time using bupaR
      throughput <- self$event_log %>%
        throughput_time(level = "case", units = "hours")
      
      # Calculate processing time
      processing <- self$event_log %>%
        processing_time(level = "case", units = "hours")
      
      # Calculate idle time
      idle <- self$event_log %>%
        idle_time(level = "case", units = "hours")
      
      # Combine metrics
      metrics <- throughput %>%
        left_join(processing, by = "case") %>%
        left_join(idle, by = "case") %>%
        rename(
          throughput_hours = throughput_time,
          processing_hours = processing_time,
          idle_hours = idle_time
        )
      
      # Add activity counts
      activity_counts <- self$event_log %>%
        group_by(case) %>%
        summarise(
          n_activities = n(),
          n_unique_activities = n_distinct(activity)
        )
      
      metrics <- metrics %>%
        left_join(activity_counts, by = "case")
      
      # Calculate time to antibiotic
      antibiotic_times <- self$df %>%
        filter(grepl("Antibiotic", activity)) %>%
        group_by(case) %>%
        summarise(first_antibiotic = min(timestamp))
      
      case_starts <- self$df %>%
        group_by(case) %>%
        summarise(start_time = min(timestamp))
      
      time_to_antibiotic <- antibiotic_times %>%
        left_join(case_starts, by = "case") %>%
        mutate(time_to_antibiotic_hours = as.numeric(
          difftime(first_antibiotic, start_time, units = "hours")
        )) %>%
        select(case, time_to_antibiotic_hours)
      
      metrics <- metrics %>%
        left_join(time_to_antibiotic, by = "case")
      
      # Add ICU admission flag
      icu_cases <- self$df %>%
        filter(grepl("ICU", activity)) %>%
        distinct(case) %>%
        mutate(icu_admission = TRUE)
      
      metrics <- metrics %>%
        left_join(icu_cases, by = "case") %>%
        mutate(icu_admission = replace_na(icu_admission, FALSE))
      
      # Print summary statistics
      cat("\nThroughput Time Statistics:\n")
      cat(glue::glue("  Mean: {round(mean(metrics$throughput_hours), 2)} hours\n"))
      cat(glue::glue("  Median: {round(median(metrics$throughput_hours), 2)} hours\n"))
      cat(glue::glue("  Min: {round(min(metrics$throughput_hours), 2)} hours\n"))
      cat(glue::glue("  Max: {round(max(metrics$throughput_hours), 2)} hours\n"))
      
      if (any(!is.na(metrics$time_to_antibiotic_hours))) {
        cat("\nTime to First Antibiotic:\n")
        cat(glue::glue("  Mean: {round(mean(metrics$time_to_antibiotic_hours, na.rm = TRUE), 2)} hours\n"))
        cat(glue::glue("  Median: {round(median(metrics$time_to_antibiotic_hours, na.rm = TRUE), 2)} hours\n"))
      }
      
      cat(glue::glue("\nICU Admission Rate: {round(mean(metrics$icu_admission) * 100, 1)}%\n"))
      
      return(metrics)
    },
    
    #' Discover process variants (patient pathways)
    #' 
    #' @param top_k Number of top variants to return
    #' @return Data frame with variant information
    discover_process_variants = function(top_k = 5) {
      cat("\n", paste(rep("=", 60), collapse = ""), "\n")
      cat("PROCESS VARIANTS (PATIENT PATHWAYS)\n")
      cat(paste(rep("=", 60), collapse = ""), "\n\n")
      
      # Get traces using bupaR
      traces <- self$event_log %>%
        trace_explorer(coverage = 1.0, type = "frequent")
      
      # Get variant statistics
      variant_stats <- self$event_log %>%
        trace_coverage(level = "trace") %>%
        arrange(desc(absolute)) %>%
        head(top_k)
      
      # Print top variants
      cat(glue::glue("\nTop {min(top_k, nrow(variant_stats))} Patient Pathways:\n"))
      
      for (i in 1:min(top_k, nrow(variant_stats))) {
        row <- variant_stats[i,]
        activities <- strsplit(row$trace, ",")[[1]]
        cat(glue::glue("\nVariant {i}: {row$absolute} cases ({round(row$relative * 100, 1)}%)\n"))
        cat(glue::glue("  Activities: {length(activities)}\n"))
        cat(glue::glue("  Path: {paste(head(activities, 5), collapse = ' → ')}...\n"))
      }
      
      return(variant_stats)
    },
    
    #' Analyze resource utilization
    #' 
    #' @return Data frame with resource utilization metrics
    analyze_resource_utilization = function() {
      cat("\n", paste(rep("=", 60), collapse = ""), "\n")
      cat("RESOURCE UTILIZATION\n")
      cat(paste(rep("=", 60), collapse = ""), "\n\n")
      
      # Use bupaR's resource frequency function
      resource_freq <- self$event_log %>%
        resource_frequency(level = "resource")
      
      # Add percentage
      resource_freq <- resource_freq %>%
        mutate(percentage = round(absolute / sum(absolute) * 100, 1))
      
      # Get additional resource metrics
      resource_metrics <- self$df %>%
        group_by(resource) %>%
        summarise(
          n_activities = n_distinct(activity),
          first_event = min(timestamp),
          last_event = max(timestamp)
        )
      
      # Combine
      resource_utilization <- resource_freq %>%
        left_join(resource_metrics, by = "resource") %>%
        arrange(desc(absolute))
      
      cat("\nDepartment Utilization:\n")
      for (i in 1:nrow(resource_utilization)) {
        row <- resource_utilization[i,]
        cat(glue::glue("  {row$resource}: {row$absolute} events ({row$percentage}%)\n"))
      }
      
      return(resource_utilization)
    },
    
    #' Visualize patient flow
    #' 
    #' @param type Type of process map ("frequency" or "performance")
    #' @param save_path Path to save visualization
    visualize_patient_flow = function(type = "frequency", save_path = NULL) {
      # Create process map using processmapR
      if (type == "frequency") {
        map <- self$event_log %>%
          process_map(type = frequency("absolute"))
      } else {
        map <- self$event_log %>%
          process_map(type = performance(mean, "hours"))
      }
      
      if (!is.null(save_path)) {
        # Note: Saving requires additional setup
        message(glue::glue("Process map would be saved to: {save_path}"))
        message("(Actual saving requires DiagrammeRsvg and rsvg packages)")
      }
      
      return(map)
    },
    
    #' Augment log with calculated metrics
    #' 
    #' @return Augmented data frame
    augment_log_with_metrics = function() {
      augmented_df <- self$df
      
      # Add throughput time for each case
      case_throughput <- augmented_df %>%
        group_by(case) %>%
        summarise(
          min_time = min(timestamp),
          max_time = max(timestamp),
          throughput_hours = as.numeric(difftime(max_time, min_time, units = "hours"))
        )
      
      # Merge back
      augmented_df <- augmented_df %>%
        left_join(case_throughput %>% select(case, throughput_hours), by = "case")
      
      # Add time since case start
      augmented_df <- augmented_df %>%
        group_by(case) %>%
        mutate(
          time_since_start = as.numeric(difftime(timestamp, min(timestamp), units = "hours"))
        )
      
      # Add activity position in case
      augmented_df <- augmented_df %>%
        group_by(case) %>%
        mutate(activity_position = row_number())
      
      message("\nLog augmented with:")
      message("  - throughput_hours: Total case duration")
      message("  - time_since_start: Hours since case began")
      message("  - activity_position: Position of activity in case")
      
      return(augmented_df)
    }
  )
)

# Main function to demonstrate patient flow analysis
run_patient_flow_analysis <- function() {
  cat("\n", paste(rep("=", 70), collapse = ""), "\n")
  cat("PATIENT FLOW ANALYSIS - R Implementation with bupaR\n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  cat("This example demonstrates patient flow analysis for sepsis cases,\n")
  cat("using the native bupaR package capabilities in R.\n")
  
  # Initialize analyzer
  analyzer <- PatientFlowAnalyzer$new()
  
  # Load event log (creates sample data similar to bupaR's sepsis dataset)
  analyzer$load_event_log()
  
  # 1. Describe log structure
  structure <- analyzer$describe_log_structure()
  
  # 2. Calculate performance metrics
  performance <- analyzer$calculate_performance_metrics()
  
  # 3. Discover process variants
  variants <- analyzer$discover_process_variants(top_k = 5)
  
  # 4. Analyze resource utilization
  resources <- analyzer$analyze_resource_utilization()
  
  # 5. Augment log with calculated metrics
  augmented_log <- analyzer$augment_log_with_metrics()
  
  # 6. Visualize patient flow (optional)
  # process_map <- analyzer$visualize_patient_flow(type = "frequency")
  
  cat("\n", paste(rep("=", 70), collapse = ""), "\n")
  cat("ANALYSIS COMPLETE\n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  cat("This analysis provides insights using bupaR's native capabilities:\n")
  cat("- Patient pathway discovery\n")
  cat("- Performance metrics calculation\n")
  cat("- Resource utilization analysis\n")
  cat("- Process variant identification\n")
  cat("\nFor Python users, an equivalent implementation using PM4PY\n")
  cat("is available in the Python examples.\n")
  
  return(list(analyzer = analyzer, augmented_log = augmented_log))
}

# Example usage
if (interactive()) {
  result <- run_patient_flow_analysis()
  
  # Additional analysis examples
  cat("\n", paste(rep("=", 70), collapse = ""), "\n")
  cat("ADDITIONAL ANALYSIS EXAMPLES\n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  
  augmented_log <- result$augmented_log
  
  # Example: Count cases per activity (using dplyr)
  cat("Cases per Activity:\n")
  activity_counts <- augmented_log %>%
    group_by(activity) %>%
    summarise(n_cases = n_distinct(case)) %>%
    arrange(desc(n_cases)) %>%
    head(5)
  
  for (i in 1:nrow(activity_counts)) {
    row <- activity_counts[i,]
    cat(glue::glue("  {row$activity}: {row$n_cases} cases\n"))
  }
  
  # Example: Average time per activity
  cat("\nAverage Time Since Start per Activity:\n")
  avg_times <- augmented_log %>%
    group_by(activity) %>%
    summarise(avg_time = mean(time_since_start)) %>%
    arrange(avg_time) %>%
    head(5)
  
  for (i in 1:nrow(avg_times)) {
    row <- avg_times[i,]
    cat(glue::glue("  {row$activity}: {round(row$avg_time, 2)} hours\n"))
  }
  
  # Example: Using bupaR's built-in analysis functions
  cat("\n", paste(rep("=", 70), collapse = ""), "\n")
  cat("BUPAR-SPECIFIC ANALYSIS\n")
  cat(paste(rep("=", 70), collapse = ""), "\n\n")
  
  event_log <- result$analyzer$event_log
  
  # Activity presence
  cat("Activity Presence (% of cases containing each activity):\n")
  presence <- event_log %>%
    activity_presence() %>%
    arrange(desc(relative)) %>%
    head(5)
  
  for (i in 1:nrow(presence)) {
    row <- presence[i,]
    cat(glue::glue("  {row$activity}: {round(row$relative * 100, 1)}%\n"))
  }
  
  # Start activities
  cat("\nStart Activities:\n")
  starts <- event_log %>%
    start_activities(level = "activity") %>%
    arrange(desc(absolute)) %>%
    head(3)
  
  for (i in 1:nrow(starts)) {
    row <- starts[i,]
    cat(glue::glue("  {row$activity}: {row$absolute} cases\n"))
  }
  
  # End activities
  cat("\nEnd Activities:\n")
  ends <- event_log %>%
    end_activities(level = "activity") %>%
    arrange(desc(absolute)) %>%
    head(3)
  
  for (i in 1:nrow(ends)) {
    row <- ends[i,]
    cat(glue::glue("  {row$activity}: {row$absolute} cases\n"))
  }
}