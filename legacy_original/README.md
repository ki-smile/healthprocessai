# Legacy Original Implementations

This directory contains the original monolithic implementations of the process mining framework before the refactoring into the modular HealthProcessAI structure.

## Contents

### Python/
- **openRouter.py** - Original monolithic Python implementation (36KB)
- **prompt_*.txt** - LLM prompt templates (moved copies to `resources/prompts/`)
- **legacy_backup/** - Previous backup directory

### R/
- **openRouter.R** - Original monolithic R implementation  
- **Reports/** - Generated LLM analysis reports from original runs
  - Case I - Infection progression analysis
  - Case II - Organ damage analysis
  - Case III - Glomerular filtration rate analysis
  - Case IV - Kidney disease progression analysis
- **Data files** - Original data files (proper copies in `data/` directory)
  - sepsisAgregated_Infection.csv (26MB)
  - sepsisAgregated_Organ.csv (318KB)
  - study matrices (CSV files)
- **R environment files** - .RData, .Rhistory

## Current Status

✅ **Python code** has been refactored into:
- `core/step1_data_loader.py`
- `core/step2_process_mining.py`
- `core/step3_llm_integration.py`
- `core/step4_advanced_analytics.py`

✅ **Data files** have been organized in:
- `data/` directory (main location)

✅ **Prompts** have been organized in:
- `resources/prompts/` directory

✅ **Reports** generation functionality has been implemented in:
- `core/report_generator.py`

## Why Keep These Files?

1. **Historical reference** - Original implementation logic
2. **Generated reports** - Previous analysis results with different LLMs
3. **Validation** - Can compare outputs between old and new implementations
4. **R environment** - .RData may contain saved analysis objects

## Migration Notes

If you need to reference the original implementations:

### For Python users:
- Original logic is in `Python/openRouter.py`
- New modular implementation in `core/` directory
- Use the new modular approach for all new work

### For R users:
- Original script is in `R/openRouter.R`
- New R tutorial with modern approach in `tutorials/r_tutorial.md`
- Data files are available in the main `data/` directory

---

*These files are preserved for reference but should not be used for new development. Use the refactored HealthProcessAI framework instead.*