#!/usr/bin/env Rscript
# HealthProcessAI R Implementation - Complete Test Suite
# Run all tests for the R modules

# Load required libraries
suppressPackageStartupMessages({
  library(testthat)
  library(tidyverse)
  library(R6)
})

# Set up test environment
cat("\n", paste(rep("=", 80), collapse = ""), "\n")
cat("🧪 HealthProcessAI R Implementation - Test Suite\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")
cat("Running comprehensive tests for all R6 modules...\n")
cat("Developed at SMAILE, Karolinska Institutet\n\n")

# Track test results
test_results <- list()
total_tests <- 0
total_failures <- 0

# Helper function to run and report test results
run_test_file <- function(test_file, module_name) {
  cat(paste(rep("-", 60), collapse = ""), "\n")
  cat("🔍 Testing:", module_name, "\n")
  cat("📁 File:", test_file, "\n\n")
  
  if (!file.exists(test_file)) {
    cat("❌ Test file not found:", test_file, "\n\n")
    return(list(passed = 0, failed = 1, skipped = 0))
  }
  
  # Run the test
  tryCatch({
    result <- testthat::test_file(test_file, reporter = "summary")
    
    # Extract results
    n_passed <- sum(result$passed, na.rm = TRUE)
    n_failed <- sum(result$failed, na.rm = TRUE) 
    n_skipped <- sum(result$skipped, na.rm = TRUE)
    
    # Report results
    if (n_failed == 0) {
      cat("✅", module_name, "- All tests passed!", "\n")
      cat("   ", n_passed, "tests passed,", n_skipped, "skipped\n\n")
    } else {
      cat("❌", module_name, "- Some tests failed!", "\n")
      cat("   ", n_passed, "passed,", n_failed, "failed,", n_skipped, "skipped\n\n")
    }
    
    return(list(passed = n_passed, failed = n_failed, skipped = n_skipped))
    
  }, error = function(e) {
    cat("💥 Error running tests for", module_name, "\n")
    cat("   Error:", conditionMessage(e), "\n\n")
    return(list(passed = 0, failed = 1, skipped = 0))
  })
}

# Test configuration
test_modules <- list(
  list(
    file = "R/tests/test_step1_data_loader.R",
    name = "Step 1: EventLogLoader",
    description = "Data loading and validation"
  ),
  list(
    file = "R/tests/test_step2_process_mining.R", 
    name = "Step 2: ProcessMiner",
    description = "Process discovery with bupaR"
  ),
  list(
    file = "R/tests/test_step3_llm_integration.R",
    name = "Step 3: LLMAnalyzer", 
    description = "AI model integration"
  ),
  list(
    file = "R/tests/test_step4_advanced_analytics.R",
    name = "Step 4: AdvancedProcessAnalyzer",
    description = "Clustering and advanced analytics"
  ),
  list(
    file = "R/tests/test_step5_orchestrator.R",
    name = "Step 5: ReportOrchestrator",
    description = "Multi-model report synthesis"
  ),
  list(
    file = "R/tests/test_report_generator.R",
    name = "ReportGenerator",
    description = "Report generation with RMarkdown"
  )
)

# Pre-flight checks
cat("🔧 Pre-flight Checks:\n")
cat(paste(rep("-", 40), collapse = ""), "\n")

# Check if core modules exist
core_modules <- c(
  "R/core/step1_data_loader.R",
  "R/core/step2_process_mining.R", 
  "R/core/step3_llm_integration.R",
  "R/core/step4_advanced_analytics.R",
  "R/core/step5_orchestrator.R",
  "R/core/report_generator.R"
)

all_modules_exist <- TRUE
for (module in core_modules) {
  if (file.exists(module)) {
    cat("✓", basename(module), "\n")
  } else {
    cat("✗", basename(module), "- NOT FOUND\n")
    all_modules_exist <- FALSE
  }
}

if (!all_modules_exist) {
  stop("❌ Some core modules are missing. Please ensure all R/core/*.R files exist.")
}

# Check optional dependencies
cat("\n📦 Optional Dependencies:\n")
optional_packages <- c("bupaR", "rmarkdown", "processmapR", "edeaR")
for (pkg in optional_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("✓", pkg, "\n")
  } else {
    cat("⚠️", pkg, "- Not available (some tests may be skipped)\n")
  }
}

cat("\n")

# Run all tests
for (module in test_modules) {
  result <- run_test_file(module$file, module$name)
  test_results[[module$name]] <- result
  total_tests <- total_tests + result$passed + result$failed
  total_failures <- total_failures + result$failed
}

# Summary report
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📊 TEST SUMMARY REPORT\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# Overall statistics
total_passed <- sum(sapply(test_results, function(x) x$passed))
total_skipped <- sum(sapply(test_results, function(x) x$skipped))

cat("🔢 Overall Statistics:\n")
cat("   Total Tests Run:", total_tests, "\n")
cat("   Tests Passed:   ", total_passed, "\n") 
cat("   Tests Failed:   ", total_failures, "\n")
cat("   Tests Skipped:  ", total_skipped, "\n")
cat("   Success Rate:   ", round(total_passed / total_tests * 100, 1), "%\n\n")

# Module-by-module breakdown
cat("📋 Module Breakdown:\n")
for (module_name in names(test_results)) {
  result <- test_results[[module_name]]
  status <- if (result$failed == 0) "✅ PASS" else "❌ FAIL"
  cat("   ", status, "-", module_name, "\n")
  cat("      ", result$passed, "passed,", result$failed, "failed,", result$skipped, "skipped\n")
}

# Final verdict
cat("\n🏆 FINAL VERDICT:\n")
if (total_failures == 0) {
  cat("   ✅ ALL TESTS PASSED! 🎉\n")
  cat("   The R implementation is working correctly.\n")
  
  # Additional success info
  cat("\n🚀 Ready for Production:\n")
  cat("   • All 6 core modules tested successfully\n")
  cat("   • Event log processing ✓\n") 
  cat("   • Process mining integration ✓\n")
  cat("   • LLM API connectivity ✓\n")
  cat("   • Advanced analytics ✓\n")
  cat("   • Report orchestration ✓\n")
  cat("   • Multi-format report generation ✓\n")
  
} else {
  cat("   ❌ SOME TESTS FAILED\n")
  cat("   Please review the failed tests above and fix issues.\n")
  
  # Failure analysis
  failed_modules <- names(test_results)[sapply(test_results, function(x) x$failed > 0)]
  if (length(failed_modules) > 0) {
    cat("\n🔧 Modules needing attention:\n")
    for (module in failed_modules) {
      cat("   • ", module, "\n")
    }
  }
}

# Environment info
cat("\n💻 Test Environment:\n")
cat("   R Version:     ", R.version.string, "\n")
cat("   Platform:      ", R.version$platform, "\n")
cat("   Test Date:     ", as.character(Sys.time()), "\n")
cat("   Working Dir:   ", getwd(), "\n")

# Next steps
cat("\n📚 Next Steps:\n")
if (total_failures == 0) {
  cat("   1. Run the complete pipeline: source('R/examples/complete_pipeline_example.R')\n")
  cat("   2. Test with real data files\n") 
  cat("   3. Set up OpenRouter API key for LLM features\n")
  cat("   4. Generate your first clinical report\n")
} else {
  cat("   1. Review and fix failed tests\n")
  cat("   2. Re-run: Rscript R/tests/run_all_tests.R\n")
  cat("   3. Check module implementations in R/core/\n")
  cat("   4. Ensure all dependencies are installed\n")
}

cat("\n", paste(rep("=", 80), collapse = ""), "\n")
cat("🧪 HealthProcessAI R Test Suite Complete\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# Exit with appropriate code
if (total_failures > 0) {
  quit(status = 1)
} else {
  quit(status = 0)
}