# Test Suite for Step 3: LLM Integration
# ======================================
# Tests for the LLMAnalyzer R6 class and related functions

# Load required libraries for testing
library(testthat)
library(httr2)
library(jsonlite)
library(glue)

# Source the LLM integration module
source("R/core/step3_llm_integration.R")

# Create test process data
create_llm_test_data <- function() {
  list(
    num_cases = 100,
    num_events = 450,
    num_activities = 8,
    avg_duration_hours = 24.5,
    min_duration_hours = 2.0,
    max_duration_hours = 72.0,
    top_variant_coverage = "35%",
    date_range = list(
      start = "2024-01-01",
      end = "2024-01-31"
    ),
    top_5_activities = list(
      list(activity = "Admission", count = 100),
      list(activity = "Blood Test", count = 85),
      list(activity = "Consultation", count = 78),
      list(activity = "Medication", count = 65),
      list(activity = "Discharge", count = 95)
    ),
    critical_transitions = c(
      "Emergency → ICU admission (high priority)",
      "Fever → Blood culture (diagnostic)",
      "Infection markers → Antibiotic therapy"
    ),
    description = "Sepsis progression analysis of 100 patient cases",
    key_findings = c(
      "Average time to antibiotic: 4.2 hours",
      "ICU admission rate: 25%",
      "Most critical pathway: Emergency → Triage → Blood Culture"
    )
  )
}

# Mock successful API response
create_mock_api_response <- function() {
  list(
    choices = list(
      list(
        message = list(
          content = "# Clinical Analysis Report

## Key Findings
1. The sepsis progression shows typical patterns
2. Average case duration of 24.5 hours indicates moderate complexity
3. Critical transitions identify key intervention points

## Recommendations  
1. Implement early warning systems
2. Optimize blood culture timing
3. Standardize antibiotic protocols"
        )
      )
    ),
    usage = list(
      total_tokens = 150,
      prompt_tokens = 100,
      completion_tokens = 50
    )
  )
}

# Test: LLMAnalyzer initialization
test_that("LLMAnalyzer initializes correctly", {
  # Test successful initialization
  analyzer <- LLMAnalyzer$new("test-api-key")
  
  expect_true(inherits(analyzer, "LLMAnalyzer"))
  expect_equal(analyzer$api_key, "test-api-key")
  expect_equal(analyzer$base_url, "https://openrouter.ai/api/v1")
  expect_true(is.list(analyzer$AVAILABLE_MODELS))
})

test_that("LLMAnalyzer requires API key", {
  expect_error(
    LLMAnalyzer$new(NULL),
    "OpenRouter API key is required"
  )
  
  expect_error(
    LLMAnalyzer$new(""),
    "OpenRouter API key is required"
  )
})

# Test: Clinical prompt creation
test_that("create_clinical_prompt works correctly", {
  analyzer <- LLMAnalyzer$new("test-key")
  test_data <- create_llm_test_data()
  
  # Test sepsis use case
  prompt <- analyzer$create_clinical_prompt(test_data, "sepsis")
  
  expect_true(is.character(prompt))
  expect_true(nchar(prompt) > 0)
  expect_true(grepl("sepsis", prompt, ignore.case = TRUE))
  expect_true(grepl("100", prompt))  # Should include num_cases
  expect_true(grepl("24.5", prompt))  # Should include avg_duration
  expect_true(grepl("Admission", prompt))  # Should include activities
  
  # Test different use case
  infection_prompt <- analyzer$create_clinical_prompt(test_data, "infection")
  expect_true(grepl("infection", infection_prompt, ignore.case = TRUE))
  expect_false(identical(prompt, infection_prompt))
})

# Test: Model querying (mocked)
test_that("query_model handles responses correctly", {
  analyzer <- LLMAnalyzer$new("test-key")
  
  # Mock successful response using local testing (skip API call)
  skip_if_not(interactive(), "Skipping API tests in non-interactive mode")
  
  messages <- list(list(role = "user", content = "Test prompt"))
  
  # Test with invalid model (should return error)
  result <- analyzer$query_model("invalid/model", messages)
  expect_true("error" %in% names(result))
})

# Test: Multiple model analysis (mocked)
test_that("analyze_with_multiple_models works correctly", {
  analyzer <- LLMAnalyzer$new("test-key")
  
  # Mock the query_model method to avoid API calls
  analyzer$query_model <- function(model_name, messages, temperature = 0.7, max_tokens = NULL) {
    # Return mock successful response
    create_mock_api_response()
  }
  
  prompt <- "Test clinical analysis prompt"
  models <- c("deepseek")  # Use single model for testing
  
  results <- analyzer$analyze_with_multiple_models(prompt, models, delay_seconds = 0)
  
  expect_true(is.list(results))
  expect_true("deepseek" %in% names(results))
  expect_equal(results$deepseek$status, "success")
  expect_true(nchar(results$deepseek$content) > 0)
  expect_true(results$deepseek$tokens > 0)
})

test_that("analyze_with_multiple_models handles errors", {
  analyzer <- LLMAnalyzer$new("test-key")
  
  # Mock the query_model method to return errors
  analyzer$query_model <- function(model_name, messages, temperature = 0.7, max_tokens = NULL) {
    list(error = "API Error")
  }
  
  prompt <- "Test prompt"
  results <- analyzer$analyze_with_multiple_models(prompt, c("deepseek"))
  
  expect_true(is.list(results))
  expect_equal(results$deepseek$status, "error")
})

# Test: Clinical report generation
test_that("generate_clinical_report works correctly", {
  analyzer <- LLMAnalyzer$new("test-key")
  test_data <- create_llm_test_data()
  
  model_response <- "# Clinical Analysis

## Key Findings
1. Sepsis progression patterns identified
2. Critical intervention points mapped
3. Resource utilization optimized

## Recommendations
1. Early warning implementation
2. Protocol standardization"

  metadata <- list(
    analysis_type = "Sepsis Analysis",
    ai_model = "test-model"
  )
  
  report <- analyzer$generate_clinical_report(test_data, model_response, metadata)
  
  expect_true(is.character(report))
  expect_true(nchar(report) > 0)
  expect_true(grepl("Clinical Process Mining Analysis Report", report))
  expect_true(grepl("100", report))  # Should include case count
  expect_true(grepl("24.5", report))  # Should include duration
  expect_true(grepl("Sepsis Analysis", report))  # Should include metadata
  expect_true(grepl(model_response, report, fixed = TRUE))  # Should include LLM response
})

# Test: Results saving
test_that("save_analysis_results works correctly", {
  analyzer <- LLMAnalyzer$new("test-key")
  
  # Create test results
  results <- list(
    deepseek = list(
      status = "success",
      content = "Test analysis content",
      model = "deepseek/deepseek-r1",
      tokens = 100
    ),
    claude = list(
      status = "error", 
      content = "API Error",
      model = "anthropic/claude-sonnet-4",
      tokens = 0
    )
  )
  
  # Save to temp directory
  temp_dir <- tempfile()
  saved_files <- analyzer$save_analysis_results(results, temp_dir)
  
  expect_true(is.list(saved_files))
  expect_true(dir.exists(temp_dir))
  expect_true("deepseek" %in% names(saved_files))  # Successful model should be saved
  expect_false("claude" %in% names(saved_files))   # Error model should not be saved
  expect_true("summary" %in% names(saved_files))   # Summary should always be saved
  
  # Check files exist
  expect_true(file.exists(saved_files$deepseek))
  expect_true(file.exists(saved_files$summary))
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

# Test: Functional interface - analyze_with_llm
test_that("analyze_with_llm functional interface works", {
  skip_if_not(interactive(), "Skipping API tests in non-interactive mode")
  
  test_data <- create_llm_test_data()
  
  # This would require a real API key, so we'll skip in automated testing
  # In practice: results <- analyze_with_llm(test_data, "real-api-key", c("deepseek"))
  # expect_true(is.list(results))
})

# Test: Functional interface - generate_llm_report 
test_that("generate_llm_report functional interface works", {
  test_data <- create_llm_test_data()
  
  # Create mock LLM results
  llm_results <- list(
    deepseek = list(
      status = "success",
      content = "Clinical analysis content here",
      model = "deepseek/deepseek-r1"
    )
  )
  
  report <- generate_llm_report(test_data, llm_results, "deepseek")
  
  expect_true(is.character(report))
  expect_true(nchar(report) > 0)
  expect_true(grepl("Clinical Process Mining Analysis Report", report))
})

test_that("generate_llm_report handles errors correctly", {
  test_data <- create_llm_test_data()
  
  # Test with missing model
  llm_results <- list(deepseek = list(status = "success", content = "test"))
  expect_error(
    generate_llm_report(test_data, llm_results, "nonexistent"),
    "not found in results"
  )
  
  # Test with failed model
  failed_results <- list(deepseek = list(status = "error", content = "API failed"))
  expect_error(
    generate_llm_report(test_data, failed_results, "deepseek"),
    "analysis failed"
  )
})

# Test: Model availability
test_that("AVAILABLE_MODELS contains expected models", {
  analyzer <- LLMAnalyzer$new("test-key")
  
  expect_true("claude" %in% names(analyzer$AVAILABLE_MODELS))
  expect_true("gpt4" %in% names(analyzer$AVAILABLE_MODELS))
  expect_true("gemini" %in% names(analyzer$AVAILABLE_MODELS))
  expect_true("deepseek" %in% names(analyzer$AVAILABLE_MODELS))
  expect_true("grok" %in% names(analyzer$AVAILABLE_MODELS))
  
  # Check that model names are properly formatted
  expect_true(grepl("anthropic/", analyzer$AVAILABLE_MODELS$claude))
  expect_true(grepl("openai/", analyzer$AVAILABLE_MODELS$gpt4))
})

# Print test completion message
cat("✅ Step 3 LLM Integration tests completed\n")