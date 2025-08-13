# Test Suite for Step 1: Data Loader
# ==================================
# Tests for the EventLogLoader R6 class and related functions

# Load required libraries for testing
library(testthat)
library(tibble)
library(dplyr)
library(lubridate)

# Source the data loader module
source("R/core/step1_data_loader.R")

# Create test data
create_test_data <- function() {
  tibble::tibble(
    case = c("P001", "P001", "P001", "P002", "P002"),
    activity = c("Admission", "Test", "Discharge", "Admission", "Test"),
    timestamp = c(
      "2024-01-01 08:00:00",
      "2024-01-01 10:00:00", 
      "2024-01-01 14:00:00",
      "2024-01-02 09:00:00",
      "2024-01-02 11:00:00"
    ),
    resource = c("Ward A", "Lab", "Ward A", "Ward B", "Lab"),
    SepsisLabel = c(0, 0, 0, 1, 1)
  )
}

# Test: EventLogLoader initialization
test_that("EventLogLoader initializes correctly", {
  # Create temp test file
  test_data <- create_test_data()
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_file)
  
  # Test successful initialization
  loader <- EventLogLoader$new(temp_file)
  
  expect_true(inherits(loader, "EventLogLoader"))
  expect_equal(loader$filepath, temp_file)
  expect_null(loader$raw_data)
  expect_null(loader$prepared_data)
  
  # Clean up
  unlink(temp_file)
})

test_that("EventLogLoader fails with non-existent file", {
  expect_error(
    EventLogLoader$new("non_existent_file.csv"),
    "Event log file not found"
  )
})

# Test: Data loading
test_that("load_data works correctly", {
  # Create temp test file
  test_data <- create_test_data()
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_file)
  
  # Test loading
  loader <- EventLogLoader$new(temp_file)
  loaded_data <- loader$load_data()
  
  expect_true(inherits(loaded_data, "data.frame"))
  expect_equal(nrow(loaded_data), 5)
  expect_true(all(c("case", "activity", "timestamp") %in% names(loaded_data)))
  
  # Clean up
  unlink(temp_file)
})

test_that("load_data validates required columns", {
  # Create data missing required columns
  incomplete_data <- tibble::tibble(
    case = c("P001", "P002"),
    # Missing 'activity' and 'timestamp'
    resource = c("Ward A", "Ward B")
  )
  
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(incomplete_data, temp_file)
  
  loader <- EventLogLoader$new(temp_file)
  
  expect_error(
    loader$load_data(),
    "Missing required columns"
  )
  
  # Clean up
  unlink(temp_file)
})

# Test: Data preparation
test_that("prepare_data works correctly", {
  # Create temp test file
  test_data <- create_test_data()
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_file)
  
  # Test preparation
  loader <- EventLogLoader$new(temp_file)
  loader$load_data()
  prepared_data <- loader$prepare_data()
  
  expect_true(inherits(prepared_data, "data.frame"))
  expect_true(lubridate::is.POSIXct(prepared_data$timestamp))
  expect_true("hour" %in% names(prepared_data))
  expect_true("day_of_week" %in% names(prepared_data))
  expect_true("time_since_start" %in% names(prepared_data))
  
  # Check sorting
  expect_true(all(prepared_data$case == c("P001", "P001", "P001", "P002", "P002")))
  
  # Clean up
  unlink(temp_file)
})

# Test: Statistics
test_that("get_statistics returns correct information", {
  # Create temp test file
  test_data <- create_test_data()
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_file)
  
  # Get statistics
  loader <- EventLogLoader$new(temp_file)
  loader$load_data()
  loader$prepare_data()
  stats <- loader$get_statistics()
  
  expect_equal(stats$num_events, 5)
  expect_equal(stats$num_cases, 2)
  expect_equal(stats$num_activities, 3)
  expect_true("sepsis_rate" %in% names(stats))
  expect_equal(stats$sepsis_rate, 0.5) # 1 out of 2 cases
  
  # Clean up
  unlink(temp_file)
})

# Test: Filtering by outcome
test_that("filter_by_outcome works correctly", {
  # Create temp test file
  test_data <- create_test_data()
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_file)
  
  # Test filtering
  loader <- EventLogLoader$new(temp_file)
  loader$load_data()
  loader$prepare_data()
  
  # Filter for sepsis cases
  sepsis_data <- loader$filter_by_outcome(sepsis_only = TRUE)
  expect_equal(unique(sepsis_data$case), "P002")
  expect_equal(nrow(sepsis_data), 2)
  
  # Filter for non-sepsis cases
  non_sepsis_data <- loader$filter_by_outcome(sepsis_only = FALSE)
  expect_equal(unique(non_sepsis_data$case), "P001")
  expect_equal(nrow(non_sepsis_data), 3)
  
  # Clean up
  unlink(temp_file)
})

# Test: Sampling cases
test_that("sample_cases works correctly", {
  # Create temp test file with more data
  test_data <- bind_rows(
    create_test_data(),
    tibble::tibble(
      case = c("P003", "P003", "P004", "P004"),
      activity = c("Admission", "Discharge", "Admission", "Discharge"),
      timestamp = c(
        "2024-01-03 08:00:00", "2024-01-03 12:00:00",
        "2024-01-04 09:00:00", "2024-01-04 13:00:00"
      ),
      resource = c("Ward C", "Ward C", "Ward D", "Ward D"),
      SepsisLabel = c(0, 0, 1, 1)
    )
  )
  
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_file)
  
  # Test sampling
  loader <- EventLogLoader$new(temp_file)
  loader$load_data()
  loader$prepare_data()
  
  sampled_data <- loader$sample_cases(n = 2, seed = 42)
  expect_equal(dplyr::n_distinct(sampled_data$case), 2)
  expect_true(nrow(sampled_data) <= nrow(loader$prepared_data))
  
  # Clean up
  unlink(temp_file)
})

# Test: Functional interface
test_that("load_event_log functional interface works", {
  # Create temp test file
  test_data <- create_test_data()
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_file)
  
  # Test functional interface
  loaded_data <- load_event_log(temp_file, prepare_data = TRUE)
  
  expect_true(inherits(loaded_data, "data.frame"))
  expect_true(lubridate::is.POSIXct(loaded_data$timestamp))
  expect_true("hour" %in% names(loaded_data))
  
  # Clean up
  unlink(temp_file)
})

# Print test completion message
cat("✅ Step 1 Data Loader tests completed\n")