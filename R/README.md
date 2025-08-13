# 📊 HealthProcessAI - R Implementation

## Modern R Implementation for Healthcare Process Mining

This directory contains the R implementation of HealthProcessAI using the bupaR ecosystem for process mining and httr2 for LLM integration.

**Developed at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet**

## 📁 Directory Structure

```
R/
├── core/                    # Core R modules (5-step pipeline)
│   ├── __init__.R          # Package initialization
│   ├── step1_data_loader.R # Data loading with tidyverse
│   ├── step2_process_mining.R # Process mining with bupaR
│   ├── step3_llm_integration.R # LLM integration with httr2  
│   ├── step4_advanced_analytics.R # Advanced analytics
│   ├── step5_orchestrator.R # Report orchestration
│   └── report_generator.R  # Report generation with RMarkdown
├── examples/               # R example scripts
├── tests/                  # testthat unit tests
└── README.md              # This file
```

## 🚀 Quick Start

### 1. Initialize the R Environment

```r
# Load the core package
source("R/core/__init__.R")

# Load all modules
source_all_modules()
```

### 2. Run Complete Pipeline

```r
# Source main example
source("R/examples/complete_pipeline_example.R")
```

## 🔧 Technology Stack

| Component | R Package | Python Equivalent |
|-----------|-----------|-------------------|
| **Process Mining** | bupaR, edeaR | PM4PY |
| **Data Manipulation** | tidyverse, dplyr | pandas |
| **HTTP Requests** | httr2 | requests |
| **JSON Handling** | jsonlite | json |
| **Date/Time** | lubridate | datetime |
| **Reporting** | rmarkdown | markdown |
| **Visualization** | ggplot2, processmapR | matplotlib |
| **Testing** | testthat | pytest |

## 📈 Core Pipeline (5 Steps)

1. **Data Loading** - Load and prepare clinical event logs
2. **Process Mining** - Discover clinical pathways using bupaR
3. **LLM Integration** - Generate insights via OpenRouter API
4. **Advanced Analytics** - Conformance checking, clustering, bottlenecks
5. **Report Orchestration** - Consolidate multi-model outputs

## 🏥 Clinical Use Cases

- **Sepsis Progression Analysis** - Track infection to sepsis pathways
- **Organ Failure Monitoring** - Multi-organ dysfunction patterns  
- **Clinical Pathway Optimization** - Reduce care delivery bottlenecks
- **Disease Progression Modeling** - Temporal disease evolution

## 📚 Documentation

- See `tutorials/r_tutorial.md` for comprehensive R tutorial
- See `docs/COMPARISON_PYTHON_R.md` for Python vs R comparison
- Individual module documentation in each R file

## 🧪 Testing

```r
# Run all tests
testthat::test_dir("R/tests")
```

## 📊 Examples

All Python examples have been ported to R:

- `complete_pipeline_example.R` - Full 5-step pipeline
- `example_patient_flow.R` - Patient journey analysis  
- `example_physionet_to_infection.R` - PhysioNet infection analysis
- `example_physionet_to_organ.R` - PhysioNet organ failure analysis
- `example_transform_raw_to_eventlog.R` - Data transformation

## 🔗 Integration

This R implementation maintains feature parity with the Python version and can:
- Process the same data files
- Use the same OpenRouter API endpoints
- Generate equivalent analysis results
- Produce comparable visualizations

---

*For questions or support, visit: https://github.com/ki-smile/HealthProcessAI*