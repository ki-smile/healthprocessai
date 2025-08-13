# Test Suite for Step 2: Process Mining
# =====================================
# Tests for the ProcessMiner R6 class and related functions

# Load required libraries for testing
library(testthat)
library(tibble)
library(dplyr)
library(bupaR)
library(edeaR)
library(processmapR)
library(lubridate)

# Source the process mining module
source("R/core/step2_process_mining.R")

# Create test data suitable for process mining
create_process_test_data <- function() {
  tibble::tibble(
    case = c("P001", "P001", "P001", "P002", "P002", "P002", "P003", "P003"),
    activity = c("Admission", "Blood Test", "Discharge", 
                 "Admission", "CT Scan", "Discharge",
                 "Emergency", "ICU Transfer"),
    timestamp = c(
      "2024-01-01 08:00:00", "2024-01-01 10:00:00", "2024-01-01 16:00:00",
      "2024-01-02 09:00:00", "2024-01-02 11:00:00", "2024-01-02 15:00:00",
      "2024-01-03 07:00:00", "2024-01-03 14:00:00"
    ),
    resource = c("Ward A", "Lab", "Ward A", "Ward B", "Radiology", "Ward B", "ER", "ICU"),
    SepsisLabel = c(0, 0, 0, 1, 1, 1, 1, 1)
  ) %>%
    dplyr::mutate(timestamp = lubridate::ymd_hms(timestamp))
}

# Test: ProcessMiner initialization
test_that("ProcessMiner initializes correctly", {
  miner <- ProcessMiner$new()
  
  expect_true(inherits(miner, "ProcessMiner"))
  expect_null(miner$event_log)
  expect_null(miner$process_map_freq)
  expect_null(miner$variants)
})

# Test: Event log creation
test_that("create_event_log works correctly", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  
  # Test successful event log creation
  event_log <- miner$create_event_log(test_data)
  
  expect_true(inherits(event_log, "eventlog"))
  expect_equal(bupaR::n_cases(event_log), 3)
  expect_equal(bupaR::n_events(event_log), 8)
  expect_equal(bupaR::n_activities(event_log), 6)
  
  # Check column names are correct
  expect_true(miner$CASE_ID_KEY %in% names(event_log))
  expect_true(miner$ACTIVITY_KEY %in% names(event_log))
  expect_true(miner$TIMESTAMP_KEY %in% names(event_log))
})

test_that("create_event_log validates required columns", {
  # Test with missing columns
  incomplete_data <- tibble::tibble(
    case = c("P001", "P002"),
    # Missing 'activity' and 'timestamp'
    resource = c("Ward A", "Ward B")
  )
  
  miner <- ProcessMiner$new()
  
  expect_error(
    miner$create_event_log(incomplete_data),
    "Missing required columns"
  )
})

# Test: Process map discovery
test_that("discover_process_map works correctly", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  miner$create_event_log(test_data)
  
  # Test frequency process map
  freq_map <- miner$discover_process_map(type = "frequency", render = FALSE)
  expect_true(!is.null(freq_map))
  
  # Test performance process map
  perf_map <- miner$discover_process_map(type = "performance", render = FALSE)
  expect_true(!is.null(perf_map))
  
  # Test invalid type
  expect_error(
    miner$discover_process_map(type = "invalid"),
    "Unknown map type"
  )
})

test_that("discover_process_map requires event log", {
  miner <- ProcessMiner$new()
  
  expect_error(
    miner$discover_process_map(),
    "No event log created"
  )
})

# Test: Start and end activities
test_that("get_start_end_activities works correctly", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  miner$create_event_log(test_data)
  
  activities <- miner$get_start_end_activities()
  
  expect_true("start_activities" %in% names(activities))
  expect_true("end_activities" %in% names(activities))
  expect_true(inherits(activities$start_activities, "data.frame"))
  expect_true(inherits(activities$end_activities, "data.frame"))
  
  # Check that we have the expected start activities
  start_acts <- activities$start_activities$activity_id
  expect_true("Admission" %in% start_acts | "Emergency" %in% start_acts)
})

# Test: Process matrix creation
test_that("create_process_matrix works correctly", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  miner$create_event_log(test_data)
  
  matrix <- miner$create_process_matrix()
  
  expect_true(inherits(matrix, "data.frame"))
  expect_true(nrow(matrix) > 0)
  expect_true(ncol(matrix) > 0)
})

# Test: Variants discovery
test_that("discover_variants works correctly", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  miner$create_event_log(test_data)
  
  variants <- miner$discover_variants(top_k = 3)
  
  expect_true(inherits(variants, "data.frame"))
  expect_true("trace" %in% names(variants))
  expect_true("cases" %in% names(variants))
  expect_true("percentage" %in% names(variants))
  expect_true(nrow(variants) <= 3)
  expect_true(all(variants$percentage >= 0 & variants$percentage <= 100))
})

# Test: Process metrics calculation
test_that("calculate_process_metrics works correctly", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  miner$create_event_log(test_data)
  
  metrics <- miner$calculate_process_metrics()
  
  expect_true(is.list(metrics))
  expect_true("num_cases" %in% names(metrics))
  expect_true("num_events" %in% names(metrics))
  expect_true("num_activities" %in% names(metrics))
  expect_true("avg_duration_hours" %in% names(metrics))
  
  expect_equal(metrics$num_cases, 3)
  expect_equal(metrics$num_events, 8)
  expect_true(metrics$avg_duration_hours > 0)
})

# Test: Discovery methods comparison
test_that("compare_discovery_methods works correctly", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  miner$create_event_log(test_data)
  
  comparison <- miner$compare_discovery_methods()
  
  expect_true(is.list(comparison))
  expect_true("frequency_map" %in% names(comparison))
  expect_true("performance_map" %in% names(comparison))
  expect_true("variants" %in% names(comparison))
  expect_true("process_matrix" %in% names(comparison))
  
  # Check that at least some methods succeeded
  successful <- sapply(comparison, function(x) "status" %in% names(x) && x$status == "success")
  expect_true(sum(successful) > 0)
})

# Test: Results export
test_that("export_results works correctly", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  miner$create_event_log(test_data)
  
  # Create some results first
  miner$discover_process_map(type = "frequency")
  miner$discover_variants(top_k = 3)
  miner$create_process_matrix()
  
  # Export to temp directory
  temp_dir <- tempfile()
  exported <- miner$export_results(temp_dir)
  
  expect_true(is.list(exported))
  expect_true(dir.exists(temp_dir))
  
  # Check that metrics file was created
  expect_true("metrics" %in% names(exported))
  expect_true(file.exists(exported$metrics))
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

# Test: Functional interface - create_process_map
test_that("create_process_map functional interface works", {
  test_data <- create_process_test_data()
  miner <- ProcessMiner$new()
  event_log <- miner$create_event_log(test_data)
  
  # Test functional interface
  freq_map <- create_process_map(event_log, type = "frequency")
  expect_true(!is.null(freq_map))
  
  perf_map <- create_process_map(event_log, type = "performance")
  expect_true(!is.null(perf_map))
  
  expect_error(
    create_process_map(event_log, type = "invalid"),
    "Type must be"
  )
})

# Test: Functional interface - analyze_process
test_that("analyze_process functional interface works", {
  test_data <- create_process_test_data()
  
  # Test complete functional analysis
  results <- analyze_process(test_data)
  
  expect_true(is.list(results))
  expect_true("event_log" %in% names(results))
  expect_true("process_map" %in% names(results))
  expect_true("variants" %in% names(results))
  expect_true("metrics" %in% names(results))
  
  expect_true(inherits(results$event_log, "eventlog"))
  expect_true(inherits(results$variants, "data.frame"))
  expect_true(is.list(results$metrics))
})

# Print test completion message
cat("✅ Step 2 Process Mining tests completed\n")