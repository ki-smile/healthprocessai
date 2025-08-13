#' HealthProcessAI: Healthcare Process Mining with LLM Integration
#'
#' @description
#' HealthProcessAI provides a comprehensive R framework for healthcare process mining
#' with integrated Large Language Model (LLM) capabilities. The package enables
#' clinical pathway discovery, patient journey analysis, sepsis progression modeling,
#' and AI-powered clinical insight generation.
#'
#' @section Main Components:
#' 
#' The package implements a 5-step modular pipeline:
#' 
#' \enumerate{
#'   \item \strong{Data Loading} (\code{\link{EventLogLoader}}) - Load and validate healthcare event logs
#'   \item \strong{Process Mining} (\code{\link{ProcessMiner}}) - Discover clinical pathways using bupaR
#'   \item \strong{LLM Integration} (\code{\link{LLMAnalyzer}}) - Generate AI-powered clinical insights
#'   \item \strong{Advanced Analytics} (\code{\link{AdvancedProcessAnalyzer}}) - Clustering, predictions, and KPIs
#'   \item \strong{Report Orchestration} (\code{\link{ReportOrchestrator}}) - Multi-model consensus building
#' }
#' 
#' Additional components:
#' \itemize{
#'   \item \code{\link{ReportGenerator}} - Multi-format report generation
#'   \item Data transformation utilities for PhysioNet and clinical datasets
#'   \item Comprehensive testing suite and documentation
#' }
#'
#' @section Key Features:
#' \itemize{
#'   \item Modern R6 class architecture with object-oriented programming
#'   \item Integration with bupaR ecosystem for process mining
#'   \item OpenRouter API integration for multiple LLM models
#'   \item Support for sepsis progression and organ failure analysis
#'   \item Multi-format report generation (Markdown, HTML, PDF, Word)
#'   \item Comprehensive visualization and statistical analysis
#'   \item Robust error handling and data validation
#' }
#'
#' @section Clinical Applications:
#' \itemize{
#'   \item Sepsis progression pathway discovery
#'   \item Organ failure pattern analysis  
#'   \item Patient journey optimization
#'   \item Clinical protocol conformance checking
#'   \item Resource utilization analysis
#'   \item Predictive risk modeling
#'   \item Healthcare quality improvement
#' }
#'
#' @section Getting Started:
#' 
#' \preformatted{
#' # Load the package
#' library(HealthProcessAI)
#' 
#' # Load sample data
#' loader <- EventLogLoader$new()
#' event_log <- loader$load_from_csv("sepsis_data.csv")
#' 
#' # Discover process patterns
#' miner <- ProcessMiner$new()
#' dfg <- miner$discover_dfg(event_log)
#' 
#' # Generate AI insights (requires API key)
#' analyzer <- LLMAnalyzer$new(api_key = Sys.getenv("OPENROUTER_API_KEY"))
#' insights <- analyzer$query_model("anthropic/claude-3.5-sonnet", prompt)
#' 
#' # Advanced analytics
#' advanced <- AdvancedProcessAnalyzer$new(event_log)
#' clusters <- advanced$cluster_patient_pathways(n_clusters = 3)
#' 
#' # Generate report
#' generator <- ReportGenerator$new()
#' report <- generator$generate_markdown_report(results)
#' }
#'
#' @section API Keys:
#' 
#' LLM features require an OpenRouter API key:
#' \preformatted{
#' Sys.setenv(OPENROUTER_API_KEY = "your-key-here")
#' }
#' 
#' Get your API key from: \url{https://openrouter.ai/}
#'
#' @section Dependencies:
#' 
#' \strong{Required packages:}
#' tidyverse, R6, httr2, jsonlite, lubridate, cluster
#' 
#' \strong{Suggested packages:}
#' bupaR, rmarkdown, ggplot2, testthat
#'
#' @docType package
#' @name HealthProcessAI-package
#' @aliases HealthProcessAI
#' @author Farhad Abtahi \email{farhad.abtahi@@ki.se}, Eduardo Illueca Fernandez \email{eduardo.illueca@@ki.se}, Kaile Chen \email{kaile.chen@@ki.se}
#' @references 
#' \itemize{
#'   \item SMAILE Lab, Karolinska Institutet: \url{https://smile.ki.se}
#'   \item GitHub Repository: \url{https://github.com/ki-smile/HealthProcessAI}
#'   \item bupaR Documentation: \url{https://www.bupar.net/}
#'   \item OpenRouter API: \url{https://openrouter.ai/docs}
#' }
#' @keywords package healthcare process-mining clinical-pathways
NULL

# Global variables to prevent R CMD check notes
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(
    "case", "activity", "timestamp", "resource", "lifecycle",
    "activity_instance_id", "n", "freq", "duration", "cluster",
    "risk_score", "prediction", "model", "content", "success",
    "tokens_used", "agreement_score", "contribution_score"
  ))
}

#' @import R6
#' @import dplyr
#' @import tidyr
#' @import readr
#' @import lubridate
#' @import stringr
#' @import glue
#' @import jsonlite
#' @import httr2
#' @import cluster
#' @importFrom stats kmeans hclust cutree dist median quantile
#' @importFrom utils head tail str
#' @importFrom methods is
NULL