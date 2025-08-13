# Test Suite for Step 4: Advanced Analytics
# =========================================
# Tests for the AdvancedProcessAnalyzer R6 class and related functions

# Load required libraries for testing
library(testthat)
library(R6)
library(tidyverse)
library(bupaR)
library(edeaR)
library(cluster)
library(lubridate)

# Source the advanced analytics module
source("R/core/step4_advanced_analytics.R")

# Create test event log
create_advanced_test_data <- function() {
  test_data <- tibble::tibble(
    case = c(
      "P001", "P001", "P001", "P001",
      "P002", "P002", "P002", "P002", "P002", "P002",
      "P003", "P003", "P003"
    ),
    activity = c(
      "Registration", "Consultation", "Lab Test", "Discharge",
      "Emergency Admission", "High Fever", "Blood Culture", "Infection", "Antibiotic", "ICU Admission",
      "Registration", "Surgery", "Recovery"
    ),
    timestamp = c(
      "2024-01-01 09:00:00", "2024-01-01 10:00:00", "2024-01-01 11:00:00", "2024-01-01 15:00:00",
      "2024-01-02 02:00:00", "2024-01-02 03:00:00", "2024-01-02 04:00:00", 
      "2024-01-02 06:00:00", "2024-01-02 08:00:00", "2024-01-02 12:00:00",
      "2024-01-03 10:00:00", "2024-01-03 14:00:00", "2024-01-04 08:00:00"
    ),
    resource = c(
      "Reception", "Dr. Smith", "Lab", "Reception",
      "ER", "Dr. Emergency", "Lab", "Dr. Emergency", "Pharmacy", "ICU",
      "Reception", "OR", "ICU"
    ),
    SepsisLabel = c(
      0, 0, 0, 0,
      1, 1, 1, 1, 1, 1,
      0, 0, 0
    )
  ) %>%
    dplyr::mutate(timestamp = lubridate::ymd_hms(timestamp))
  
  # Create bupaR eventlog
  event_log <- bupaR::eventlog(
    eventlog = test_data,
    case_id = "case",
    activity_id = "activity",
    timestamp = "timestamp", 
    resource_id = "resource"
  )
  
  return(event_log)
}

# Test: AdvancedProcessAnalyzer initialization
test_that("AdvancedProcessAnalyzer initializes correctly", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  expect_true(inherits(analyzer, "AdvancedProcessAnalyzer"))
  expect_true(bupaR::is.eventlog(analyzer$event_log))
  expect_equal(bupaR::n_cases(analyzer$event_log), 3)
})

test_that("AdvancedProcessAnalyzer requires valid event log", {
  expect_error(
    AdvancedProcessAnalyzer$new("not_an_eventlog"),
    "Input must be a bupaR eventlog object"
  )
  
  expect_error(
    AdvancedProcessAnalyzer$new(NULL),
    "Input must be a bupaR eventlog object"
  )
})

# Test: Patient pathway clustering
test_that("cluster_patient_pathways works correctly", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  # Test kmeans clustering
  clusters <- analyzer$cluster_patient_pathways(n_clusters = 2, method = "kmeans")
  
  expect_true(is.list(clusters))
  expect_equal(clusters$method, "kmeans")
  expect_true(clusters$n_clusters >= 1)
  expect_true(is.numeric(clusters$assignments))
  expect_equal(length(clusters$assignments), 3)  # 3 cases
  expect_true(is.list(clusters$cluster_profiles))
  expect_true(is.numeric(clusters$silhouette_score))
})

test_that("cluster_patient_pathways handles different methods", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  # Test hierarchical clustering
  clusters_hier <- analyzer$cluster_patient_pathways(n_clusters = 2, method = "hierarchical")
  expect_equal(clusters_hier$method, "hierarchical")
  
  # Test PAM clustering
  clusters_pam <- analyzer$cluster_patient_pathways(n_clusters = 2, method = "pam")
  expect_equal(clusters_pam$method, "pam")
  
  # Test unsupported method
  expect_error(
    analyzer$cluster_patient_pathways(method = "unsupported"),
    "Unsupported clustering method"
  )
})

# Test: Bottleneck analysis
test_that("analyze_bottlenecks works correctly", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  bottlenecks <- analyzer$analyze_bottlenecks(threshold_percentile = 75)
  
  expect_true(is.list(bottlenecks))
  expect_true("bottlenecks" %in% names(bottlenecks))
  expect_true("critical_activities" %in% names(bottlenecks))
  expect_true("improvement_potential" %in% names(bottlenecks))
  expect_true(is.data.frame(bottlenecks$bottlenecks) || is_tibble(bottlenecks$bottlenecks))
  expect_true(is.numeric(bottlenecks$avg_total_wait_hours))
})

# Test: Clinical KPI calculation
test_that("calculate_clinical_kpis works correctly", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  kpis <- analyzer$calculate_clinical_kpis()
  
  expect_true(is.list(kpis))
  expect_true("total_cases" %in% names(kpis))
  expect_true("total_events" %in% names(kpis))
  expect_true("unique_activities" %in% names(kpis))
  expect_equal(kpis$total_cases, 3)
  expect_equal(kpis$total_events, 13)
  expect_true(kpis$unique_activities > 0)
  
  # Test that duration metrics are calculated
  expect_true("avg_length_of_stay" %in% names(kpis))
  expect_true("median_length_of_stay" %in% names(kpis))
  expect_true(is.numeric(kpis$avg_length_of_stay))
})

# Test: Conformance checking
test_that("check_guideline_conformance works correctly", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  test_rules <- list(
    "Blood Test must follow High Fever within 2 hours",
    "ICU Admission must follow severe symptoms"
  )
  
  conformance <- analyzer$check_guideline_conformance(test_rules, "Test Guideline")
  
  expect_true(is.list(conformance))
  expect_equal(conformance$guideline, "Test Guideline")
  expect_equal(conformance$total_cases, 3)
  expect_true(is.numeric(conformance$compliance_rate))
  expect_true(conformance$compliance_rate >= 0 && conformance$compliance_rate <= 1)
  expect_true("violations" %in% names(conformance))
  expect_true("fitness_score" %in% names(conformance))
})

# Test: Predictive monitoring
test_that("predict_case_outcome works correctly", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  # Create partial trace (first 3 events of case P002)
  partial_trace <- tibble::tibble(
    case_id = c("P002", "P002", "P002"),
    activity = c("Emergency Admission", "High Fever", "Blood Culture"),
    timestamp = c("2024-01-02 02:00:00", "2024-01-02 03:00:00", "2024-01-02 04:00:00"),
    resource = c("ER", "Dr. Emergency", "Lab")
  ) %>%
    dplyr::mutate(timestamp = lubridate::ymd_hms(timestamp))
  
  prediction <- analyzer$predict_case_outcome(partial_trace, "sepsis")
  
  expect_true(is.list(prediction))
  expect_equal(prediction$outcome_type, "sepsis")
  expect_true(is.numeric(prediction$risk_score))
  expect_true(prediction$risk_score >= 0 && prediction$risk_score <= 100)
  expect_true(prediction$risk_level %in% c("LOW", "MODERATE", "HIGH"))
  expect_true(is.numeric(prediction$confidence))
  expect_true(is.character(prediction$risk_factors))
  expect_true(is.character(prediction$recommended_actions))
})

# Test: Results export
test_that("export_advanced_results works correctly", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  # Generate some results first
  analyzer$cluster_patient_pathways(n_clusters = 2)
  analyzer$calculate_clinical_kpis()
  
  # Export to temporary directory
  temp_dir <- tempfile()
  saved_files <- analyzer$export_advanced_results(temp_dir)
  
  expect_true(is.list(saved_files))
  expect_true(dir.exists(temp_dir))
  expect_true("clusters" %in% names(saved_files))
  expect_true("kpis" %in% names(saved_files))
  expect_true("summary" %in% names(saved_files))
  
  # Check files exist
  expect_true(file.exists(saved_files$clusters))
  expect_true(file.exists(saved_files$kpis))
  expect_true(file.exists(saved_files$summary))
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

# Test: Functional interface - analyze_advanced_patterns
test_that("analyze_advanced_patterns functional interface works", {
  event_log <- create_advanced_test_data()
  
  results <- analyze_advanced_patterns(
    event_log,
    include_clustering = TRUE,
    include_bottlenecks = TRUE,
    include_kpis = TRUE
  )
  
  expect_true(is.list(results))
  expect_true("analyzer" %in% names(results))
  expect_true("clusters" %in% names(results))
  expect_true("bottlenecks" %in% names(results))
  expect_true("kpis" %in% names(results))
  expect_true(inherits(results$analyzer, "AdvancedProcessAnalyzer"))
})

test_that("analyze_advanced_patterns handles selective analysis", {
  event_log <- create_advanced_test_data()
  
  # Test with only clustering
  results_clustering <- analyze_advanced_patterns(
    event_log,
    include_clustering = TRUE,
    include_bottlenecks = FALSE,
    include_kpis = FALSE
  )
  
  expect_true("clusters" %in% names(results_clustering))
  expect_false("bottlenecks" %in% names(results_clustering))
  expect_false("kpis" %in% names(results_clustering))
})

# Test: Functional interface - predict_clinical_risk
test_that("predict_clinical_risk functional interface works", {
  # Create test partial events
  partial_events <- tibble::tibble(
    case_id = c("TEST", "TEST", "TEST"),
    activity = c("Emergency Admission", "High Fever", "Infection"),
    timestamp = c("2024-01-01 10:00:00", "2024-01-01 11:00:00", "2024-01-01 12:00:00"),
    resource = c("ER", "Dr. Test", "Lab")
  ) %>%
    dplyr::mutate(timestamp = lubridate::ymd_hms(timestamp))
  
  prediction <- predict_clinical_risk(partial_events, "sepsis")
  
  expect_true(is.list(prediction))
  expect_equal(prediction$outcome_type, "sepsis")
  expect_true(is.numeric(prediction$risk_score))
  expect_true(prediction$risk_level %in% c("LOW", "MODERATE", "HIGH"))
  expect_true(length(prediction$risk_factors) >= 0)
})

# Test: Edge cases and error handling
test_that("AdvancedProcessAnalyzer handles edge cases", {
  event_log <- create_advanced_test_data()
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  
  # Test clustering with more clusters than cases
  expect_warning(
    clusters <- analyzer$cluster_patient_pathways(n_clusters = 10, method = "kmeans"),
    NA  # Should handle gracefully without warnings if implemented correctly
  )
  
  # Test bottleneck analysis with extreme percentile
  bottlenecks_extreme <- analyzer$analyze_bottlenecks(threshold_percentile = 99)
  expect_true(is.list(bottlenecks_extreme))
  
  # Test prediction with empty trace
  empty_trace <- tibble::tibble(
    case_id = character(0),
    activity = character(0),
    timestamp = lubridate::ymd_hms(character(0)),
    resource = character(0)
  )
  
  prediction_empty <- analyzer$predict_case_outcome(empty_trace, "sepsis")
  expect_true(is.list(prediction_empty))
  expect_equal(prediction_empty$risk_score, 0)
})

# Print test completion message
cat("✅ Step 4 Advanced Analytics tests completed\n")