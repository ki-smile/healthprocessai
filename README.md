# 🏥 HealthProcessAI

## Process Mining Framework for Healthcare & Life Sciences

[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/smaile/healthprocessai/blob/main/notebooks/HealthProcessAI_Python_Colab.ipynb)

**Developed at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet**

HealthProcessAI is a comprehensive dual-language (Python & R) framework for applying process mining techniques to healthcare data, with integrated AI capabilities for generating clinical insights.

## 🎯 Overview

HealthProcessAI provides parallel implementations in both **Python** and **R**, allowing researchers and practitioners to choose their preferred environment while maintaining consistent methodology and results.

### 🐍 Python Implementation
- **Process Mining**: PM4PY library
- **Data Handling**: Pandas, NumPy
- **Visualization**: Graphviz, Matplotlib
- **AI Integration**: OpenRouter API

### 📊 R Implementation  
- **Process Mining**: bupaR ecosystem
- **Data Handling**: tidyverse, dplyr
- **Visualization**: processmapR, ggplot2
- **AI Integration**: httr, OpenRouter API

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
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/smaile/healthprocessai/blob/main/notebooks/HealthProcessAI_Python_Colab.ipynb)

#### R
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/smaile/healthprocessai/blob/main/notebooks/HealthProcessAI_R_Colab.ipynb)

### Option 2: Local Installation with Conda (Recommended)

```bash
# Clone repository
git clone https://github.com/smaile/healthprocessai.git
cd healthprocessai

# Create conda environment
conda env create -f environment.yml
conda activate healthprocessai

# Run Python example
python examples/complete_pipeline_example.py

# Run R example
Rscript R/openRouter.R
```

### Option 3: Quick Install

#### Python
```bash
pip install -r requirements.txt
python examples/complete_pipeline_example.py
```

#### R
```R
source("requirements.R")  # Installs all R packages
source("R/openRouter.R")
```

## 📊 Key Features

| Feature | Python | R | Notes |
|---------|--------|---|-------|
| **Process Discovery** | PM4PY | bupaR | Both support DFG, Petri nets |
| **Data Size** | Large (64-bit) | Medium | Python better for big data |
| **Visualization** | Graphviz | processmapR | R has interactive options |
| **LLM Integration** | ✅ | ✅ | Same OpenRouter API |
| **Report Generation** | MD/HTML/PDF | MD/HTML | Python has more formats |
| **Report Orchestration** | ✅ | 🔄 | NEW: Multi-model synthesis |
| **Performance** | Fast | Moderate | Python ~2x faster |
| **Learning Curve** | Moderate | Easier | R more intuitive syntax |

## 🏥 Use Cases

1. **Sepsis Progression Analysis** - Track infection to sepsis pathways
2. **Organ Failure Monitoring** - Identify multi-organ dysfunction patterns
3. **Clinical Pathway Optimization** - Reduce bottlenecks in care delivery
4. **Disease Progression Modeling** - Understand temporal disease evolution
5. **Multi-Model Report Consolidation** - Synthesize insights from multiple AI models

## 📁 Project Structure

```
healthprocessai/
├── 📂 core/           # Python core modules
├── 📂 R/              # R implementation
├── 📂 examples/       # Example scripts (Python)
├── 📂 tutorials/      # Learning tutorials
├── 📂 notebooks/      # Jupyter & Colab notebooks
├── 📂 data/           # Sample datasets
├── 📂 docs/           # Technical documentation
├── 📂 tests/          # Test suites
└── 📂 reports/        # Generated reports
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

### R
```r
library(bupaR)
library(httr)

# Load data
event_log <- read_csv("data/sepsis_events.csv") %>%
  eventlog(case_id = "case",
           activity_id = "activity",
           timestamp = "timestamp")

# Discover process
process_map(event_log)

# Generate insights
insights <- query_openrouter(process_data, api_key)

# Create report
generate_report(insights, format = "html")
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
- **GitHub**: [github.com/smaile/healthprocessai](https://github.com/smaile/healthprocessai)
- **Issues**: [Report Issues](https://github.com/smaile/healthprocessai/issues)

## 🔗 Citation

If you use HealthProcessAI in your research, please cite:

```bibtex
@software{healthprocessai2024,
  title = {HealthProcessAI: Process Mining Framework for Healthcare},
  author = {Abtahi, Farhad and Illueca Fernandez, Eduardo and Chen, Kaile},
  organization = {SMAILE Lab, Karolinska Institutet},
  year = {2024},
  url = {https://github.com/smaile/healthprocessai}
}
```

---

*Developed with ❤️ at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet*