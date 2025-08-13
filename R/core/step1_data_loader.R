# HealthProcessAI - R Step 1: Data Loading and Preparation
# ========================================================
#
# STEP 1: DATA LOADING AND PREPARATION
# ====================================
# This module handles the first step of the process mining pipeline:
# loading event log data from CSV files and preparing it for analysis.
#
# Learning Goals:
# - Understand event log structure and requirements
# - Learn how to load and validate healthcare data using tidyverse
# - Convert raw data into bupaR-compatible format
#
# Key Concepts:
# - Event logs contain: case ID, activity, timestamp, resource
# - Each row represents one event in a patient's journey
# - Cases are individual patient episodes
#
# Technology Mapping:
# - Python pandas -> R tidyverse/dplyr
# - Python pathlib -> R fs/base R file functions
# - Python logging -> R message/warning/stop functions
#
# Developed at SMAILE (Stockholm Medical AI Lab for Enhancement),
# Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(glue)
  library(fs)
})

# EventLogLoader R6 Class
#' Event Log Loader for Healthcare Process Mining
#' 
#' This class is responsible for:
#' 1. Reading CSV files containing event logs
#' 2. Validating required columns exist
#' 3. Converting data types appropriately
#' 4. Providing basic statistics about the loaded data
#' 
#' @import R6
#' @import tidyverse
#' @import lubridate
#' @export
EventLogLoader <- R6::R6Class(
  classname = "EventLogLoader",
  
  # Public methods and fields
  public = list(
    
    # Required columns for process mining analysis
    REQUIRED_COLUMNS = c("case", "activity", "timestamp"),
    
    # Optional but useful columns  
    OPTIONAL_COLUMNS = c("resource", "lifecycle", "SepsisLabel"),
    
    # Instance variables
    filepath = NULL,
    raw_data = NULL,
    prepared_data = NULL,
    
    #' Initialize the event log loader
    #' 
    #' @param filepath Path to the CSV file containing event log data
    #' @return New EventLogLoader instance
    #' 
    #' @examples
    #' loader <- EventLogLoader$new("data/sepsis_events.csv")
    initialize = function(filepath) {
      # Validate file exists
      if (!fs::file_exists(filepath)) {
        stop(glue::glue("Event log file not found: {filepath}"))
      }
      
      self$filepath <- filepath
      message(glue::glue("✅ Initialized EventLogLoader for: {fs::path_file(filepath)}"))
    },
    
    #' Load raw data from CSV file
    #' 
    #' @return tibble containing the raw event log data
    #' 
    #' @examples  
    #' loader <- EventLogLoader$new("sepsis_events.csv")
    #' data <- loader$load_data()
    #' cat(glue::glue("Loaded {nrow(data)} events"))
    load_data = function() {
      tryCatch({
        # Load CSV with readr (tidyverse)
        self$raw_data <- readr::read_csv(self$filepath, show_col_types = FALSE)
        
        # Log basic information for learning
        message(glue::glue("✅ Successfully loaded {nrow(self$raw_data)} events"))
        message(glue::glue("📊 Columns found: {paste(names(self$raw_data), collapse = ', ')}"))
        
        # Validate required columns
        private$validate_columns()
        
        return(self$raw_data)
        
      }, error = function(e) {
        stop(glue::glue("❌ Error loading data: {e$message}"))
      })
    },
    
    #' Prepare data for process mining analysis
    #' 
    #' This method:
    #' 1. Converts timestamp to datetime format
    #' 2. Removes any null values in required columns
    #' 3. Sorts events by case and timestamp
    #' 4. Adds derived features if needed
    #' 
    #' @return tibble ready for process mining analysis
    prepare_data = function() {
      if (is.null(self$raw_data)) {
        stop("❌ No data loaded. Call load_data() first.")
      }
      
      # Create a copy to avoid modifying original data
      self$prepared_data <- self$raw_data
      
      # Step 1: Convert timestamp to datetime
      message("🔄 Converting timestamps to datetime format...")
      self$prepared_data <- self$prepared_data %>%
        dplyr::mutate(
          timestamp = lubridate::ymd_hms(timestamp, quiet = TRUE)
        )
      
      # Check for parsing failures
      na_timestamps <- sum(is.na(self$prepared_data$timestamp))
      if (na_timestamps > 0) {
        warning(glue::glue("⚠️  {na_timestamps} timestamps could not be parsed"))
      }
      
      # Step 2: Remove rows with null values in required columns
      initial_count <- nrow(self$prepared_data)
      self$prepared_data <- self$prepared_data %>%
        tidyr::drop_na(all_of(self$REQUIRED_COLUMNS))
      
      removed_count <- initial_count - nrow(self$prepared_data)
      if (removed_count > 0) {
        warning(glue::glue("⚠️  Removed {removed_count} events with missing data"))
      }
      
      # Step 3: Sort by case and timestamp for chronological order
      self$prepared_data <- self$prepared_data %>%
        dplyr::arrange(case, timestamp)
      
      # Step 4: Add derived features
      private$add_derived_features()
      
      message(glue::glue("✅ Data preparation complete: {nrow(self$prepared_data)} events ready"))
      
      return(self$prepared_data)
    },
    
    #' Get basic statistics about the loaded event log
    #' 
    #' @return list containing various statistics
    #' 
    #' @examples
    #' stats <- loader$get_statistics()
    #' cat(glue::glue("Total cases: {stats$num_cases}"))
    #' cat(glue::glue("Total events: {stats$num_events}"))
    get_statistics = function() {
      if (is.null(self$prepared_data)) {
        stop("❌ No data prepared. Call prepare_data() first.")
      }
      
      stats <- list(
        num_events = nrow(self$prepared_data),
        num_cases = dplyr::n_distinct(self$prepared_data$case),
        num_activities = dplyr::n_distinct(self$prepared_data$activity),
        activities = unique(self$prepared_data$activity),
        date_range = list(
          start = min(self$prepared_data$timestamp, na.rm = TRUE),
          end = max(self$prepared_data$timestamp, na.rm = TRUE)
        ),
        avg_events_per_case = nrow(self$prepared_data) / dplyr::n_distinct(self$prepared_data$case)
      )
      
      # Add resource statistics if available
      if ("resource" %in% names(self$prepared_data)) {
        stats$num_resources <- dplyr::n_distinct(self$prepared_data$resource)
      }
      
      # Add sepsis statistics if available  
      if ("SepsisLabel" %in% names(self$prepared_data)) {
        sepsis_cases <- self$prepared_data %>%
          dplyr::group_by(case) %>%
          dplyr::summarise(sepsis_label = max(SepsisLabel, na.rm = TRUE), .groups = "drop")
        
        stats$sepsis_rate <- mean(sepsis_cases$sepsis_label == 1, na.rm = TRUE)
        stats$num_sepsis_cases <- sum(sepsis_cases$sepsis_label == 1, na.rm = TRUE)
      }
      
      return(stats)
    },
    
    #' Filter cases based on sepsis outcome
    #' 
    #' @param sepsis_only If TRUE, keep only sepsis cases; if FALSE, keep non-sepsis cases
    #' @return Filtered tibble
    #' 
    #' @examples
    #' sepsis_events <- loader$filter_by_outcome(sepsis_only = TRUE)
    #' cat(glue::glue("Sepsis cases: {n_distinct(sepsis_events$case)}"))
    filter_by_outcome = function(sepsis_only = TRUE) {
      if (!"SepsisLabel" %in% names(self$prepared_data)) {
        warning("⚠️  SepsisLabel column not found. Returning all data.")
        return(self$prepared_data)
      }
      
      # Get cases with desired outcome
      case_outcomes <- self$prepared_data %>%
        dplyr::group_by(case) %>%
        dplyr::summarise(sepsis_label = max(SepsisLabel, na.rm = TRUE), .groups = "drop")
      
      if (sepsis_only) {
        target_cases <- case_outcomes %>%
          dplyr::filter(sepsis_label == 1) %>%
          dplyr::pull(case)
        message(glue::glue("🔍 Filtering for sepsis cases: {length(target_cases)} cases"))
      } else {
        target_cases <- case_outcomes %>%
          dplyr::filter(sepsis_label == 0) %>%
          dplyr::pull(case)
        message(glue::glue("🔍 Filtering for non-sepsis cases: {length(target_cases)} cases"))
      }
      
      # Filter events for target cases
      filtered_data <- self$prepared_data %>%
        dplyr::filter(case %in% target_cases)
      
      return(filtered_data)
    },
    
    #' Sample a subset of cases for testing and learning
    #' 
    #' @param n Number of cases to sample
    #' @param seed Random seed for reproducibility
    #' @return tibble with sampled cases
    #' 
    #' @examples
    #' sample_data <- loader$sample_cases(n = 50)
    #' cat(glue::glue("Sampled {n_distinct(sample_data$case)} cases"))
    sample_cases = function(n = 100, seed = 42) {
      if (is.null(self$prepared_data)) {
        stop("❌ No data prepared. Call prepare_data() first.")
      }
      
      set.seed(seed)
      
      # Get unique case IDs
      all_cases <- unique(self$prepared_data$case)
      
      # Sample n cases (or all if n is larger)
      n_sample <- min(n, length(all_cases))
      sampled_cases <- sample(all_cases, size = n_sample, replace = FALSE)
      
      # Filter events for sampled cases
      sampled_data <- self$prepared_data %>%
        dplyr::filter(case %in% sampled_cases)
      
      message(glue::glue("🎲 Sampled {n_sample} cases with {nrow(sampled_data)} events"))
      
      return(sampled_data)
    }
  ),
  
  # Private methods
  private = list(
    
    #' Validate that required columns exist in the dataset
    #' @description Internal method to check column requirements
    validate_columns = function() {
      missing_columns <- setdiff(self$REQUIRED_COLUMNS, names(self$raw_data))
      
      if (length(missing_columns) > 0) {
        stop(glue::glue(
          "❌ Missing required columns: {paste(missing_columns, collapse = ', ')}. ",
          "Required columns are: {paste(self$REQUIRED_COLUMNS, collapse = ', ')}"
        ))
      }
      
      # Log optional columns that were found
      found_optional <- intersect(self$OPTIONAL_COLUMNS, names(self$raw_data))
      if (length(found_optional) > 0) {
        message(glue::glue("📋 Optional columns found: {paste(found_optional, collapse = ', ')}"))
      }
    },
    
    #' Add useful derived features to the dataset
    #' @description Internal method to create time-based and case-based features
    add_derived_features = function() {
      if ("timestamp" %in% names(self$prepared_data)) {
        # Extract time-based features
        self$prepared_data <- self$prepared_data %>%
          dplyr::mutate(
            hour = lubridate::hour(timestamp),
            day_of_week = lubridate::wday(timestamp, week_start = 1), # Monday = 1
            # Calculate time since case start for each event (in hours)
            time_since_start = as.numeric(difftime(timestamp, 
              min(timestamp), units = "hours"))
          ) %>%
          dplyr::group_by(case) %>%
          dplyr::mutate(
            time_since_start = as.numeric(difftime(timestamp, 
              min(timestamp), units = "hours"))
          ) %>%
          dplyr::ungroup()
        
        message("✨ Added derived time features: hour, day_of_week, time_since_start")
      }
    }
  )
)

# Convenience function for quick loading (functional interface)
#' Load and prepare event log data (functional interface)
#' 
#' @param filepath Path to CSV file
#' @param prepare_data Whether to automatically prepare the data
#' @return tibble with event log data
#' @export
#' 
#' @examples
#' data <- load_event_log("data/sepsis_events.csv")
load_event_log <- function(filepath, prepare_data = TRUE) {
  loader <- EventLogLoader$new(filepath)
  data <- loader$load_data()
  
  if (prepare_data) {
    data <- loader$prepare_data()
  }
  
  return(data)
}

# Print module information
cat("📊 HealthProcessAI R - Step 1: Data Loader\n")
cat("==========================================\n")
cat("✅ EventLogLoader R6 class available\n")
cat("✅ load_event_log() function available\n")
cat("📚 Uses: tidyverse, lubridate, R6\n\n")
cat("Example usage:\n")
cat('  loader <- EventLogLoader$new("data/sepsis_events.csv")\n')
cat("  data <- loader$load_data()\n")
cat("  prepared <- loader$prepare_data()\n")
cat("  stats <- loader$get_statistics()\n\n")