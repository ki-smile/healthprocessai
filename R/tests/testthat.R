# Test runner for HealthProcessAI R implementation
# This file sets up the testthat testing framework

library(testthat)
library(tidyverse)
library(R6)

# Source all core modules before running tests
source("R/core/step1_data_loader.R")
source("R/core/step2_process_mining.R")
source("R/core/step3_llm_integration.R")
source("R/core/step4_advanced_analytics.R")
source("R/core/step5_orchestrator.R")
source("R/core/report_generator.R")

# Run all tests
test_check("HealthProcessAI")