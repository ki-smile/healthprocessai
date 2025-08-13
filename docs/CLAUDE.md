# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a process mining project focused on analyzing sepsis progression using clinical data. The codebase contains both Python and R implementations for process mining analysis using various LLM models through the OpenRouter API.

**Developed at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet**

## Key Commands

### Python Development
```bash
# Run the main Python script
python Python/openRouter.py

# Install required Python packages (if needed)
pip install pm4py pandas numpy requests graphviz
```

### Data Files
The project uses CSV data files for sepsis cases located in both Python/ and R/ directories:
- `sepsisAgregated_Infection.csv` - Large dataset (~26MB) with infection-related sepsis cases
- `sepsisAgregated_Organ.csv` - Organ damage sepsis cases
- `study1_matrix_*.csv` and `study2_matrix_*.csv` - Process matrices for analysis

## Architecture and Structure

### Core Components

1. **Process Mining Analysis** (`Python/openRouter.py`)
   - `ProcessMiningAnalyzer` class handles PM4PY-based process mining
   - Converts CSV event logs to PM4PY format
   - Filters sepsis cases based on SepsisLabel
   - Generates process maps and matrices
   - Integrates with OpenRouter API for LLM analysis

2. **LLM Integration**
   - Both Python and R scripts query multiple LLM models via OpenRouter API
   - Models include: Anthropic Claude, Google Gemini, OpenAI GPT-4, DeepSeek, X-AI Grok
   - Prompts stored in `prompt_*.txt` files for different analysis scenarios

3. **Analysis Cases**
   The project analyzes four main sepsis progression scenarios:
   - Case I: Infection progression
   - Case II: Organ damage with/without sepsis
   - Case III: Glomerular filtration rate
   - Case IV: Kidney disease progression

4. **Report Generation**
   - Generated reports stored in `R/Reports/` organized by case
   - Each case contains model-specific analysis reports in Markdown format
   - Process maps exported as PNG images

5. **Report Orchestration** (`core/step5_orchestrator.py`) **[NEW]**
   - `ReportOrchestrator` class consolidates reports from multiple LLM models
   - Synthesizes consensus findings and preserves unique insights
   - Identifies areas of agreement and disagreement
   - Creates comprehensive multi-model reports
   - Orchestrated reports stored in `reports/orchestrated/`

### Key Data Flow
1. Load sepsis event logs from CSV files
2. Convert to PM4PY event log format with standard columns (case:concept:name, concept:name, time:timestamp)
3. Filter cases based on SepsisLabel (0 or 1)
4. Generate process maps and matrices
5. Query LLM models with process mining results and clinical prompts
6. Generate comprehensive clinical reports in Markdown
7. **[NEW]** Orchestrate multiple model reports using Claude API to create unified insights

## Advanced Methodological Approaches

### Based on State-of-the-Art Healthcare Process Mining Research

The project incorporates methodological approaches from recent healthcare process mining studies:

1. **Conformance Checking**
   - Token-based replay for guideline compliance assessment
   - Deviation analysis and categorization
   - Clinical protocol adherence measurement

2. **Patient Stratification**
   - Clustering based on pathway similarity
   - Outcome-based cohort identification
   - Feature importance analysis for cluster differentiation

3. **Bottleneck Analysis**
   - Sojourn time calculation at each activity
   - Critical path identification
   - Resource utilization optimization

4. **Predictive Process Monitoring**
   - Real-time risk assessment
   - Early warning system integration
   - Outcome prediction based on partial traces

5. **Clinical Performance Indicators**
   - Length of stay metrics
   - Readmission rate calculation
   - Resource utilization analysis
   - Guideline compliance rates

## Important Notes

- The Python script requires Graphviz to be installed at `C:\Program Files\Graphviz\bin` (Windows path hardcoded)
- OpenRouter API key must be set in environment or script
- Process states modeled: low/normal/high temperature, infection, sepsis (transitions are reversible)
- Reports target clinical and epidemiological stakeholders
- Advanced analytics module (`step4_advanced_analytics.py`) implements research-grade methodologies
- **[NEW]** Orchestrator module (`step5_orchestrator.py`) requires Claude API key for multi-model synthesis
- **[NEW]** Web evaluation dashboard (`website/llm_evaluation.html`) displays and compares all model reports
- project is aiming to provide a framework for learning process mining in Python and R and how to integrate it with LLM for making final reports and clinical insights. it is done by providing examples