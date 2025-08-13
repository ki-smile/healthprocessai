# Test suite for Step 2: Process Mining
# Tests ProcessMiner R6 class functionality

library(testthat)
library(tidyverse)
library(R6)

# Source the modules
source("R/core/step1_data_loader.R")
source("R/core/step2_process_mining.R")

# Test data creation helper
create_test_event_log <- function() {
  tibble(
    case = paste0("Case_", rep(1:3, each = 4)),
    activity = rep(c("Start", "Task_A", "Task_B", "End"), 3),
    timestamp = as.POSIXct("2024-01-01") + 
      hours(rep(c(0, 1, 3, 4), 3)) + 
      days(rep(0:2, each = 4)),
    resource = rep(c("R1", "R2", "R1", "R3"), 3),
    lifecycle = "complete"
  )
}

# Test ProcessMiner class
test_that("ProcessMiner initializes correctly", {
  miner <- ProcessMiner$new()
  expect_s3_class(miner, "ProcessMiner")
  expect_s3_class(miner, "R6")
})

test_that("ProcessMiner discovers process patterns", {
  if (requireNamespace("bupaR", quietly = TRUE)) {
    miner <- ProcessMiner$new()
    test_data <- create_test_event_log()
    
    # Convert to bupaR format first
    loader <- EventLogLoader$new()
    bupar_log <- loader$convert_to_bupar(test_data)
    
    # Discover DFG
    dfg <- miner$discover_dfg(bupar_log, type = "frequency")
    expect_s3_class(dfg, "data.frame")
    expect_true(all(c("from", "to", "n") %in% names(dfg)))
    
    # Check expected transitions
    expected_transitions <- c("Start->Task_A", "Task_A->Task_B", "Task_B->End")
    actual_transitions <- paste0(dfg$from, "->", dfg$to)
    expect_true(all(expected_transitions %in% actual_transitions))
  } else {
    skip("bupaR not available")
  }
})

test_that("ProcessMiner calculates performance metrics", {
  if (requireNamespace("bupaR", quietly = TRUE)) {
    miner <- ProcessMiner$new()
    test_data <- create_test_event_log()
    
    loader <- EventLogLoader$new()
    bupar_log <- loader$convert_to_bupar(test_data)
    
    metrics <- miner$calculate_performance_metrics(bupar_log)
    
    expect_type(metrics, "list")
    expect_true("n_cases" %in% names(metrics))
    expect_true("n_events" %in% names(metrics))
    expect_true("n_activities" %in% names(metrics))
    expect_true("avg_case_duration" %in% names(metrics))
    expect_true("n_variants" %in% names(metrics))
    
    expect_equal(metrics$n_cases, 3)
    expect_equal(metrics$n_events, 12)
    expect_equal(metrics$n_activities, 4)
    expect_gt(metrics$avg_case_duration, 0)
  } else {
    skip("bupaR not available")
  }
})

test_that("ProcessMiner identifies bottlenecks", {
  if (requireNamespace("bupaR", quietly = TRUE)) {
    miner <- ProcessMiner$new()
    test_data <- create_test_event_log()
    
    # Create bottleneck by making Task_B take longer
    test_data$timestamp[test_data$activity == "Task_B"] <- 
      test_data$timestamp[test_data$activity == "Task_B"] + hours(5)
    test_data$timestamp[test_data$activity == "End"] <- 
      test_data$timestamp[test_data$activity == "End"] + hours(5)
    
    loader <- EventLogLoader$new()
    bupar_log <- loader$convert_to_bupar(test_data)
    
    bottlenecks <- miner$identify_bottlenecks(bupar_log, threshold_percentile = 50)
    
    expect_s3_class(bottlenecks, "data.frame")
    expect_true("activity" %in% names(bottlenecks))
    expect_true("avg_duration_hours" %in% names(bottlenecks))
    
    # Task_B should be identified as bottleneck
    task_b_duration <- bottlenecks$avg_duration_hours[bottlenecks$activity == "Task_B"]
    expect_gt(task_b_duration, 2)  # Should be longer than other activities
  } else {
    skip("bupaR not available")
  }
})

test_that("ProcessMiner analyzes process variants", {
  if (requireNamespace("bupaR", quietly = TRUE)) {
    miner <- ProcessMiner$new()
    
    # Create data with different variants
    variant_data <- tibble(
      case = paste0("Case_", c(rep(1:2, each = 3), rep(3:4, each = 4))),
      activity = c(
        # Variant 1: Start -> Task_A -> End (2 cases)
        "Start", "Task_A", "End", "Start", "Task_A", "End",
        # Variant 2: Start -> Task_A -> Task_B -> End (2 cases)  
        "Start", "Task_A", "Task_B", "End", "Start", "Task_A", "Task_B", "End"
      ),
      timestamp = as.POSIXct("2024-01-01") + 
        hours(c(0, 1, 2, 0, 1, 2, 0, 1, 2, 3, 0, 1, 2, 3)),
      resource = "R1"
    )
    
    loader <- EventLogLoader$new()
    bupar_log <- loader$convert_to_bupar(variant_data)
    
    variants <- miner$analyze_process_variants(bupar_log, top_n = 5)
    
    expect_s3_class(variants, "data.frame")
    expect_true("trace" %in% names(variants))
    expect_true("absolute_frequency" %in% names(variants))
    expect_true("relative_frequency" %in% names(variants))
    
    # Should have 2 variants
    expect_equal(nrow(variants), 2)
    
    # Both variants should have frequency of 2
    expect_true(all(variants$absolute_frequency == 2))
  } else {
    skip("bupaR not available")
  }
})

test_that("ProcessMiner handles resource analysis", {
  if (requireNamespace("bupaR", quietly = TRUE)) {
    miner <- ProcessMiner$new()
    test_data <- create_test_event_log()
    
    loader <- EventLogLoader$new()
    bupar_log <- loader$convert_to_bupar(test_data)
    
    resource_analysis <- miner$analyze_resource_utilization(bupar_log)
    
    expect_s3_class(resource_analysis, "data.frame")
    expect_true("resource" %in% names(resource_analysis))
    expect_true("frequency" %in% names(resource_analysis))
    expect_true("activities" %in% names(resource_analysis))
    
    # Should have all resources from test data
    expected_resources <- c("R1", "R2", "R3")
    expect_true(all(expected_resources %in% resource_analysis$resource))
  } else {
    skip("bupaR not available")
  }
})

test_that("ProcessMiner exports process maps", {
  if (requireNamespace("bupaR", quietly = TRUE) && 
      requireNamespace("processmapR", quietly = TRUE)) {
    
    miner <- ProcessMiner$new()
    test_data <- create_test_event_log()
    
    loader <- EventLogLoader$new()
    bupar_log <- loader$convert_to_bupar(test_data)
    
    # Test process map creation (returns grViz object)
    process_map <- miner$create_process_map(bupar_log, type = "frequency")
    
    # Should return a DiagrammeR object or similar
    expect_s3_class(process_map, c("grViz", "htmlwidget"))
  } else {
    skip("bupaR or processmapR not available")
  }
})

test_that("ProcessMiner handles empty or invalid data", {
  miner <- ProcessMiner$new()
  
  # Empty data
  empty_data <- tibble(
    case = character(0),
    activity = character(0), 
    timestamp = as.POSIXct(character(0)),
    resource = character(0)
  )
  
  expect_error(miner$discover_dfg(empty_data), "empty|invalid")
})

test_that("ProcessMiner performance analysis works", {
  if (requireNamespace("bupaR", quietly = TRUE)) {
    miner <- ProcessMiner$new()
    test_data <- create_test_event_log()
    
    # Add some variation in timing
    test_data$timestamp[test_data$case == "Case_2"] <- 
      test_data$timestamp[test_data$case == "Case_2"] + hours(2)
    
    loader <- EventLogLoader$new()
    bupar_log <- loader$convert_to_bupar(test_data)
    
    performance <- miner$analyze_case_performance(bupar_log)
    
    expect_s3_class(performance, "data.frame")
    expect_true("case" %in% names(performance))
    expect_true("duration_hours" %in% names(performance))
    expect_true("n_activities" %in% names(performance))
    
    expect_equal(nrow(performance), 3)  # 3 cases
    
    # Case_2 should have longer duration
    case2_duration <- performance$duration_hours[performance$case == "Case_2"]
    other_durations <- performance$duration_hours[performance$case != "Case_2"]
    expect_gt(case2_duration, max(other_durations))
  } else {
    skip("bupaR not available")
  }
})

# Run the tests
if (interactive()) {
  cat("\n🧪 Running ProcessMiner Tests...\n")
  cat("=" * 50, "\n")
  
  if (requireNamespace("bupaR", quietly = TRUE)) {
    test_results <- testthat::test_file("R/tests/test_step2_process_mining.R", reporter = "summary")
    
    if (all(test_results$passed)) {
      cat("✅ All ProcessMiner tests passed!\n")
    } else {
      cat("❌ Some ProcessMiner tests failed.\n")
    }
  } else {
    cat("⚠️ bupaR not available - skipping ProcessMiner tests\n")
  }
}