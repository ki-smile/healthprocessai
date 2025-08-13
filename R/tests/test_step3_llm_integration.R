# Test suite for Step 3: LLM Integration
# Tests LLMAnalyzer R6 class functionality

library(testthat)
library(tidyverse)
library(R6)
library(httr2)
library(jsonlite)

# Source the module
source("R/core/step3_llm_integration.R")

# Mock API responses for testing
mock_openrouter_response <- function(content = "Test response from AI model") {
  list(
    choices = list(
      list(
        message = list(
          content = content,
          role = "assistant"
        ),
        finish_reason = "stop"
      )
    ),
    usage = list(
      prompt_tokens = 100,
      completion_tokens = 50,
      total_tokens = 150
    ),
    model = "anthropic/claude-3.5-sonnet"
  )
}

# Test LLMAnalyzer class
test_that("LLMAnalyzer initializes correctly", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  expect_s3_class(analyzer, "LLMAnalyzer")
  expect_s3_class(analyzer, "R6")
  expect_equal(analyzer$api_key, "test_key")
  expect_equal(analyzer$base_url, "https://openrouter.ai/api/v1")
})

test_that("LLMAnalyzer validates API key", {
  # Valid key
  expect_silent(LLMAnalyzer$new(api_key = "sk-test123"))
  
  # Invalid key (empty)
  expect_error(LLMAnalyzer$new(api_key = ""), "API key cannot be empty")
  
  # Invalid key (NULL)
  expect_error(LLMAnalyzer$new(api_key = NULL), "API key cannot be empty")
})

test_that("LLMAnalyzer formats prompts correctly", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  # Test clinical prompt formatting
  process_data <- "Process analysis results here"
  clinical_context <- "Sepsis analysis"
  
  formatted <- analyzer$format_clinical_prompt(process_data, clinical_context)
  
  expect_type(formatted, "character")
  expect_true(str_detect(formatted, "Process analysis results here"))
  expect_true(str_detect(formatted, "Sepsis analysis"))
  expect_true(str_detect(formatted, "clinical insights"))
})

test_that("LLMAnalyzer handles model validation", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  # Valid models
  valid_models <- c(
    "anthropic/claude-3.5-sonnet",
    "openai/gpt-4o",
    "google/gemini-pro-1.5",
    "deepseek/deepseek-r1",
    "x-ai/grok-2-1212"
  )
  
  for (model in valid_models) {
    expect_true(analyzer$validate_model(model))
  }
  
  # Invalid model
  expect_false(analyzer$validate_model("invalid/model"))
})

test_that("LLMAnalyzer constructs request body correctly", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  request_body <- analyzer$create_request_body(
    model = "anthropic/claude-3.5-sonnet",
    prompt = "Test prompt",
    max_tokens = 500,
    temperature = 0.7
  )
  
  expect_type(request_body, "list")
  expect_equal(request_body$model, "anthropic/claude-3.5-sonnet")
  expect_equal(request_body$max_tokens, 500)
  expect_equal(request_body$temperature, 0.7)
  expect_equal(length(request_body$messages), 1)
  expect_equal(request_body$messages[[1]]$role, "user")
  expect_equal(request_body$messages[[1]]$content, "Test prompt")
})

test_that("LLMAnalyzer parses API responses correctly", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  mock_response <- mock_openrouter_response("This is a test clinical insight.")
  
  parsed <- analyzer$parse_api_response(mock_response)
  
  expect_type(parsed, "list")
  expect_equal(parsed$content, "This is a test clinical insight.")
  expect_equal(parsed$model, "anthropic/claude-3.5-sonnet")
  expect_equal(parsed$tokens_used, 150)
  expect_true(parsed$success)
})

test_that("LLMAnalyzer handles API errors gracefully", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  # Test error response parsing
  error_response <- list(
    error = list(
      message = "Invalid API key",
      type = "authentication_error",
      code = 401
    )
  )
  
  parsed_error <- analyzer$parse_api_response(error_response)
  
  expect_false(parsed_error$success)
  expect_true(str_detect(parsed_error$error, "Invalid API key"))
})

test_that("LLMAnalyzer generates clinical reports", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  # Mock process results
  process_results <- list(
    n_cases = 100,
    n_activities = 5,
    avg_duration = 2.5,
    bottlenecks = tibble(
      activity = c("Lab_Test", "Doctor_Consult"),
      avg_duration_hours = c(4.2, 2.1)
    )
  )
  
  # Test report generation (would normally call API)
  report_structure <- analyzer$format_clinical_prompt(
    jsonlite::toJSON(process_results, auto_unbox = TRUE),
    "Sepsis progression analysis"
  )
  
  expect_type(report_structure, "character")
  expect_true(str_detect(report_structure, "100"))  # n_cases
  expect_true(str_detect(report_structure, "Lab_Test"))  # bottleneck
})

test_that("LLMAnalyzer handles multiple model analysis", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  models <- c("anthropic/claude-3.5-sonnet", "openai/gpt-4o")
  
  # Test structure for multiple model analysis
  for (model in models) {
    expect_true(analyzer$validate_model(model))
    
    request_body <- analyzer$create_request_body(
      model = model,
      prompt = "Test prompt",
      max_tokens = 200
    )
    
    expect_equal(request_body$model, model)
    expect_type(request_body, "list")
  }
})

test_that("LLMAnalyzer rate limiting works", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  # Test rate limiting delay calculation
  expect_type(analyzer$rate_limit_delay, "numeric")
  expect_gte(analyzer$rate_limit_delay, 0.5)  # Should have some delay
  expect_lte(analyzer$rate_limit_delay, 5.0)  # But not too long
})

test_that("LLMAnalyzer token counting estimates work", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  # Test basic token estimation
  short_text <- "Hello world"
  long_text <- paste(rep("This is a test sentence.", 50), collapse = " ")
  
  short_tokens <- analyzer$estimate_tokens(short_text)
  long_tokens <- analyzer$estimate_tokens(long_text)
  
  expect_type(short_tokens, "numeric")
  expect_type(long_tokens, "numeric")
  expect_lt(short_tokens, long_tokens)
  expect_gt(short_tokens, 0)
})

test_that("LLMAnalyzer handles timeout and retry logic", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  # Test retry parameters
  expect_type(analyzer$max_retries, "numeric")
  expect_gte(analyzer$max_retries, 1)
  expect_lte(analyzer$max_retries, 5)
  
  expect_type(analyzer$retry_delay, "numeric")
  expect_gte(analyzer$retry_delay, 0.5)
})

test_that("LLMAnalyzer clinical context templates work", {
  analyzer <- LLMAnalyzer$new(api_key = "test_key")
  
  contexts <- c("sepsis", "organ_failure", "infection", "general")
  
  for (context in contexts) {
    prompt <- analyzer$format_clinical_prompt("test data", context)
    expect_type(prompt, "character")
    expect_gt(nchar(prompt), 50)  # Should be substantive
  }
})

# Integration test helper (requires actual API key)
test_that("LLMAnalyzer integration test (requires API key)", {
  skip_if(Sys.getenv("OPENROUTER_API_KEY") == "", "No API key provided")
  skip_if_offline("API tests require internet connection")
  
  api_key <- Sys.getenv("OPENROUTER_API_KEY")
  analyzer <- LLMAnalyzer$new(api_key = api_key)
  
  # Simple test query
  response <- analyzer$query_model(
    model = "anthropic/claude-3.5-sonnet",
    prompt = "What is process mining? Answer in one sentence.",
    max_tokens = 50
  )
  
  expect_type(response, "list")
  expect_true(response$success)
  expect_true(nchar(response$content) > 10)
  expect_gt(response$tokens_used, 0)
})

# Run the tests
if (interactive()) {
  cat("\n🧪 Running LLMAnalyzer Tests...\n")
  cat("=" * 50, "\n")
  
  test_results <- testthat::test_file("R/tests/test_step3_llm_integration.R", reporter = "summary")
  
  if (all(test_results$passed)) {
    cat("✅ All LLMAnalyzer tests passed!\n")
  } else {
    cat("❌ Some LLMAnalyzer tests failed.\n")
  }
  
  # Note about integration tests
  if (Sys.getenv("OPENROUTER_API_KEY") == "") {
    cat("ℹ️ Set OPENROUTER_API_KEY environment variable to run integration tests\n")
  }
}