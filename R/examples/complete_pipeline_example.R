# HealthProcessAI - Complete Pipeline Example (R Implementation)
# ==============================================================
#
# COMPLETE PIPELINE EXAMPLE: SEPSIS PROGRESSION ANALYSIS
# ======================================================
# This script demonstrates the complete process mining pipeline for healthcare data,
# incorporating all modules and advanced methodological approaches.
#
# This example shows:
# 1. Data loading and preparation
# 2. Process discovery and visualization
# 3. Advanced analytics (clustering, bottlenecks, predictions)
# 4. LLM-powered clinical insights
# 5. Comprehensive report generation
# 6. Multi-model report orchestration
#
# Perfect for learning the end-to-end workflow of healthcare process mining.
#
# Developed at SMAILE (Stockholm Medical AI Lab for Enhancement),
# Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(bupaR)
  library(glue)
  library(jsonlite)
  library(lubridate)
  library(R6)
})

# Source all modules
source("R/core/step1_data_loader.R")
source("R/core/step2_process_mining.R")
source("R/core/step3_llm_integration.R")
source("R/core/step4_advanced_analytics.R")
source("R/core/step5_orchestrator.R")
source("R/core/report_generator.R")

#' Complete Process Mining Pipeline R6 Class
#' 
#' Orchestrates all steps of healthcare process mining analysis,
#' from data loading to final report generation.
#' 
#' @import R6
#' @export
CompleteProcessMiningPipeline <- R6::R6Class(
  classname = "CompleteProcessMiningPipeline",
  
  public = list(
    
    # Instance variables
    data_path = NULL,
    api_key = NULL,
    output_dir = NULL,
    
    # Components
    loader = NULL,
    miner = NULL,
    analyzer = NULL,
    advanced_analyzer = NULL,
    orchestrator = NULL,
    report_generator = NULL,
    
    # Results storage
    results = NULL,
    
    #' Initialize the pipeline
    #' 
    #' @param data_path Path to event log CSV file
    #' @param api_key OpenRouter API key for LLM integration
    #' @param output_dir Directory for saving results
    initialize = function(data_path, api_key = NULL, output_dir = "./results") {
      self$data_path <- data_path
      self$api_key <- api_key
      self$output_dir <- output_dir
      
      # Create output directory
      if (!dir.exists(self$output_dir)) {
        dir.create(self$output_dir, recursive = TRUE)
      }
      
      # Initialize results storage
      self$results <- list(
        timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        data_path = data_path,
        steps_completed = character()
      )
      
      message(glue::glue("✅ Initialized pipeline for {basename(data_path)}"))
    },
    
    #' Run complete analysis pipeline
    #' 
    #' @param sepsis_only Whether to filter for sepsis cases only
    #' @param use_llm Whether to use LLM for insights generation
    #' @param llm_models Vector of LLM models to use
    #' @return List containing all analysis results
    run_complete_analysis = function(sepsis_only = TRUE, use_llm = TRUE, 
                                    llm_models = NULL) {
      cat("\n", paste(rep("=", 60), collapse = ""), "\n")
      cat("STARTING COMPLETE PROCESS MINING PIPELINE\n")
      cat(paste(rep("=", 60), collapse = ""), "\n\n")
      
      tryCatch({
        # Step 1: Data Loading and Preparation
        private$step1_load_data()
        
        # Step 2: Filter cases if needed
        private$step2_filter_cases(sepsis_only)
        
        # Step 3: Process Discovery
        private$step3_process_discovery()
        
        # Step 4: Advanced Analytics
        private$step4_advanced_analytics()
        
        # Step 5: Generate Clinical Insights
        if (use_llm && !is.null(self$api_key)) {
          private$step5_llm_insights(llm_models)
        } else {
          message("ℹ️ Skipping LLM insights (no API key provided)")
        }
        
        # Step 6: Multi-Model Orchestration (if multiple models used)
        if (use_llm && length(llm_models) > 1) {
          private$step6_orchestrate_reports()
        }
        
        # Step 7: Generate Final Report
        private$step7_generate_report()
        
        # Step 8: Export All Results
        private$step8_export_results()
        
        cat("\n", paste(rep("=", 60), collapse = ""), "\n")
        cat("PIPELINE COMPLETED SUCCESSFULLY\n")
        cat(paste(rep("=", 60), collapse = ""), "\n")
        
      }, error = function(e) {
        message(glue::glue("❌ Pipeline failed: {e$message}"))
        self$results$error <- e$message
        stop(e)
      })
      
      return(self$results)
    }
  ),
  
  private = list(
    
    # Data storage
    raw_data = NULL,
    prepared_data = NULL,
    filtered_data = NULL,
    event_log = NULL,
    
    #' Step 1: Load and prepare data
    step1_load_data = function() {
      cat("\n", paste(rep("=", 40), collapse = ""), "\n")
      cat("STEP 1: DATA LOADING AND PREPARATION\n")
      cat(paste(rep("=", 40), collapse = ""), "\n\n")
      
      # Initialize loader
      self$loader <- EventLogLoader$new(self$data_path)
      
      # Load and prepare data
      private$raw_data <- self$loader$load_data()
      message(glue::glue("✓ Loaded {nrow(private$raw_data)} events"))
      
      private$prepared_data <- self$loader$prepare_data()
      message(glue::glue("✓ Prepared {nrow(private$prepared_data)} events"))
      
      # Get statistics
      stats <- self$loader$get_statistics()
      self$results$data_statistics <- stats
      self$results$steps_completed <- c(self$results$steps_completed, "data_loading")
      
      # Log summary
      cat("\nData Summary:\n")
      cat(glue::glue("  - Total cases: {stats$num_cases}\n"))
      cat(glue::glue("  - Total events: {stats$num_events}\n"))
      cat(glue::glue("  - Unique activities: {stats$num_activities}\n"))
      if (!is.null(stats$sepsis_rate)) {
        cat(glue::glue("  - Sepsis rate: {round(stats$sepsis_rate * 100, 1)}%\n"))
      }
    },
    
    #' Step 2: Filter cases
    step2_filter_cases = function(sepsis_only) {
      cat("\n", paste(rep("=", 40), collapse = ""), "\n")
      cat("STEP 2: CASE FILTERING\n")
      cat(paste(rep("=", 40), collapse = ""), "\n\n")
      
      if (sepsis_only) {
        private$filtered_data <- self$loader$filter_by_outcome(sepsis_only = TRUE)
        message(glue::glue("✓ Filtered to {length(unique(private$filtered_data$case))} sepsis cases"))
      } else {
        private$filtered_data <- private$prepared_data
        message("✓ Using all cases (no filtering)")
      }
      
      self$results$filtering <- list(
        sepsis_only = sepsis_only,
        cases_after_filter = length(unique(private$filtered_data$case))
      )
      self$results$steps_completed <- c(self$results$steps_completed, "filtering")
    },
    
    #' Step 3: Process discovery
    step3_process_discovery = function() {
      cat("\n", paste(rep("=", 40), collapse = ""), "\n")
      cat("STEP 3: PROCESS DISCOVERY\n")
      cat(paste(rep("=", 40), collapse = ""), "\n\n")
      
      # Initialize process miner
      self$miner <- ProcessMiner$new()
      
      # Create event log
      private$event_log <- self$miner$create_event_log(private$filtered_data)
      message(glue::glue("✓ Created event log with {bupaR::n_cases(private$event_log)} cases"))
      
      # Discover process maps
      freq_map <- self$miner$discover_process_map(type = "frequency", render = FALSE)
      message("✓ Discovered frequency-based process map")
      
      perf_map <- self$miner$discover_process_map(type = "performance", render = FALSE)
      message("✓ Discovered performance-based process map")
      
      # Create process matrix
      matrix <- self$miner$create_process_matrix()
      message(glue::glue("✓ Created process matrix ({nrow(matrix)}x{ncol(matrix)})"))
      
      # Discover variants
      variants <- self$miner$discover_variants(top_k = 10)
      message(glue::glue("✓ Discovered {nrow(variants)} top variants"))
      
      # Calculate metrics
      metrics <- self$miner$calculate_process_metrics()
      
      self$results$process_discovery <- list(
        num_transitions = nrow(self$miner$get_transitions()),
        num_variants = nrow(variants),
        metrics = metrics
      )
      self$results$steps_completed <- c(self$results$steps_completed, "process_discovery")
      
      # Log key findings
      cat("\nProcess Discovery Results:\n")
      cat(glue::glue("  - Average case duration: {round(metrics$avg_duration_hours, 1)} hours\n"))
      if (nrow(variants) > 0) {
        cat(glue::glue("  - Most common variant covers: {variants$percentage[1]}% of cases\n"))
      }
    },
    
    #' Step 4: Advanced analytics
    step4_advanced_analytics = function() {
      cat("\n", paste(rep("=", 40), collapse = ""), "\n")
      cat("STEP 4: ADVANCED ANALYTICS\n")
      cat(paste(rep("=", 40), collapse = ""), "\n\n")
      
      # Initialize advanced analyzer
      self$advanced_analyzer <- AdvancedProcessAnalyzer$new(private$event_log)
      
      # 4.1: Patient Clustering
      cat("\n4.1 Patient Pathway Clustering\n")
      clusters <- self$advanced_analyzer$cluster_patient_pathways(
        n_clusters = 3, 
        method = "kmeans"
      )
      message(glue::glue("✓ Identified {clusters$n_clusters} patient clusters"))
      message(glue::glue("  Silhouette score: {round(clusters$silhouette_score, 3)}"))
      
      # 4.2: Bottleneck Analysis
      cat("\n4.2 Bottleneck Analysis\n")
      bottlenecks <- self$advanced_analyzer$analyze_bottlenecks()
      message(glue::glue("✓ Identified {sum(bottlenecks$bottlenecks$is_bottleneck, na.rm = TRUE)} bottlenecks"))
      
      if (nrow(bottlenecks$bottlenecks) > 0) {
        top_bottleneck <- bottlenecks$bottlenecks[1,]
        message(glue::glue("  Top bottleneck: {top_bottleneck$activity} (avg: {round(top_bottleneck$mean, 1)} hours)"))
      }
      
      # 4.3: Clinical KPIs
      cat("\n4.3 Clinical KPI Calculation\n")
      kpis <- self$advanced_analyzer$calculate_clinical_kpis()
      message(glue::glue("✓ Calculated {length(kpis)} KPIs"))
      message(glue::glue("  Average LOS: {round(kpis$avg_length_of_stay, 1)} hours"))
      message(glue::glue("  Daily admissions: {round(kpis$daily_admissions, 1)}"))
      
      # 4.4: Predictive Monitoring (demonstration)
      cat("\n4.4 Predictive Monitoring Capability\n")
      if (bupaR::n_events(private$event_log) > 3) {
        # Create sample partial trace
        sample_events <- private$event_log %>%
          head(3)
        
        prediction <- self$advanced_analyzer$predict_case_outcome(sample_events, "sepsis")
        message(glue::glue("✓ Prediction demo - Risk level: {prediction$risk_level}"))
      }
      
      self$results$advanced_analytics <- list(
        clusters = clusters,
        bottlenecks = bottlenecks,
        kpis = kpis
      )
      self$results$steps_completed <- c(self$results$steps_completed, "advanced_analytics")
    },
    
    #' Step 5: LLM insights generation
    step5_llm_insights = function(llm_models = NULL) {
      cat("\n", paste(rep("=", 40), collapse = ""), "\n")
      cat("STEP 5: AI-POWERED CLINICAL INSIGHTS\n")
      cat(paste(rep("=", 40), collapse = ""), "\n\n")
      
      if (is.null(llm_models)) {
        llm_models <- c("deepseek")  # Default to free model
      }
      
      # Initialize LLM analyzer
      self$analyzer <- LLMAnalyzer$new(self$api_key)
      
      # Prepare process data for LLM
      process_data <- list(
        num_cases = self$results$data_statistics$num_cases,
        avg_duration_hours = self$results$process_discovery$metrics$avg_duration_hours,
        num_variants = self$results$process_discovery$metrics$num_variants,
        num_activities = self$results$data_statistics$num_activities,
        num_events = self$results$data_statistics$num_events,
        top_5_activities = self$results$process_discovery$metrics$top_5_activities,
        key_findings = c(
          glue::glue("Identified {self$results$advanced_analytics$clusters$n_clusters} distinct patient clusters"),
          glue::glue("Average length of stay is {round(self$results$advanced_analytics$kpis$avg_length_of_stay, 1)} hours"),
          if (nrow(self$results$advanced_analytics$bottlenecks$bottlenecks) > 0) {
            glue::glue("Top bottleneck: {self$results$advanced_analytics$bottlenecks$bottlenecks$activity[1]}")
          } else {
            "No significant bottlenecks identified"
          }
        )
      )
      
      # Create clinical prompt
      prompt <- self$analyzer$create_clinical_prompt(process_data, "sepsis")
      
      # Query models
      message(glue::glue("Querying {length(llm_models)} AI models..."))
      llm_results <- self$analyzer$analyze_with_multiple_models(
        prompt, 
        models = llm_models, 
        delay_seconds = 1
      )
      
      # Log results
      for (model in names(llm_results)) {
        result <- llm_results[[model]]
        status_icon <- ifelse(result$status == "success", "✓", "✗")
        message(glue::glue("  {status_icon} {model}: {result$status}"))
      }
      
      self$results$llm_insights <- llm_results
      self$results$steps_completed <- c(self$results$steps_completed, "llm_insights")
    },
    
    #' Step 6: Orchestrate multiple model reports
    step6_orchestrate_reports = function() {
      cat("\n", paste(rep("=", 40), collapse = ""), "\n")
      cat("STEP 6: MULTI-MODEL ORCHESTRATION\n")
      cat(paste(rep("=", 40), collapse = ""), "\n\n")
      
      if (is.null(self$results$llm_insights) || length(self$results$llm_insights) <= 1) {
        message("ℹ️ Skipping orchestration (need multiple models)")
        return()
      }
      
      # Initialize orchestrator
      self$orchestrator <- ReportOrchestrator$new()
      
      # Extract successful reports
      reports <- list()
      for (model in names(self$results$llm_insights)) {
        if (self$results$llm_insights[[model]]$status == "success") {
          reports[[model]] <- self$results$llm_insights[[model]]$content
        }
      }
      
      if (length(reports) > 1) {
        # Create case info
        case_info <- list(
          title = "Sepsis Progression Analysis",
          description = glue::glue("Analysis of {self$results$data_statistics$num_cases} patient cases")
        )
        
        # Consolidate reports
        orchestrated <- self$orchestrator$consolidate_reports(reports, case_info)
        
        # Save orchestrated report
        orch_path <- file.path(self$output_dir, "orchestrated_report.md")
        writeLines(orchestrated, orch_path)
        
        message(glue::glue("✓ Orchestrated {length(reports)} model reports"))
        message(glue::glue("✓ Saved to {basename(orch_path)}"))
        
        self$results$orchestrated_report <- orch_path
      }
      
      self$results$steps_completed <- c(self$results$steps_completed, "orchestration")
    },
    
    #' Step 7: Generate comprehensive report
    step7_generate_report = function() {
      cat("\n", paste(rep("=", 40), collapse = ""), "\n")
      cat("STEP 7: REPORT GENERATION\n")
      cat(paste(rep("=", 40), collapse = ""), "\n\n")
      
      # Initialize report generator
      self$report_generator <- ReportGenerator$new(self$output_dir)
      
      # Prepare report data
      report_data <- list(
        statistics = self$results$data_statistics,
        variants = self$miner$discover_variants(top_k = 5),
        process_map = list(
          transitions = self$miner$get_transitions() %>% head(10)
        ),
        advanced_analytics = self$results$advanced_analytics,
        llm_insights = if (!is.null(self$results$llm_insights)) {
          # Get first successful model's content
          for (model in names(self$results$llm_insights)) {
            if (self$results$llm_insights[[model]]$status == "success") {
              self$results$llm_insights[[model]]$content
              break
            }
          }
        } else {
          "No AI insights generated"
        }
      )
      
      # Generate reports in multiple formats
      report_files <- self$report_generator$generate_report(
        report_data,
        "clinical_analysis",
        formats = c("markdown", "html")
      )
      
      message(glue::glue("✓ Generated {length(report_files)} report formats"))
      
      self$results$report_files <- report_files
      self$results$steps_completed <- c(self$results$steps_completed, "report_generation")
    },
    
    #' Step 8: Export all results
    step8_export_results = function() {
      cat("\n", paste(rep("=", 40), collapse = ""), "\n")
      cat("STEP 8: EXPORTING RESULTS\n")
      cat(paste(rep("=", 40), collapse = ""), "\n\n")
      
      # Export process mining results
      if (!is.null(self$miner)) {
        exported <- self$miner$export_results(self$output_dir)
        message(glue::glue("✓ Exported process mining results ({length(exported)} files)"))
      }
      
      # Export advanced analytics results
      if (!is.null(self$advanced_analyzer)) {
        adv_exported <- self$advanced_analyzer$export_advanced_results(
          file.path(self$output_dir, "advanced_analytics")
        )
        message(glue::glue("✓ Exported advanced analytics ({length(adv_exported)} files)"))
      }
      
      # Export pipeline results as JSON
      results_path <- file.path(self$output_dir, "pipeline_results.json")
      jsonlite::write_json(self$results, results_path, pretty = TRUE, auto_unbox = TRUE)
      message(glue::glue("✓ Pipeline results saved to {basename(results_path)}"))
      
      # Create process visualization if possible
      tryCatch({
        if (!is.null(self$miner)) {
          viz_path <- file.path(self$output_dir, "process_map.png")
          # Note: Actual visualization would require additional setup
          message("ℹ️ Process visualization export requires graphviz setup")
        }
      }, error = function(e) {
        warning(glue::glue("Could not create visualization: {e$message}"))
      })
      
      self$results$steps_completed <- c(self$results$steps_completed, "export")
    }
  )
)

# Main function to run the pipeline
run_complete_pipeline <- function(data_path, api_key = NULL, output_dir = "./pipeline_results") {
  
  # Print header
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  cat("COMPLETE HEALTHCARE PROCESS MINING PIPELINE (R)\n")
  cat(paste(rep("=", 60), collapse = ""), "\n\n")
  cat(glue::glue("Data: {data_path}\n"))
  cat(glue::glue("Output: {output_dir}\n"))
  cat(glue::glue("LLM Integration: {ifelse(!is.null(api_key), 'Enabled', 'Disabled (no API key)')}\n"))
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  
  # Initialize pipeline
  pipeline <- CompleteProcessMiningPipeline$new(
    data_path = data_path,
    api_key = api_key,
    output_dir = output_dir
  )
  
  # Run complete analysis
  results <- pipeline$run_complete_analysis(
    sepsis_only = TRUE,
    use_llm = !is.null(api_key),
    llm_models = c("deepseek")  # Using free model for demo
  )
  
  # Print summary
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  cat("PIPELINE SUMMARY\n")
  cat(paste(rep("=", 60), collapse = ""), "\n\n")
  cat(glue::glue("Steps completed: {paste(results$steps_completed, collapse = ', ')}\n"))
  cat(glue::glue("Output directory: {output_dir}\n"))
  
  if (!is.null(results$report_files)) {
    cat("Generated reports:\n")
    for (format in names(results$report_files)) {
      cat(glue::glue("  - {format}: {basename(results$report_files[[format]])}\n"))
    }
  }
  
  if (!is.null(results$error)) {
    cat(glue::glue("\n⚠️ Error occurred: {results$error}\n"))
  } else {
    cat("\n✅ Pipeline completed successfully!\n")
  }
  
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  
  return(results)
}

# Example usage
if (interactive()) {
  # Configuration
  DATA_PATH <- "data/sepsisAgregated_Infection.csv"  # Update with your data path
  API_KEY <- Sys.getenv("OPENROUTER_API_KEY")  # Set your API key as environment variable
  OUTPUT_DIR <- "./pipeline_results_R"
  
  # Run the pipeline
  results <- run_complete_pipeline(DATA_PATH, API_KEY, OUTPUT_DIR)
}