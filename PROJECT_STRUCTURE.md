# 📁 HealthProcessAI Project Structure

## Complete Directory Organization

```
healthprocessai/
│
├── 📄 README.md                    # Main project documentation
├── 📄 setup.py                     # Python package configuration
├── 📄 requirements.txt             # Python dependencies
├── 📄 requirements-dev.txt         # Development dependencies
├── 📄 requirements.R               # R dependencies installer
├── 📄 environment.yml              # Conda environment configuration
├── 📄 .gitignore                   # Git ignore rules
├── 📄 LICENSE                      # Project license
│
├── 📂 core/                        # Core modules
│   ├── step1_data_loader.py       # Data loading and preparation
│   ├── step2_process_mining.py    # Process discovery algorithms
│   ├── step3_llm_integration.py   # LLM/AI integration
│   ├── step4_advanced_analytics.py # Advanced analytics
│   └── report_generator.py        # Report generation (MD/PDF)
│
├── 📂 examples/                    # Example implementations
│   ├── complete_pipeline_example.py    # End-to-end pipeline
│   ├── example_patient_flow.py         # Patient flow analysis
│   ├── example_physionet_to_infection.py # Infection progression
│   ├── example_physionet_to_organ.py   # Organ failure progression
│   └── example_transform_raw_to_eventlog.py # Data transformation
│
├── 📂 tests/                       # Test suites
│   ├── test_suite.py              # Comprehensive test suite
│   ├── test_step1_data_loader.py # Data loader tests
│   ├── test_process_mining.py    # Process mining tests
│   └── test_integration.py       # Integration tests
│
├── 📂 notebooks/                   # Jupyter notebooks
│   ├── HealthProcessAI_Python_Colab.ipynb # Python Google Colab
│   ├── HealthProcessAI_R_Colab.ipynb      # R Google Colab
│   ├── Tutorial_01_Getting_Started.ipynb  # Tutorial notebook
│   └── Tutorial_02_Advanced_Analysis.ipynb # Advanced tutorial
│
├── 📂 data/                        # Data files
│   ├── sepsisAgregated_Infection.csv # Infection progression data
│   ├── sepsisAgregated_Organ.csv     # Organ failure data
│   ├── study1_matrix_*.csv           # Study 1 matrices
│   ├── study2_matrix_*.csv           # Study 2 matrices
│   └── sample/                       # Sample datasets
│       └── sample_event_log.csv      # Small sample for testing
│
├── 📂 docs/                        # Documentation
│   ├── TUTORIAL.md                # Comprehensive tutorial
│   ├── CLAUDE.md                  # Claude AI guidance
│   ├── SETUP_GUIDE.md             # Installation guide
│   ├── HEALTH_CHECK.md            # Project health check
│   ├── API_REFERENCE.md           # API documentation
│   └── CONTRIBUTING.md            # Contribution guidelines
│
├── 📂 resources/                   # Resources and templates
│   ├── prompts/                   # LLM prompt templates
│   │   ├── prompt_infection.txt   # Infection analysis prompt
│   │   ├── prompt_organ.txt       # Organ failure prompt
│   │   ├── prompt_kidney.txt      # Kidney disease prompt
│   │   └── prompt_kidney_2.txt    # Alternative kidney prompt
│   └── templates/                 # Report templates
│       ├── report_template.md     # Markdown template
│       └── report_template.html   # HTML template
│
├── 📂 reports/                     # Generated reports (gitignored)
│   ├── markdown/                  # Markdown reports
│   ├── pdf/                       # PDF reports
│   ├── html/                      # HTML reports
│   └── data/                      # Raw data exports
│
├── 📂 website/                     # Project website
│   ├── index.html                 # Main website
│   ├── css/                       # Stylesheets
│   ├── js/                        # JavaScript
│   └── assets/                    # Images and media
│
├── 📂 src/                         # Package source
│   └── healthprocessai/           # Python package
│       ├── __init__.py            # Package initialization
│       ├── clinical/              # Clinical modules
│       ├── epidemiology/          # Epidemiology modules
│       ├── disease_progression/   # Disease progression
│       └── utils/                 # Utility functions
│
├── 📂 R/                           # R implementation
│   ├── openRouter.R               # Main R script
│   ├── functions/                 # R functions
│   └── Reports/                   # R-generated reports
│       ├── Case I - Infection/
│       ├── Case II - Organ Damage/
│       ├── Case III - Glomerular Filtration Rate/
│       └── Case IV - Kidney Disease Progression/
│
├── 📂 config/                      # Configuration files
│   ├── settings.json              # Application settings
│   ├── models.json                # LLM model configurations
│   └── logging.conf               # Logging configuration
│
├── 📂 legacy_original/             # Original implementations (reference only)
│   ├── Python/                    # Original monolithic Python implementation
│   ├── R/                         # Original R implementation with reports
│   └── README.md                  # Explanation of legacy contents
│
└── 📂 .github/                     # GitHub specific
    ├── workflows/                  # GitHub Actions
    │   ├── tests.yml              # Automated testing
    │   └── docs.yml               # Documentation build
    └── ISSUE_TEMPLATE/            # Issue templates

```

## Key File Descriptions

### Core Modules (`core/`)
- **step1_data_loader.py**: Handles CSV loading, data validation, and preparation
- **step2_process_mining.py**: PM4PY integration for process discovery
- **step3_llm_integration.py**: OpenRouter API for multi-model LLM analysis
- **step4_advanced_analytics.py**: Clustering, predictions, bottleneck analysis
- **report_generator.py**: Generates MD/HTML/PDF reports with visualizations

### Examples (`examples/`)
- **complete_pipeline_example.py**: Full workflow from data to insights
- **example_patient_flow.py**: bupaR-style patient journey analysis
- **example_physionet_to_infection.py**: Transform raw data to infection events
- **example_physionet_to_organ.py**: Transform raw data to organ failure events

### Data (`data/`)
- **sepsisAgregated_*.csv**: Pre-processed event logs (~26MB each)
- **study*_matrix_*.csv**: Process matrices for comparative analysis

### Documentation (`docs/`)
- **TUTORIAL.md**: 8-section comprehensive tutorial
- **SETUP_GUIDE.md**: Installation for Conda, Colab, Docker
- **CLAUDE.md**: AI assistance guidelines

### Reports (`reports/`)
Generated reports are organized by format:
- `markdown/`: Human-readable Markdown reports
- `pdf/`: Professional PDF reports for stakeholders
- `html/`: Interactive HTML reports
- `data/`: JSON exports of analysis results

## Environment Setup

### Quick Start
```bash
# Using Conda (recommended)
conda env create -f environment.yml
conda activate healthprocessai

# Using pip
pip install -r requirements.txt

# For development
pip install -r requirements-dev.txt
```

### Google Colab
Open `notebooks/HealthProcessAI_Python_Colab.ipynb` in Google Colab for instant access.

## Typical Workflow

1. **Data Loading**: Use `core/step1_data_loader.py`
2. **Process Mining**: Use `core/step2_process_mining.py`
3. **LLM Analysis**: Use `core/step3_llm_integration.py`
4. **Advanced Analytics**: Use `core/step4_advanced_analytics.py`
5. **Report Generation**: Use `core/report_generator.py`

## Output Locations

- **Reports**: `reports/markdown/`, `reports/pdf/`
- **Process Maps**: `reports/data/`
- **Logs**: `logs/` (if logging enabled)
- **Temporary**: `tmp/` (cleaned automatically)

---

*Developed at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet*