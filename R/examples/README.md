# 📊 HealthProcessAI R Examples

## R Implementation Examples

This directory contains R versions of all Python examples, ported to use the bupaR ecosystem for process mining and healthcare analysis.

## 📁 Available Examples

### Core Pipeline Examples
- **`complete_pipeline_example.R`** - Complete 5-step HealthProcessAI pipeline in R
- **`example_patient_flow.R`** - Patient journey analysis with bupaR

### PhysioNet Data Processing
- **`example_physionet_to_infection.R`** - Infection progression analysis
- **`example_physionet_to_organ.R`** - Organ failure monitoring  
- **`example_transform_raw_to_eventlog.R`** - Raw data to event log transformation

## 🚀 Usage

### Prerequisites
```r
# Install required packages
source("requirements.R")

# Initialize HealthProcessAI R core
source("R/core/__init__.R")
source_all_modules()
```

### Run Examples
```r
# Run complete pipeline
source("R/examples/complete_pipeline_example.R")

# Run specific analysis
source("R/examples/example_patient_flow.R")
```

## 📊 Example Outputs

Each example generates:
- **Process Maps** - Visual representation of clinical pathways
- **Statistical Reports** - Process mining metrics and performance indicators
- **LLM Insights** - AI-generated clinical interpretations (if API key configured)
- **Markdown Reports** - Comprehensive analysis documents

## 🔧 Technology Mapping

Examples demonstrate R equivalents of Python functionality:

| Python | R Equivalent |
|--------|-------------|
| `pm4py.convert_to_event_log()` | `bupaR::eventlog()` |
| `pm4py.discover_dfg()` | `bupaR::process_map()` |
| `pandas.read_csv()` | `readr::read_csv()` |
| `requests.post()` | `httr2::req_perform()` |
| `matplotlib.pyplot` | `ggplot2` + `processmapR` |

## 📚 Documentation

Each example includes:
- **Header comments** explaining the clinical use case
- **Step-by-step documentation** of the R implementation  
- **Output descriptions** of generated results
- **Clinical interpretation** of findings

---

*These examples maintain feature parity with the Python implementation while leveraging R's strengths in statistical analysis and visualization.*