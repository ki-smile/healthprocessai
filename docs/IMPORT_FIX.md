# Import Error Fix Guide

## Problem
When running `python examples/complete_pipeline_example.py` directly, you may encounter:
```
ModuleNotFoundError: No module named 'core'
```

## Solution

### Option 1: Run as Module (Recommended)
Instead of running the script directly, use the `-m` flag to run it as a module:

```bash
# From the repository root directory:
python -m examples.complete_pipeline_example
```

### Option 2: Add Project to Python Path
If you need to run the script directly, first add the project root to Python path:

```bash
# Linux/Mac
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
python examples/complete_pipeline_example.py

# Windows
set PYTHONPATH=%PYTHONPATH%;%cd%
python examples/complete_pipeline_example.py
```

### Option 3: Install Package in Development Mode
Install the package in development mode so imports work from anywhere:

```bash
pip install -e .
python examples/complete_pipeline_example.py
```

## Why This Happens

Python needs to know where to find the `core` module. When you run a script directly with `python examples/script.py`, Python doesn't automatically add the parent directory to its module search path. 

Using `python -m` tells Python to run the script as a module, which properly sets up the import paths relative to the current directory.

## Best Practice

Always run Python scripts from the repository root directory using the module syntax:
- ✅ `python -m examples.complete_pipeline_example`
- ✅ `python -m examples.example_patient_flow`
- ❌ `python examples/complete_pipeline_example.py` (may cause import errors)

## Additional Notes

The error you saw about `AttributeError: 'NoneType' object has no attribute 'split'` is unrelated to imports - it's a scikit-learn/threadpoolctl compatibility issue that may require updating your packages:

```bash
pip install --upgrade scikit-learn threadpoolctl numpy
```