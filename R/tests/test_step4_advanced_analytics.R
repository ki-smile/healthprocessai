# Test suite for Step 4: Advanced Analytics
# Tests AdvancedProcessAnalyzer R6 class functionality

library(testthat)
library(tidyverse)
library(R6)
library(cluster)

# Source the modules
source("R/core/step1_data_loader.R")
source("R/core/step4_advanced_analytics.R")

# Test data creation helper
create_test_event_log <- function() {
  tibble(
    case = paste0("Case_", rep(1:10, each = 4)),
    activity = rep(c("Admission", "Assessment", "Treatment", "Discharge"), 10),
    timestamp = as.POSIXct("2024-01-01") + 
      hours(rep(c(0, 1, 5, 8), 10)) + 
      days(rep(0:9, each = 4)),
    resource = rep(c("ER", "Doctor", "Nurse", "Admin"), 10),
    cost = runif(40, 100, 1000),
    outcome = rep(c("Good", "Fair", "Good", "Poor", "Good"), c(8, 8, 8, 8, 8))
  )
}

create_sepsis_event_log <- function() {
  # Create sepsis-specific event log for testing
  n_patients <- 20
  sepsis_cases <- sample(1:n_patients, size = n_patients * 0.3)  # 30% sepsis
  
  all_events <- list()
  
  for (patient in 1:n_patients) {
    is_sepsis <- patient %in% sepsis_cases
    
    # Basic pathway
    activities <- c("Admission", "Vitals_Check", "Lab_Test")
    
    # Add complications for sepsis cases
    if (is_sepsis) {
      activities <- c(activities, "Organ_Dysfunction", "ICU_Transfer", "Sepsis_Treatment")
    }
    
    activities <- c(activities, "Discharge")
    
    patient_events <- tibble(
      case = paste0("P", sprintf("%03d", patient)),
      activity = activities,
      timestamp = as.POSIXct("2024-01-01") + 
        hours(cumsum(c(0, runif(length(activities)-1, 1, 4)))),
      resource = sample(c("ER", "ICU", "Lab", "Doctor"), length(activities), replace = TRUE),
      sepsis_label = as.integer(is_sepsis)
    )
    
    all_events <- append(all_events, list(patient_events))
  }
  
  bind_rows(all_events)
}

# Test AdvancedProcessAnalyzer class
test_that("AdvancedProcessAnalyzer initializes correctly", {
  test_data <- create_test_event_log()
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  expect_s3_class(analyzer, "AdvancedProcessAnalyzer")
  expect_s3_class(analyzer, "R6")
  expect_s3_class(analyzer$event_log, "data.frame")
  expect_equal(nrow(analyzer$event_log), nrow(test_data))
})

test_that("AdvancedProcessAnalyzer validates event log", {
  # Valid event log
  valid_data <- create_test_event_log()
  expect_silent(AdvancedProcessAnalyzer$new(valid_data))
  
  # Invalid event log (missing columns)
  invalid_data <- valid_data %>% select(-activity)
  expect_error(AdvancedProcessAnalyzer$new(invalid_data), "required columns")
})

test_that("Patient pathway clustering works", {
  test_data <- create_sepsis_event_log()
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  # Test k-means clustering
  result <- analyzer$cluster_patient_pathways(n_clusters = 3, method = "kmeans")
  
  expect_type(result, "list")
  expect_true("clusters" %in% names(result))
  expect_true("summary" %in% names(result))
  expect_true("features" %in% names(result))
  
  expect_s3_class(result$clusters, "data.frame")
  expect_equal(nrow(result$clusters), n_distinct(test_data$case))
  expect_true("cluster" %in% names(result$clusters))
  expect_equal(length(unique(result$clusters$cluster)), 3)
  
  # Test hierarchical clustering
  result_hclust <- analyzer$cluster_patient_pathways(n_clusters = 2, method = "hierarchical")
  expect_equal(length(unique(result_hclust$clusters$cluster)), 2)
  
  # Test PAM clustering
  result_pam <- analyzer$cluster_patient_pathways(n_clusters = 2, method = "pam")
  expect_equal(length(unique(result_pam$clusters$cluster)), 2)
})

test_that("Clinical KPIs calculation works", {
  test_data <- create_test_event_log()
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  kpis <- analyzer$calculate_clinical_kpis()
  
  expect_type(kpis, "list")
  expect_true("avg_los" %in% names(kpis))
  expect_true("completion_rate" %in% names(kpis))
  expect_true("activity_efficiency" %in% names(kpis))
  expect_true("resource_utilization" %in% names(kpis))
  expect_true("cost_metrics" %in% names(kpis))
  
  expect_type(kpis$avg_los, "double")
  expect_gte(kpis$avg_los, 0)
  expect_type(kpis$completion_rate, "double")
  expect_gte(kpis$completion_rate, 0)
  expect_lte(kpis$completion_rate, 1)
})

test_that("Conformance checking works", {
  if (requireNamespace("bupaR", quietly = TRUE)) {
    test_data <- create_test_event_log()
    analyzer <- AdvancedProcessAnalyzer$new(test_data)
    
    # Define reference model (expected pathway)
    reference_model <- c("Admission", "Assessment", "Treatment", "Discharge")
    
    conformance <- analyzer$check_conformance(reference_model)
    
    expect_type(conformance, "list")
    expect_true("case_conformance" %in% names(conformance))
    expect_true("overall_metrics" %in% names(conformance))
    
    expect_s3_class(conformance$case_conformance, "data.frame")
    expect_true("case" %in% names(conformance$case_conformance))
    expect_true("conformance_score" %in% names(conformance$case_conformance))
    
    # All cases should have some conformance score
    expect_true(all(!is.na(conformance$case_conformance$conformance_score)))
  } else {
    skip("bupaR not available")
  }
})

test_that("Predictive monitoring works", {
  test_data <- create_sepsis_event_log()
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  predictions <- analyzer$predictive_monitoring(
    target_activity = "Sepsis_Treatment",
    threshold = 0.3
  )
  
  expect_s3_class(predictions, "data.frame")
  expect_true("case" %in% names(predictions))
  expect_true("risk_score" %in% names(predictions))
  expect_true("prediction" %in% names(predictions))
  
  expect_equal(nrow(predictions), n_distinct(test_data$case))
  expect_type(predictions$risk_score, "double")
  expect_true(all(predictions$risk_score >= 0 & predictions$risk_score <= 1))
  expect_type(predictions$prediction, "character")
  expect_true(all(predictions$prediction %in% c("High Risk", "Low Risk")))
})

test_that("Activity pattern analysis works", {
  test_data <- create_sepsis_event_log()
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  patterns <- analyzer$analyze_activity_patterns()
  
  expect_type(patterns, "list")
  expect_true("sequence_patterns" %in% names(patterns))
  expect_true("transition_matrix" %in% names(patterns))
  expect_true("activity_stats" %in% names(patterns))
  
  expect_s3_class(patterns$sequence_patterns, "data.frame")
  expect_s3_class(patterns$transition_matrix, "data.frame")
  expect_s3_class(patterns$activity_stats, "data.frame")
})

test_that("Outcome analysis works", {
  test_data <- create_test_event_log()
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  # Test with outcome column
  outcome_analysis <- analyzer$analyze_outcomes(outcome_column = "outcome")
  
  expect_type(outcome_analysis, "list")
  expect_true("outcome_distribution" %in% names(outcome_analysis))
  expect_true("pathway_outcomes" %in% names(outcome_analysis))
  
  expect_s3_class(outcome_analysis$outcome_distribution, "data.frame")
  expect_s3_class(outcome_analysis$pathway_outcomes, "data.frame")
})

test_that("Time-based analysis works", {
  test_data <- create_test_event_log()
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  time_analysis <- analyzer$analyze_temporal_patterns()
  
  expect_type(time_analysis, "list")
  expect_true("case_durations" %in% names(time_analysis))
  expect_true("activity_durations" %in% names(time_analysis))
  expect_true("arrival_patterns" %in% names(time_analysis))
  
  expect_s3_class(time_analysis$case_durations, "data.frame")
  expect_s3_class(time_analysis$activity_durations, "data.frame")
})

test_that("Resource analysis works", {
  test_data <- create_test_event_log()
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  resource_analysis <- analyzer$analyze_resource_performance()
  
  expect_type(resource_analysis, "list")
  expect_true("resource_stats" %in% names(resource_analysis))
  expect_true("resource_efficiency" %in% names(resource_analysis))
  expect_true("workload_distribution" %in% names(resource_analysis))
  
  expect_s3_class(resource_analysis$resource_stats, "data.frame")
  expect_s3_class(resource_analysis$resource_efficiency, "data.frame")
  expect_s3_class(resource_analysis$workload_distribution, "data.frame")
})

test_that("Bottleneck detection works", {
  test_data <- create_test_event_log()
  
  # Create artificial bottleneck
  test_data$timestamp[test_data$activity == "Treatment"] <- 
    test_data$timestamp[test_data$activity == "Treatment"] + hours(10)
  test_data$timestamp[test_data$activity == "Discharge"] <- 
    test_data$timestamp[test_data$activity == "Discharge"] + hours(10)
  
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  bottlenecks <- analyzer$detect_process_bottlenecks(threshold_percentile = 75)
  
  expect_s3_class(bottlenecks, "data.frame")
  expect_true("bottleneck_type" %in% names(bottlenecks))
  expect_true("severity" %in% names(bottlenecks))
  expect_true("description" %in% names(bottlenecks))
  
  # Treatment should be identified as bottleneck
  expect_true(any(str_detect(bottlenecks$description, "Treatment")))
})

test_that("Advanced analytics handles missing data", {
  test_data <- create_test_event_log()
  
  # Introduce missing values
  test_data$resource[1:5] <- NA
  test_data$cost[6:10] <- NA
  
  analyzer <- AdvancedProcessAnalyzer$new(test_data)
  
  # Should handle missing data gracefully
  expect_silent({
    kpis <- analyzer$calculate_clinical_kpis()
    clustering <- analyzer$cluster_patient_pathways(n_clusters = 2)
    patterns <- analyzer$analyze_activity_patterns()
  })
  
  expect_type(kpis, "list")
  expect_type(clustering, "list")
  expect_type(patterns, "list")
})

test_that("Performance optimization features work", {
  # Create larger dataset to test performance
  large_data <- create_sepsis_event_log()
  
  # Duplicate to make it larger
  large_data <- bind_rows(
    large_data,
    large_data %>% mutate(case = paste0(case, "_2")),
    large_data %>% mutate(case = paste0(case, "_3"))
  )
  
  analyzer <- AdvancedProcessAnalyzer$new(large_data)
  
  # Test that operations complete in reasonable time
  start_time <- Sys.time()
  
  clustering <- analyzer$cluster_patient_pathways(n_clusters = 3)
  kpis <- analyzer$calculate_clinical_kpis()
  
  end_time <- Sys.time()
  
  expect_lt(as.numeric(difftime(end_time, start_time, units = "secs")), 30)  # Should complete in < 30 seconds
  expect_type(clustering, "list")
  expect_type(kpis, "list")
})

# Run the tests
if (interactive()) {
  cat("\n🧪 Running AdvancedProcessAnalyzer Tests...\n")
  cat("=" * 50, "\n")
  
  test_results <- testthat::test_file("R/tests/test_step4_advanced_analytics.R", reporter = "summary")
  
  if (all(test_results$passed)) {
    cat("✅ All AdvancedProcessAnalyzer tests passed!\n")
  } else {
    cat("❌ Some AdvancedProcessAnalyzer tests failed.\n")
  }
}