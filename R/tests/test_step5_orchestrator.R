# Test suite for Step 5: Report Orchestrator
# Tests ReportOrchestrator R6 class functionality

library(testthat)
library(tidyverse)
library(R6)
library(jsonlite)

# Source the module
source("R/core/step5_orchestrator.R")

# Mock LLM responses for testing
create_mock_llm_responses <- function() {
  list(
    "anthropic/claude-3.5-sonnet" = list(
      content = "## Clinical Analysis\n\n1. **Key Findings**: Sepsis progression shows clear patterns with 3 distinct stages.\n2. **Risk Factors**: Early vital sign deterioration and elevated lactate levels.\n3. **Recommendations**: Implement early warning systems and rapid response protocols.\n\n**Model Confidence**: High",
      model = "anthropic/claude-3.5-sonnet",
      tokens_used = 150,
      success = TRUE
    ),
    "openai/gpt-4o" = list(
      content = "## Process Mining Insights\n\n1. **Patient Pathways**: Three main variants identified in sepsis progression.\n2. **Bottlenecks**: Laboratory processing delays contribute to treatment delays.\n3. **Clinical Implications**: Early detection protocols could improve outcomes.\n\n**Analysis Quality**: Comprehensive",
      model = "openai/gpt-4o", 
      tokens_used = 140,
      success = TRUE
    ),
    "google/gemini-pro-1.5" = list(
      content = "## Healthcare Process Analysis\n\n1. **Temporal Patterns**: Sepsis onset typically occurs 12-48 hours post-admission.\n2. **Resource Utilization**: ICU transfers show seasonal variation patterns.\n3. **Quality Metrics**: Overall mortality rates align with published benchmarks.\n\n**Analytical Depth**: Detailed",
      model = "google/gemini-pro-1.5",
      tokens_used = 135,
      success = TRUE
    )
  )
}

create_mock_process_data <- function() {
  list(
    n_cases = 150,
    n_activities = 8,
    avg_case_duration = 3.2,
    sepsis_rate = 0.28,
    bottlenecks = tibble(
      activity = c("Lab_Processing", "Doctor_Consult", "ICU_Transfer"),
      avg_duration_hours = c(4.5, 2.1, 1.8)
    ),
    outcomes = list(
      mortality_rate = 0.15,
      avg_los = 7.2,
      readmission_rate = 0.08
    )
  )
}

# Test ReportOrchestrator class
test_that("ReportOrchestrator initializes correctly", {
  orchestrator <- ReportOrchestrator$new()
  expect_s3_class(orchestrator, "ReportOrchestrator")
  expect_s3_class(orchestrator, "R6")
})

test_that("ReportOrchestrator extracts key insights", {
  orchestrator <- ReportOrchestrator$new()
  
  mock_response <- create_mock_llm_responses()[[1]]
  insights <- orchestrator$extract_key_insights(mock_response$content)
  
  expect_type(insights, "list")
  expect_true("findings" %in% names(insights))
  expect_true("recommendations" %in% names(insights))
  expect_true("clinical_points" %in% names(insights))
  
  expect_gt(length(insights$findings), 0)
  expect_gt(length(insights$recommendations), 0)
})

test_that("ReportOrchestrator identifies consensus points", {
  orchestrator <- ReportOrchestrator$new()
  mock_responses <- create_mock_llm_responses()
  
  consensus <- orchestrator$identify_consensus(mock_responses)
  
  expect_type(consensus, "list")
  expect_true("common_themes" %in% names(consensus))
  expect_true("agreement_score" %in% names(consensus))
  expect_true("consensus_points" %in% names(consensus))
  
  expect_type(consensus$agreement_score, "double")
  expect_gte(consensus$agreement_score, 0)
  expect_lte(consensus$agreement_score, 1)
  expect_gt(length(consensus$common_themes), 0)
})

test_that("ReportOrchestrator finds unique insights", {
  orchestrator <- ReportOrchestrator$new()
  mock_responses <- create_mock_llm_responses()
  
  unique_insights <- orchestrator$identify_unique_insights(mock_responses)
  
  expect_type(unique_insights, "list")
  expect_true(all(names(mock_responses) %in% names(unique_insights)))
  
  # Each model should have some unique insights
  for (model in names(mock_responses)) {
    expect_type(unique_insights[[model]], "character")
    expect_gt(length(unique_insights[[model]]), 0)
  }
})

test_that("ReportOrchestrator calculates model agreement", {
  orchestrator <- ReportOrchestrator$new()
  
  # Test with identical responses (high agreement)
  identical_responses <- list(
    model1 = list(content = "Sepsis progression shows three stages"),
    model2 = list(content = "Sepsis development has three distinct phases"),
    model3 = list(content = "Three-stage sepsis progression pattern observed")
  )
  
  high_agreement <- orchestrator$calculate_model_agreement(identical_responses)
  expect_type(high_agreement, "double")
  expect_gt(high_agreement, 0.5)
  
  # Test with different responses (low agreement)
  different_responses <- list(
    model1 = list(content = "Sepsis progression shows clear patterns"),
    model2 = list(content = "Cardiovascular complications are primary concern"),  
    model3 = list(content = "Resource allocation needs optimization")
  )
  
  low_agreement <- orchestrator$calculate_model_agreement(different_responses)
  expect_type(low_agreement, "double")
  expect_lt(low_agreement, high_agreement)
})

test_that("ReportOrchestrator synthesizes recommendations", {
  orchestrator <- ReportOrchestrator$new()
  mock_responses <- create_mock_llm_responses()
  
  recommendations <- orchestrator$synthesize_recommendations(mock_responses)
  
  expect_type(recommendations, "list")
  expect_true("priority_recommendations" %in% names(recommendations))
  expect_true("supporting_evidence" %in% names(recommendations))
  expect_true("implementation_notes" %in% names(recommendations))
  
  expect_gt(length(recommendations$priority_recommendations), 0)
  expect_type(recommendations$supporting_evidence, "list")
})

test_that("ReportOrchestrator performs quality assessment", {
  orchestrator <- ReportOrchestrator$new()
  mock_responses <- create_mock_llm_responses()
  
  quality_assessment <- orchestrator$assess_response_quality(mock_responses)
  
  expect_type(quality_assessment, "list")
  expect_true("overall_quality_score" %in% names(quality_assessment))
  expect_true("model_scores" %in% names(quality_assessment))
  expect_true("quality_dimensions" %in% names(quality_assessment))
  
  expect_type(quality_assessment$overall_quality_score, "double")
  expect_gte(quality_assessment$overall_quality_score, 0)
  expect_lte(quality_assessment$overall_quality_score, 1)
  
  expect_s3_class(quality_assessment$model_scores, "data.frame")
  expect_true("model" %in% names(quality_assessment$model_scores))
  expect_true("score" %in% names(quality_assessment$model_scores))
})

test_that("ReportOrchestrator creates comprehensive orchestration", {
  orchestrator <- ReportOrchestrator$new()
  mock_responses <- create_mock_llm_responses()
  mock_process_data <- create_mock_process_data()
  
  orchestrated_report <- orchestrator$orchestrate_reports(
    model_results = mock_responses,
    process_data = mock_process_data
  )
  
  expect_type(orchestrated_report, "list")
  
  # Check main sections
  expected_sections <- c(
    "executive_summary",
    "consensus", 
    "unique_insights",
    "recommendations",
    "quality_assessment",
    "model_attribution",
    "metadata"
  )
  
  expect_true(all(expected_sections %in% names(orchestrated_report)))
  
  # Check executive summary
  expect_type(orchestrated_report$executive_summary, "character")
  expect_gt(nchar(orchestrated_report$executive_summary), 100)
  
  # Check consensus section
  expect_type(orchestrated_report$consensus, "list")
  expect_true("agreement_score" %in% names(orchestrated_report$consensus))
  
  # Check recommendations
  expect_type(orchestrated_report$recommendations, "list")
  expect_gt(length(orchestrated_report$recommendations$priority_recommendations), 0)
  
  # Check metadata
  expect_type(orchestrated_report$metadata, "list")
  expect_true("n_models" %in% names(orchestrated_report$metadata))
  expect_equal(orchestrated_report$metadata$n_models, 3)
})

test_that("ReportOrchestrator handles single model input", {
  orchestrator <- ReportOrchestrator$new()
  
  single_response <- list(
    "anthropic/claude-3.5-sonnet" = create_mock_llm_responses()[[1]]
  )
  
  result <- orchestrator$orchestrate_reports(
    model_results = single_response,
    process_data = create_mock_process_data()
  )
  
  expect_type(result, "list")
  expect_equal(result$metadata$n_models, 1)
  
  # Should still have all sections but consensus might be limited
  expect_true("executive_summary" %in% names(result))
  expect_true("unique_insights" %in% names(result))
})

test_that("ReportOrchestrator handles failed model responses", {
  orchestrator <- ReportOrchestrator$new()
  
  mixed_responses <- list(
    "anthropic/claude-3.5-sonnet" = list(
      content = "Valid response with clinical insights.",
      success = TRUE
    ),
    "openai/gpt-4o" = list(
      content = "API Error: Rate limit exceeded",
      success = FALSE,
      error = "Rate limit"
    ),
    "google/gemini-pro-1.5" = list(
      content = "Another valid clinical analysis.",
      success = TRUE
    )
  )
  
  result <- orchestrator$orchestrate_reports(
    model_results = mixed_responses,
    process_data = create_mock_process_data()
  )
  
  expect_type(result, "list")
  expect_equal(result$metadata$n_models, 3)
  expect_equal(result$metadata$successful_models, 2)
  expect_equal(result$metadata$failed_models, 1)
})

test_that("ReportOrchestrator attribution tracking works", {
  orchestrator <- ReportOrchestrator$new()
  mock_responses <- create_mock_llm_responses()
  
  result <- orchestrator$orchestrate_reports(
    model_results = mock_responses,
    process_data = create_mock_process_data()
  )
  
  expect_true("model_attribution" %in% names(result))
  attribution <- result$model_attribution
  
  expect_s3_class(attribution, "data.frame")
  expect_true("model" %in% names(attribution))
  expect_true("contribution_score" %in% names(attribution))
  expect_true("key_contributions" %in% names(attribution))
  
  expect_equal(nrow(attribution), 3)  # Three models
  expect_true(all(attribution$contribution_score >= 0))
  expect_true(all(attribution$contribution_score <= 1))
})

test_that("ReportOrchestrator confidence scoring works", {
  orchestrator <- ReportOrchestrator$new()
  
  # High confidence scenario (multiple models agree)
  high_conf_responses <- list(
    model1 = list(content = "Sepsis progression shows three distinct stages with clear biomarkers"),
    model2 = list(content = "Three-phase sepsis development with identifiable biomarker patterns"),
    model3 = list(content = "Clear three-stage sepsis progression with biomarker indicators")
  )
  
  high_conf_result <- orchestrator$orchestrate_reports(
    model_results = high_conf_responses,
    process_data = create_mock_process_data()
  )
  
  # Low confidence scenario (models disagree)
  low_conf_responses <- list(
    model1 = list(content = "Sepsis shows unpredictable patterns"),
    model2 = list(content = "Cardiovascular complications are unrelated to sepsis timing"),
    model3 = list(content = "Resource constraints affect all patient outcomes equally")
  )
  
  low_conf_result <- orchestrator$orchestrate_reports(
    model_results = low_conf_responses,
    process_data = create_mock_process_data()
  )
  
  expect_gt(high_conf_result$consensus$agreement_score, 
           low_conf_result$consensus$agreement_score)
})

test_that("ReportOrchestrator export functions work", {
  orchestrator <- ReportOrchestrator$new()
  mock_responses <- create_mock_llm_responses()
  
  result <- orchestrator$orchestrate_reports(
    model_results = mock_responses,
    process_data = create_mock_process_data()
  )
  
  # Test markdown export
  markdown_export <- orchestrator$export_to_markdown(result)
  expect_type(markdown_export, "character")
  expect_true(str_detect(markdown_export, "# Executive Summary"))
  expect_true(str_detect(markdown_export, "## Consensus"))
  expect_true(str_detect(markdown_export, "## Recommendations"))
  
  # Test JSON export
  json_export <- orchestrator$export_to_json(result)
  expect_type(json_export, "character")
  
  # Should be valid JSON
  parsed_json <- jsonlite::fromJSON(json_export)
  expect_type(parsed_json, "list")
  expect_true("executive_summary" %in% names(parsed_json))
})

# Integration test
test_that("ReportOrchestrator end-to-end workflow", {
  # Simulate complete workflow
  orchestrator <- ReportOrchestrator$new()
  
  # 1. Mock multi-model analysis results
  model_results <- create_mock_llm_responses()
  process_data <- create_mock_process_data()
  
  # 2. Orchestrate
  orchestrated <- orchestrator$orchestrate_reports(model_results, process_data)
  
  # 3. Export to different formats
  markdown_report <- orchestrator$export_to_markdown(orchestrated)
  json_report <- orchestrator$export_to_json(orchestrated)
  
  # 4. Verify complete workflow
  expect_type(orchestrated, "list")
  expect_type(markdown_report, "character")
  expect_type(json_report, "character")
  
  # Should contain key clinical insights
  expect_true(str_detect(markdown_report, "[Ss]epsis"))
  expect_true(str_detect(markdown_report, "[Rr]ecommend"))
  
  # JSON should be parseable
  expect_silent(jsonlite::fromJSON(json_report))
})

# Run the tests
if (interactive()) {
  cat("\n🧪 Running ReportOrchestrator Tests...\n")
  cat("=" * 50, "\n")
  
  test_results <- testthat::test_file("R/tests/test_step5_orchestrator.R", reporter = "summary")
  
  if (all(test_results$passed)) {
    cat("✅ All ReportOrchestrator tests passed!\n")
  } else {
    cat("❌ Some ReportOrchestrator tests failed.\n")
  }
}