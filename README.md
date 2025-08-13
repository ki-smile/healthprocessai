# 🏥 HealthProcessAI

## Process Mining Framework for Healthcare & Life Sciences

[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/ki-smile/HealthProcessAI/blob/main/notebooks/HealthProcessAI_Python_Colab.ipynb)

**Developed at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet**

HealthProcessAI is a comprehensive dual-language (Python & R) framework for applying process mining techniques to healthcare data, with integrated AI capabilities for generating clinical insights.

## 🎯 Overview

HealthProcessAI provides parallel implementations in both **Python** and **R**, allowing researchers and practitioners to choose their preferred environment while maintaining consistent methodology and results.

### 🐍 Python Implementation
- **Process Mining**: PM4PY library
- **Data Handling**: Pandas, NumPy
- **Visualization**: Graphviz, Matplotlib
- **AI Integration**: OpenRouter API

### 📊 R Implementation (NEW: Full 5-Step Pipeline)
- **Process Mining**: bupaR ecosystem
- **Data Handling**: tidyverse, dplyr
- **Visualization**: processmapR, ggplot2
- **AI Integration**: httr2, OpenRouter API
- **Advanced Analytics**: cluster, stats packages
- **Report Generation**: RMarkdown (MD/HTML/PDF/Word)

## 📚 Tutorials

### Learning Resources
- 📚 [Complete Tutorial](tutorials/complete_tutorial.md) - Comprehensive technical guide (2,700+ lines)
- 👩‍⚕️ [Clinician Tutorial](tutorials/clinician_pm_tutorial.md) - Healthcare professional guide
- 🐍 [Python Tutorial](tutorials/python_tutorial.md) - Python-specific implementation
- ⚡ [Quick Start](tutorials/quickstart.md) - 10-minute getting started guide

### Documentation
- 🔄 [Python vs R Comparison](docs/COMPARISON_PYTHON_R.md) - Detailed technical comparison
- 🚀 [Setup Guide](docs/SETUP_GUIDE.md) - Installation instructions
- 📁 [Project Structure](PROJECT_STRUCTURE.md) - Directory organization
- 📖 [API Documentation](docs/API_REFERENCE.md) - Technical reference

### Quick Links
- [Google Colab - Python](notebooks/HealthProcessAI_Python_Colab.ipynb)
- [Google Colab - R](notebooks/HealthProcessAI_R_Colab.ipynb)
- [Examples](examples/)

## 🚀 Quick Start

### Option 1: Google Colab (No Installation)

#### Python
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/ki-smile/HealthProcessAI/blob/main/notebooks/HealthProcessAI_Python_Colab.ipynb)

#### R
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/ki-smile/HealthProcessAI/blob/main/notebooks/HealthProcessAI_R_Colab.ipynb)

### Option 2: Local Installation with Conda (Recommended)

```bash
# Clone repository
git clone https://github.com/ki-smile/HealthProcessAI.git
cd HealthProcessAI

# Create conda environment (choose one):
# Option A: Latest compatible versions
conda env create -f environment.yml
conda activate healthprocessai

# Option B: Stable fixed versions (recommended if you encounter issues)
conda env create -f environment_stable.yml
conda activate healthprocessai_stable

# IMPORTANT: Always run from the repository root directory
# Use the -m flag to ensure proper module resolution (RECOMMENDED)
python -m examples.complete_pipeline_example

# Alternative: Run directly (may cause import errors)
# python examples/complete_pipeline_example.py

# Run modern R example (NEW: Full 5-step pipeline)
Rscript R/examples/complete_pipeline_example.R
```

### Option 3: Quick Install

#### Python
```bash
pip install -r requirements.txt

# IMPORTANT: Always run from the repository root directory using -m flag
python -m examples.complete_pipeline_example

# Note: If you get import errors, see docs/IMPORT_FIX.md for solutions
```

#### R
```R
# Install all required packages
source("requirements.R")

# Run the modern R implementation
source("R/examples/complete_pipeline_example.R")

# Example with custom data
pipeline <- CompleteProcessMiningPipeline$new(
  data_path = "data/your_data.csv",
  api_key = Sys.getenv("OPENROUTER_API_KEY"),
  output_dir = "./results_R"
)
results <- pipeline$run_complete_analysis()
```

## 📊 Key Features

| Feature | Python | R | Notes |
|---------|--------|---|-------|
| **Process Discovery** | PM4PY | bupaR | Both support full process mining |
| **Data Size** | Large (64-bit) | Medium-Large | Both handle healthcare datasets |
| **Visualization** | Graphviz | processmapR | R has interactive options |
| **LLM Integration** | ✅ | ✅ | Same OpenRouter API, multiple models |
| **Report Generation** | MD/HTML/PDF | MD/HTML/PDF/Word | R adds Word format |
| **Report Orchestration** | ✅ | ✅ | NEW: Both support multi-model synthesis |
| **Advanced Analytics** | ✅ | ✅ | Clustering, bottlenecks, predictions |
| **Performance** | Fast | Good | Python slightly faster on large data |
| **Learning Curve** | Moderate | Easier | R more intuitive for analysts |

## 🏥 Use Cases

1. **Sepsis Progression Analysis** - Track infection to sepsis pathways
2. **Organ Failure Monitoring** - Identify multi-organ dysfunction patterns
3. **Clinical Pathway Optimization** - Reduce bottlenecks in care delivery
4. **Disease Progression Modeling** - Understand temporal disease evolution
5. **Multi-Model Report Consolidation** - Synthesize insights from multiple AI models

## 📁 Project Structure

```
healthprocessai/
├── 📂 core/                # Python core modules (5-step pipeline)
├── 📂 R/                   # R implementation (NEW: Full pipeline)
│   ├── 📂 core/           # R core modules (5-step pipeline)
│   ├── 📂 examples/       # R example scripts
│   └── 📂 tests/          # R test suite
├── 📂 examples/            # Python example scripts
├── 📂 tutorials/           # Learning tutorials
├── 📂 notebooks/           # Jupyter & Colab notebooks
├── 📂 data/               # Sample datasets
├── 📂 docs/               # Technical documentation
├── 📂 tests/              # Python test suites
├── 📂 reports/            # Generated reports
└── 📂 legacy_original/    # Original R implementation
```

## 🔧 Requirements

### Python
- Python 3.10+
- PM4PY 2.7+
- Pandas 2.0+
- NumPy 1.24+

### R
- R 4.0+
- bupaR 0.5+
- tidyverse 2.0+
- httr 1.4+

## 🎯 New Feature: Report Orchestration (Step 5)

HealthProcessAI now includes an **Orchestrator** feature that consolidates insights from multiple LLM models into unified, comprehensive reports. The orchestrator:

- **Synthesizes** findings from 5+ different AI models
- **Identifies** consensus points and areas of disagreement
- **Preserves** innovative model-specific insights
- **Generates** comprehensive multi-model reports

### Using the Orchestrator

```python
from core.step5_orchestrator import ReportOrchestrator

# Initialize orchestrator
orchestrator = ReportOrchestrator(api_key=your_api_key)

# Consolidate multiple reports
orchestrated_report = orchestrator.consolidate_reports(
    reports={
        'anthropic': anthropic_report,
        'deepseek': deepseek_report,
        'google': gemini_report,
        'openai': gpt4_report,
        'xai': grok_report
    },
    case_info={
        'title': 'Sepsis Progression Analysis',
        'description': 'Multi-model synthesis of sepsis pathways'
    }
)

# Save orchestrated report
with open('reports/orchestrated/consolidated_analysis.md', 'w') as f:
    f.write(orchestrated_report)
```

### Orchestrated Report Features

- **Executive Summary** with consensus findings
- **Model Attribution** for each insight
- **Areas of Agreement vs. Disagreement**
- **Consolidated Recommendations**
- **Research Questions** from all models
- **Innovation Highlights** from each model

## 📈 Example Workflow

### Python
```python
from core.step1_data_loader import EventLogLoader
from core.step2_process_mining import ProcessMiner
from core.step3_llm_integration import LLMAnalyzer
from core.report_generator import ReportGenerator
from core.step5_orchestrator import ReportOrchestrator

# Load data
loader = EventLogLoader("data/sepsis_events.csv")
data = loader.load_and_prepare()

# Discover process
miner = ProcessMiner()
event_log = miner.create_event_log(data)
dfg = miner.discover_dfg()

# Generate insights
analyzer = LLMAnalyzer(api_key)
insights = analyzer.analyze(dfg)

# Create report
generator = ReportGenerator()
generator.generate_report(results, formats=['pdf'])

# NEW: Orchestrate multiple model reports (Step 5)
orchestrator = ReportOrchestrator()
orchestrated = orchestrator.consolidate_reports(
    reports={'anthropic': insights1, 'gemini': insights2, ...},
    case_info={'title': 'Sepsis Progression'}
)
```

### R (NEW: Full Pipeline Implementation)
```r
library(tidyverse)
library(bupaR)
library(R6)

# Source modern R modules
source("R/core/step1_data_loader.R")
source("R/core/step2_process_mining.R")
source("R/core/step3_llm_integration.R")
source("R/core/step4_advanced_analytics.R")
source("R/core/step5_orchestrator.R")
source("R/core/report_generator.R")

# Initialize pipeline
pipeline <- CompleteProcessMiningPipeline$new(
  data_path = "data/sepsis_events.csv",
  api_key = Sys.getenv("OPENROUTER_API_KEY"),
  output_dir = "./results"
)

# Run complete analysis with all steps
results <- pipeline$run_complete_analysis(
  sepsis_only = TRUE,
  use_llm = TRUE,
  llm_models = c("anthropic", "deepseek", "google")
)

# Results include:
# - Process discovery with bupaR
# - Advanced analytics (clustering, bottlenecks, KPIs)
# - Multi-model LLM insights
# - Orchestrated report synthesis
# - Multiple output formats (MD, HTML, PDF, Word)
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### Areas for Contribution
- Additional process mining algorithms
- New clinical use cases
- Performance optimizations
- Documentation translations
- Visualization improvements

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## 👥 Contributors

### Core Development Team

- **Farhad Abtahi** - Project Lead & Architecture Design
- **Eduardo Illueca Fernandez** - Process Mining Implementation & R Development
- **Kaile Chen** - Healthcare Analytics & Clinical Integration

### Contributing Organizations

- **SMAILE Lab** (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet
- Department of Clinical Science, Intervention and Technology, Karolinska Institutet

## 🙏 Acknowledgments

- PM4PY team (Python process mining)
- bupaR developers (R process mining)
- OpenRouter (LLM API access)
- PhysioNet (Clinical datasets)
- SMAILE Lab, Karolinska Institutet

## 📧 Contact

- **Project Lead**: Farhad Abtahi
- **Development Team**: SMAILE Lab
- **Email**: smaile@ki.se
- **GitHub**: [github.com/ki-smile/HealthProcessAI](https://github.com/ki-smile/HealthProcessAI)
- **Issues**: [Report Issues](https://github.com/ki-smile/HealthProcessAI/issues)

## 🔗 Citation

If you use HealthProcessAI in your research, please cite:

```bibtex
@software{healthprocessai2024,
  title = {HealthProcessAI: Process Mining Framework for Healthcare},
  author = {Abtahi, Farhad and Illueca Fernandez, Eduardo and Chen, Kaile},
  organization = {SMAILE Lab, Karolinska Institutet},
  year = {2024},
  url = {https://github.com/ki-smile/HealthProcessAI}
}
```

---

*Developed with ❤️ at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet*