# HealthProcessAI R Core Package Initialization
# ===========================================
# 
# This file initializes the HealthProcessAI R core modules for process mining
# and LLM integration in healthcare data analysis.
#
# Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments),
# Karolinska Institutet

# Load required libraries for the core package
suppressPackageStartupMessages({
  library(tidyverse)
  library(bupaR)
  library(httr2)
  library(jsonlite)
  library(glue)
  library(lubridate)
})

# Package information
PACKAGE_NAME <- "HealthProcessAI-R"
PACKAGE_VERSION <- "0.1.0"
PACKAGE_DESCRIPTION <- "Process Mining Framework for Healthcare & Life Sciences with AI Integration"
PACKAGE_URL <- "https://github.com/ki-smile/HealthProcessAI"

# Global configuration
.HEALTHPROCESSAI_ENV <- new.env(parent = emptyenv())
.HEALTHPROCESSAI_ENV$debug <- FALSE
.HEALTHPROCESSAI_ENV$default_timeout <- 60

# Core module paths
CORE_MODULES <- list(
  data_loader = "step1_data_loader.R",
  process_mining = "step2_process_mining.R", 
  llm_integration = "step3_llm_integration.R",
  advanced_analytics = "step4_advanced_analytics.R",
  orchestrator = "step5_orchestrator.R",
  report_generator = "report_generator.R"
)

#' Source all core modules
#' 
#' Loads all HealthProcessAI R core modules
#' @export
source_all_modules <- function() {
  core_dir <- file.path("R", "core")
  
  for (module in CORE_MODULES) {
    module_path <- file.path(core_dir, module)
    if (file.exists(module_path)) {
      source(module_path)
      cat("✅ Loaded module:", module, "\n")
    } else {
      cat("⚠️  Module not found:", module, "\n")
    }
  }
}

#' Get package information
#' @export
get_package_info <- function() {
  list(
    name = PACKAGE_NAME,
    version = PACKAGE_VERSION,
    description = PACKAGE_DESCRIPTION,
    url = PACKAGE_URL
  )
}

# Print initialization message
cat("🏥 HealthProcessAI R Core Package\n")
cat("=================================\n")
cat("Version:", PACKAGE_VERSION, "\n")
cat("Developed at SMAILE, Karolinska Institutet\n")
cat("Repository:", PACKAGE_URL, "\n\n")

# List available modules
cat("Available core modules:\n")
for (name in names(CORE_MODULES)) {
  cat("  -", name, "\n")
}
cat("\nUse source_all_modules() to load all modules\n")