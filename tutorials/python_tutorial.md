# 🐍 HealthProcessAI Python Tutorial

## Complete Guide to Process Mining in Healthcare with Python

This tutorial covers the Python implementation of HealthProcessAI using PM4PY and modern Python libraries.

**Contributors:**
- **Farhad Abtahi** - Framework Architecture & Healthcare Integration
- **Eduardo Illueca Fernandez** - Process Mining Algorithms & Implementation
- **Kaile Chen** - Clinical Analytics & Data Transformation Methods

## 📚 Table of Contents

1. [Environment Setup](#1-environment-setup)
2. [Data Loading & Preparation](#2-data-loading--preparation)
3. [Process Discovery with PM4PY](#3-process-discovery-with-pm4py)
4. [Advanced Analytics](#4-advanced-analytics)
5. [LLM Integration](#5-llm-integration)
6. [Report Generation](#6-report-generation)
7. [Production Deployment](#7-production-deployment)
8. [Best Practices](#8-best-practices)

---

## 1. Environment Setup

### 1.1 Conda Environment (Recommended)

```bash
# Create environment
conda create -n healthprocessai python=3.10
conda activate healthprocessai

# Install from environment.yml
conda env create -f environment.yml
```

### 1.2 Virtual Environment

```bash
# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (Mac/Linux)
source venv/bin/activate

# Install packages
pip install -r requirements.txt
```

### 1.3 Verify Installation

```python
import pm4py
import pandas as pd
import numpy as np

print(f"PM4PY version: {pm4py.__version__}")
print(f"Pandas version: {pd.__version__}")
print(f"NumPy version: {np.__version__}")

# Test PM4PY
from pm4py.objects.log.importer.xes import importer as xes_importer
print("✅ All packages installed successfully!")
```

---

## 2. Data Loading & Preparation

### 2.1 Understanding Event Logs

```python
import pandas as pd
from datetime import datetime

# Event log structure
event_log_structure = {
    'case': 'Patient/Case identifier',
    'activity': 'Clinical activity/event',
    'timestamp': 'When the event occurred',
    'resource': 'Who/what performed the activity',
    'additional_attributes': 'Any other relevant data'
}

# Load healthcare event log
df = pd.read_csv('data/sepsisAgregated_Infection.csv')
print(f"Loaded {len(df)} events from {df['case'].nunique()} patients")
```

### 2.2 Data Preparation Pipeline

```python
from core.step1_data_loader import EventLogLoader

class HealthcareDataPrep:
    """Prepare healthcare data for process mining."""
    
    def __init__(self, filepath):
        self.loader = EventLogLoader(filepath)
        
    def prepare_pipeline(self):
        # Step 1: Load raw data
        raw_data = self.loader.load_data()
        print(f"✅ Loaded {len(raw_data)} events")
        
        # Step 2: Clean and validate
        raw_data = self.clean_data(raw_data)
        
        # Step 3: Add derived features
        prepared_data = self.loader.prepare_data()
        
        # Step 4: Filter by outcome if needed
        sepsis_data = self.loader.filter_by_outcome(sepsis_only=True)
        
        return prepared_data
    
    def clean_data(self, df):
        """Clean healthcare data."""
        # Remove nulls in critical columns
        df = df.dropna(subset=['case', 'activity', 'timestamp'])
        
        # Standardize activity names
        df['activity'] = df['activity'].str.strip().str.title()
        
        # Convert timestamps
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        
        return df

# Usage
prep = HealthcareDataPrep('data/sepsis_events.csv')
data = prep.prepare_pipeline()
```

---

## 3. Process Discovery with PM4PY

### 3.1 Creating Event Logs

```python
import pm4py
from pm4py.objects.log.obj import EventLog, Trace, Event
from pm4py.util import constants

def create_event_log(df):
    """Convert DataFrame to PM4PY EventLog."""
    
    # Rename columns to PM4PY format
    df_pm4py = df.rename(columns={
        'case': 'case:concept:name',
        'activity': 'concept:name',
        'timestamp': 'time:timestamp',
        'resource': 'org:resource'
    })
    
    # Convert to EventLog
    event_log = pm4py.convert_to_event_log(df_pm4py)
    
    print(f"Created event log with {len(event_log)} cases")
    return event_log

event_log = create_event_log(data)
```

### 3.2 Process Discovery Algorithms

```python
# Directly-Follows Graph (DFG)
dfg, start_activities, end_activities = pm4py.discover_dfg(event_log)
print(f"Discovered {len(dfg)} transitions")

# Visualize DFG
pm4py.view_dfg(dfg, start_activities, end_activities)

# Heuristics Miner
from pm4py.algo.discovery.heuristics import algorithm as heuristics_miner
heu_net = heuristics_miner.apply(event_log)
pm4py.view_heuristics_net(heu_net)

# Alpha Miner (for structured processes)
from pm4py.algo.discovery.alpha import algorithm as alpha_miner
petri_net, initial_marking, final_marking = alpha_miner.apply(event_log)
pm4py.view_petri_net(petri_net, initial_marking, final_marking)

# Inductive Miner (noise-resistant)
from pm4py.algo.discovery.inductive import algorithm as inductive_miner
net, im, fm = inductive_miner.apply(event_log)
```

### 3.3 Process Maps and Visualization

```python
from pm4py.visualization.dfg import visualizer as dfg_visualizer
from pm4py.statistics.traces.generic.log import case_statistics

# Custom visualization parameters
parameters = {
    dfg_visualizer.Variants.FREQUENCY.value.Parameters.FORMAT: "png",
    dfg_visualizer.Variants.FREQUENCY.value.Parameters.START_ACTIVITIES: start_activities,
    dfg_visualizer.Variants.FREQUENCY.value.Parameters.END_ACTIVITIES: end_activities,
    dfg_visualizer.Variants.FREQUENCY.value.Parameters.FONT_SIZE: 12,
    dfg_visualizer.Variants.FREQUENCY.value.Parameters.BGCOLOR: "white"
}

# Generate and save visualization
gviz = dfg_visualizer.apply(dfg, start_activities, end_activities, parameters=parameters)
dfg_visualizer.save(gviz, "process_map.png")

# Get process statistics
variants = pm4py.get_variants(event_log)
print(f"Found {len(variants)} process variants")

# Top variants
for variant, cases in list(variants.items())[:5]:
    print(f"Variant: {variant}")
    print(f"  Cases: {len(cases)} ({len(cases)/len(event_log)*100:.1f}%)")
```

---

## 4. Advanced Analytics

### 4.1 Conformance Checking

```python
from pm4py.algo.conformance.tokenreplay import algorithm as token_replay

# Check conformance between log and model
replayed_traces = token_replay.apply(event_log, petri_net, 
                                     initial_marking, final_marking)

# Calculate fitness
fitness = sum([x['trace_fitness'] for x in replayed_traces]) / len(replayed_traces)
print(f"Process fitness: {fitness:.2%}")

# Identify deviations
deviations = [x for x in replayed_traces if x['trace_fitness'] < 1.0]
print(f"Found {len(deviations)} non-conforming cases")
```

### 4.2 Performance Analysis

```python
from pm4py.statistics.attributes.log import get as attributes_get
from pm4py.algo.enhancement.sna import algorithm as sna

# Case duration statistics
from pm4py.statistics.traces.generic.log import case_statistics
case_durations = case_statistics.get_all_case_durations(event_log)

print(f"Average case duration: {np.mean(case_durations):.2f} hours")
print(f"Median case duration: {np.median(case_durations):.2f} hours")

# Bottleneck analysis
from pm4py.statistics.sojourn_time.log import get as soj_time_get
sojourn_times = soj_time_get.apply(event_log, 
                                   parameters={
                                       soj_time_get.Parameters.AGGREGATION_MEASURE: "mean"
                                   })

# Find bottlenecks (activities with longest waiting times)
bottlenecks = sorted(sojourn_times.items(), 
                    key=lambda x: x[1], 
                    reverse=True)[:5]

print("\nTop 5 Bottlenecks:")
for activity, wait_time in bottlenecks:
    print(f"  {activity}: {wait_time:.2f} hours average wait")
```

### 4.3 Predictive Process Monitoring

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import numpy as np

def prepare_features_for_prediction(event_log):
    """Prepare features for outcome prediction."""
    features = []
    labels = []
    
    for trace in event_log:
        # Extract trace features
        trace_features = {
            'num_events': len(trace),
            'duration': (trace[-1]['time:timestamp'] - 
                        trace[0]['time:timestamp']).total_seconds() / 3600,
            'unique_activities': len(set([e['concept:name'] for e in trace])),
            'has_icu': int(any('ICU' in e['concept:name'] for e in trace)),
            'has_antibiotic': int(any('Antibiotic' in e['concept:name'] for e in trace))
        }
        
        features.append(list(trace_features.values()))
        
        # Extract label (e.g., sepsis outcome)
        labels.append(trace.attributes.get('SepsisLabel', 0))
    
    return np.array(features), np.array(labels)

# Prepare data
X, y = prepare_features_for_prediction(event_log)

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, 
                                                      test_size=0.2, 
                                                      random_state=42)

# Train model
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train, y_train)

# Evaluate
accuracy = clf.score(X_test, y_test)
print(f"Prediction accuracy: {accuracy:.2%}")

# Feature importance
feature_names = ['num_events', 'duration', 'unique_activities', 
                'has_icu', 'has_antibiotic']
importances = clf.feature_importances_

for name, importance in zip(feature_names, importances):
    print(f"{name}: {importance:.3f}")
```

---

## 5. LLM Integration

### 5.1 Setting up OpenRouter

```python
from core.step3_llm_integration import LLMAnalyzer
import os

# Set API key
os.environ['OPENROUTER_API_KEY'] = 'your-api-key-here'

# Initialize analyzer
analyzer = LLMAnalyzer(os.environ['OPENROUTER_API_KEY'])
```

### 5.2 Generating Clinical Insights

```python
def generate_process_insights(dfg, event_log, analyzer):
    """Generate AI-powered insights from process mining results."""
    
    # Prepare process data
    process_data = {
        'num_cases': len(event_log),
        'num_events': sum(len(trace) for trace in event_log),
        'num_activities': len(pm4py.get_event_attribute_values(event_log, 'concept:name')),
        'top_transitions': sorted(dfg.items(), key=lambda x: x[1], reverse=True)[:10],
        'variants': len(pm4py.get_variants(event_log))
    }
    
    # Create prompt
    prompt = analyzer.create_clinical_prompt(process_data, 'sepsis_progression')
    
    # Query multiple models
    models = [
        'anthropic/claude-3-sonnet',
        'openai/gpt-4',
        'google/gemini-pro'
    ]
    
    insights = {}
    for model in models:
        try:
            response = analyzer.query_model(model, [{"role": "user", "content": prompt}])
            insights[model] = response['choices'][0]['message']['content']
        except Exception as e:
            print(f"Error with {model}: {e}")
    
    return insights

# Generate insights
insights = generate_process_insights(dfg, event_log, analyzer)
```

---

## 6. Report Generation

### 6.1 Creating Comprehensive Reports

```python
from core.report_generator import ReportGenerator

# Initialize generator
generator = ReportGenerator(output_base_dir="reports")

# Prepare results
results = {
    'statistics': {
        'num_cases': len(event_log),
        'num_events': sum(len(trace) for trace in event_log),
        'num_activities': len(pm4py.get_event_attribute_values(event_log, 'concept:name')),
        'avg_case_duration': np.mean(case_durations),
        'sepsis_rate': 0.35  # Calculate from data
    },
    'variants': variants,
    'dfg': dfg,
    'llm_insights': insights.get('anthropic/claude-3-sonnet', ''),
    'bottlenecks': bottlenecks
}

# Generate reports in multiple formats
output_files = generator.generate_report(
    results,
    report_name="sepsis_analysis",
    formats=['markdown', 'html', 'pdf']
)

print("Reports generated:")
for format_type, filepath in output_files.items():
    print(f"  {format_type}: {filepath}")
```

### 6.2 Custom Visualizations

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)

# Activity frequency plot
activities = pm4py.get_event_attribute_values(event_log, 'concept:name')
activity_df = pd.DataFrame(list(activities.items()), 
                          columns=['Activity', 'Frequency'])
activity_df = activity_df.sort_values('Frequency', ascending=False).head(10)

plt.figure(figsize=(12, 6))
sns.barplot(data=activity_df, x='Activity', y='Frequency', palette='viridis')
plt.xticks(rotation=45, ha='right')
plt.title('Top 10 Most Frequent Activities')
plt.tight_layout()
plt.savefig('reports/activity_frequency.png', dpi=300)
plt.show()

# Case duration distribution
plt.figure(figsize=(12, 6))
plt.hist(case_durations, bins=50, edgecolor='black', alpha=0.7)
plt.axvline(np.mean(case_durations), color='red', linestyle='--', 
           label=f'Mean: {np.mean(case_durations):.2f}h')
plt.axvline(np.median(case_durations), color='green', linestyle='--', 
           label=f'Median: {np.median(case_durations):.2f}h')
plt.xlabel('Case Duration (hours)')
plt.ylabel('Frequency')
plt.title('Distribution of Case Durations')
plt.legend()
plt.tight_layout()
plt.savefig('reports/duration_distribution.png', dpi=300)
plt.show()
```

---

## 7. Production Deployment

### 7.1 API Development with FastAPI

```python
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="HealthProcessAI API")

class ProcessMiningRequest(BaseModel):
    data_path: str
    algorithm: str = "dfg"
    filter_percentage: float = 0.8

@app.post("/discover_process")
async def discover_process(file: UploadFile = File(...)):
    """Discover process from uploaded event log."""
    
    # Save uploaded file
    df = pd.read_csv(file.file)
    
    # Process mining
    event_log = create_event_log(df)
    dfg, start, end = pm4py.discover_dfg(event_log)
    
    # Return results
    return {
        "num_cases": len(event_log),
        "num_activities": len(pm4py.get_event_attribute_values(event_log, 'concept:name')),
        "num_transitions": len(dfg),
        "top_transitions": sorted(dfg.items(), key=lambda x: x[1], reverse=True)[:10]
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "version": "1.0.0"}

# Run with: uvicorn main:app --reload
```

### 7.2 Docker Deployment

```dockerfile
# Dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run application
CMD ["python", "main.py"]
```

```bash
# Build and run
docker build -t healthprocessai .
docker run -p 8000:8000 healthprocessai
```

---

## 8. Best Practices

### 8.1 Code Organization

```python
# project_structure.py
"""
healthprocessai/
├── core/                 # Core modules
│   ├── __init__.py
│   ├── data_loader.py   # Data loading
│   ├── process_miner.py # Process discovery
│   └── analyzer.py      # Analysis
├── utils/               # Utilities
│   ├── __init__.py
│   └── helpers.py
├── config/              # Configuration
│   └── settings.py
└── main.py             # Entry point
"""
```

### 8.2 Error Handling

```python
import logging
from typing import Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def safe_process_discovery(df: pd.DataFrame) -> Optional[tuple]:
    """Safely discover process with error handling."""
    try:
        # Validate input
        if df.empty:
            raise ValueError("Empty dataframe provided")
        
        # Check required columns
        required_cols = ['case', 'activity', 'timestamp']
        missing_cols = set(required_cols) - set(df.columns)
        if missing_cols:
            raise ValueError(f"Missing columns: {missing_cols}")
        
        # Process discovery
        event_log = create_event_log(df)
        dfg, start, end = pm4py.discover_dfg(event_log)
        
        logger.info(f"Successfully discovered process with {len(dfg)} transitions")
        return dfg, start, end
        
    except Exception as e:
        logger.error(f"Process discovery failed: {e}")
        return None
```

### 8.3 Performance Optimization

```python
# Use efficient data types
df['case'] = df['case'].astype('category')
df['activity'] = df['activity'].astype('category')
df['resource'] = df['resource'].astype('category')

# Process in chunks for large files
def process_large_file(filepath, chunk_size=10000):
    """Process large files in chunks."""
    results = []
    
    for chunk in pd.read_csv(filepath, chunksize=chunk_size):
        # Process chunk
        result = process_chunk(chunk)
        results.append(result)
    
    # Combine results
    return combine_results(results)

# Use multiprocessing for parallel processing
from multiprocessing import Pool

def parallel_analysis(event_logs):
    """Analyze multiple event logs in parallel."""
    with Pool() as pool:
        results = pool.map(analyze_log, event_logs)
    return results
```

### 8.4 Testing

```python
import pytest

def test_event_log_creation():
    """Test event log creation from DataFrame."""
    # Create test data
    df = pd.DataFrame({
        'case': ['C1', 'C1', 'C2'],
        'activity': ['A', 'B', 'A'],
        'timestamp': pd.date_range('2024-01-01', periods=3, freq='H')
    })
    
    # Create event log
    event_log = create_event_log(df)
    
    # Assertions
    assert len(event_log) == 2  # Two cases
    assert len(event_log[0]) == 2  # First case has 2 events
    assert len(event_log[1]) == 1  # Second case has 1 event

def test_dfg_discovery():
    """Test DFG discovery."""
    # Test implementation
    pass

# Run tests with: pytest test_process_mining.py
```

---

## 📚 Additional Resources

- [PM4PY Documentation](https://pm4py.fit.fraunhofer.de/)
- [PM4PY Examples](https://github.com/pm4py/pm4py-core)
- [Process Mining Book](http://www.processmining.org/book/start)
- [Python Best Practices](https://docs.python-guide.org/)

---

## 🎯 Next Steps

1. **Explore advanced algorithms**: Try different discovery algorithms
2. **Build custom analyzers**: Create domain-specific analysis tools
3. **Deploy to production**: Set up API and monitoring
4. **Integrate with EHR**: Connect to hospital systems
5. **Create dashboards**: Build real-time monitoring

---

## 👥 About the Authors

- **Farhad Abtahi**: Lead architect of the HealthProcessAI framework, specializing in healthcare AI systems and clinical workflow optimization.
- **Eduardo Illueca Fernandez**: Process mining specialist focusing on algorithmic implementation and cross-platform development (Python/R).
- **Kaile Chen**: Healthcare analytics researcher with expertise in clinical data transformation and sepsis progression modeling.

*This tutorial is part of HealthProcessAI - Developed at SMAILE, Karolinska Institutet*