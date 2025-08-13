# Test suite for Report Generator
# Tests ReportGenerator R6 class functionality

library(testthat)
library(tidyverse)
library(R6)

# Source the module
source("R/core/report_generator.R")

# Mock report data for testing
create_mock_report_data <- function() {
  list(
    title = "Sepsis Patient Journey Analysis",
    subtitle = "Process Mining Report with AI Insights",
    date = Sys.Date(),
    author = "HealthProcessAI",
    organization = "SMAILE Lab, Karolinska Institutet",
    executive_summary = "This analysis reveals key patterns in sepsis progression with three distinct phases and identifies critical intervention points.",
    
    process_analysis = list(
      n_cases = 250,
      n_activities = 12,
      avg_case_duration = 4.2,
      top_activities = tibble(
        activity = c("Vital_Signs_Check", "Lab_Test", "Doctor_Assessment", "Medication_Admin"),
        frequency = c(1250, 890, 720, 650)
      ),
      bottlenecks = tibble(
        activity = c("Lab_Processing", "Doctor_Consult"),
        avg_duration_hours = c(3.2, 1.8),
        impact_score = c(0.85, 0.72)
      )
    ),
    
    clinical_insights = list(
      key_findings = c(
        "Early vital sign deterioration precedes sepsis onset by 6-12 hours",
        "Lactate elevation > 2.0 mmol/L strongly predicts sepsis development", 
        "Three distinct patient pathways identified with different outcomes"
      ),
      risk_factors = c(
        "Age > 65 years",
        "Comorbid diabetes",
        "Delayed antibiotic administration"
      ),
      recommendations = c(
        "Implement automated early warning system",
        "Reduce laboratory processing delays",
        "Standardize sepsis response protocols"
      )
    ),
    
    model_analysis = list(
      models_consulted = c("Claude-3.5", "GPT-4", "Gemini-Pro"),
      consensus_score = 0.87,
      agreement_areas = c("Early detection importance", "Protocol standardization need"),
      unique_insights = list(
        "Claude-3.5" = "Seasonal variation in sepsis severity patterns",
        "GPT-4" = "Resource allocation inefficiencies during night shifts",
        "Gemini-Pro" = "Correlation between staffing levels and outcomes"
      )
    ),
    
    statistical_summary = tibble(
      metric = c("Cases Analyzed", "Sepsis Rate", "Mortality Rate", "Avg LOS", "Readmission Rate"),
      value = c("250", "28%", "15%", "7.2 days", "8%"),
      benchmark = c("-", "25-30%", "10-20%", "5-10 days", "5-15%"),
      status = c("✓", "Within Range", "Within Range", "Within Range", "Within Range")
    )
  )
}

# Test ReportGenerator class
test_that("ReportGenerator initializes correctly", {
  generator <- ReportGenerator$new()
  expect_s3_class(generator, "ReportGenerator")
  expect_s3_class(generator, "R6")
})

test_that("ReportGenerator creates markdown report", {
  generator <- ReportGenerator$new()
  mock_data <- create_mock_report_data()
  
  markdown_report <- generator$generate_markdown_report(mock_data)
  
  expect_type(markdown_report, "character")
  expect_gt(nchar(markdown_report), 1000)  # Should be substantial
  
  # Check for key sections
  expect_true(str_detect(markdown_report, "# Sepsis Patient Journey Analysis"))
  expect_true(str_detect(markdown_report, "## Executive Summary"))
  expect_true(str_detect(markdown_report, "## Process Analysis"))
  expect_true(str_detect(markdown_report, "## Clinical Insights"))
  expect_true(str_detect(markdown_report, "## Model Analysis"))
  
  # Check for data inclusion
  expect_true(str_detect(markdown_report, "250"))  # n_cases
  expect_true(str_detect(markdown_report, "4.2"))  # avg_case_duration
  expect_true(str_detect(markdown_report, "Lab_Processing"))  # bottleneck
})

test_that("ReportGenerator creates HTML report", {
  if (requireNamespace("rmarkdown", quietly = TRUE)) {
    generator <- ReportGenerator$new()
    mock_data <- create_mock_report_data()
    
    # Create temporary directory for test
    temp_dir <- tempdir()
    output_file <- file.path(temp_dir, "test_report.html")
    
    result <- generator$generate_html_report(mock_data, output_file)
    
    expect_true(result$success)
    expect_true(file.exists(output_file))
    
    # Read and check HTML content
    html_content <- readLines(output_file, warn = FALSE)
    html_content <- paste(html_content, collapse = " ")
    
    expect_true(str_detect(html_content, "<html"))
    expect_true(str_detect(html_content, "Sepsis Patient Journey"))
    expect_true(str_detect(html_content, "SMAILE Lab"))
    
    # Clean up
    if (file.exists(output_file)) file.remove(output_file)
  } else {
    skip("rmarkdown not available")
  }
})

test_that("ReportGenerator creates PDF report", {
  if (requireNamespace("rmarkdown", quietly = TRUE)) {
    generator <- ReportGenerator$new()
    mock_data <- create_mock_report_data()
    
    temp_dir <- tempdir()
    output_file <- file.path(temp_dir, "test_report.pdf")
    
    # PDF generation might fail without LaTeX, so we expect either success or graceful failure
    result <- generator$generate_pdf_report(mock_data, output_file)
    
    expect_type(result, "list")
    expect_true("success" %in% names(result))
    
    if (result$success) {
      expect_true(file.exists(output_file))
      # Clean up
      if (file.exists(output_file)) file.remove(output_file)
    } else {
      # Should provide informative error message
      expect_true("error" %in% names(result))
      expect_type(result$error, "character")
    }
  } else {
    skip("rmarkdown not available")
  }
})

test_that("ReportGenerator creates Word document", {
  if (requireNamespace("rmarkdown", quietly = TRUE)) {
    generator <- ReportGenerator$new()
    mock_data <- create_mock_report_data()
    
    temp_dir <- tempdir()
    output_file <- file.path(temp_dir, "test_report.docx")
    
    result <- generator$generate_word_report(mock_data, output_file)
    
    expect_type(result, "list")
    expect_true("success" %in% names(result))
    
    if (result$success) {
      expect_true(file.exists(output_file))
      # Clean up
      if (file.exists(output_file)) file.remove(output_file)
    }
  } else {
    skip("rmarkdown not available")
  }
})

test_that("ReportGenerator formats tables correctly", {
  generator <- ReportGenerator$new()
  
  test_table <- tibble(
    metric = c("Cases", "Activities", "Duration"),
    value = c("250", "12", "4.2 hours"),
    status = c("Good", "Normal", "Within Range")
  )
  
  formatted_table <- generator$format_table_for_markdown(test_table)
  
  expect_type(formatted_table, "character")
  expect_true(str_detect(formatted_table, "\\|"))  # Markdown table format
  expect_true(str_detect(formatted_table, "metric"))  # Column header
  expect_true(str_detect(formatted_table, "250"))    # Data value
})

test_that("ReportGenerator creates visualizations", {
  generator <- ReportGenerator$new()
  mock_data <- create_mock_report_data()
  
  # Test activity frequency chart
  activity_chart <- generator$create_activity_frequency_chart(
    mock_data$process_analysis$top_activities
  )
  
  expect_s3_class(activity_chart, "ggplot")
  
  # Test bottleneck analysis chart
  bottleneck_chart <- generator$create_bottleneck_chart(
    mock_data$process_analysis$bottlenecks
  )
  
  expect_s3_class(bottleneck_chart, "ggplot")
})

test_that("ReportGenerator handles missing data gracefully", {
  generator <- ReportGenerator$new()
  
  # Incomplete data
  incomplete_data <- list(
    title = "Test Report",
    date = Sys.Date(),
    executive_summary = "Brief summary"
  )
  
  # Should not error, but handle gracefully
  markdown_report <- generator$generate_markdown_report(incomplete_data)
  
  expect_type(markdown_report, "character")
  expect_true(str_detect(markdown_report, "Test Report"))
  expect_true(str_detect(markdown_report, "Brief summary"))
})

test_that("ReportGenerator template system works", {
  generator <- ReportGenerator$new()
  
  # Test clinical template
  clinical_template <- generator$get_clinical_report_template()
  expect_type(clinical_template, "character")
  expect_true(str_detect(clinical_template, "title"))
  expect_true(str_detect(clinical_template, "executive_summary"))
  
  # Test research template  
  research_template <- generator$get_research_report_template()
  expect_type(research_template, "character")
  expect_true(str_detect(research_template, "methodology"))
  expect_true(str_detect(research_template, "results"))
})

test_that("ReportGenerator metadata generation works", {
  generator <- ReportGenerator$new()
  mock_data <- create_mock_report_data()
  
  metadata <- generator$generate_report_metadata(mock_data)
  
  expect_type(metadata, "list")
  expect_true("generated_at" %in% names(metadata))
  expect_true("generator_version" %in% names(metadata))
  expect_true("data_summary" %in% names(metadata))
  
  expect_s3_class(metadata$generated_at, "POSIXct")
  expect_type(metadata$generator_version, "character")
})

test_that("ReportGenerator handles custom styling", {
  generator <- ReportGenerator$new()
  
  # Test with custom CSS
  custom_css <- "body { font-family: Arial; }"
  generator$set_custom_css(custom_css)
  
  expect_equal(generator$custom_css, custom_css)
  
  # Test theme selection
  generator$set_report_theme("clinical")
  expect_equal(generator$current_theme, "clinical")
  
  generator$set_report_theme("research") 
  expect_equal(generator$current_theme, "research")
})

test_that("ReportGenerator export functions work", {
  generator <- ReportGenerator$new()
  mock_data <- create_mock_report_data()
  
  temp_dir <- tempdir()
  
  # Test multi-format export
  export_result <- generator$export_all_formats(
    data = mock_data,
    output_dir = temp_dir,
    filename_base = "test_report"
  )
  
  expect_type(export_result, "list")
  expect_true("markdown" %in% names(export_result))
  expect_true("html" %in% names(export_result))
  
  # Check markdown was created
  expect_true(export_result$markdown$success)
  markdown_file <- file.path(temp_dir, "test_report.md")
  expect_true(file.exists(markdown_file))
  
  # Clean up
  files_to_remove <- list.files(temp_dir, pattern = "test_report", full.names = TRUE)
  file.remove(files_to_remove)
})

test_that("ReportGenerator handles large datasets efficiently", {
  generator <- ReportGenerator$new()
  
  # Create large mock dataset
  large_data <- create_mock_report_data()
  
  # Add large tables
  large_data$process_analysis$detailed_activities <- tibble(
    activity = paste0("Activity_", 1:1000),
    frequency = sample(1:500, 1000, replace = TRUE),
    avg_duration = runif(1000, 0.5, 10)
  )
  
  large_data$statistical_summary <- tibble(
    metric = paste0("Metric_", 1:500),
    value = runif(500, 0, 100),
    category = sample(c("Clinical", "Operational", "Financial"), 500, replace = TRUE)
  )
  
  # Should handle large data without errors
  start_time <- Sys.time()
  markdown_report <- generator$generate_markdown_report(large_data)
  end_time <- Sys.time()
  
  expect_type(markdown_report, "character")
  expect_gt(nchar(markdown_report), 5000)  # Should be substantial
  
  # Should complete in reasonable time (< 10 seconds)
  expect_lt(as.numeric(difftime(end_time, start_time, units = "secs")), 10)
})

test_that("ReportGenerator validation works", {
  generator <- ReportGenerator$new()
  
  # Valid data
  valid_data <- create_mock_report_data()
  expect_true(generator$validate_report_data(valid_data))
  
  # Invalid data (missing title)
  invalid_data <- valid_data
  invalid_data$title <- NULL
  expect_false(generator$validate_report_data(invalid_data))
  
  # Invalid data (wrong date format)
  invalid_data2 <- valid_data
  invalid_data2$date <- "not-a-date"
  expect_false(generator$validate_report_data(invalid_data2))
})

# Run the tests
if (interactive()) {
  cat("\n🧪 Running ReportGenerator Tests...\n")
  cat("=" * 50, "\n")
  
  test_results <- testthat::test_file("R/tests/test_report_generator.R", reporter = "summary")
  
  if (all(test_results$passed)) {
    cat("✅ All ReportGenerator tests passed!\n")
  } else {
    cat("❌ Some ReportGenerator tests failed.\n")
  }
  
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    cat("ℹ️ Install rmarkdown package for full report generation testing\n")
  }
}