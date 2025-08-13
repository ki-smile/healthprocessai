# HealthProcessAI - R Step 3: LLM Integration for Clinical Insights
# ================================================================
#
# STEP 3: LLM INTEGRATION FOR CLINICAL INSIGHTS
# ==============================================
# This module integrates Large Language Models (LLMs) through OpenRouter API
# to generate clinical insights from process mining results.
#
# Learning Goals:
# - Understand how to integrate LLMs with process mining using R
# - Learn to structure prompts for clinical analysis
# - Query multiple models and compare responses using httr2
# - Generate professional reports from AI insights
#
# Key Concepts:
# - OpenRouter provides access to multiple LLM models
# - Prompts should include context and specific questions
# - Different models may provide different perspectives
# - Results should be validated by domain experts
#
# Technology Mapping:
# - Python requests -> R httr2
# - Python json -> R jsonlite
# - Python logging -> R message/warning
# - Python string formatting -> R glue
#
# Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments),
# Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(httr2)
  library(jsonlite)
  library(glue)
  library(tidyverse)
  library(R6)
})

# LLMAnalyzer R6 Class
#' Large Language Model Integration for Clinical Process Analysis
#' 
#' This class:
#' 1. Connects to OpenRouter API
#' 2. Structures prompts with process mining results
#' 3. Queries multiple LLM models
#' 4. Generates clinical reports
#' 
#' @import R6
#' @import httr2
#' @import jsonlite
#' @export
LLMAnalyzer <- R6::R6Class(
  classname = "LLMAnalyzer",
  
  # Public methods and fields
  public = list(
    
    # Available models through OpenRouter (as of 2024)
    AVAILABLE_MODELS = list(
      "claude" = "anthropic/claude-sonnet-4",
      "gpt4" = "openai/gpt-4.1", 
      "gemini" = "google/gemini-2.5-pro",
      "deepseek" = "deepseek/deepseek-r1:free",  # Free tier
      "grok" = "x-ai/grok-4"
    ),
    
    # Instance variables
    api_key = NULL,
    base_url = "https://openrouter.ai/api/v1",
    
    #' Initialize the LLM analyzer with OpenRouter API key
    #' 
    #' @param api_key OpenRouter API key
    #' @return New LLMAnalyzer instance
    #' 
    #' @examples
    #' analyzer <- LLMAnalyzer$new("your-api-key-here")
    initialize = function(api_key) {
      if (is.null(api_key) || api_key == "") {
        stop("❌ OpenRouter API key is required")
      }
      
      self$api_key <- api_key
      message("✅ Initialized LLM Analyzer with OpenRouter API")
    },
    
    #' Create a structured prompt for clinical analysis
    #' 
    #' This method creates prompts that:
    #' - Provide context about the process mining analysis
    #' - Include relevant metrics and patterns
    #' - Ask specific clinical questions
    #' - Request actionable insights
    #' 
    #' @param process_data List containing process mining results
    #' @param use_case Type of clinical analysis (sepsis, infection, organ)
    #' @return Formatted prompt string
    #' 
    #' @examples
    #' prompt <- analyzer$create_clinical_prompt(metrics, "sepsis")
    create_clinical_prompt = function(process_data, use_case = "sepsis") {
      # Base prompt template
      base_prompt <- "You are an expert clinical data analyst specializing in process mining
and sepsis progression analysis. You're analyzing patient pathway data to identify
patterns and provide actionable insights for healthcare improvement.

CONTEXT:
- Analysis type: {use_case} progression analysis
- Data source: Electronic health records processed through process mining
- Goal: Identify clinical patterns and improvement opportunities

PROCESS MINING RESULTS:
{process_summary}

KEY METRICS:
- Total cases analyzed: {num_cases}
- Average case duration: {avg_duration} hours
- Number of unique pathways: {num_variants}
- Most common pathway coverage: {top_variant_coverage}

TOP ACTIVITIES:
{top_activities}

CRITICAL TRANSITIONS:
{critical_transitions}

Please provide:
1. Clinical interpretation of the discovered patterns
2. Key risk factors identified in the process
3. Potential early warning signs
4. Recommendations for clinical intervention
5. Suggestions for process improvement

Format your response as a structured clinical report suitable for
medical professionals."

      # Extract data for prompt
      prompt_data <- list(
        use_case = stringr::str_to_title(use_case),
        process_summary = private$format_process_summary(process_data),
        num_cases = process_data$num_cases %||% "Unknown",
        avg_duration = process_data$avg_duration_hours %||% "Unknown", 
        num_variants = length(process_data$variants %||% list()) %||% "Unknown",
        top_variant_coverage = process_data$top_variant_coverage %||% "Unknown",
        top_activities = private$format_top_activities(process_data),
        critical_transitions = private$format_critical_transitions(process_data)
      )
      
      # Use glue for string interpolation
      formatted_prompt <- glue::glue(base_prompt, .envir = prompt_data)
      
      return(as.character(formatted_prompt))
    },
    
    #' Query a specific LLM model through OpenRouter
    #' 
    #' @param model_name Model identifier (e.g., 'anthropic/claude-sonnet-4')
    #' @param messages List of message lists with 'role' and 'content'
    #' @param temperature Creativity parameter (0=deterministic, 1=creative)
    #' @param max_tokens Maximum response length
    #' @return API response list
    #' 
    #' @examples
    #' messages <- list(list(role = "user", content = "Analyze this sepsis data..."))
    #' response <- analyzer$query_model("anthropic/claude-sonnet-4", messages)
    query_model = function(model_name, messages, temperature = 0.7, max_tokens = NULL) {
      # Prepare request payload
      payload <- list(
        model = model_name,
        messages = messages,
        temperature = temperature
      )
      
      if (!is.null(max_tokens)) {
        payload$max_tokens <- max_tokens
      }
      
      tryCatch({
        # Create httr2 request
        req <- httr2::request(self$base_url) %>%
          httr2::req_url_path_append("chat/completions") %>%
          httr2::req_method("POST") %>%
          httr2::req_headers(
            "Authorization" = paste("Bearer", self$api_key),
            "Content-Type" = "application/json",
            "HTTP-Referer" = "http://localhost:8080",  # Required by OpenRouter
            "X-Title" = "HealthProcessAI R Process Mining Analysis"
          ) %>%
          httr2::req_body_json(payload) %>%
          httr2::req_timeout(60)  # 60 second timeout
        
        # Perform request
        resp <- httr2::req_perform(req)
        
        # Check response status and parse
        if (httr2::resp_status(resp) == 200) {
          result <- httr2::resp_body_json(resp)
          message(glue::glue("✅ Successfully queried {model_name}"))
          return(result)
        } else {
          error_msg <- glue::glue("API error {httr2::resp_status(resp)}: {httr2::resp_body_string(resp)}")
          warning(error_msg)
          return(list(error = error_msg))
        }
        
      }, error = function(e) {
        error_msg <- glue::glue("Error querying {model_name}: {e$message}")
        warning(error_msg)
        return(list(error = error_msg))
      })
    },
    
    #' Query multiple models for comparative analysis
    #' 
    #' This is useful for:
    #' - Getting diverse perspectives
    #' - Validating insights across models  
    #' - Comparing model capabilities
    #' 
    #' @param prompt The analysis prompt
    #' @param models Vector of model names to query (or NULL for defaults)
    #' @param delay_seconds Delay between API calls to avoid rate limits
    #' @return Named list mapping model names to their responses
    #' 
    #' @examples
    #' results <- analyzer$analyze_with_multiple_models(
    #'   prompt,
    #'   models = c('claude', 'gpt4')
    #' )
    analyze_with_multiple_models = function(prompt, models = NULL, delay_seconds = 1) {
      if (is.null(models)) {
        # Use free tier model by default
        models <- c("deepseek")
      }
      
      results <- list()
      
      for (model_key in models) {
        # Get full model name
        model_name <- self$AVAILABLE_MODELS[[model_key]] %||% model_key
        
        message(glue::glue("🤖 Querying {model_name}..."))
        
        # Prepare messages
        messages <- list(list(role = "user", content = prompt))
        
        # Query model
        response <- self$query_model(model_name, messages)
        
        # Extract content
        if (!"error" %in% names(response)) {
          tryCatch({
            content <- response$choices[[1]]$message$content
            token_usage <- response$usage %||% list()
            
            results[[model_key]] <- list(
              status = "success",
              content = content,
              tokens = token_usage$total_tokens %||% 0,
              model = model_name
            )
          }, error = function(e) {
            results[[model_key]] <- list(
              status = "error",
              content = glue::glue("Failed to parse response: {e$message}"),
              model = model_name
            )
          })
        } else {
          results[[model_key]] <- list(
            status = "error", 
            content = response$error,
            model = model_name
          )
        }
        
        # Delay between requests (except for last model)
        if (delay_seconds > 0 && model_key != models[length(models)]) {
          Sys.sleep(delay_seconds)
        }
      }
      
      successful_models <- sum(sapply(results, function(x) x$status == "success"))
      message(glue::glue("📊 Queried {successful_models}/{length(models)} models successfully"))
      
      return(results)
    },
    
    #' Generate a formatted clinical report combining process mining and LLM insights
    #' 
    #' @param process_data Process mining results
    #' @param model_response LLM analysis response  
    #' @param metadata Additional metadata for the report
    #' @return Formatted markdown report
    #' 
    #' @examples
    #' report <- analyzer$generate_clinical_report(
    #'   metrics,
    #'   llm_response,
    #'   list(analyst = 'Dr. Smith', date = '2024-01-15')
    #' )
    generate_clinical_report = function(process_data, model_response, metadata = NULL) {
      # Report template
      report_template <- "# Clinical Process Mining Analysis Report

## Report Metadata
- **Generated**: {timestamp}
- **Analysis Type**: {analysis_type}  
- **Data Source**: Electronic Health Records
- **Process Mining Tool**: bupaR (R)
- **AI Model**: {ai_model}

---

## Executive Summary

{executive_summary}

---

## Process Mining Results

### Dataset Overview
- **Total Cases**: {num_cases}
- **Analysis Period**: {date_range}
- **Average Case Duration**: {avg_duration} hours
- **Unique Process Variants**: {num_variants}

### Key Process Metrics

| Metric | Value |
|--------|-------|
| Total Events | {total_events} |
| Unique Activities | {num_activities} |
| Most Common Pathway Coverage | {top_variant_coverage} |
| Minimum Case Duration | {min_duration} hours |
| Maximum Case Duration | {max_duration} hours |

### Top Activities

{top_activities_table}

---

## Clinical Analysis

{model_response}

---

## Methodology

### Process Mining Analysis
- **Framework**: HealthProcessAI (R implementation)
- **Process Discovery**: bupaR library with frequency-based analysis
- **Statistical Analysis**: edeaR for process metrics and performance indicators

### AI Analysis  
- **LLM Integration**: OpenRouter API for multi-model analysis
- **Prompt Engineering**: Structured clinical analysis prompts
- **Validation**: Multiple model comparison for robust insights

---

## Disclaimer

This analysis is generated through automated process mining and AI analysis.
All clinical insights should be validated by qualified medical professionals
before implementation. This tool is intended to support, not replace,
clinical decision-making.

---

*Report generated by HealthProcessAI*
*Developed at SMAILE, Karolinska Institutet*"

      # Prepare report data
      report_data <- list(
        timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        analysis_type = metadata$analysis_type %||% "Process Mining",
        ai_model = metadata$ai_model %||% "OpenRouter API",
        executive_summary = private$extract_executive_summary(model_response),
        num_cases = process_data$num_cases %||% "N/A",
        date_range = private$format_date_range(process_data),
        avg_duration = round(process_data$avg_duration_hours %||% 0, 2),
        num_variants = length(process_data$variants %||% list()),
        total_events = process_data$num_events %||% "N/A",
        num_activities = process_data$num_activities %||% "N/A", 
        top_variant_coverage = process_data$top_variant_coverage %||% "N/A",
        min_duration = round(process_data$min_duration_hours %||% 0, 2),
        max_duration = round(process_data$max_duration_hours %||% 0, 2),
        top_activities_table = private$format_activities_table(process_data),
        model_response = model_response
      )
      
      # Generate report using glue
      formatted_report <- glue::glue(report_template, .envir = report_data)
      
      message("📄 Generated clinical report with LLM insights")
      
      return(as.character(formatted_report))
    },
    
    #' Save analysis results to files
    #' 
    #' @param results Results from analyze_with_multiple_models()
    #' @param output_dir Directory to save results
    #' @return List of saved file paths
    save_analysis_results = function(results, output_dir = "llm_analysis_results") {
      # Create output directory
      if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
      }
      
      saved_files <- list()
      
      # Save individual model responses
      for (model_name in names(results)) {
        if (results[[model_name]]$status == "success") {
          filename <- file.path(output_dir, glue::glue("Report_{model_name}.md"))
          writeLines(results[[model_name]]$content, filename)
          saved_files[[model_name]] <- filename
          message(glue::glue("💾 Saved {model_name} analysis to {filename}"))
        }
      }
      
      # Save summary JSON
      summary_file <- file.path(output_dir, "analysis_summary.json") 
      summary_data <- lapply(results, function(r) list(
        status = r$status,
        model = r$model,
        tokens = r$tokens %||% 0,
        content_length = nchar(r$content %||% "")
      ))
      
      jsonlite::write_json(summary_data, summary_file, pretty = TRUE)
      saved_files$summary <- summary_file
      
      message(glue::glue("📁 Saved {length(saved_files)} files to {output_dir}/"))
      
      return(saved_files)
    }
  ),
  
  # Private methods
  private = list(
    
    #' Format process data into readable summary
    #' @param process_data List of process mining results
    format_process_summary = function(process_data) {
      summary_lines <- c()
      
      if ("description" %in% names(process_data)) {
        summary_lines <- c(summary_lines, process_data$description)
      }
      
      if ("key_findings" %in% names(process_data)) {
        summary_lines <- c(summary_lines, "Key Findings:")
        for (finding in process_data$key_findings) {
          summary_lines <- c(summary_lines, glue::glue("  - {finding}"))
        }
      }
      
      if (length(summary_lines) == 0) {
        return("Process analysis completed")
      } else {
        return(paste(summary_lines, collapse = "\n"))
      }
    },
    
    #' Format top activities list
    #' @param process_data List of process mining results
    format_top_activities = function(process_data) {
      activities <- process_data$top_5_activities %||% list()
      
      if (length(activities) == 0) {
        return("No activity data available")
      }
      
      lines <- c()
      for (i in seq_along(activities)) {
        act <- activities[[i]]
        line <- glue::glue("{i}. {act$activity %||% 'Unknown'}: {act$count %||% 0} occurrences")
        lines <- c(lines, line)
      }
      
      return(paste(lines, collapse = "\n"))
    },
    
    #' Format critical transitions information
    #' @param process_data List of process mining results
    format_critical_transitions = function(process_data) {
      transitions <- process_data$critical_transitions %||% c()
      
      if (length(transitions) == 0) {
        return("Transition analysis pending")
      }
      
      lines <- paste("- ", transitions)
      return(paste(lines, collapse = "\n"))
    },
    
    #' Extract executive summary from model response
    #' @param model_response Full model response text
    extract_executive_summary = function(model_response) {
      # Simple extraction - look for first paragraph or first few sentences
      if (is.null(model_response) || nchar(model_response) == 0) {
        return("Analysis completed. Please see detailed findings below.")
      }
      
      # Split into sentences and take first 2-3
      sentences <- unlist(strsplit(model_response, "\\. "))
      if (length(sentences) >= 2) {
        summary <- paste(sentences[1:min(3, length(sentences))], collapse = ". ")
        return(paste(summary, ".", sep = ""))
      } else {
        return(substr(model_response, 1, min(200, nchar(model_response))))
      }
    },
    
    #' Format date range from process data
    #' @param process_data List of process mining results  
    format_date_range = function(process_data) {
      if ("date_range" %in% names(process_data)) {
        start_date <- process_data$date_range$start %||% "Unknown"
        end_date <- process_data$date_range$end %||% "Unknown"
        return(glue::glue("{start_date} to {end_date}"))
      } else {
        return("Date range not available")
      }
    },
    
    #' Format activities as a markdown table
    #' @param process_data List of process mining results
    format_activities_table = function(process_data) {
      activities <- process_data$top_5_activities %||% list()
      
      if (length(activities) == 0) {
        return("| Activity | Count |\n|----------|-------|\n| No data | - |")
      }
      
      # Create table header
      table_lines <- c("| Rank | Activity | Occurrences |", "|------|----------|-------------|")
      
      # Add activity rows
      for (i in seq_along(activities)) {
        act <- activities[[i]]
        line <- glue::glue("| {i} | {act$activity %||% 'Unknown'} | {act$count %||% 0} |")
        table_lines <- c(table_lines, line)
      }
      
      return(paste(table_lines, collapse = "\n"))
    }
  )
)

# Convenience functions for quick analysis (functional interface)

#' Quick LLM analysis of process mining results (functional interface)
#' 
#' @param process_data Process mining results list
#' @param api_key OpenRouter API key
#' @param models Vector of model names to query
#' @param use_case Clinical use case ("sepsis", "infection", "organ")
#' @return List with LLM analysis results
#' @export
analyze_with_llm <- function(process_data, api_key, models = c("deepseek"), use_case = "sepsis") {
  analyzer <- LLMAnalyzer$new(api_key)
  prompt <- analyzer$create_clinical_prompt(process_data, use_case)
  results <- analyzer$analyze_with_multiple_models(prompt, models)
  return(results)
}

#' Generate clinical report from LLM analysis (functional interface)
#' 
#' @param process_data Process mining results
#' @param llm_results Results from analyze_with_llm()
#' @param model_key Which model result to use for report
#' @return Formatted markdown report
#' @export
generate_llm_report <- function(process_data, llm_results, model_key = names(llm_results)[1]) {
  if (!model_key %in% names(llm_results)) {
    stop(glue::glue("Model '{model_key}' not found in results"))
  }
  
  if (llm_results[[model_key]]$status != "success") {
    stop(glue::glue("Model '{model_key}' analysis failed: {llm_results[[model_key]]$content}"))
  }
  
  # Create analyzer just for report generation
  analyzer <- LLMAnalyzer$new("dummy")  # Won't be used for API calls
  
  metadata <- list(
    analysis_type = "Process Mining + LLM Analysis",
    ai_model = llm_results[[model_key]]$model
  )
  
  report <- analyzer$generate_clinical_report(
    process_data,
    llm_results[[model_key]]$content, 
    metadata
  )
  
  return(report)
}

# Print module information  
cat("🤖 HealthProcessAI R - Step 3: LLM Integration\n")
cat("============================================\n")
cat("✅ LLMAnalyzer R6 class available\n")
cat("✅ analyze_with_llm() function available\n")
cat("✅ generate_llm_report() function available\n")
cat("📚 Uses: httr2, jsonlite, glue\n\n")
cat("Example usage:\n")
cat('  analyzer <- LLMAnalyzer$new("your-api-key")\n')
cat("  prompt <- analyzer$create_clinical_prompt(process_data)\n")
cat("  results <- analyzer$analyze_with_multiple_models(prompt)\n")
cat("  report <- analyzer$generate_clinical_report(process_data, results)\n\n")