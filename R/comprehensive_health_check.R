#!/usr/bin/env Rscript
#' Comprehensive Health Check for HealthProcessAI R Implementation
#' ===============================================================
#'
#' This script performs a complete health check of the R codebase including:
#' - Code quality checks (styler, lintr)
#' - Unit tests (testthat)
#' - Package structure validation
#' - Module loading verification
#' - Pipeline functionality
#' - Dependencies check
#'
#' Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments),
#' Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(jsonlite)
  library(glue)
})

#' Comprehensive Health Checker R6 Class
#'
#' @description
#' Performs comprehensive health checks on the HealthProcessAI R implementation.
ComprehensiveHealthChecker <- R6::R6Class(
  classname = "ComprehensiveHealthChecker",
  
  public = list(
    results = NULL,
    start_time = NULL,
    passed_checks = 0,
    failed_checks = 0,
    warnings = 0,
    
    #' Initialize health checker
    initialize = function() {
      self$results <- list()
      self$start_time <- Sys.time()
      self$passed_checks <- 0
      self$failed_checks <- 0
      self$warnings <- 0
    },
    
    #' Run a system command safely
    #'
    #' @param cmd Character string command to run
    #' @param description Description of the check
    #' @return List with success status and output
    run_command = function(cmd, description) {
      tryCatch({
        result <- system(cmd, intern = TRUE, ignore.stderr = FALSE)
        attr_status <- attr(result, "status")
        status <- is.null(attr_status) || attr_status == 0
        
        list(
          success = status,
          output = if(length(result) > 0) paste(result, collapse = "\n") else ""
        )
      }, error = function(e) {
        list(success = FALSE, output = conditionMessage(e))
      })
    },
    
    #' Check if all R modules can be loaded
    check_module_loading = function() {
      cat("\n🔍 Checking R module loading...\n")
      results <- list(passed = character(), failed = list())
      
      modules <- c(
        "R/core/step1_data_loader.R",
        "R/core/step2_process_mining.R", 
        "R/core/step3_llm_integration.R",
        "R/core/step4_advanced_analytics.R",
        "R/core/step5_orchestrator.R",
        "R/core/report_generator.R"
      )
      
      for (module in modules) {
        if (file.exists(module)) {
          tryCatch({
            source(module, local = TRUE)
            results$passed <- c(results$passed, module)
            cat(glue("  ✅ {basename(module)}\n"))
          }, error = function(e) {
            results$failed <- append(results$failed, list(list(
              module = module,
              error = conditionMessage(e)
            )))
            cat(glue("  ❌ {basename(module)}: {conditionMessage(e)}\n"))
          })
        } else {
          results$failed <- append(results$failed, list(list(
            module = module,
            error = "File not found"
          )))
          cat(glue("  ❌ {basename(module)}: File not found\n"))
        }
      }
      
      self$results$module_loading <- results
      
      if (length(results$failed) == 0) {
        self$passed_checks <- self$passed_checks + 1
      } else {
        self$failed_checks <- self$failed_checks + 1
      }
      
      return(results)
    },
    
    #' Check R code styling with styler
    check_code_styling = function() {
      cat("\n🎨 Checking R code styling...\n")
      
      if (!requireNamespace("styler", quietly = TRUE)) {
        cat("  ⚠️  styler package not available. Install with: install.packages('styler')\n")
        self$warnings <- self$warnings + 1
        return(list(status = "skipped", reason = "styler not available"))
      }
      
      tryCatch({
        # Check if files need styling
        r_files <- list.files("R", pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
        
        if (length(r_files) == 0) {
          cat("  ⚠️  No R files found to check\n")
          return(list(status = "warning", reason = "No R files found"))
        }
        
        # Count files that need styling
        needs_styling <- 0
        for (file in r_files) {
          if (styler::style_file(file, dry = "on")$changed) {
            needs_styling <- needs_styling + 1
          }
        }
        
        if (needs_styling == 0) {
          cat("  ✅ All R files are properly styled\n")
          self$passed_checks <- self$passed_checks + 1
          return(list(status = "passed", files_checked = length(r_files)))
        } else {
          cat(glue("  ⚠️  {needs_styling} files need styling\n"))
          self$warnings <- self$warnings + 1
          return(list(
            status = "warning", 
            files_need_styling = needs_styling,
            total_files = length(r_files)
          ))
        }
      }, error = function(e) {
        cat(glue("  ❌ Error checking code styling: {conditionMessage(e)}\n"))
        self$failed_checks <- self$failed_checks + 1
        return(list(status = "failed", error = conditionMessage(e)))
      })
    },
    
    #' Check R code with lintr
    check_linting = function() {
      cat("\n📝 Running R linting with lintr...\n")
      
      if (!requireNamespace("lintr", quietly = TRUE)) {
        cat("  ⚠️  lintr package not available. Install with: install.packages('lintr')\n")
        self$warnings <- self$warnings + 1
        return(list(status = "skipped", reason = "lintr not available"))
      }
      
      tryCatch({
        r_files <- list.files("R", pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
        
        if (length(r_files) == 0) {
          cat("  ⚠️  No R files found to lint\n")
          return(list(status = "warning", reason = "No R files found"))
        }
        
        total_issues <- 0
        issue_types <- list()
        
        for (file in r_files) {
          suppressMessages({
            lints <- lintr::lint(file)
          })
          
          if (length(lints) > 0) {
            total_issues <- total_issues + length(lints)
            for (lint in lints) {
              lint_type <- class(lint)[1]
              if (is.null(issue_types[[lint_type]])) {
                issue_types[[lint_type]] <- 0
              }
              issue_types[[lint_type]] <- issue_types[[lint_type]] + 1
            }
          }
        }
        
        if (total_issues == 0) {
          cat("  ✅ No linting issues found\n")
          self$passed_checks <- self$passed_checks + 1
          return(list(status = "passed", files_checked = length(r_files)))
        } else {
          cat(glue("  ⚠️  {total_issues} linting issues found\n"))
          self$warnings <- self$warnings + 1
          return(list(
            status = "warning",
            total_issues = total_issues,
            issue_types = issue_types,
            files_checked = length(r_files)
          ))
        }
      }, error = function(e) {
        cat(glue("  ❌ Error during linting: {conditionMessage(e)}\n"))
        self$failed_checks <- self$failed_checks + 1
        return(list(status = "failed", error = conditionMessage(e)))
      })
    },
    
    #' Run unit tests with testthat
    run_tests = function() {
      cat("\n🧪 Running unit tests...\n")
      
      if (!requireNamespace("testthat", quietly = TRUE)) {
        cat("  ⚠️  testthat package not available. Install with: install.packages('testthat')\n")
        self$warnings <- self$warnings + 1
        return(list(status = "skipped", reason = "testthat not available"))
      }
      
      test_dir <- "R/tests"
      if (!dir.exists(test_dir)) {
        cat(glue("  ⚠️  Test directory not found: {test_dir}\n"))
        self$warnings <- self$warnings + 1
        return(list(status = "warning", reason = "No test directory"))
      }
      
      tryCatch({
        # Get list of test files
        test_files <- list.files(test_dir, pattern = "^test.*\\.R$", full.names = TRUE)
        
        if (length(test_files) == 0) {
          cat("  ⚠️  No test files found\n")
          self$warnings <- self$warnings + 1
          return(list(status = "warning", reason = "No test files found"))
        }
        
        # Run tests and capture results
        total_tests <- 0
        total_passed <- 0
        total_failed <- 0
        total_skipped <- 0
        
        for (test_file in test_files) {
          cat(glue("  Running {basename(test_file)}...\n"))
          
          # Run individual test file
          suppressMessages({
            result <- testthat::test_file(test_file, reporter = "minimal", stop_on_failure = FALSE)
          })
          
          if (inherits(result, "testthat_results")) {
            n_tests <- length(result)
            n_passed <- sum(sapply(result, function(x) x$passed), na.rm = TRUE)
            n_failed <- sum(sapply(result, function(x) x$failed), na.rm = TRUE)
            n_skipped <- sum(sapply(result, function(x) x$skipped), na.rm = TRUE)
            
            total_tests <- total_tests + n_tests
            total_passed <- total_passed + n_passed
            total_failed <- total_failed + n_failed
            total_skipped <- total_skipped + n_skipped
            
            if (n_failed > 0) {
              cat(glue("    ❌ {n_passed} passed, {n_failed} failed, {n_skipped} skipped\n"))
            } else {
              cat(glue("    ✅ {n_passed} passed, {n_skipped} skipped\n"))
            }
          }
        }
        
        # Summary
        if (total_failed == 0) {
          cat(glue("\n  ✅ All tests passed: {total_passed} passed, {total_skipped} skipped\n"))
          self$passed_checks <- self$passed_checks + 1
          return(list(
            status = "passed",
            total_tests = total_tests,
            passed = total_passed,
            failed = total_failed,
            skipped = total_skipped
          ))
        } else {
          cat(glue("\n  ❌ Some tests failed: {total_passed} passed, {total_failed} failed, {total_skipped} skipped\n"))
          self$failed_checks <- self$failed_checks + 1
          return(list(
            status = "failed",
            total_tests = total_tests,
            passed = total_passed,
            failed = total_failed,
            skipped = total_skipped
          ))
        }
      }, error = function(e) {
        cat(glue("  ❌ Error running tests: {conditionMessage(e)}\n"))
        self$failed_checks <- self$failed_checks + 1
        return(list(status = "failed", error = conditionMessage(e)))
      })
    },
    
    #' Check package dependencies
    check_dependencies = function() {
      cat("\n📦 Checking package dependencies...\n")
      
      required_packages <- c(
        "tidyverse", "dplyr", "tidyr", "readr", "lubridate", "stringr",
        "glue", "jsonlite", "R6", "httr2", "cluster"
      )
      
      suggested_packages <- c(
        "bupaR", "edeaR", "processmapR", "rmarkdown", "knitr", 
        "ggplot2", "testthat", "styler", "lintr"
      )
      
      results <- list(
        required = list(available = character(), missing = character()),
        suggested = list(available = character(), missing = character())
      )
      
      # Check required packages
      for (pkg in required_packages) {
        if (requireNamespace(pkg, quietly = TRUE)) {
          results$required$available <- c(results$required$available, pkg)
          cat(glue("  ✅ {pkg} (required)\n"))
        } else {
          results$required$missing <- c(results$required$missing, pkg)
          cat(glue("  ❌ {pkg} (required) - MISSING\n"))
        }
      }
      
      # Check suggested packages
      for (pkg in suggested_packages) {
        if (requireNamespace(pkg, quietly = TRUE)) {
          results$suggested$available <- c(results$suggested$available, pkg)
          cat(glue("  ✅ {pkg} (suggested)\n"))
        } else {
          results$suggested$missing <- c(results$suggested$missing, pkg)
          cat(glue("  ⚠️  {pkg} (suggested) - missing\n"))
        }
      }
      
      self$results$dependencies <- results
      
      if (length(results$required$missing) == 0) {
        if (length(results$suggested$missing) > 0) {
          self$warnings <- self$warnings + 1
        } else {
          self$passed_checks <- self$passed_checks + 1
        }
      } else {
        self$failed_checks <- self$failed_checks + 1
      }
      
      return(results)
    },
    
    #' Validate package structure
    check_package_structure = function() {
      cat("\n📁 Checking package structure...\n")
      
      required_files <- c(
        "R/DESCRIPTION",
        "R/NAMESPACE", 
        "R/R/package.R",
        "R/man/HealthProcessAI-package.Rd"
      )
      
      required_dirs <- c(
        "R/core",
        "R/examples", 
        "R/tests",
        "R/man",
        "R/R"
      )
      
      results <- list(
        files = list(found = character(), missing = character()),
        directories = list(found = character(), missing = character())
      )
      
      # Check files
      for (file in required_files) {
        if (file.exists(file)) {
          results$files$found <- c(results$files$found, file)
          cat(glue("  ✅ {file}\n"))
        } else {
          results$files$missing <- c(results$files$missing, file)
          cat(glue("  ❌ {file}\n"))
        }
      }
      
      # Check directories
      for (dir in required_dirs) {
        if (dir.exists(dir)) {
          results$directories$found <- c(results$directories$found, dir)
          cat(glue("  ✅ {dir}/\n"))
        } else {
          results$directories$missing <- c(results$directories$missing, dir)
          cat(glue("  ❌ {dir}/\n"))
        }
      }
      
      self$results$package_structure <- results
      
      if (length(results$files$missing) == 0 && length(results$directories$missing) == 0) {
        self$passed_checks <- self$passed_checks + 1
        return(list(status = "passed"))
      } else {
        self$failed_checks <- self$failed_checks + 1
        return(list(status = "failed", results = results))
      }
    },
    
    #' Test R6 class instantiation
    test_r6_classes = function() {
      cat("\n🏗️  Testing R6 class instantiation...\n")
      
      # Source core modules first
      core_files <- list.files("R/core", pattern = "\\.R$", full.names = TRUE)
      
      for (file in core_files) {
        tryCatch({
          source(file, local = TRUE)
        }, error = function(e) {
          cat(glue("  ⚠️  Error sourcing {basename(file)}: {conditionMessage(e)}\n"))
        })
      }
      
      classes_to_test <- list(
        "EventLogLoader" = function() EventLogLoader$new(),
        "ProcessMiner" = function() ProcessMiner$new(),
        "ReportGenerator" = function() ReportGenerator$new()
      )
      
      # Only test LLMAnalyzer if we have a test key
      # classes_to_test[["LLMAnalyzer"]] <- function() LLMAnalyzer$new("test-key")
      
      results <- list(passed = character(), failed = list())
      
      for (class_name in names(classes_to_test)) {
        tryCatch({
          instance <- classes_to_test[[class_name]]()
          if (inherits(instance, "R6")) {
            results$passed <- c(results$passed, class_name)
            cat(glue("  ✅ {class_name}\n"))
          } else {
            results$failed <- append(results$failed, list(list(
              class = class_name,
              error = "Not an R6 instance"
            )))
            cat(glue("  ❌ {class_name}: Not an R6 instance\n"))
          }
        }, error = function(e) {
          results$failed <- append(results$failed, list(list(
            class = class_name,
            error = conditionMessage(e)
          )))
          cat(glue("  ❌ {class_name}: {conditionMessage(e)}\n"))
        })
      }
      
      self$results$r6_classes <- results
      
      if (length(results$failed) == 0) {
        self$passed_checks <- self$passed_checks + 1
      } else {
        self$failed_checks <- self$failed_checks + 1
      }
      
      return(results)
    },
    
    #' Generate comprehensive report
    generate_report = function() {
      end_time <- Sys.time()
      duration <- round(as.numeric(difftime(end_time, self$start_time, units = "secs")), 2)
      
      cat("\n", paste(rep("=", 80), collapse = ""), "\n")
      cat("📊 COMPREHENSIVE HEALTH CHECK REPORT\n")
      cat(paste(rep("=", 80), collapse = ""), "\n\n")
      
      # Overall summary
      total_checks <- self$passed_checks + self$failed_checks + self$warnings
      success_rate <- if(total_checks > 0) round((self$passed_checks / total_checks) * 100, 1) else 0
      
      cat("🔍 Overall Summary:\n")
      cat(glue("   • Total checks: {total_checks}\n"))
      cat(glue("   • Passed: {self$passed_checks}\n"))
      cat(glue("   • Failed: {self$failed_checks}\n")) 
      cat(glue("   • Warnings: {self$warnings}\n"))
      cat(glue("   • Success rate: {success_rate}%\n"))
      cat(glue("   • Duration: {duration} seconds\n"))
      
      # Health status
      if (self$failed_checks == 0) {
        if (self$warnings == 0) {
          cat("\n🎉 OVERALL STATUS: EXCELLENT HEALTH ✅\n")
          cat("   All checks passed without issues!\n")
        } else {
          cat("\n✅ OVERALL STATUS: GOOD HEALTH\n")
          cat("   All critical checks passed with some minor warnings.\n")
        }
      } else {
        cat("\n⚠️ OVERALL STATUS: NEEDS ATTENTION\n")
        cat("   Some critical checks failed. Please review and fix issues.\n")
      }
      
      # Detailed results
      if (length(self$results) > 0) {
        cat("\n📋 Detailed Results:\n")
        
        for (check_name in names(self$results)) {
          result <- self$results[[check_name]]
          cat(glue("   • {str_to_title(gsub('_', ' ', check_name))}: "))
          
          if (is.list(result) && "status" %in% names(result)) {
            status <- result$status
            if (status == "passed") {
              cat("✅ PASSED\n")
            } else if (status == "failed") {
              cat("❌ FAILED\n")
            } else if (status == "warning") {
              cat("⚠️ WARNING\n") 
            } else {
              cat("ℹ️ SKIPPED\n")
            }
          } else {
            cat("ℹ️ COMPLETED\n")
          }
        }
      }
      
      # Recommendations
      cat("\n💡 Recommendations:\n")
      if (self$failed_checks > 0) {
        cat("   1. Review failed checks and fix critical issues\n")
        cat("   2. Run individual checks for detailed error messages\n")
      }
      if (self$warnings > 0) {
        cat("   3. Address warnings for better code quality\n")
        cat("   4. Install missing suggested packages for full functionality\n")
      }
      if (self$passed_checks == total_checks) {
        cat("   1. Excellent! Consider running performance benchmarks\n")
        cat("   2. Review documentation for completeness\n")
        cat("   3. Consider adding more comprehensive tests\n")
      }
      
      # Next steps
      cat("\n🚀 Next Steps:\n")
      cat("   • Run specific checks for detailed diagnostics\n")
      cat("   • Use styler::style_dir('R/') to fix styling issues\n") 
      cat("   • Install missing packages with install.packages()\n")
      cat("   • Run R/tests/run_all_tests.R for detailed test results\n")
      
      cat("\n", paste(rep("=", 80), collapse = ""), "\n")
      cat("🏥 HealthProcessAI R Implementation Health Check Complete\n")
      cat(paste(rep("=", 80), collapse = ""), "\n\n")
      
      # Return summary for programmatic use
      list(
        summary = list(
          total_checks = total_checks,
          passed = self$passed_checks,
          failed = self$failed_checks,
          warnings = self$warnings,
          success_rate = success_rate,
          duration = duration,
          status = if(self$failed_checks == 0) "healthy" else "needs_attention"
        ),
        detailed_results = self$results,
        timestamp = end_time
      )
    },
    
    #' Run all health checks
    run_all_checks = function() {
      cat("🏥 HealthProcessAI R Implementation - Comprehensive Health Check\n")
      cat(paste(rep("=", 80), collapse = ""), "\n")
      cat("Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments),\n")
      cat("Karolinska Institutet\n")
      cat("\nStarting comprehensive health check...\n")
      
      # Run all checks
      self$results$module_loading <- self$check_module_loading()
      self$results$dependencies <- self$check_dependencies()
      self$results$package_structure <- self$check_package_structure()
      self$results$code_styling <- self$check_code_styling()
      self$results$linting <- self$check_linting()
      self$results$unit_tests <- self$run_tests()
      self$results$r6_classes <- self$test_r6_classes()
      
      # Generate final report
      report <- self$generate_report()
      
      # Save results
      results_file <- "R_health_check_results.json"
      writeLines(jsonlite::toJSON(report, auto_unbox = TRUE, pretty = TRUE), results_file)
      cat(glue("\n💾 Detailed results saved to: {results_file}\n"))
      
      return(report)
    }
  )
)

# Main execution
if (!interactive()) {
  checker <- ComprehensiveHealthChecker$new()
  result <- checker$run_all_checks()
  
  # Exit with error code if health check failed
  if (result$summary$failed > 0) {
    quit(status = 1)
  } else {
    quit(status = 0)
  }
} else {
  # Interactive usage
  cat("ℹ️ Comprehensive health checker loaded.\n")
  cat("Usage: checker <- ComprehensiveHealthChecker$new(); checker$run_all_checks()\n")
}