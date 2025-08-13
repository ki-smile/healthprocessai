# Test suite for Step 1: Data Loader
# Tests EventLogLoader R6 class functionality

library(testthat)
library(tidyverse)
library(lubridate)
library(R6)

# Source the module
source("R/core/step1_data_loader.R")

# Test data creation helper
create_test_event_log <- function() {
  tibble(
    case = paste0("Case_", rep(1:3, each = 3)),
    activity = rep(c("Start", "Middle", "End"), 3),
    timestamp = as.POSIXct("2024-01-01") + hours(rep(c(0, 1, 2), 3)) + days(rep(0:2, each = 3)),
    resource = rep(c("R1", "R2", "R1"), 3),
    lifecycle = "complete",
    cost = runif(9, 100, 500)
  )
}

# Test EventLogLoader class
test_that("EventLogLoader initializes correctly", {
  loader <- EventLogLoader$new()
  expect_s3_class(loader, "EventLogLoader")
  expect_s3_class(loader, "R6")
})

test_that("EventLogLoader loads data from tibble", {
  loader <- EventLogLoader$new()
  test_data <- create_test_event_log()
  
  result <- loader$load_from_data_frame(test_data)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 9)
  expect_true(all(c("case", "activity", "timestamp", "resource") %in% names(result)))
})

test_that("EventLogLoader validates event log format", {
  loader <- EventLogLoader$new()
  
  # Valid data
  valid_data <- create_test_event_log()
  expect_true(loader$validate_event_log(valid_data))
  
  # Invalid data - missing required columns
  invalid_data <- valid_data %>% select(-activity)
  expect_false(loader$validate_event_log(invalid_data))
})

test_that("EventLogLoader converts to bupaR format", {
  if (requireNamespace("bupaR", quietly = TRUE)) {
    loader <- EventLogLoader$new()
    test_data <- create_test_event_log()
    
    bupar_log <- loader$convert_to_bupar(test_data)
    
    expect_s3_class(bupar_log, "eventlog")
    expect_equal(bupaR::n_cases(bupar_log), 3)
    expect_equal(bupaR::n_activities(bupar_log), 3)
  } else {
    skip("bupaR not available")
  }
})

test_that("EventLogLoader applies filters correctly", {
  loader <- EventLogLoader$new()
  test_data <- create_test_event_log()
  
  # Filter by case
  filtered <- loader$apply_filters(test_data, case_filter = c("Case_1"))
  expect_equal(n_distinct(filtered$case), 1)
  expect_equal(filtered$case[1], "Case_1")
  
  # Filter by activity
  filtered <- loader$apply_filters(test_data, activity_filter = c("Start", "End"))
  expect_true(all(filtered$activity %in% c("Start", "End")))
  expect_false(any(filtered$activity == "Middle"))
  
  # Filter by date range
  date_filter <- loader$apply_filters(
    test_data, 
    date_range = c(as.POSIXct("2024-01-01"), as.POSIXct("2024-01-01 12:00:00"))
  )
  expect_true(all(date_filter$timestamp <= as.POSIXct("2024-01-01 12:00:00")))
})

test_that("EventLogLoader calculates basic statistics", {
  loader <- EventLogLoader$new()
  test_data <- create_test_event_log()
  
  stats <- loader$get_basic_statistics(test_data)
  
  expect_type(stats, "list")
  expect_equal(stats$n_cases, 3)
  expect_equal(stats$n_events, 9)
  expect_equal(stats$n_activities, 3)
  expect_true("date_range" %in% names(stats))
})

test_that("EventLogLoader handles missing data gracefully", {
  loader <- EventLogLoader$new()
  
  # Data with missing values
  test_data <- create_test_event_log()
  test_data$resource[1:3] <- NA
  
  expect_true(loader$validate_event_log(test_data))
  
  stats <- loader$get_basic_statistics(test_data)
  expect_type(stats$missing_resources, "integer")
})

test_that("EventLogLoader column mapping works", {
  loader <- EventLogLoader$new()
  
  # Data with different column names
  test_data <- tibble(
    patient_id = paste0("P", 1:6),
    event_name = rep(c("Admission", "Discharge"), 3),
    event_time = as.POSIXct("2024-01-01") + hours(0:5),
    department = rep(c("ER", "ICU", "Ward"), 2)
  )
  
  mapped_data <- loader$load_from_data_frame(
    test_data,
    case_col = "patient_id",
    activity_col = "event_name", 
    timestamp_col = "event_time",
    resource_col = "department"
  )
  
  expect_true(all(c("case", "activity", "timestamp", "resource") %in% names(mapped_data)))
  expect_equal(mapped_data$case, test_data$patient_id)
  expect_equal(mapped_data$activity, test_data$event_name)
})

# Run the tests
if (interactive()) {
  cat("\n🧪 Running EventLogLoader Tests...\n")
  cat("=" * 50, "\n")
  
  test_results <- testthat::test_file("R/tests/test_step1_data_loader.R", reporter = "summary")
  
  if (all(test_results$passed)) {
    cat("✅ All EventLogLoader tests passed!\n")
  } else {
    cat("❌ Some EventLogLoader tests failed.\n")
  }
}