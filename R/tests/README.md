# 🧪 HealthProcessAI R Tests

## Test Suite for R Implementation

This directory contains the testthat-based test suite for the HealthProcessAI R implementation, ensuring feature parity with the Python version.

## 📁 Test Structure

```
tests/
├── testthat/
│   ├── test_step1_data_loader.R      # Data loading tests
│   ├── test_step2_process_mining.R   # Process mining tests
│   ├── test_step3_llm_integration.R  # LLM integration tests
│   ├── test_step4_advanced_analytics.R # Advanced analytics tests
│   ├── test_step5_orchestrator.R     # Orchestrator tests
│   ├── test_report_generator.R       # Report generation tests
│   └── test_examples.R               # Example script tests
├── fixtures/                         # Test data files
└── README.md                         # This file
```

## 🚀 Running Tests

### Run All Tests
```r
# From project root
testthat::test_dir("R/tests")

# Or using devtools
devtools::test(pkg = "R")
```

### Run Specific Tests
```r
# Test specific module
testthat::test_file("R/tests/testthat/test_step2_process_mining.R")

# Test with pattern matching
testthat::test_dir("R/tests", filter = "data_loader")
```

### Run with Coverage
```r
# Generate test coverage report
covr::package_coverage(path = "R")
```

## 🔧 Test Categories

### Unit Tests
- **Function-level testing** of individual R functions
- **Input validation** and error handling
- **Data type conversions** between R and bupaR formats

### Integration Tests
- **Pipeline testing** across multiple steps
- **API integration** with OpenRouter (mocked)
- **File I/O operations** and data persistence

### Comparison Tests
- **Python-R parity** testing for equivalent results
- **Cross-validation** of process mining outputs
- **Performance benchmarking** between implementations

## 📊 Test Data

### Sample Datasets
- **`fixtures/sample_sepsis_data.csv`** - Small test dataset
- **`fixtures/test_event_log.csv`** - Minimal event log for unit tests
- **`fixtures/expected_outputs/`** - Expected results for validation

### Mock Objects
- **Mock API responses** for LLM integration testing
- **Stub data** for rapid test execution
- **Test doubles** for external dependencies

## 🏥 Clinical Test Cases

Tests cover all clinical scenarios:

1. **Sepsis Progression** - Infection to sepsis pathway validation
2. **Organ Failure** - Multi-organ dysfunction pattern testing  
3. **Kidney Function** - GFR monitoring test cases
4. **Disease Progression** - Temporal evolution validation

## 📈 Test Metrics

Target test coverage:
- **Core modules**: >90% coverage
- **Examples**: >80% coverage  
- **Edge cases**: Comprehensive error handling
- **Performance**: Benchmarks vs Python implementation

## 🔄 Continuous Testing

### Pre-commit Tests
```r
# Quick validation before commits
testthat::test_dir("R/tests", reporter = "summary")
```

### Full Test Suite
```r
# Comprehensive testing for releases
source("R/tests/run_all_tests.R")
```

## 📚 Writing Tests

### Test Structure
```r
test_that("Data loader handles CSV files correctly", {
  # Setup
  test_file <- "fixtures/sample_data.csv"
  
  # Execute
  result <- load_event_data(test_file)
  
  # Verify
  expect_s3_class(result, "data.frame")
  expect_true("case_id" %in% names(result))
  expect_gt(nrow(result), 0)
})
```

### Mock API Calls
```r
test_that("LLM integration handles API errors gracefully", {
  # Mock failed API response
  with_mock(
    httr2::req_perform = function(...) stop("API Error"),
    {
      expect_error(query_openrouter("test", "prompt"))
      expect_message(query_openrouter("test", "prompt"), "API.*failed")
    }
  )
})
```

---

*Comprehensive testing ensures the R implementation maintains reliability and feature parity with the Python version.*