# Troubleshooting Guide

## Common Issues and Solutions

### 1. Import Error: "No module named 'core'"

**Problem:**
```python
ModuleNotFoundError: No module named 'core'
```

**Solution:**
Run scripts using the module syntax from the repository root:
```bash
# ✅ Correct
python -m examples.complete_pipeline_example

# ❌ Incorrect
python examples/complete_pipeline_example.py
```

See [IMPORT_FIX.md](IMPORT_FIX.md) for detailed explanations.

---

### 2. ThreadPoolCtl Error with Scikit-learn

**Problem:**
```python
AttributeError: 'NoneType' object has no attribute 'split'
# In threadpoolctl.py during sklearn operations
```

**Solutions:**

#### Option 1: Use Stable Environment (Recommended)
```bash
conda env create -f environment_stable.yml
conda activate healthprocessai_stable
```

#### Option 2: Update Packages
```bash
conda update scikit-learn threadpoolctl numpy joblib
# or
pip install --upgrade scikit-learn==1.3.0 threadpoolctl==3.2.0 numpy==1.24.3
```

#### Option 3: Set Thread Limits (Temporary Fix)
```bash
# Linux/Mac
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
python -m examples.complete_pipeline_example

# Windows
set OMP_NUM_THREADS=1
set MKL_NUM_THREADS=1
set OPENBLAS_NUM_THREADS=1
python -m examples.complete_pipeline_example
```

---

### 3. Graphviz Not Found

**Problem:**
```
ExecutableNotFound: failed to execute ['dot', '-Kdot', '-Tpng'], make sure the Graphviz executables are on your systems' PATH
```

**Solutions:**

#### macOS:
```bash
brew install graphviz
```

#### Ubuntu/Debian:
```bash
sudo apt-get install graphviz
```

#### Windows:
1. Download from https://graphviz.org/download/
2. Install to `C:\Program Files\Graphviz`
3. Add `C:\Program Files\Graphviz\bin` to PATH

#### Conda:
```bash
conda install -c conda-forge graphviz python-graphviz
```

---

### 4. PM4PY Installation Issues

**Problem:**
PM4PY not installing correctly or import errors

**Solution:**
Install via pip after activating conda environment:
```bash
conda activate healthprocessai
pip install pm4py==2.7.11.7
```

---

### 5. Memory Issues with Large Datasets

**Problem:**
Out of memory errors when processing large event logs

**Solutions:**

1. **Filter data early:**
```python
loader = EventLogLoader("large_data.csv")
# Filter before processing
filtered_data = loader.filter_by_outcome(sepsis_only=True)
```

2. **Use sampling:**
```python
# Sample 10% of cases
sampled_df = df.groupby('case').sample(frac=0.1)
```

3. **Increase memory allocation:**
```bash
# Set before running Python
export PYTHONMALLOC=malloc
python -m examples.complete_pipeline_example
```

---

### 6. OpenRouter API Key Issues

**Problem:**
API key not recognized or authentication failures

**Solutions:**

1. **Set environment variable:**
```bash
# Linux/Mac
export OPENROUTER_API_KEY="your-api-key-here"

# Windows
set OPENROUTER_API_KEY=your-api-key-here
```

2. **Use .env file:**
Create `.env` in project root:
```
OPENROUTER_API_KEY=your-api-key-here
```

3. **Pass directly in code:**
```python
analyzer = LLMAnalyzer(api_key="your-api-key-here")
```

---

### 7. R Package Installation Issues

**Problem:**
R packages failing to install

**Solution:**
```R
# Install from CRAN with dependencies
install.packages(c("tidyverse", "bupaR", "R6"), 
                 dependencies = TRUE,
                 repos = "https://cloud.r-project.org")

# If bupaR fails, try:
install.packages("remotes")
remotes::install_github("bupaverse/bupaR")
```

---

### 8. Jupyter Notebook Kernel Issues

**Problem:**
Jupyter can't find the healthprocessai kernel

**Solution:**
```bash
conda activate healthprocessai
python -m ipykernel install --user --name healthprocessai --display-name "HealthProcessAI"
jupyter notebook
```

---

## Platform-Specific Issues

### macOS Apple Silicon (M1/M2/M3)

Some packages may need special handling:

```bash
# Create environment with x86_64 emulation if needed
CONDA_SUBDIR=osx-64 conda create -n healthprocessai python=3.10
conda activate healthprocessai
conda config --env --set subdir osx-64
conda env update -f environment.yml
```

### Windows

1. **Long path issues:**
   Enable long paths in Windows:
   - Open Group Policy Editor (gpedit.msc)
   - Navigate to: Computer Configuration > Administrative Templates > System > Filesystem
   - Enable "Enable Win32 long paths"

2. **Execution policy for scripts:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

---

## Getting Help

If you encounter issues not covered here:

1. Check existing issues: https://github.com/ki-smile/HealthProcessAI/issues
2. Create a new issue with:
   - Your operating system and version
   - Python version (`python --version`)
   - Conda version (`conda --version`)
   - Complete error message
   - Steps to reproduce

3. Contact: smaile@ki.se