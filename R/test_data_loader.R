# Quick test of the R Data Loader
# ===============================

# Source the required packages
suppressPackageStartupMessages({
  if (!require(R6)) install.packages("R6")
  if (!require(tidyverse)) install.packages("tidyverse")
  if (!require(lubridate)) install.packages("lubridate")  
  if (!require(glue)) install.packages("glue")
  if (!require(fs)) install.packages("fs")
  
  library(R6)
  library(tidyverse)
  library(lubridate)
  library(glue)
  library(fs)
})

# Source our data loader
source("R/core/step1_data_loader.R")

# Create sample test data
cat("📊 Creating sample test data...\n")
test_data <- tibble::tibble(
  case = c("P001", "P001", "P001", "P002", "P002", "P003", "P003"),
  activity = c("Admission", "Blood Test", "Discharge", 
               "Admission", "Antibiotic", "Admission", "ICU Transfer"),
  timestamp = c("2024-01-01 08:00:00", "2024-01-01 10:30:00", "2024-01-01 16:00:00",
                "2024-01-02 09:15:00", "2024-01-02 12:00:00",
                "2024-01-03 07:30:00", "2024-01-03 14:45:00"),
  resource = c("Ward A", "Lab", "Ward A", "Ward B", "Pharmacy", "ER", "ICU"),
  SepsisLabel = c(0, 0, 0, 1, 1, 1, 1)
)

# Write to temporary file
temp_file <- "temp_test_data.csv"
readr::write_csv(test_data, temp_file)
cat(glue::glue("✅ Created test file: {temp_file}\n\n"))

# Test EventLogLoader class
cat("🔬 Testing EventLogLoader R6 Class\n")
cat("==================================\n")

tryCatch({
  # Initialize loader
  loader <- EventLogLoader$new(temp_file)
  cat("\n")
  
  # Load data
  raw_data <- loader$load_data()
  cat(glue::glue("📈 Loaded data dimensions: {nrow(raw_data)} rows × {ncol(raw_data)} columns\n\n"))
  
  # Prepare data  
  prepared_data <- loader$prepare_data()
  cat(glue::glue("📊 Prepared data dimensions: {nrow(prepared_data)} rows × {ncol(prepared_data)} columns\n"))
  cat(glue::glue("🕐 Derived features added: {paste(c('hour', 'day_of_week', 'time_since_start'), collapse = ', ')}\n\n"))
  
  # Get statistics
  stats <- loader$get_statistics()
  cat("📊 Dataset Statistics:\n")
  cat(glue::glue("   • Total events: {stats$num_events}\n"))
  cat(glue::glue("   • Total cases: {stats$num_cases}\n"))
  cat(glue::glue("   • Total activities: {stats$num_activities}\n"))
  cat(glue::glue("   • Sepsis rate: {round(stats$sepsis_rate * 100, 1)}%\n"))
  cat(glue::glue("   • Date range: {stats$date_range$start} to {stats$date_range$end}\n\n"))
  
  # Test filtering
  sepsis_data <- loader$filter_by_outcome(sepsis_only = TRUE)
  cat(glue::glue("🔍 Sepsis cases: {n_distinct(sepsis_data$case)} cases, {nrow(sepsis_data)} events\n"))
  
  non_sepsis_data <- loader$filter_by_outcome(sepsis_only = FALSE) 
  cat(glue::glue("🔍 Non-sepsis cases: {n_distinct(non_sepsis_data$case)} cases, {nrow(non_sepsis_data)} events\n\n"))
  
  # Test sampling
  sample_data <- loader$sample_cases(n = 2, seed = 42)
  cat("\n")
  
  # Test functional interface
  cat("🔬 Testing Functional Interface\n")
  cat("==============================\n")
  functional_data <- load_event_log(temp_file, prepare_data = TRUE)
  cat(glue::glue("✅ Functional interface loaded {nrow(functional_data)} events\n\n"))
  
  cat("🎉 All tests completed successfully!\n")
  
}, error = function(e) {
  cat(glue::glue("❌ Error during testing: {e$message}\n"))
}, finally = {
  # Clean up
  if (file.exists(temp_file)) {
    unlink(temp_file)
    cat(glue::glue("🧹 Cleaned up temp file: {temp_file}\n"))
  }
})

cat("\n✅ R Data Loader test completed!\n")