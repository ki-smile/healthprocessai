# 🚀 HealthProcessAI Setup Guide

This guide provides detailed instructions for setting up HealthProcessAI in different environments.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Conda Setup (Recommended)](#conda-setup-recommended)
3. [Google Colab Setup](#google-colab-setup)
4. [Local Installation](#local-installation)
5. [Docker Setup](#docker-setup)
6. [Troubleshooting](#troubleshooting)

---

## 🏃 Quick Start

The fastest way to get started depends on your environment:

- **Local Machine**: Use [Conda](#conda-setup-recommended) (recommended)
- **Cloud/Browser**: Use [Google Colab](#google-colab-setup) (no installation needed)
- **Production**: Use [Docker](#docker-setup)

---

## 🐍 Conda Setup (Recommended)

Conda provides isolated environments and manages both Python and system dependencies.

### Prerequisites
- Install [Anaconda](https://www.anaconda.com/download) or [Miniconda](https://docs.conda.io/en/latest/miniconda.html)

### Step 1: Clone the Repository
```bash
git clone https://github.com/ki-smile/HealthProcessAI.git
cd HealthProcessAI
```

### Step 2: Create Conda Environment
```bash
# Create environment from file
conda env create -f environment.yml

# Activate the environment
conda activate healthprocessai
```

### Step 3: Verify Installation
```bash
# Check Python version
python --version  # Should show Python 3.10.x

# Test imports
python -c "import pm4py; print(f'PM4PY version: {pm4py.__version__}')"
python -c "import pandas; print(f'Pandas version: {pandas.__version__}')"
```

### Step 4: Configure API Keys
```bash
# Create .env file
echo "OPENROUTER_API_KEY=your-key-here" > .env

# Or export directly
export OPENROUTER_API_KEY="your-key-here"
```

### Step 5: Run Examples
```bash
# Navigate to examples
cd examples

# Run patient flow example
python example_patient_flow.py

# Run complete pipeline
python complete_pipeline_example.py
```

### Step 6: Launch Jupyter
```bash
# Start Jupyter Lab
jupyter lab

# Or classic notebook
jupyter notebook
```

---

## ☁️ Google Colab Setup

Google Colab provides free cloud-based Jupyter notebooks with GPU support.

### Option 1: Quick Start (One-Click)

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/ki-smile/HealthProcessAI/blob/main/notebooks/HealthProcessAI_Python_Colab.ipynb)

Click the badge above to open our pre-configured notebook.

### Option 2: Manual Setup in Colab

Create a new notebook and run these cells:

#### Cell 1: Install Dependencies
```python
# Install required packages
!pip install pm4py pandas numpy matplotlib seaborn graphviz requests -q
!pip install scikit-learn python-dotenv markdown weasyprint -q

# Install system dependencies
!apt-get update -qq
!apt-get install -y graphviz -qq

print("✅ All packages installed!")
```

#### Cell 2: Clone Repository
```python
# Clone HealthProcessAI repository
!git clone https://github.com/ki-smile/HealthProcessAI.git

# Navigate to repository
import os
os.chdir('healthprocessai')

# Add to Python path
import sys
sys.path.append('/content/healthprocessai')

print("✅ Repository cloned and configured!")
```

#### Cell 3: Configure API Key
```python
# Option 1: Direct input
OPENROUTER_API_KEY = "" # @param {type:"string"}

# Option 2: Use Colab secrets (recommended)
from google.colab import userdata
try:
    OPENROUTER_API_KEY = userdata.get('OPENROUTER_API_KEY')
    print("✅ API key loaded from secrets")
except:
    print("⚠️ Add your API key above or in Colab secrets")
```

#### Cell 4: Import and Test
```python
# Import HealthProcessAI modules
from core.step1_data_loader import EventLogLoader
from core.step2_process_mining import ProcessMiner
from core.step3_llm_integration import LLMAnalyzer

print("✅ HealthProcessAI imported successfully!")
```

#### Cell 5: Load Sample Data
```python
# Load sample data
import pandas as pd

# Option 1: Use provided data
df = pd.read_csv('data/sepsisAgregated_Infection.csv')

# Option 2: Upload your own
from google.colab import files
uploaded = files.upload()

print(f"✅ Loaded {len(df)} events")
```

### Working with Google Drive

Mount Google Drive to save results:

```python
from google.colab import drive
drive.mount('/content/drive')

# Save results to Drive
output_path = '/content/drive/MyDrive/HealthProcessAI_Results/'
!mkdir -p {output_path}
```

### GPU Acceleration (Optional)

Enable GPU for faster processing:

1. Runtime → Change runtime type
2. Select GPU as hardware accelerator
3. Verify GPU:
```python
import tensorflow as tf
print("GPU Available: ", tf.config.list_physical_devices('GPU'))
```

---

## 💻 Local Installation

### Option 1: Using pip with virtual environment

```bash
# Create virtual environment
python -m venv healthprocessai-env

# Activate (Windows)
healthprocessai-env\Scripts\activate

# Activate (Mac/Linux)
source healthprocessai-env/bin/activate

# Install requirements
pip install -r requirements.txt

# Install package in development mode
pip install -e .
```

### Option 2: Direct pip install (when published)

```bash
pip install healthprocessai
```

### System Dependencies

#### Windows
1. Download Graphviz from [graphviz.org](https://graphviz.org/download/)
2. Add to PATH: `C:\Program Files\Graphviz\bin`

#### Mac
```bash
brew install graphviz
```

#### Linux
```bash
sudo apt-get install graphviz
# or
sudo yum install graphviz
```

---

## 🐳 Docker Setup

### Using Pre-built Image (Coming Soon)
```bash
docker pull ki-smile/healthprocessai:latest
docker run -p 8888:8888 ki-smile/healthprocessai
```

### Build from Source
```bash
# Clone repository
git clone https://github.com/ki-smile/HealthProcessAI.git
cd HealthProcessAI

# Build image
docker build -t healthprocessai .

# Run container
docker run -p 8888:8888 -v $(pwd)/data:/app/data healthprocessai
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. PM4PY Import Error
```bash
# Solution: Install with specific version
pip install pm4py==2.7.11.7
```

#### 2. Graphviz Not Found
```bash
# Solution: Install system package
conda install graphviz python-graphviz -c conda-forge
```

#### 3. Memory Issues with Large Datasets
```python
# Solution: Process in chunks
chunk_size = 10000
for chunk in pd.read_csv('large_file.csv', chunksize=chunk_size):
    process_chunk(chunk)
```

#### 4. API Rate Limits
```python
# Solution: Add delays between requests
import time
time.sleep(1)  # Wait 1 second between API calls
```

### Environment Variables

Create `.env` file in project root:
```
OPENROUTER_API_KEY=your-key-here
HEALTHPROCESSAI_DATA_DIR=/path/to/data
HEALTHPROCESSAI_OUTPUT_DIR=/path/to/output
```

### Verify Installation

Run the test suite:
```bash
# Run all tests
pytest tests/

# Run with coverage
pytest --cov=healthprocessai tests/

# Run specific test
pytest tests/test_data_loader.py
```

---

## 📚 Additional Resources

- [API Key Setup](https://openrouter.ai/keys)
- [PM4PY Documentation](https://pm4py.fit.fraunhofer.de/)
- [Conda Cheat Sheet](https://docs.conda.io/projects/conda/en/latest/user-guide/cheatsheet.html)
- [Google Colab Tips](https://colab.research.google.com/notebooks/pro.ipynb)

---

## 🆘 Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search [existing issues](https://github.com/ki-smile/HealthProcessAI/issues)
3. Create a [new issue](https://github.com/ki-smile/HealthProcessAI/issues/new) with:
   - Your environment (OS, Python version)
   - Error message
   - Steps to reproduce

---

*Developed at SMAILE, Karolinska Institutet*