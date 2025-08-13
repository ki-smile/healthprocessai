# Test Suite for Step 5: Report Orchestrator
# ==========================================
# Tests for the ReportOrchestrator R6 class and related functions

# Load required libraries for testing
library(testthat)
library(R6)
library(glue)
library(stringr)
library(jsonlite)

# Source the orchestrator module
source("R/core/step5_orchestrator.R")

# Create sample reports for testing
create_test_reports <- function() {
  reports <- list(
    "claude" = "# Clinical Analysis
## Key Findings
Early intervention critical for patient outcomes. 
Clinical evidence shows 40% improvement with timely care.
Recommend immediate implementation of protocols.

## Recommendations
1. Establish rapid response protocols
2. Train clinical staff on guidelines
3. Monitor compliance metrics",
    
    "gemini" = "# Innovative Insights  
## Novel Hypotheses
Propose \"cascade prevention\" model for patient care.
Unique biomarker patterns suggest new therapeutic targets.
Revolutionary approach to risk stratification needed.

## Future Directions
1. Investigate genetic markers
2. Develop personalized treatments
3. Research novel interventions",
    
    "deepseek" = "# Practical Summary
## Statistics
- 150 cases analyzed
- 25% improvement in outcomes
- $50K cost savings per year

## Action Items
1. Deploy alert systems (3 months)
2. Update protocols (1 month) 
3. Measure results (ongoing)"
  )
  
  return(reports)
}

# Create test case info
create_test_case_info <- function() {
  return(list(
    title = "Test Case Analysis",
    description = "healthcare process mining test case",
    date_range = "2024-01-01 to 2024-03-31"
  ))
}

# Test: ReportOrchestrator initialization
test_that("ReportOrchestrator initializes correctly", {
  # Test basic initialization
  orchestrator <- ReportOrchestrator$new()
  
  expect_true(inherits(orchestrator, "ReportOrchestrator"))
  expect_true(is.character(orchestrator$consolidation_prompt_template))
  expect_true(nchar(orchestrator$consolidation_prompt_template) > 0)
  
  # Test initialization with API key
  orchestrator_with_key <- ReportOrchestrator$new("test-api-key")
  expect_equal(orchestrator_with_key$api_key, "test-api-key")
})

# Test: Model agreement analysis
test_that("analyze_model_agreement works correctly", {
  orchestrator <- ReportOrchestrator$new()
  reports <- create_test_reports()
  
  agreement <- orchestrator$analyze_model_agreement(reports)
  
  expect_true(is.list(agreement))
  expect_true("common_themes" %in% names(agreement))
  expect_true("unique_insights" %in% names(agreement))
  expect_true("agreement_score" %in% names(agreement))
  expect_true("total_themes" %in% names(agreement))
  expect_true("models_analyzed" %in% names(agreement))
  
  expect_true(is.numeric(agreement$agreement_score))
  expect_true(agreement$agreement_score >= 0 && agreement$agreement_score <= 1)
  expect_equal(length(agreement$models_analyzed), 3)
})

test_that("analyze_model_agreement handles edge cases", {
  orchestrator <- ReportOrchestrator$new()
  
  # Test with empty reports
  empty_reports <- list()
  expect_error(
    orchestrator$analyze_model_agreement(empty_reports),
    NA  # Should handle gracefully
  )
  
  # Test with single report
  single_report <- list("model1" = "Test content")
  agreement_single <- orchestrator$analyze_model_agreement(single_report)
  expect_true(is.list(agreement_single))
  expect_equal(length(agreement_single$models_analyzed), 1)
})

# Test: Attribution summary generation
test_that("generate_attribution_summary works correctly", {
  orchestrator <- ReportOrchestrator$new()
  reports <- create_test_reports()
  
  attribution <- orchestrator$generate_attribution_summary(reports)
  
  expect_true(is.list(attribution))
  expect_true("model_scores" %in% names(attribution))
  expect_true("best_clinical_analysis" %in% names(attribution))
  expect_true("best_innovative_insights" %in% names(attribution))
  expect_true("best_actionable_recommendations" %in% names(attribution))
  
  # Check that all models are scored
  expect_equal(length(attribution$model_scores), 3)
  for (model in names(reports)) {
    expect_true(model %in% names(attribution$model_scores))
    
    scores <- attribution$model_scores[[model]]
    expect_true("clinical_accuracy" %in% names(scores))
    expect_true("innovation" %in% names(scores))
    expect_true("actionability" %in% names(scores))
    expect_true("clarity" %in% names(scores))
    
    # All scores should be between 0 and 1
    expect_true(scores$clinical_accuracy >= 0 && scores$clinical_accuracy <= 1)
    expect_true(scores$innovation >= 0 && scores$innovation <= 1)
    expect_true(scores$actionability >= 0 && scores$actionability <= 1)
    expect_true(scores$clarity >= 0 && scores$clarity <= 1)
  }
})

# Test: Report consolidation
test_that("consolidate_reports works correctly", {
  orchestrator <- ReportOrchestrator$new()
  reports <- create_test_reports()
  case_info <- create_test_case_info()
  
  # Test template-based consolidation
  consolidated <- orchestrator$consolidate_reports(reports, case_info, use_live_api = FALSE)
  
  expect_true(is.character(consolidated))
  expect_true(nchar(consolidated) > 0)
  expect_true(stringr::str_detect(consolidated, "Orchestrated Process Mining Analysis"))
  expect_true(stringr::str_detect(consolidated, case_info$title))
  expect_true(stringr::str_detect(consolidated, "Executive Summary"))
  expect_true(stringr::str_detect(consolidated, "Key Findings"))
  expect_true(stringr::str_detect(consolidated, "Recommendations"))
  
  # Check that model names appear in the report (attribution)
  for (model_name in names(reports)) {
    expect_true(stringr::str_detect(consolidated, stringr::str_to_title(model_name)))
  }
})

test_that("consolidate_reports handles different inputs", {
  orchestrator <- ReportOrchestrator$new()
  
  # Test with minimal case info
  reports <- create_test_reports()
  minimal_case <- list(title = "Test")
  
  consolidated_minimal <- orchestrator$consolidate_reports(reports, minimal_case)
  expect_true(is.character(consolidated_minimal))
  expect_true(nchar(consolidated_minimal) > 0)
  
  # Test with single report
  single_report <- list("model1" = "Test content with clinical evidence and recommendations")
  consolidated_single <- orchestrator$consolidate_reports(single_report, minimal_case)
  expect_true(is.character(consolidated_single))
  expect_true(nchar(consolidated_single) > 0)
})

test_that("consolidate_reports requires valid inputs", {
  orchestrator <- ReportOrchestrator$new()
  case_info <- create_test_case_info()
  
  # Test with empty reports
  expect_error(
    orchestrator$consolidate_reports(list(), case_info),
    "No reports provided for consolidation"
  )
})

# Test: File operations
test_that("save_orchestrated_report works correctly", {
  orchestrator <- ReportOrchestrator$new()
  
  test_content <- "# Test Report\nThis is a test report content."
  temp_dir <- tempfile()
  
  saved_path <- orchestrator$save_orchestrated_report(
    test_content, 
    "test_case", 
    temp_dir
  )
  
  expect_true(file.exists(saved_path))
  expect_true(dir.exists(temp_dir))
  
  # Read back and verify content
  saved_content <- readLines(saved_path)
  expect_true(any(stringr::str_detect(saved_content, "Test Report")))
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

test_that("export_consolidation_analysis works correctly", {
  orchestrator <- ReportOrchestrator$new()
  reports <- create_test_reports()
  case_info <- create_test_case_info()
  consolidated <- "Test consolidated report"
  
  temp_dir <- tempfile()
  
  analysis_path <- orchestrator$export_consolidation_analysis(
    reports,
    consolidated,
    case_info,
    temp_dir
  )
  
  expect_true(file.exists(analysis_path))
  expect_true(stringr::str_detect(analysis_path, "\\.json$"))
  
  # Read and verify JSON structure
  analysis_data <- jsonlite::fromJSON(analysis_path)
  expect_true("case_info" %in% names(analysis_data))
  expect_true("models_analyzed" %in% names(analysis_data))
  expect_true("agreement_analysis" %in% names(analysis_data))
  expect_true("attribution_summary" %in% names(analysis_data))
  expect_true("consolidation_stats" %in% names(analysis_data))
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

# Test: Functional interfaces
test_that("orchestrate_reports functional interface works", {
  reports <- create_test_reports()
  case_info <- create_test_case_info()
  
  consolidated <- orchestrate_reports(reports, case_info)
  
  expect_true(is.character(consolidated))
  expect_true(nchar(consolidated) > 0)
  expect_true(stringr::str_detect(consolidated, "Orchestrated Process Mining Analysis"))
})

test_that("analyze_model_consensus functional interface works", {
  reports <- create_test_reports()
  
  consensus <- analyze_model_consensus(reports)
  
  expect_true(is.list(consensus))
  expect_true("agreement_score" %in% names(consensus))
  expect_true("common_themes" %in% names(consensus))
  expect_true(is.numeric(consensus$agreement_score))
})

test_that("complete_orchestration_analysis functional interface works", {
  reports <- create_test_reports()
  case_info <- create_test_case_info()
  temp_dir <- tempfile()
  
  results <- complete_orchestration_analysis(reports, case_info, temp_dir)
  
  expect_true(is.list(results))
  expect_true("consolidated_report" %in% names(results))
  expect_true("agreement_analysis" %in% names(results))
  expect_true("attribution_summary" %in% names(results))
  expect_true("report_file" %in% names(results))
  expect_true("analysis_file" %in% names(results))
  
  # Check files were created
  expect_true(file.exists(results$report_file))
  expect_true(file.exists(results$analysis_file))
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

# Test: Scoring methods (private functions tested indirectly)
test_that("scoring methods work correctly", {
  orchestrator <- ReportOrchestrator$new()
  
  # Create reports with different characteristics
  clinical_report <- "Clinical evidence shows significant improvements. 
                     Medical guidelines recommend immediate intervention. 
                     Study results demonstrate 95% statistical significance."
  
  innovative_report <- "Novel hypothesis suggests unique therapeutic approach.
                       Innovative biomarker constellation proposed.
                       Future research should investigate revolutionary methods."
  
  actionable_report <- "Recommend immediate implementation of protocols.
                       Action plan: 1) Deploy systems 2) Train staff 3) Monitor results.
                       Urgent priority for patient safety improvement."
  
  test_reports <- list(
    "clinical" = clinical_report,
    "innovative" = innovative_report,
    "actionable" = actionable_report
  )
  
  attribution <- orchestrator$generate_attribution_summary(test_reports)
  
  # Clinical report should score high on clinical accuracy
  clinical_scores <- attribution$model_scores$clinical
  expect_true(clinical_scores$clinical_accuracy > 0.5)
  
  # Innovative report should score high on innovation
  innovative_scores <- attribution$model_scores$innovative
  expect_true(innovative_scores$innovation > 0.5)
  
  # Actionable report should score high on actionability
  actionable_scores <- attribution$model_scores$actionable
  expect_true(actionable_scores$actionability > 0.5)
})

# Print test completion message
cat("✅ Step 5 Report Orchestrator tests completed\n")