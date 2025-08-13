\name{HealthProcessAI-package}
\alias{HealthProcessAI-package}
\alias{HealthProcessAI}
\docType{package}
\title{
\packageTitle{HealthProcessAI}
}
\description{
\packageDescription{HealthProcessAI}
}
\details{
HealthProcessAI is a comprehensive R framework for healthcare process mining with integrated Large Language Model (LLM) capabilities. The package provides a modern, modular architecture for analyzing clinical pathways, patient journeys, and healthcare processes.

\subsection{Core Components}{
The package implements a 5-step pipeline architecture:

\enumerate{
\item \strong{Data Loading} (\code{\link{EventLogLoader}}) - Load and validate healthcare event logs
\item \strong{Process Mining} (\code{\link{ProcessMiner}}) - Discover clinical pathways using bupaR
\item \strong{LLM Integration} (\code{\link{LLMAnalyzer}}) - Generate AI-powered clinical insights
\item \strong{Advanced Analytics} (\code{\link{AdvancedProcessAnalyzer}}) - Clustering, predictions, and KPIs
\item \strong{Report Orchestration} (\code{\link{ReportOrchestrator}}) - Multi-model consensus building
}

Additional components:
\itemize{
\item \code{\link{ReportGenerator}} - Multi-format report generation with RMarkdown
\item Data transformation utilities for PhysioNet and clinical datasets
\item Comprehensive testing suite with testthat
}
}

\subsection{Key Features}{
\itemize{
\item Modern R6 class architecture with object-oriented programming
\item Integration with bupaR ecosystem for process mining
\item OpenRouter API integration for multiple LLM models
\item Support for sepsis progression analysis and organ failure modeling
\item Multi-format report generation (Markdown, HTML, PDF, Word)
\item Comprehensive visualization and statistical analysis tools
\item Robust error handling and data validation
}
}

\subsection{Clinical Applications}{
\itemize{
\item Sepsis progression pathway discovery
\item Organ failure pattern analysis
\item Patient journey optimization
\item Clinical protocol conformance checking
\item Resource utilization analysis
\item Predictive risk modeling
\item Healthcare quality improvement
}
}

\subsection{Getting Started}{
\preformatted{
# Load the package
library(HealthProcessAI)

# Load sample sepsis data
loader <- EventLogLoader$new()
event_log <- loader$load_from_csv("data/sepsis_data.csv")

# Discover process patterns
miner <- ProcessMiner$new()
dfg <- miner$discover_dfg(event_log)

# Generate AI insights (requires OpenRouter API key)
analyzer <- LLMAnalyzer$new(api_key = "your-api-key")
insights <- analyzer$query_model("anthropic/claude-3.5-sonnet", 
                                 "Analyze this sepsis data...")

# Advanced analytics
advanced <- AdvancedProcessAnalyzer$new(event_log)
clusters <- advanced$cluster_patient_pathways(n_clusters = 3)

# Generate comprehensive report
generator <- ReportGenerator$new()
report <- generator$generate_markdown_report(results)
}
}

\subsection{Dependencies}{
\strong{Required:}
\itemize{
\item tidyverse, dplyr, tidyr, readr - Data manipulation
\item lubridate - Date/time handling
\item stringr, glue - String processing
\item jsonlite - JSON handling
\item R6 - Object-oriented programming
\item httr2 - HTTP API client
\item cluster - Clustering algorithms
}

\strong{Suggested:}
\itemize{
\item bupaR, edeaR, processmapR - Process mining ecosystem
\item rmarkdown, knitr - Report generation
\item ggplot2, plotly - Visualization
\item testthat - Testing framework
}
}

\subsection{API Keys}{
LLM features require an OpenRouter API key. Set the environment variable:
\preformatted{
Sys.setenv(OPENROUTER_API_KEY = "your-key-here")
}

Get your API key from: \url{https://openrouter.ai/}
}
}
\author{
\packageAuthor{HealthProcessAI}

Maintainer: \packageMaintainer{HealthProcessAI}
}
\references{
\itemize{
\item SMAILE Lab, Karolinska Institutet: \url{https://smile.ki.se}
\item GitHub Repository: \url{https://github.com/ki-smile/HealthProcessAI}
\item bupaR Documentation: \url{https://www.bupar.net/}
\item OpenRouter API: \url{https://openrouter.ai/docs}
}
}
\keyword{package}
\keyword{healthcare}
\keyword{process-mining}
\keyword{clinical-pathways}
\examples{
\dontrun{
# Complete pipeline example
library(HealthProcessAI)

# 1. Load data
loader <- EventLogLoader$new()
event_log <- loader$load_from_csv("sepsis_data.csv",
                                  case_col = "patient_id",
                                  activity_col = "activity",
                                  timestamp_col = "timestamp")

# 2. Process mining
miner <- ProcessMiner$new()
dfg <- miner$discover_dfg(event_log, type = "frequency")
metrics <- miner$calculate_performance_metrics(event_log)

# 3. LLM analysis (requires API key)
if (Sys.getenv("OPENROUTER_API_KEY") != "") {
  llm <- LLMAnalyzer$new(Sys.getenv("OPENROUTER_API_KEY"))
  insights <- llm$analyze_with_multiple_models(
    process_results = metrics,
    models = c("anthropic/claude-3.5-sonnet", "openai/gpt-4o")
  )
}

# 4. Advanced analytics
advanced <- AdvancedProcessAnalyzer$new(event_log)
clusters <- advanced$cluster_patient_pathways(n_clusters = 3)
kpis <- advanced$calculate_clinical_kpis()

# 5. Generate report
generator <- ReportGenerator$new()
report_data <- list(
  title = "Sepsis Analysis Report",
  process_metrics = metrics,
  clusters = clusters,
  kpis = kpis
)
markdown_report <- generator$generate_markdown_report(report_data)
}
}