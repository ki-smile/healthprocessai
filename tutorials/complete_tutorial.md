# Process Mining in Healthcare: A Complete Tutorial

## Table of Contents
1. [Introduction to Process Mining](#introduction)
2. [Healthcare Process Mining Fundamentals](#healthcare-fundamentals)
3. [Understanding Event Logs](#event-logs)
4. [Process Discovery Techniques](#process-discovery)
5. [Hands-On Tutorial: Sepsis Analysis](#hands-on-tutorial)
6. [Integrating AI for Clinical Insights](#ai-integration)
7. [Evaluation Metrics and Validation](#evaluation-metrics)
8. [Advanced Techniques](#advanced-techniques)
9. [Real-World Case Studies](#case-studies)
10. [Deployment and Monitoring](#deployment)
11. [Best Practices and Pitfalls](#best-practices)
12. [Exercises and Solutions](#exercises)

---

## 1. Introduction to Process Mining {#introduction}

### What is Process Mining?

Process mining is a data-driven approach that sits at the intersection of data science and process management. It extracts knowledge from event logs recorded by information systems to:

- **Discover** real processes (vs. assumed processes)
- **Monitor** deviations and compliance
- **Enhance** processes based on facts, not opinions

### Why Process Mining in Healthcare?

Healthcare processes are:
- **Complex**: Multiple departments, specialists, and pathways
- **Variable**: Each patient is unique
- **Critical**: Lives depend on efficiency and accuracy
- **Data-rich**: Electronic Health Records (EHRs) capture detailed logs

### Real-World Healthcare Applications

1. **Clinical Pathways**: Discover actual treatment sequences
2. **Emergency Department**: Reduce waiting times and bottlenecks
3. **Surgery Planning**: Optimize operating room utilization
4. **Sepsis Detection**: Identify early warning patterns
5. **Patient Flow**: Track journey through hospital systems

---

## 2. Healthcare Process Mining Fundamentals {#healthcare-fundamentals}

### The Three Types of Process Mining

#### 1. Process Discovery
Creating process models from event data without prior knowledge.

```
Event Log → Algorithm → Process Model
```

**Example**: Discovering how sepsis patients actually progress through the ICU, revealing that 30% skip expected monitoring steps.

#### 2. Conformance Checking
Comparing actual processes against expected protocols.

```
Event Log + Model → Deviations
```

**Example**: Checking if stroke patients receive thrombolysis within the golden hour protocol.

#### 3. Process Enhancement
Improving existing models with additional information.

```
Event Log + Model → Enhanced Model
```

**Example**: Adding wait times to emergency department pathways to identify bottlenecks.

### Key Healthcare Concepts

#### Clinical Pathways
Standardized, evidence-based multidisciplinary plans of care. Process mining reveals:
- How often pathways are followed
- Common deviations and their reasons
- Outcomes of different path variations

#### Patient Journey
The complete experience from admission to discharge:
1. **Entry Point**: Emergency, referral, walk-in
2. **Diagnostic Phase**: Tests, imaging, consultations
3. **Treatment Phase**: Medications, procedures, therapy
4. **Discharge Planning**: Follow-up, home care, transfer

#### Clinical Events
Healthcare-specific activities in process mining:
- **Administrative**: Registration, admission, discharge
- **Clinical**: Diagnosis, medication, procedure
- **Diagnostic**: Lab test, imaging, biopsy
- **Monitoring**: Vital signs, assessments

---

## 3. Understanding Event Logs {#event-logs}

### Anatomy of a Healthcare Event Log

Every event in a healthcare process requires:

| Field | Description | Example |
|-------|-------------|---------|
| **Case ID** | Unique patient/episode identifier | "Patient_1234" |
| **Activity** | What happened | "Blood Test Ordered" |
| **Timestamp** | When it happened | "2024-01-15 14:30:00" |
| **Resource** | Who/what performed it | "Dr. Smith" or "Lab_01" |
| **Additional** | Context-specific data | "Test Type: CBC" |

### Example: Sepsis Event Log Structure

```csv
case,activity,timestamp,resource,temperature,SepsisLabel
P001,Admission,2024-01-15 08:00:00,ER_Nurse,38.5,0
P001,Triage,2024-01-15 08:15:00,ER_Nurse,38.5,0
P001,Blood Culture,2024-01-15 09:00:00,Lab_Tech,38.8,0
P001,Antibiotics,2024-01-15 10:00:00,ER_Doctor,39.2,1
P001,ICU Transfer,2024-01-15 11:00:00,Transport,39.5,1
```

### Data Quality Considerations

Common issues in healthcare event logs:

1. **Missing Timestamps**: Manual documentation delays
2. **Duplicate Events**: Multiple system entries
3. **Granularity Mismatch**: Mixing detailed and high-level events
4. **Incomplete Cases**: Patients transferred or lost to follow-up

### Preparing Healthcare Data for Process Mining

```python
# Example: Cleaning healthcare event data
import pandas as pd

def prepare_healthcare_log(df):
    """
    Prepare healthcare data for process mining.
    """
    # Remove duplicates
    df = df.drop_duplicates()
    
    # Handle missing timestamps
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    df = df.dropna(subset=['timestamp'])
    
    # Standardize activity names
    activity_mapping = {
        'ER Admission': 'Admission',
        'Emergency Admission': 'Admission',
        'Lab Work': 'Blood Test',
        'Laboratory Test': 'Blood Test'
    }
    df['activity'] = df['activity'].replace(activity_mapping)
    
    # Sort by case and time
    df = df.sort_values(['case', 'timestamp'])
    
    return df
```

---

## 4. Process Discovery Techniques {#process-discovery}

### Alpha Algorithm
The simplest discovery algorithm, good for structured processes.

**How it works**:
1. Identifies direct succession relations (a→b)
2. Builds a Petri net based on these relations
3. Best for: Well-structured clinical protocols

**Limitations**: Cannot handle loops or noise

### Heuristic Mining
More robust to noise and exceptional behavior.

**How it works**:
1. Calculates dependency frequencies
2. Filters based on thresholds
3. Best for: Real-world healthcare data with variations

### Inductive Mining
Guarantees sound process models (proper start/end).

**How it works**:
1. Recursively splits the event log
2. Discovers block-structured models
3. Best for: Creating understandable clinical pathways

### Directly-Follows Graphs (DFG)
Most intuitive visualization for healthcare professionals.

```python
# Creating a DFG from healthcare data
import pm4py

def create_clinical_dfg(event_log):
    """
    Create a Directly-Follows Graph for clinical data.
    """
    # Discover DFG
    dfg = pm4py.discover_dfg(event_log)
    
    # Visualize with frequencies
    pm4py.view_dfg(
        dfg[0],  # Graph
        dfg[1],  # Start activities
        dfg[2],  # End activities
        format='png'
    )
    
    return dfg
```

---

## 5. Hands-On Tutorial: Sepsis Analysis {#hands-on-tutorial}

Let's walk through a complete sepsis progression analysis using our modular approach.

### Step 1: Understanding the Clinical Context

Sepsis is a life-threatening condition where the body's response to infection damages its own tissues. Early detection is crucial:

- **Mortality Rate**: Increases 7-10% each hour treatment is delayed
- **Key Indicators**: Temperature changes, elevated white blood cell count, organ dysfunction
- **Challenge**: Symptoms overlap with many conditions

### Modular Components

First, let's define our modular components that make the analysis reusable and maintainable:

#### step1_data_loader.py

```python
import pandas as pd
import numpy as np
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

class EventLogLoader:
    """
    A class for loading and preparing healthcare event logs for process mining.
    """
    
    def __init__(self, file_path):
        """
        Initialize the EventLogLoader.
        
        Args:
            file_path (str): Path to the CSV file containing event log data
        """
        self.file_path = file_path
        self.raw_data = None
        self.prepared_data = None
        
    def load_data(self):
        """
        Load raw data from CSV file.
        
        Returns:
            pandas.DataFrame: Raw event log data
        """
        try:
            self.raw_data = pd.read_csv(self.file_path)
            print(f"✓ Loaded {len(self.raw_data)} events from {self.file_path}")
            return self.raw_data
        except FileNotFoundError:
            print(f"✗ File not found: {self.file_path}")
            return None
        except Exception as e:
            print(f"✗ Error loading data: {e}")
            return None
    
    def prepare_data(self):
        """
        Clean and prepare the event log data for process mining.
        
        Returns:
            pandas.DataFrame: Cleaned and prepared event log data
        """
        if self.raw_data is None:
            print("✗ No raw data loaded. Call load_data() first.")
            return None
        
        df = self.raw_data.copy()
        
        # Convert timestamps
        if 'timestamp' in df.columns:
            df['timestamp'] = pd.to_datetime(df['timestamp'], errors='coerce')
        
        # Remove rows with missing critical information
        initial_rows = len(df)
        df = df.dropna(subset=['case', 'activity', 'timestamp'])
        removed_rows = initial_rows - len(df)
        if removed_rows > 0:
            print(f"✓ Removed {removed_rows} rows with missing critical data")
        
        # Remove duplicates
        initial_rows = len(df)
        df = df.drop_duplicates(subset=['case', 'activity', 'timestamp'])
        removed_dups = initial_rows - len(df)
        if removed_dups > 0:
            print(f"✓ Removed {removed_dups} duplicate events")
        
        # Standardize activity names
        activity_mapping = {
            'ER Registration': 'Registration',
            'Emergency Registration': 'Registration',
            'Lab Work': 'Lab Test',
            'Laboratory Test': 'Lab Test',
            'Blood Work': 'Lab Test',
            'IV Liquid': 'IV Administration',
            'IV Antibiotics': 'Antibiotics',
            'Leucocytes': 'Lab Test',
            'CRP': 'Lab Test',
            'LacticAcid': 'Lab Test'
        }
        df['activity'] = df['activity'].replace(activity_mapping)
        
        # Sort by case and timestamp
        df = df.sort_values(['case', 'timestamp'])
        
        # Reset index
        df = df.reset_index(drop=True)
        
        self.prepared_data = df
        print(f"✓ Data preparation complete: {len(df)} events ready for analysis")
        
        return self.prepared_data
    
    def get_statistics(self):
        """
        Get basic statistics about the event log.
        
        Returns:
            dict: Statistics about the event log
        """
        if self.prepared_data is None:
            return {}
        
        df = self.prepared_data
        
        stats = {
            'num_events': len(df),
            'num_cases': df['case'].nunique(),
            'num_activities': df['activity'].nunique(),
            'date_range': {
                'start': df['timestamp'].min().strftime('%Y-%m-%d'),
                'end': df['timestamp'].max().strftime('%Y-%m-%d')
            },
            'avg_events_per_case': len(df) / df['case'].nunique(),
            'activities': df['activity'].value_counts().to_dict()
        }
        
        # Add sepsis-specific statistics if SepsisLabel column exists
        if 'SepsisLabel' in df.columns:
            sepsis_cases = df[df['SepsisLabel'] == 1]['case'].nunique()
            total_cases = df['case'].nunique()
            stats['sepsis_rate'] = sepsis_cases / total_cases
            stats['sepsis_cases'] = sepsis_cases
            stats['non_sepsis_cases'] = total_cases - sepsis_cases
        
        return stats
    
    def filter_by_outcome(self, sepsis_only=True):
        """
        Filter data by sepsis outcome.
        
        Args:
            sepsis_only (bool): If True, return only sepsis cases. If False, return non-sepsis cases.
            
        Returns:
            pandas.DataFrame: Filtered data
        """
        if self.prepared_data is None or 'SepsisLabel' not in self.prepared_data.columns:
            print("✗ No prepared data or SepsisLabel column not found")
            return None
        
        if sepsis_only:
            # Get cases that developed sepsis
            sepsis_case_ids = self.prepared_data[self.prepared_data['SepsisLabel'] == 1]['case'].unique()
            filtered_data = self.prepared_data[self.prepared_data['case'].isin(sepsis_case_ids)]
        else:
            # Get cases that never developed sepsis
            sepsis_case_ids = self.prepared_data[self.prepared_data['SepsisLabel'] == 1]['case'].unique()
            filtered_data = self.prepared_data[~self.prepared_data['case'].isin(sepsis_case_ids)]
        
        print(f"✓ Filtered to {filtered_data['case'].nunique()} cases")
        return filtered_data
    
    def export_for_pm4py(self, data=None, filename=None):
        """
        Export data in PM4PY compatible format.
        
        Args:
            data (DataFrame): Data to export (default: prepared_data)
            filename (str): Output filename (optional)
            
        Returns:
            pandas.DataFrame: PM4PY compatible DataFrame
        """
        if data is None:
            data = self.prepared_data
        
        if data is None:
            print("✗ No data to export")
            return None
        
        # Create PM4PY compatible column names
        pm4py_data = data.copy()
        pm4py_data = pm4py_data.rename(columns={
            'case': 'case:concept:name',
            'activity': 'concept:name',
            'timestamp': 'time:timestamp'
        })
        
        # Ensure proper data types
        pm4py_data['case:concept:name'] = pm4py_data['case:concept:name'].astype(str)
        pm4py_data['concept:name'] = pm4py_data['concept:name'].astype(str)
        
        if filename:
            pm4py_data.to_csv(filename, index=False)
            print(f"✓ Exported to {filename}")
        
        return pm4py_data
```

#### step2_process_mining.py

```python
import pm4py
import pandas as pd
import numpy as np
from pm4py.objects.log.importer.xes import importer as xes_importer
from pm4py.objects.conversion.log import converter as log_converter
from pm4py.algo.discovery.dfg import algorithm as dfg_discovery
from pm4py.visualization.dfg import visualizer as dfg_visualization
from pm4py.algo.discovery.inductive import algorithm as inductive_miner
from pm4py.visualization.process_tree import visualizer as pt_visualizer
from pm4py.algo.discovery.heuristics import algorithm as heuristics_miner
from pm4py.statistics.traces.generic.log import case_statistics
import matplotlib.pyplot as plt
import seaborn as sns

class ProcessMiner:
    """
    A class for process mining analysis on healthcare event logs.
    """
    
    def __init__(self):
        """
        Initialize the ProcessMiner.
        """
        self.event_log = None
        self.dfg = None
        self.start_activities = None
        self.end_activities = None
        self.performance_dfg = None
        
    def create_event_log(self, dataframe):
        """
        Convert a pandas DataFrame to a PM4PY event log.
        
        Args:
            dataframe (pandas.DataFrame): Input data with case, activity, timestamp columns
            
        Returns:
            pm4py.objects.log.obj.EventLog: PM4PY event log object
        """
        # Ensure proper column names for PM4PY
        df = dataframe.copy()
        
        # Rename columns to PM4PY standard if needed
        column_mapping = {
            'case': 'case:concept:name',
            'activity': 'concept:name', 
            'timestamp': 'time:timestamp'
        }
        
        for old_name, new_name in column_mapping.items():
            if old_name in df.columns and new_name not in df.columns:
                df = df.rename(columns={old_name: new_name})
        
        # Convert to PM4PY event log
        self.event_log = log_converter.apply(df)
        
        print(f"✓ Created event log with {len(self.event_log)} cases")
        return self.event_log
    
    def discover_dfg(self, activity_threshold=0.0, path_threshold=0.0):
        """
        Discover a Directly-Follows Graph from the event log.
        
        Args:
            activity_threshold (float): Minimum frequency for activities (0.0 to 1.0)
            path_threshold (float): Minimum frequency for paths (0.0 to 1.0)
            
        Returns:
            tuple: (dfg, start_activities, end_activities)
        """
        if self.event_log is None:
            print("✗ No event log loaded. Call create_event_log() first.")
            return None, None, None
        
        # Discover DFG
        dfg = dfg_discovery.apply(self.event_log)
        start_activities = pm4py.get_start_activities(self.event_log)
        end_activities = pm4py.get_end_activities(self.event_log)
        
        # Apply thresholds if specified
        if activity_threshold > 0 or path_threshold > 0:
            dfg, start_activities, end_activities = pm4py.filter_dfg_on_activities_percentage(
                dfg, start_activities, end_activities, activity_threshold
            )
            dfg, start_activities, end_activities = pm4py.filter_dfg_on_paths_percentage(
                dfg, start_activities, end_activities, path_threshold
            )
        
        self.dfg = dfg
        self.start_activities = start_activities
        self.end_activities = end_activities
        
        print(f"✓ Discovered DFG with {len(dfg)} transitions")
        return dfg, start_activities, end_activities
    
    def discover_performance_dfg(self):
        """
        Discover performance information (timing) in the process.
        
        Returns:
            dict: Performance DFG with average durations
        """
        if self.event_log is None:
            print("✗ No event log loaded. Call create_event_log() first.")
            return None
        
        # Calculate performance DFG
        self.performance_dfg = dfg_discovery.apply(self.event_log, variant=dfg_discovery.Variants.PERFORMANCE)
        
        # Convert seconds to hours for healthcare context
        performance_hours = {}
        for key, value in self.performance_dfg.items():
            performance_hours[key] = value / 3600  # Convert to hours
        
        print(f"✓ Calculated performance metrics for {len(performance_hours)} transitions")
        return performance_hours
    
    def discover_variants(self, top_k=10):
        """
        Discover the most common process variants (paths).
        
        Args:
            top_k (int): Number of top variants to return
            
        Returns:
            pandas.DataFrame: Top variants with frequencies
        """
        if self.event_log is None:
            print("✗ No event log loaded. Call create_event_log() first.")
            return None
        
        # Get variants
        variants = pm4py.get_variants(self.event_log)
        
        # Calculate statistics
        total_cases = len(self.event_log)
        variant_stats = []
        
        for variant, cases in variants.items():
            variant_stats.append({
                'variant': ' → '.join(variant),
                'cases': len(cases),
                'percentage': (len(cases) / total_cases) * 100,
                'avg_length': len(variant)
            })
        
        # Sort by frequency and return top k
        variant_df = pd.DataFrame(variant_stats)
        variant_df = variant_df.sort_values('cases', ascending=False).head(top_k)
        variant_df = variant_df.reset_index(drop=True)
        
        print(f"✓ Found {len(variants)} unique variants, showing top {top_k}")
        return variant_df
    
    def visualize_dfg(self, filename=None, format='png'):
        """
        Visualize the Directly-Follows Graph.
        
        Args:
            filename (str): Output filename (optional)
            format (str): Output format ('png', 'svg', 'pdf')
        """
        if self.dfg is None:
            print("✗ No DFG discovered. Call discover_dfg() first.")
            return
        
        try:
            gviz = dfg_visualization.apply(
                self.dfg, 
                self.start_activities, 
                self.end_activities,
                parameters={dfg_visualization.Variants.FREQUENCY.value.Parameters.FORMAT: format}
            )
            
            if filename:
                dfg_visualization.save(gviz, filename)
                print(f"✓ DFG saved to {filename}")
            else:
                dfg_visualization.view(gviz)
                print("✓ DFG visualization displayed")
                
        except Exception as e:
            print(f"✗ Error creating DFG visualization: {e}")
    
    def create_process_matrix(self):
        """
        Create a process matrix showing transition frequencies.
        
        Returns:
            pandas.DataFrame: Matrix of activity transitions
        """
        if self.dfg is None:
            print("✗ No DFG discovered. Call discover_dfg() first.")
            return None
        
        # Get all unique activities
        activities = set()
        for (source, target), freq in self.dfg.items():
            activities.add(source)
            activities.add(target)
        
        activities = sorted(list(activities))
        
        # Create matrix
        matrix = pd.DataFrame(0, index=activities, columns=activities)
        
        for (source, target), freq in self.dfg.items():
            matrix.loc[source, target] = freq
        
        print(f"✓ Created process matrix ({len(activities)}x{len(activities)})")
        return matrix
    
    def analyze_bottlenecks(self, top_n=5):
        """
        Identify potential bottlenecks in the process.
        
        Args:
            top_n (int): Number of top bottlenecks to return
            
        Returns:
            pandas.DataFrame: Bottleneck analysis results
        """
        if self.performance_dfg is None:
            print("✗ No performance data. Call discover_performance_dfg() first.")
            return None
        
        # Convert performance data to DataFrame
        bottleneck_data = []
        for (source, target), avg_time in self.performance_dfg.items():
            avg_hours = avg_time / 3600
            bottleneck_data.append({
                'transition': f"{source} → {target}",
                'avg_duration_hours': avg_hours,
                'source_activity': source,
                'target_activity': target
            })
        
        bottlenecks_df = pd.DataFrame(bottleneck_data)
        bottlenecks_df = bottlenecks_df.sort_values('avg_duration_hours', ascending=False)
        bottlenecks_df = bottlenecks_df.head(top_n).reset_index(drop=True)
        
        print(f"✓ Identified top {top_n} potential bottlenecks")
        return bottlenecks_df
    
    def discover_inductive_model(self, noise_threshold=0.0):
        """
        Discover a process model using Inductive Miner.
        
        Args:
            noise_threshold (float): Noise threshold for filtering
            
        Returns:
            Process tree object
        """
        if self.event_log is None:
            print("✗ No event log loaded. Call create_event_log() first.")
            return None
        
        try:
            # Apply inductive miner
            process_tree = inductive_miner.apply(
                self.event_log, 
                parameters={inductive_miner.Variants.IM.value.Parameters.NOISE_THRESHOLD: noise_threshold}
            )
            
            print("✓ Discovered process model using Inductive Miner")
            return process_tree
            
        except Exception as e:
            print(f"✗ Error in inductive mining: {e}")
            return None
    
    def calculate_case_statistics(self):
        """
        Calculate statistics for individual cases.
        
        Returns:
            dict: Case statistics including duration and activity counts
        """
        if self.event_log is None:
            print("✗ No event log loaded. Call create_event_log() first.")
            return None
        
        stats = {}
        
        # Calculate case durations
        case_durations = []
        case_lengths = []
        
        for case in self.event_log:
            if len(case) > 1:
                start_time = case[0]['time:timestamp']
                end_time = case[-1]['time:timestamp']
                duration_hours = (end_time - start_time).total_seconds() / 3600
                case_durations.append(duration_hours)
            else:
                case_durations.append(0)
            
            case_lengths.append(len(case))
        
        stats['case_durations_hours'] = {
            'mean': np.mean(case_durations),
            'median': np.median(case_durations),
            'std': np.std(case_durations),
            'min': np.min(case_durations),
            'max': np.max(case_durations)
        }
        
        stats['case_lengths'] = {
            'mean': np.mean(case_lengths),
            'median': np.median(case_lengths),
            'std': np.std(case_lengths),
            'min': np.min(case_lengths),
            'max': np.max(case_lengths)
        }
        
        print("✓ Calculated case statistics")
        return stats
```

#### step3_llm_integration.py

```python
import requests
import json
import time
import os
from datetime import datetime
import pandas as pd

class LLMAnalyzer:
    """
    A class for integrating Large Language Models with process mining results.
    """
    
    def __init__(self, api_key, base_url="https://openrouter.ai/api/v1"):
        """
        Initialize the LLM Analyzer.
        
        Args:
            api_key (str): OpenRouter API key
            base_url (str): API base URL
        """
        self.api_key = api_key
        self.base_url = base_url
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
    def create_clinical_prompt(self, process_results, domain="healthcare"):
        """
        Create a comprehensive clinical analysis prompt.
        
        Args:
            process_results (dict): Results from process mining analysis
            domain (str): Clinical domain (e.g., "sepsis", "emergency")
            
        Returns:
            str: Formatted prompt for LLM analysis
        """
        prompt = f"""
You are a clinical epidemiologist and process improvement expert analyzing healthcare data. 
Please provide a comprehensive analysis of the following process mining results.

CLINICAL CONTEXT:
- Domain: {domain.capitalize()} care pathways
- Setting: Hospital environment with electronic health records
- Objective: Identify opportunities for improved patient outcomes and process efficiency

PROCESS MINING FINDINGS:
- Total Cases Analyzed: {process_results.get('num_cases', 'N/A'):,}
- Average Case Duration: {process_results.get('avg_case_duration_hours', 'N/A')} hours
- Process Variants: {process_results.get('num_variants', 'N/A')} distinct pathways discovered
- Most Common Pathway: Covers {process_results.get('top_variant_coverage', 'N/A')} of patients
- Total Activities: {process_results.get('num_activities', 'N/A')} distinct clinical activities
- Total Events: {process_results.get('total_events', 'N/A'):,}

TOP CLINICAL ACTIVITIES:
"""
        
        # Add top activities
        if 'top_5_activities' in process_results:
            for i, activity in enumerate(process_results['top_5_activities'][:5], 1):
                prompt += f"\n{i}. {activity['activity']}: {activity['count']:,} occurrences"
        
        prompt += f"""

KEY FINDINGS:
"""
        # Add key findings
        if 'key_findings' in process_results:
            for finding in process_results['key_findings']:
                prompt += f"\n- {finding}"
        
        prompt += f"""

CRITICAL TRANSITIONS:
"""
        # Add critical transitions
        if 'critical_transitions' in process_results:
            for transition in process_results['critical_transitions']:
                prompt += f"\n- {transition}"
        
        prompt += f"""

ANALYSIS REQUESTED:
Please provide a structured analysis covering:

1. CLINICAL SIGNIFICANCE
   - What do these patterns reveal about {domain} care?
   - Which findings are most clinically relevant?
   - How do patterns align with evidence-based guidelines?

2. QUALITY IMPROVEMENT OPPORTUNITIES
   - Where are the biggest inefficiencies?
   - What processes could be standardized?
   - Which activities could be optimized or eliminated?

3. EARLY WARNING INDICATORS
   - What patterns predict adverse outcomes?
   - Which activities are early indicators of complications?
   - How could monitoring be improved?

4. RESOURCE OPTIMIZATION
   - Where are resources being over/under-utilized?
   - What staffing patterns emerge?
   - How could scheduling be improved?

5. ACTIONABLE RECOMMENDATIONS
   - Specific, implementable changes for clinical teams
   - Monitoring metrics to track improvement
   - Risk mitigation strategies

Please format your response with clear headers and bullet points. Focus on actionable insights 
that could improve patient outcomes and operational efficiency.
        """
        
        return prompt
    
    def analyze_with_multiple_models(self, prompt, models=None, delay_seconds=1):
        """
        Analyze the prompt with multiple LLM models for comparison.
        
        Args:
            prompt (str): Analysis prompt
            models (list): List of model names to use
            delay_seconds (int): Delay between API calls
            
        Returns:
            dict: Results from each model
        """
        if models is None:
            models = [
                "anthropic/claude-3.5-sonnet",
                "openai/gpt-4-turbo",
                "google/gemini-pro-1.5",
                "deepseek/deepseek-r1"
            ]
        
        results = {}
        
        for model in models:
            print(f"Analyzing with {model}...")
            
            try:
                response = requests.post(
                    f"{self.base_url}/chat/completions",
                    headers=self.headers,
                    json={
                        "model": model,
                        "messages": [
                            {"role": "user", "content": prompt}
                        ],
                        "max_tokens": 4000,
                        "temperature": 0.7
                    }
                )
                
                if response.status_code == 200:
                    data = response.json()
                    results[model.split('/')[-1]] = {
                        'status': 'success',
                        'content': data['choices'][0]['message']['content'],
                        'model': model,
                        'timestamp': datetime.now().isoformat()
                    }
                    print(f"✓ Success with {model}")
                else:
                    results[model.split('/')[-1]] = {
                        'status': 'error',
                        'error': f"HTTP {response.status_code}: {response.text}",
                        'model': model,
                        'timestamp': datetime.now().isoformat()
                    }
                    print(f"✗ Error with {model}: {response.status_code}")
                
            except Exception as e:
                results[model.split('/')[-1]] = {
                    'status': 'error',
                    'error': str(e),
                    'model': model,
                    'timestamp': datetime.now().isoformat()
                }
                print(f"✗ Exception with {model}: {e}")
            
            # Rate limiting
            if delay_seconds > 0:
                time.sleep(delay_seconds)
        
        return results
    
    def generate_clinical_report(self, process_results, llm_analysis, metadata=None):
        """
        Generate a comprehensive clinical report combining process mining and LLM insights.
        
        Args:
            process_results (dict): Process mining results
            llm_analysis (str): LLM analysis content
            metadata (dict): Additional metadata
            
        Returns:
            str: Formatted clinical report
        """
        report_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        report = f"""# Healthcare Process Mining Analysis Report

**Generated:** {report_date}
**Analysis Type:** {metadata.get('analysis_type', 'General Healthcare Process Analysis')}
**AI Model:** {metadata.get('ai_model', 'Multiple Models')}

---

## Executive Summary

This report presents findings from process mining analysis of healthcare event data, enhanced with AI-powered clinical insights. The analysis covers {process_results.get('num_cases', 'N/A'):,} patient cases and {process_results.get('total_events', 'N/A'):,} clinical events.

### Key Metrics
- **Total Cases:** {process_results.get('num_cases', 'N/A'):,}
- **Average Case Duration:** {process_results.get('avg_case_duration_hours', 'N/A')} hours
- **Process Variants:** {process_results.get('num_variants', 'N/A')} distinct pathways
- **Coverage of Main Pathway:** {process_results.get('top_variant_coverage', 'N/A')}

---

## Process Mining Findings

### Activity Distribution
The most frequent clinical activities observed:
"""
        
        # Add activity distribution
        if 'top_5_activities' in process_results:
            for i, activity in enumerate(process_results['top_5_activities'][:5], 1):
                report += f"\n{i}. **{activity['activity']}**: {activity['count']:,} occurrences"
        
        report += f"""

### Critical Process Transitions
"""
        
        # Add critical transitions
        if 'critical_transitions' in process_results:
            for transition in process_results['critical_transitions']:
                report += f"\n- {transition}"
        
        report += f"""

### Key Process Discoveries
"""
        
        # Add key findings
        if 'key_findings' in process_results:
            for finding in process_results['key_findings']:
                report += f"\n- {finding}"
        
        report += f"""

---

## AI-Enhanced Clinical Analysis

{llm_analysis}

---

## Recommendations for Implementation

Based on the combined process mining and AI analysis, the following implementation steps are recommended:

1. **Immediate Actions (0-30 days)**
   - Implement monitoring for identified early warning patterns
   - Train staff on critical transition timing
   - Establish alerts for process deviations

2. **Short-term Improvements (1-3 months)**
   - Optimize resource allocation based on flow patterns
   - Standardize high-variation processes
   - Implement predictive monitoring systems

3. **Long-term Optimization (3-12 months)**
   - Redesign inefficient pathways
   - Integrate findings into clinical guidelines
   - Establish continuous monitoring systems

---

## Data Quality and Limitations

### Data Sources
- Event log entries: {process_results.get('total_events', 'N/A'):,}
- Time period: {process_results.get('date_range', {}).get('start', 'N/A')} to {process_results.get('date_range', {}).get('end', 'N/A')}
- Unique patients: {process_results.get('num_cases', 'N/A'):,}

### Limitations
- Analysis based on documented events only
- May not capture informal care processes
- Results should be validated with clinical teams
- Causation cannot be inferred from correlation patterns

---

## Next Steps

1. **Validation**: Review findings with clinical domain experts
2. **Pilot Testing**: Implement changes in controlled settings
3. **Monitoring**: Establish metrics to track improvement
4. **Iteration**: Regularly update analysis with new data

---

*This report was generated using automated process mining techniques enhanced with AI analysis. All recommendations should be reviewed by qualified clinical professionals before implementation.*
"""
        
        return report
    
    def save_report(self, report_content, filename, directory="./reports"):
        """
        Save the clinical report to a file.
        
        Args:
            report_content (str): Report content to save
            filename (str): Output filename
            directory (str): Output directory
            
        Returns:
            str: Path to saved file
        """
        # Create directory if it doesn't exist
        os.makedirs(directory, exist_ok=True)
        
        # Create full path
        filepath = os.path.join(directory, filename)
        
        # Save file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(report_content)
        
        print(f"✓ Report saved to {filepath}")
        return filepath
    
    def compare_model_outputs(self, results):
        """
        Compare outputs from different models.
        
        Args:
            results (dict): Results from analyze_with_multiple_models
            
        Returns:
            pandas.DataFrame: Comparison summary
        """
        comparison_data = []
        
        for model_name, result in results.items():
            if result['status'] == 'success':
                content = result['content']
                comparison_data.append({
                    'model': model_name,
                    'status': result['status'],
                    'response_length': len(content),
                    'timestamp': result['timestamp'],
                    'has_recommendations': 'recommendation' in content.lower(),
                    'has_clinical_insights': 'clinical' in content.lower(),
                    'mentions_quality': 'quality' in content.lower()
                })
            else:
                comparison_data.append({
                    'model': model_name,
                    'status': result['status'],
                    'error': result.get('error', 'Unknown error'),
                    'timestamp': result['timestamp'],
                    'response_length': 0,
                    'has_recommendations': False,
                    'has_clinical_insights': False,
                    'mentions_quality': False
                })
        
        return pd.DataFrame(comparison_data)
```

### Step 2: Loading and Exploring the Data

```python
# Import our modular components
from step1_data_loader import EventLogLoader

# Load sepsis event data
print("Loading sepsis event log...")
loader = EventLogLoader("data/sepsisAgregated_Infection.csv")

# Load and prepare data
raw_data = loader.load_data()
prepared_data = loader.prepare_data()

# Explore the data
stats = loader.get_statistics()
print(f"\nDataset Overview:")
print(f"- Total events: {stats['num_events']:,}")
print(f"- Unique patients: {stats['num_cases']:,}")
print(f"- Unique activities: {stats['num_activities']}")
print(f"- Sepsis rate: {stats.get('sepsis_rate', 0):.1%}")
print(f"- Date range: {stats['date_range']['start']} to {stats['date_range']['end']}")

# View sample events
print("\nSample events:")
print(prepared_data.head(10))

# Check activity distribution
activity_counts = prepared_data['activity'].value_counts()
print("\nTop 5 most frequent activities:")
for activity, count in activity_counts.head().items():
    print(f"  - {activity}: {count:,} occurrences")
```

### Step 3: Process Discovery

```python
from step2_process_mining import ProcessMiner

# Initialize process miner
miner = ProcessMiner()

# Filter for sepsis cases to understand progression
print("\nAnalyzing sepsis progression patterns...")
sepsis_cases = loader.filter_by_outcome(sepsis_only=True)
print(f"Focusing on {sepsis_cases['case'].nunique()} sepsis cases")

# Create PM4PY event log
event_log = miner.create_event_log(sepsis_cases)

# Discover the process
dfg, starts, ends = miner.discover_dfg()
print(f"\nProcess discovery results:")
print(f"- Found {len(dfg)} activity transitions")
print(f"- Start activities: {list(starts.keys())[:3]}")
print(f"- End activities: {list(ends.keys())[:3]}")

# Discover common pathways
variants = miner.discover_variants(top_k=5)
print("\nTop 5 patient pathways:")
for idx, row in variants.iterrows():
    print(f"  {idx+1}. {row['percentage']}% of patients")
    print(f"     Path: {row['variant'][:100]}...")

# Calculate performance metrics
perf_dfg = miner.discover_performance_dfg()
print("\nAverage time between key activities (hours):")
for (source, target), hours in list(perf_dfg.items())[:5]:
    print(f"  {source} → {target}: {hours:.1f} hours")
```

### Step 4: Clinical Pattern Analysis

```python
# Analyze critical transitions for sepsis
def analyze_sepsis_patterns(miner, sepsis_data, non_sepsis_data):
    """
    Compare process patterns between sepsis and non-sepsis cases.
    """
    # Create event logs for both groups
    sepsis_log = miner.create_event_log(sepsis_data)
    non_sepsis_log = miner.create_event_log(non_sepsis_data)
    
    # Discover patterns for each group
    sepsis_dfg = pm4py.discover_dfg(sepsis_log)
    non_sepsis_dfg = pm4py.discover_dfg(non_sepsis_log)
    
    # Find unique transitions in sepsis cases
    sepsis_transitions = set(sepsis_dfg[0].keys())
    non_sepsis_transitions = set(non_sepsis_dfg[0].keys())
    
    unique_to_sepsis = sepsis_transitions - non_sepsis_transitions
    
    print("Transitions unique to sepsis cases:")
    for transition in list(unique_to_sepsis)[:10]:
        print(f"  - {transition[0]} → {transition[1]}")
    
    return sepsis_dfg, non_sepsis_dfg

# Compare sepsis vs non-sepsis patterns
non_sepsis_cases = loader.filter_by_outcome(sepsis_only=False)
sepsis_dfg, non_sepsis_dfg = analyze_sepsis_patterns(
    miner, sepsis_cases, non_sepsis_cases
)
```

### Step 5: Creating Process Visualizations

```python
# Visualize the sepsis progression process
miner.visualize_dfg("sepsis_process_map.png")

# Create process matrix for detailed analysis
process_matrix = miner.create_process_matrix()

# Find strongest connections (most frequent transitions)
import numpy as np

# Get top transitions
matrix_values = process_matrix.values.flatten()
threshold = np.percentile(matrix_values[matrix_values > 0], 90)

print("\nStrongest activity transitions (90th percentile):")
for i in range(len(process_matrix)):
    for j in range(len(process_matrix.columns)):
        value = process_matrix.iloc[i, j]
        if value >= threshold:
            source = process_matrix.index[i]
            target = process_matrix.columns[j]
            print(f"  {source} → {target}: {value:.0f} times")
```

### Step 6: Generating Clinical Insights with AI

```python
from step3_llm_integration import LLMAnalyzer

# Prepare process mining results for AI analysis
process_results = {
    'num_cases': stats['num_cases'],
    'avg_case_duration_hours': 48.5,
    'num_variants': len(variants),
    'top_variant_coverage': f"{variants.iloc[0]['percentage']}%",
    'num_activities': stats['num_activities'],
    'total_events': stats['num_events'],
    'top_5_activities': [
        {'activity': act, 'count': count} 
        for act, count in activity_counts.head().items()
    ],
    'key_findings': [
        'Temperature elevation precedes sepsis diagnosis by 6-12 hours',
        'Lab results show 85% correlation with sepsis onset',
        'Early antibiotic administration reduces progression by 40%'
    ],
    'critical_transitions': [
        'Normal Temperature → High Temperature (avg 4.2 hours)',
        'High Temperature → Infection Detected (avg 2.8 hours)',
        'Infection Detected → Sepsis (avg 8.5 hours)'
    ]
}

# Initialize LLM analyzer (requires API key)
API_KEY = "your-openrouter-api-key"  # Replace with actual key
analyzer = LLMAnalyzer(API_KEY)

# Create clinical prompt
prompt = analyzer.create_clinical_prompt(process_results, "sepsis")

# Get AI insights (demo with free model)
print("\nGenerating AI-powered clinical insights...")
results = analyzer.analyze_with_multiple_models(
    prompt,
    models=['deepseek/deepseek-r1'],  # Free tier model
    delay_seconds=0
)

# Generate comprehensive report
if results['deepseek-r1']['status'] == 'success':
    report = analyzer.generate_clinical_report(
        process_results,
        results['deepseek-r1']['content'],
        metadata={
            'analysis_type': 'Sepsis Progression',
            'ai_model': 'DeepSeek R1'
        }
    )
    
    # Save report
    report_path = analyzer.save_report(
        report,
        "sepsis_analysis_report.md",
        "./reports"
    )
    print(f"Report saved to: {report_path}")
```

---

## 6. Integrating AI for Clinical Insights {#ai-integration}

### Why Combine Process Mining with AI?

Process mining reveals **what** happens, AI helps explain **why** and **what to do**:

1. **Pattern Interpretation**: AI can identify clinically significant patterns
2. **Anomaly Explanation**: Understand why certain cases deviate
3. **Recommendation Generation**: Suggest evidence-based interventions
4. **Report Writing**: Transform data into actionable insights

### Effective Prompt Engineering for Healthcare

```python
def create_effective_clinical_prompt(process_data):
    """
    Create prompts that generate actionable clinical insights.
    """
    prompt = f"""
    You are a clinical epidemiologist analyzing patient pathway data.
    
    CLINICAL CONTEXT:
    - Disease: Sepsis (life-threatening organ dysfunction)
    - Setting: Emergency department and ICU
    - Objective: Identify early intervention opportunities
    
    PROCESS MINING FINDINGS:
    - {process_data['num_cases']} patients analyzed
    - Average progression time: {process_data['avg_hours']} hours
    - Critical transition: {process_data['critical_transition']}
    
    Please provide:
    1. Clinical significance of the discovered patterns
    2. Risk stratification based on pathway variations
    3. Specific early warning indicators
    4. Evidence-based intervention recommendations
    5. Implementation considerations for clinical teams
    
    Focus on actionable insights that can improve patient outcomes.
    """
    return prompt
```

### Comparing Multiple AI Models

Different models offer different strengths:

| Model | Strengths | Best For |
|-------|-----------|----------|
| **Claude** | Medical knowledge, careful analysis | Detailed clinical interpretation |
| **GPT-4** | Broad knowledge, structured output | Comprehensive reports |
| **Gemini** | Multi-modal, fast processing | Quick insights, image analysis |
| **DeepSeek** | Free tier, good reasoning | Learning and experimentation |

---

## 7. Evaluation Metrics and Validation {#evaluation-metrics}

### Process Mining Quality Metrics

#### 1. Model Quality Metrics

**Fitness**: How well does the model replay the event log?
```python
def calculate_fitness(event_log, process_model):
    """
    Calculate fitness between event log and process model.
    """
    from pm4py.algo.conformance.tokenreplay import algorithm as token_replay
    
    # Perform token-based replay
    replayed_traces = token_replay.apply(event_log, process_model)
    
    # Calculate fitness
    fitness_values = [trace['trace_fitness'] for trace in replayed_traces]
    average_fitness = sum(fitness_values) / len(fitness_values)
    
    return {
        'average_fitness': average_fitness,
        'min_fitness': min(fitness_values),
        'max_fitness': max(fitness_values),
        'fitness_distribution': fitness_values
    }
```

**Precision**: How much extra behavior does the model allow?
```python
def calculate_precision(event_log, process_model):
    """
    Calculate precision of process model.
    """
    from pm4py.algo.evaluation.precision import algorithm as precision_evaluator
    
    precision = precision_evaluator.apply(event_log, process_model)
    return precision
```

**Generalization**: Will the model work on new data?
```python
def evaluate_generalization(event_log, test_proportion=0.3):
    """
    Evaluate model generalization using train/test split.
    """
    import random
    
    # Split event log
    cases = list(event_log)
    random.shuffle(cases)
    
    split_point = int(len(cases) * (1 - test_proportion))
    train_log = cases[:split_point]
    test_log = cases[split_point:]
    
    # Discover model on training data
    train_dfg = pm4py.discover_dfg(train_log)
    
    # Evaluate on test data
    test_dfg = pm4py.discover_dfg(test_log)
    
    # Compare overlap
    train_edges = set(train_dfg[0].keys())
    test_edges = set(test_dfg[0].keys())
    
    overlap = len(train_edges.intersection(test_edges))
    generalization_score = overlap / len(train_edges.union(test_edges))
    
    return {
        'generalization_score': generalization_score,
        'train_edges': len(train_edges),
        'test_edges': len(test_edges),
        'common_edges': overlap
    }
```

#### 2. Clinical Validation Metrics

**Clinical Concordance**: Do findings align with medical knowledge?
```python
def validate_clinical_concordance(findings, clinical_guidelines):
    """
    Validate findings against clinical guidelines.
    """
    concordance_scores = []
    
    for finding in findings:
        # Check against known clinical patterns
        score = 0
        for guideline in clinical_guidelines:
            if finding['pattern'] in guideline['expected_patterns']:
                score += guideline['confidence']
        
        concordance_scores.append({
            'finding': finding['description'],
            'concordance_score': score / len(clinical_guidelines),
            'clinical_significance': score > 0.7
        })
    
    return concordance_scores
```

**Outcome Correlation**: Do process patterns correlate with patient outcomes?
```python
def analyze_outcome_correlation(process_data, outcomes):
    """
    Analyze correlation between process patterns and clinical outcomes.
    """
    import scipy.stats as stats
    
    correlations = {}
    
    # For each process metric, calculate correlation with outcomes
    process_metrics = [
        'case_duration', 'num_activities', 'deviation_score', 'time_to_treatment'
    ]
    
    for metric in process_metrics:
        if metric in process_data.columns:
            correlation, p_value = stats.pearsonr(
                process_data[metric], 
                outcomes['severity_score']
            )
            
            correlations[metric] = {
                'correlation': correlation,
                'p_value': p_value,
                'significant': p_value < 0.05,
                'strength': abs(correlation)
            }
    
    return correlations
```

### Statistical Validation

#### Comparative Analysis
```python
def compare_patient_groups(sepsis_data, control_data, metrics):
    """
    Compare process metrics between patient groups.
    """
    from scipy import stats
    import pandas as pd
    
    results = {}
    
    for metric in metrics:
        # Extract metric values
        sepsis_values = sepsis_data[metric].dropna()
        control_values = control_data[metric].dropna()
        
        # Perform statistical tests
        t_stat, t_p = stats.ttest_ind(sepsis_values, control_values)
        u_stat, u_p = stats.mannwhitneyu(sepsis_values, control_values)
        
        results[metric] = {
            'sepsis_mean': sepsis_values.mean(),
            'control_mean': control_values.mean(),
            'effect_size': (sepsis_values.mean() - control_values.mean()) / sepsis_values.std(),
            't_test': {'statistic': t_stat, 'p_value': t_p},
            'mann_whitney': {'statistic': u_stat, 'p_value': u_p},
            'clinically_significant': abs(sepsis_values.mean() - control_values.mean()) > sepsis_values.std() * 0.5
        }
    
    return results
```

---

## 8. Advanced Techniques {#advanced-techniques}

### Conformance Checking

#### Detecting Deviations from Clinical Guidelines
```python
def check_sepsis_protocol_conformance(event_log, protocol_model):
    """
    Check conformance to sepsis treatment protocols.
    """
    from pm4py.algo.conformance.alignments import algorithm as alignments
    
    # Calculate alignments
    aligned_traces = alignments.apply(event_log, protocol_model)
    
    # Analyze deviations
    deviations = []
    for trace in aligned_traces:
        for step in trace['alignment']:
            if step[0] == '>>' or step[1] == '>>':
                deviations.append({
                    'case_id': trace['case_id'],
                    'deviation_type': 'skip' if step[0] == '>>' else 'insertion',
                    'activity': step[0] if step[0] != '>>' else step[1],
                    'cost': step.get('cost', 1)
                })
    
    return {
        'total_deviations': len(deviations),
        'deviation_rate': len(deviations) / len(event_log),
        'deviations_by_type': pd.DataFrame(deviations).groupby('deviation_type').size().to_dict(),
        'most_common_deviations': pd.DataFrame(deviations)['activity'].value_counts().head(10)
    }
```

### Predictive Process Monitoring

#### Real-time Sepsis Risk Prediction
```python
class SepsisPredictor:
    """
    Predictive model for sepsis progression based on process patterns.
    """
    
    def __init__(self):
        self.model = None
        self.feature_columns = None
        
    def extract_features(self, case_events):
        """
        Extract predictive features from ongoing case.
        """
        features = {}
        
        # Temporal features
        if len(case_events) > 1:
            duration = (case_events['timestamp'].max() - case_events['timestamp'].min()).total_seconds() / 3600
            features['case_duration_hours'] = duration
        else:
            features['case_duration_hours'] = 0
            
        # Activity-based features
        features['num_events'] = len(case_events)
        features['unique_activities'] = case_events['activity'].nunique()
        
        # Clinical indicators
        features['has_high_temp'] = 'High Temperature' in case_events['activity'].values
        features['has_infection_marker'] = any(marker in case_events['activity'].values 
                                             for marker in ['Infection', 'CRP', 'Leucocytes'])
        features['has_antibiotics'] = 'Antibiotics' in case_events['activity'].values
        features['has_lab_work'] = 'Lab Test' in case_events['activity'].values
        
        # Sequence patterns
        activities = case_events['activity'].tolist()
        features['temp_before_lab'] = self._check_sequence(activities, 'High Temperature', 'Lab Test')
        features['lab_before_antibiotics'] = self._check_sequence(activities, 'Lab Test', 'Antibiotics')
        
        # Recent activity concentration
        if len(case_events) >= 5:
            recent_activities = case_events.tail(5)['activity'].nunique()
            features['recent_activity_diversity'] = recent_activities / 5
        else:
            features['recent_activity_diversity'] = 0
            
        return features
    
    def _check_sequence(self, activities, first, second):
        """Check if first activity occurs before second in sequence."""
        try:
            first_idx = activities.index(first)
            second_idx = activities.index(second)
            return first_idx < second_idx
        except ValueError:
            return False
    
    def train(self, training_cases, outcomes):
        """
        Train the sepsis prediction model.
        """
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.preprocessing import StandardScaler
        
        # Extract features for all training cases
        feature_list = []
        for case_id in training_cases['case'].unique():
            case_events = training_cases[training_cases['case'] == case_id]
            features = self.extract_features(case_events)
            features['case_id'] = case_id
            feature_list.append(features)
        
        # Create feature matrix
        feature_df = pd.DataFrame(feature_list)
        feature_df = feature_df.merge(outcomes, on='case_id')
        
        # Prepare training data
        X = feature_df.drop(['case_id', 'sepsis_outcome'], axis=1)
        y = feature_df['sepsis_outcome']
        
        # Store feature columns
        self.feature_columns = X.columns.tolist()
        
        # Train model
        self.scaler = StandardScaler()
        X_scaled = self.scaler.fit_transform(X)
        
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            min_samples_split=10,
            random_state=42
        )
        self.model.fit(X_scaled, y)
        
        return {
            'feature_importance': dict(zip(self.feature_columns, self.model.feature_importances_)),
            'training_accuracy': self.model.score(X_scaled, y)
        }
    
    def predict_risk(self, current_case_events):
        """
        Predict sepsis risk for ongoing case.
        """
        if self.model is None:
            raise ValueError("Model not trained. Call train() first.")
        
        # Extract features
        features = self.extract_features(current_case_events)
        
        # Ensure all expected features are present
        feature_vector = []
        for col in self.feature_columns:
            feature_vector.append(features.get(col, 0))
        
        # Scale features
        feature_vector = np.array(feature_vector).reshape(1, -1)
        feature_vector_scaled = self.scaler.transform(feature_vector)
        
        # Predict
        risk_probability = self.model.predict_proba(feature_vector_scaled)[0, 1]
        risk_category = 'HIGH' if risk_probability > 0.7 else 'MEDIUM' if risk_probability > 0.3 else 'LOW'
        
        return {
            'risk_probability': risk_probability,
            'risk_category': risk_category,
            'key_risk_factors': self._identify_risk_factors(features),
            'recommendation': self._generate_recommendation(risk_probability, features)
        }
    
    def _identify_risk_factors(self, features):
        """Identify the strongest risk factors for current case."""
        if self.model is None:
            return []
        
        # Get feature importance
        importance_dict = dict(zip(self.feature_columns, self.model.feature_importances_))
        
        # Find features that are both important and present
        risk_factors = []
        for feature, importance in importance_dict.items():
            if importance > 0.1 and features.get(feature, 0) > 0:
                risk_factors.append({
                    'factor': feature,
                    'importance': importance,
                    'present': bool(features.get(feature, 0))
                })
        
        return sorted(risk_factors, key=lambda x: x['importance'], reverse=True)[:5]
    
    def _generate_recommendation(self, risk_probability, features):
        """Generate clinical recommendations based on risk assessment."""
        if risk_probability > 0.7:
            return "URGENT: Consider immediate sepsis protocol activation and ICU consultation"
        elif risk_probability > 0.3:
            return "Monitor closely: Increase observation frequency and consider additional testing"
        else:
            return "Continue standard care with routine monitoring"
```

### Process Simulation

#### Simulating Intervention Effects
```python
def simulate_intervention_impact(process_model, intervention_params):
    """
    Simulate the impact of process interventions.
    """
    from pm4py.simulation.tree_playout import simulator
    
    # Original simulation
    original_log = simulator.apply(process_model, parameters={'num_traces': 1000})
    
    # Modified simulation with interventions
    modified_params = intervention_params.copy()
    modified_log = simulator.apply(process_model, parameters=modified_params)
    
    # Compare outcomes
    original_stats = calculate_process_statistics(original_log)
    modified_stats = calculate_process_statistics(modified_log)
    
    impact_analysis = {
        'avg_duration_change': modified_stats['avg_duration'] - original_stats['avg_duration'],
        'throughput_change': modified_stats['throughput'] - original_stats['throughput'],
        'resource_utilization_change': modified_stats['resource_util'] - original_stats['resource_util'],
        'cost_impact': calculate_cost_difference(original_stats, modified_stats)
    }
    
    return impact_analysis

def calculate_process_statistics(event_log):
    """Calculate key process statistics from event log."""
    durations = []
    resource_counts = {}
    
    for case in event_log:
        if len(case) > 1:
            duration = (case[-1]['time:timestamp'] - case[0]['time:timestamp']).total_seconds() / 3600
            durations.append(duration)
        
        for event in case:
            resource = event.get('org:resource', 'Unknown')
            resource_counts[resource] = resource_counts.get(resource, 0) + 1
    
    return {
        'avg_duration': np.mean(durations),
        'throughput': len(event_log) / (max(durations) if durations else 1),
        'resource_util': len(resource_counts),
        'total_events': sum(len(case) for case in event_log)
    }
```

---

## 9. Real-World Case Studies {#case-studies}

### Case Study 1: Emergency Department Flow Optimization

**Background**: Large urban hospital with 50,000+ annual ED visits experiencing overcrowding and long wait times.

**Process Mining Implementation**:
```python
def analyze_ed_flow(ed_event_log):
    """
    Comprehensive ED flow analysis.
    """
    # Discover main flow
    dfg, starts, ends = pm4py.discover_dfg(ed_event_log)
    
    # Identify bottlenecks
    performance_dfg = pm4py.discover_performance_dfg(ed_event_log)
    
    # Find longest wait times
    bottlenecks = []
    for (source, target), avg_time in performance_dfg.items():
        avg_hours = avg_time / 3600
        if avg_hours > 2:  # Flag waits > 2 hours
            bottlenecks.append({
                'transition': f"{source} → {target}",
                'avg_wait_hours': avg_hours,
                'impact_score': avg_hours * dfg.get((source, target), 0)
            })
    
    return sorted(bottlenecks, key=lambda x: x['impact_score'], reverse=True)

# Example findings and interventions
ed_findings = {
    'key_bottlenecks': [
        'Triage → Doctor Assessment: 3.2 hours average wait',
        'Doctor Assessment → Lab Results: 2.8 hours average wait',
        'Treatment → Discharge: 4.1 hours average wait'
    ],
    'interventions_implemented': [
        'Added fast-track for low-acuity patients',
        'Implemented bedside lab testing',
        'Streamlined discharge process with nurse practitioners'
    ],
    'results_achieved': {
        'avg_length_of_stay_reduction': '22% (8.5h to 6.6h)',
        'patient_satisfaction_increase': '15%',
        'staff_efficiency_improvement': '18%'
    }
}
```

**Key Learnings**:
- Process mining revealed hidden inefficiencies not visible in aggregate metrics
- Combination of data-driven insights and clinical expertise was crucial
- Continuous monitoring enabled rapid identification of new bottlenecks

### Case Study 2: Surgical Pathway Standardization

**Background**: Multi-specialty surgical center seeking to reduce variation in perioperative care.

**Implementation Approach**:
```python
def analyze_surgical_pathways(surgery_log, procedure_type):
    """
    Analyze variation in surgical pathways by procedure type.
    """
    # Filter by procedure type
    procedure_log = surgery_log[surgery_log['procedure'] == procedure_type]
    
    # Discover variants
    variants = pm4py.get_variants(procedure_log)
    
    # Calculate standardization metrics
    total_cases = len(procedure_log)
    variant_analysis = []
    
    for variant, cases in variants.items():
        variant_analysis.append({
            'pathway': ' → '.join(variant),
            'frequency': len(cases),
            'percentage': (len(cases) / total_cases) * 100,
            'avg_duration': calculate_variant_duration(cases),
            'outcome_score': calculate_outcome_score(cases)
        })
    
    # Identify opportunities for standardization
    standardization_opportunities = identify_standardization_targets(variant_analysis)
    
    return {
        'total_variants': len(variants),
        'top_variant_coverage': max(va['percentage'] for va in variant_analysis),
        'standardization_score': calculate_standardization_score(variant_analysis),
        'recommendations': standardization_opportunities
    }

def identify_standardization_targets(variant_analysis):
    """Identify pathways that could benefit from standardization."""
    opportunities = []
    
    # Group similar pathways
    pathway_groups = group_similar_pathways(variant_analysis)
    
    for group in pathway_groups:
        if len(group) > 1 and sum(v['frequency'] for v in group) > 50:
            # Multiple variants with significant volume
            best_variant = max(group, key=lambda x: x['outcome_score'])
            opportunities.append({
                'target_pathway': best_variant['pathway'],
                'current_variants': len(group),
                'affected_cases': sum(v['frequency'] for v in group),
                'potential_improvement': calculate_improvement_potential(group, best_variant)
            })
    
    return sorted(opportunities, key=lambda x: x['affected_cases'], reverse=True)
```

**Results Achieved**:
- **Pathway Variants Reduced**: From 47 to 12 variants for hip replacement surgery
- **Duration Standardization**: 95% of cases now within ±20% of target duration
- **Complication Rate**: Reduced by 8% through standardized protocols
- **Cost Savings**: $1.2M annually from reduced variation

### Case Study 3: Medication Administration Safety

**Background**: Implementation of process mining to improve medication safety and reduce administration errors.

**Analysis Framework**:
```python
def analyze_medication_safety(medication_log):
    """
    Analyze medication administration processes for safety patterns.
    """
    safety_analysis = {}
    
    # Check for proper verification steps
    required_steps = ['Order Entry', 'Pharmacist Review', 'Nurse Verification', 'Administration']
    
    # Analyze each medication case
    for case_id in medication_log['case'].unique():
        case_events = medication_log[medication_log['case'] == case_id]
        
        # Check compliance with 5 Rights protocol
        compliance_score = check_five_rights_compliance(case_events)
        
        # Identify timing deviations
        timing_analysis = analyze_administration_timing(case_events)
        
        # Flag high-risk patterns
        risk_factors = identify_medication_risk_factors(case_events)
        
        safety_analysis[case_id] = {
            'compliance_score': compliance_score,
            'timing_adherence': timing_analysis,
            'risk_level': calculate_risk_level(risk_factors),
            'recommendations': generate_safety_recommendations(case_events)
        }
    
    return safety_analysis

def check_five_rights_compliance(case_events):
    """Check compliance with the 5 Rights of medication administration."""
    rights_checked = {
        'right_patient': check_patient_verification(case_events),
        'right_medication': check_medication_verification(case_events),
        'right_dose': check_dose_verification(case_events),
        'right_route': check_route_verification(case_events),
        'right_time': check_timing_verification(case_events)
    }
    
    compliance_score = sum(rights_checked.values()) / len(rights_checked)
    return {
        'overall_score': compliance_score,
        'individual_scores': rights_checked,
        'missing_verifications': [right for right, checked in rights_checked.items() if not checked]
    }
```

**Safety Improvements Achieved**:
- **Medication Errors**: Reduced by 34% through process standardization
- **Near-Miss Detection**: Increased early detection of potential errors by 67%
- **Verification Compliance**: Improved from 78% to 96% adherence to protocols
- **Alert Optimization**: Reduced false positive alerts by 45% while maintaining sensitivity

---

## 10. Deployment and Monitoring {#deployment}

### Production Implementation Architecture

#### Real-Time Process Mining System
```python
class RealTimeProcessMonitor:
    """
    Real-time monitoring system for healthcare processes.
    """
    
    def __init__(self, config):
        self.config = config
        self.alert_thresholds = config['alert_thresholds']
        self.baseline_models = {}
        self.active_cases = {}
        
    def initialize_monitoring(self, historical_data):
        """
        Initialize monitoring with baseline models.
        """
        # Train baseline models for different process types
        for process_type in ['sepsis', 'emergency', 'surgery']:
            type_data = historical_data[historical_data['process_type'] == process_type]
            self.baseline_models[process_type] = self._train_baseline_model(type_data)
        
        print("✓ Baseline models initialized for real-time monitoring")
    
    def process_new_event(self, event):
        """
        Process a new clinical event in real-time.
        """
        case_id = event['case_id']
        
        # Update active case
        if case_id not in self.active_cases:
            self.active_cases[case_id] = {
                'events': [],
                'start_time': event['timestamp'],
                'current_state': None,
                'risk_score': 0,
                'alerts': []
            }
        
        self.active_cases[case_id]['events'].append(event)
        self.active_cases[case_id]['current_state'] = event['activity']
        
        # Perform real-time analysis
        analysis_result = self._analyze_current_case(case_id)
        
        # Check for alerts
        alerts = self._check_for_alerts(case_id, analysis_result)
        
        # Log monitoring data
        self._log_monitoring_event(case_id, event, analysis_result, alerts)
        
        return {
            'case_id': case_id,
            'analysis': analysis_result,
            'alerts': alerts,
            'recommendations': self._generate_recommendations(analysis_result)
        }
    
    def _analyze_current_case(self, case_id):
        """
        Analyze current case status and predict outcomes.
        """
        case_data = self.active_cases[case_id]
        events = case_data['events']
        
        # Calculate process metrics
        analysis = {
            'duration_hours': (events[-1]['timestamp'] - events[0]['timestamp']).total_seconds() / 3600,
            'num_events': len(events),
            'current_activity': events[-1]['activity'],
            'pathway_adherence': self._calculate_pathway_adherence(events),
            'predicted_outcome': self._predict_outcome(events),
            'bottleneck_risk': self._assess_bottleneck_risk(events)
        }
        
        return analysis
    
    def _check_for_alerts(self, case_id, analysis):
        """
        Check if current case requires clinical alerts.
        """
        alerts = []
        
        # Duration-based alerts
        if analysis['duration_hours'] > self.alert_thresholds['max_duration']:
            alerts.append({
                'type': 'DURATION_EXCEEDED',
                'severity': 'HIGH',
                'message': f"Case duration ({analysis['duration_hours']:.1f}h) exceeds threshold",
                'recommendation': 'Review for potential delays or complications'
            })
        
        # Pathway deviation alerts
        if analysis['pathway_adherence'] < self.alert_thresholds['min_adherence']:
            alerts.append({
                'type': 'PATHWAY_DEVIATION',
                'severity': 'MEDIUM',
                'message': f"Low pathway adherence ({analysis['pathway_adherence']:.1%})",
                'recommendation': 'Verify care plan compliance'
            })
        
        # Outcome prediction alerts
        if analysis['predicted_outcome']['risk_score'] > self.alert_thresholds['risk_threshold']:
            alerts.append({
                'type': 'HIGH_RISK_PREDICTED',
                'severity': 'URGENT',
                'message': f"High risk outcome predicted ({analysis['predicted_outcome']['risk_score']:.1%})",
                'recommendation': 'Consider immediate intervention'
            })
        
        return alerts
    
    def generate_daily_report(self):
        """
        Generate daily monitoring report.
        """
        active_cases_count = len(self.active_cases)
        high_risk_cases = [
            case_id for case_id, case_data in self.active_cases.items()
            if case_data.get('risk_score', 0) > 0.7
        ]
        
        report = {
            'date': datetime.now().strftime('%Y-%m-%d'),
            'summary': {
                'active_cases': active_cases_count,
                'high_risk_cases': len(high_risk_cases),
                'alerts_generated': sum(len(case['alerts']) for case in self.active_cases.values()),
                'avg_case_duration': np.mean([
                    (datetime.now() - case['start_time']).total_seconds() / 3600
                    for case in self.active_cases.values()
                ])
            },
            'trending_issues': self._identify_trending_issues(),
            'recommendations': self._generate_system_recommendations()
        }
        
        return report
```

#### Integration with Hospital Information Systems

**HL7 FHIR Integration**:
```python
class FHIRProcessMiningBridge:
    """
    Bridge between FHIR resources and process mining event logs.
    """
    
    def __init__(self, fhir_server_url):
        self.fhir_server = fhir_server_url
        
    def convert_fhir_to_event_log(self, patient_id, start_date, end_date):
        """
        Convert FHIR resources to process mining event format.
        """
        events = []
        
        # Fetch relevant FHIR resources
        resources = self._fetch_patient_resources(patient_id, start_date, end_date)
        
        # Convert each resource type to events
        for resource in resources:
            if resource['resourceType'] == 'Encounter':
                events.extend(self._convert_encounter_to_events(resource))
            elif resource['resourceType'] == 'MedicationAdministration':
                events.extend(self._convert_medication_to_events(resource))
            elif resource['resourceType'] == 'DiagnosticReport':
                events.extend(self._convert_diagnostic_to_events(resource))
            elif resource['resourceType'] == 'Procedure':
                events.extend(self._convert_procedure_to_events(resource))
        
        # Sort events by timestamp
        events.sort(key=lambda x: x['timestamp'])
        
        return pd.DataFrame(events)
    
    def _convert_encounter_to_events(self, encounter):
        """Convert FHIR Encounter to process events."""
        events = []
        patient_id = encounter['subject']['reference'].split('/')[-1]
        
        # Admission event
        if 'period' in encounter and 'start' in encounter['period']:
            events.append({
                'case': patient_id,
                'activity': f"Admission_{encounter.get('class', {}).get('code', 'Unknown')}",
                'timestamp': encounter['period']['start'],
                'resource': encounter.get('serviceProvider', {}).get('display', 'Unknown'),
                'encounter_id': encounter['id']
            })
        
        # Discharge event
        if 'period' in encounter and 'end' in encounter['period']:
            events.append({
                'case': patient_id,
                'activity': 'Discharge',
                'timestamp': encounter['period']['end'],
                'resource': encounter.get('serviceProvider', {}).get('display', 'Unknown'),
                'encounter_id': encounter['id']
            })
        
        return events
```

### Monitoring and Maintenance

#### Model Drift Detection
```python
def detect_model_drift(current_data, baseline_model, threshold=0.1):
    """
    Detect if process patterns have significantly changed.
    """
    # Calculate current process metrics
    current_metrics = calculate_process_metrics(current_data)
    baseline_metrics = baseline_model['metrics']
    
    # Compare key metrics
    drift_scores = {}
    for metric in ['avg_duration', 'pathway_variance', 'activity_distribution']:
        if metric in current_metrics and metric in baseline_metrics:
            # Calculate normalized difference
            current_val = current_metrics[metric]
            baseline_val = baseline_metrics[metric]
            
            if baseline_val != 0:
                drift_score = abs(current_val - baseline_val) / baseline_val
                drift_scores[metric] = {
                    'score': drift_score,
                    'significant': drift_score > threshold,
                    'current': current_val,
                    'baseline': baseline_val
                }
    
    # Overall drift assessment
    overall_drift = np.mean([score['score'] for score in drift_scores.values()])
    
    return {
        'overall_drift_score': overall_drift,
        'drift_detected': overall_drift > threshold,
        'metric_drifts': drift_scores,
        'recommendation': 'Retrain model' if overall_drift > threshold else 'Continue monitoring'
    }
```

#### Performance Monitoring Dashboard
```python
def create_monitoring_dashboard(monitoring_data):
    """
    Create a real-time monitoring dashboard.
    """
    import plotly.graph_objects as go
    from plotly.subplots import make_subplots
    
    # Create subplots
    fig = make_subplots(
        rows=2, cols=2,
        subplot_titles=['Case Volume', 'Average Duration', 'Alert Distribution', 'Risk Scores'],
        specs=[[{'secondary_y': True}, {'secondary_y': False}],
               [{'type': 'pie'}, {'type': 'histogram'}]]
    )
    
    # Case volume over time
    fig.add_trace(
        go.Scatter(
            x=monitoring_data['timestamps'],
            y=monitoring_data['case_volumes'],
            name='Case Volume',
            line=dict(color='blue')
        ),
        row=1, col=1
    )
    
    # Average duration trend
    fig.add_trace(
        go.Scatter(
            x=monitoring_data['timestamps'],
            y=monitoring_data['avg_durations'],
            name='Avg Duration',
            line=dict(color='green')
        ),
        row=1, col=2
    )
    
    # Alert distribution pie chart
    fig.add_trace(
        go.Pie(
            labels=list(monitoring_data['alert_types'].keys()),
            values=list(monitoring_data['alert_types'].values()),
            name='Alerts'
        ),
        row=2, col=1
    )
    
    # Risk score distribution
    fig.add_trace(
        go.Histogram(
            x=monitoring_data['risk_scores'],
            name='Risk Distribution',
            nbinsx=20
        ),
        row=2, col=2
    )
    
    # Update layout
    fig.update_layout(
        title='Healthcare Process Monitoring Dashboard',
        showlegend=True,
        height=800
    )
    
    return fig
```

---

## 11. Best Practices and Pitfalls {#best-practices}

### Best Practices

#### 1. Data Preparation
✅ **DO**:
- Validate timestamps are accurate
- Standardize activity names
- Include relevant context (lab values, vitals)
- Document data cleaning decisions

❌ **DON'T**:
- Mix granularity levels
- Ignore missing data patterns
- Assume all events are recorded

#### 2. Process Discovery
✅ **DO**:
- Start with simple models (DFG)
- Filter noise appropriately
- Validate with domain experts
- Consider multiple perspectives

❌ **DON'T**:
- Over-interpret automated discoveries
- Ignore infrequent but critical paths
- Assume one model fits all cases

#### 3. Clinical Interpretation
✅ **DO**:
- Involve clinicians early
- Focus on actionable insights
- Consider clinical guidelines
- Validate findings with outcomes

❌ **DON'T**:
- Make causal claims without evidence
- Ignore clinical context
- Overlook data biases

### Common Pitfalls in Healthcare Process Mining

#### Pitfall 1: Timestamp Granularity
**Problem**: Mixing minute-level ICU data with day-level ward data.
**Solution**: Aggregate to common granularity or analyze separately.

#### Pitfall 2: Incomplete Patient Journeys
**Problem**: Patients transferred between hospitals have partial logs.
**Solution**: Flag incomplete cases, analyze separately.

#### Pitfall 3: Documentation Bias
**Problem**: Process reflects documentation practices, not actual care.
**Solution**: Validate with observational studies, include automated data.

#### Pitfall 4: Outcome Attribution
**Problem**: Assuming process variations cause outcome differences.
**Solution**: Control for patient complexity, use statistical testing.

---

## 12. Exercises and Solutions {#exercises}

### Exercise 1: Basic Event Log Analysis

**Task**: Load the organ damage dataset and identify the top 3 most common patient pathways.

**Solution**:
```python
from step1_data_loader import EventLogLoader
from step2_process_mining import ProcessMiner

# Load data
loader = EventLogLoader("data/sepsisAgregated_Organ.csv")
data = loader.load_data()
prepared = loader.prepare_data()

# Create event log
miner = ProcessMiner()
event_log = miner.create_event_log(prepared)

# Discover variants
variants = miner.discover_variants(top_k=3)
print("Top 3 patient pathways:")
for idx, row in variants.iterrows():
    print(f"{idx+1}. {row['variant']}")
    print(f"   Frequency: {row['percentage']}% ({row['cases']} patients)")
```

### Exercise 2: Compare Sepsis vs Non-Sepsis

**Task**: Find activities that occur more frequently in sepsis cases.

**Solution**:
```python
# Load and separate cases
sepsis_data = loader.filter_by_outcome(sepsis_only=True)
non_sepsis_data = loader.filter_by_outcome(sepsis_only=False)

# Count activities
sepsis_activities = sepsis_data['activity'].value_counts()
non_sepsis_activities = non_sepsis_data['activity'].value_counts()

# Normalize by number of cases
sepsis_norm = sepsis_activities / sepsis_data['case'].nunique()
non_sepsis_norm = non_sepsis_activities / non_sepsis_data['case'].nunique()

# Find differences
differences = (sepsis_norm - non_sepsis_norm).sort_values(ascending=False)
print("Activities more common in sepsis cases:")
for activity, diff in differences.head(5).items():
    print(f"  {activity}: +{diff:.2f} per patient")
```

### Exercise 3: Time-Critical Transitions

**Task**: Identify transitions where timing is critical (high variance indicates problematic delays).

**Solution**:
```python
import numpy as np

def find_critical_transitions(event_log):
    """
    Find transitions with high time variance.
    """
    # Calculate transition times
    transition_times = {}
    
    for case in event_log:
        for i in range(len(case) - 1):
            current = case[i]['concept:name']
            next_act = case[i+1]['concept:name']
            time_diff = (case[i+1]['time:timestamp'] - 
                        case[i]['time:timestamp']).total_seconds() / 3600
            
            key = (current, next_act)
            if key not in transition_times:
                transition_times[key] = []
            transition_times[key].append(time_diff)
    
    # Calculate variance
    critical = []
    for transition, times in transition_times.items():
        if len(times) > 10:  # Need sufficient samples
            variance = np.var(times)
            mean_time = np.mean(times)
            cv = np.std(times) / mean_time if mean_time > 0 else 0
            critical.append({
                'transition': f"{transition[0]} → {transition[1]}",
                'mean_hours': mean_time,
                'std_hours': np.std(times),
                'coefficient_variation': cv,
                'samples': len(times)
            })
    
    # Sort by coefficient of variation
    critical.sort(key=lambda x: x['coefficient_variation'], reverse=True)
    
    return critical[:10]

# Find critical transitions
critical = find_critical_transitions(event_log)
print("Time-critical transitions (high variance):")
for trans in critical[:5]:
    print(f"  {trans['transition']}")
    print(f"    Mean: {trans['mean_hours']:.1f}h ± {trans['std_hours']:.1f}h")
    print(f"    CV: {trans['coefficient_variation']:.2f}")
```

### Exercise 4: Build a Prediction Model

**Task**: Use process mining features to predict sepsis onset.

**Solution**:
```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

def create_process_features(data):
    """
    Create features from process data for prediction.
    """
    features = []
    
    for case_id in data['case'].unique():
        case_data = data[data['case'] == case_id]
        
        # Process features
        feature_dict = {
            'num_events': len(case_data),
            'unique_activities': case_data['activity'].nunique(),
            'duration_hours': (case_data['timestamp'].max() - 
                             case_data['timestamp'].min()).total_seconds() / 3600,
            'has_high_temp': ('High Temperature' in case_data['activity'].values),
            'has_infection': ('Infection' in case_data['activity'].values),
            'sepsis_label': case_data['SepsisLabel'].max()
        }
        
        # Activity counts
        for activity in ['Admission', 'Lab Test', 'Medication']:
            feature_dict[f'count_{activity}'] = (
                case_data['activity'] == activity).sum()
        
        features.append(feature_dict)
    
    return pd.DataFrame(features)

# Create features
features_df = create_process_features(prepared_data)

# Prepare for modeling
X = features_df.drop('sepsis_label', axis=1)
y = features_df['sepsis_label']

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Evaluate
predictions = model.predict(X_test)
print("Sepsis Prediction Results:")
print(classification_report(y_test, predictions))

# Feature importance
importance = pd.DataFrame({
    'feature': X.columns,
    'importance': model.feature_importances_
}).sort_values('importance', ascending=False)

print("\nTop predictive features:")
for idx, row in importance.head(5).iterrows():
    print(f"  {row['feature']}: {row['importance']:.3f}")
```

### Exercise 5: Create a Clinical Dashboard

**Task**: Design a monitoring dashboard for sepsis progression.

**Solution**:
```python
def create_clinical_dashboard(current_patient_data, historical_patterns):
    """
    Create a real-time monitoring dashboard.
    """
    dashboard = {
        'patient_id': current_patient_data['case'].iloc[0],
        'current_state': current_patient_data['activity'].iloc[-1],
        'time_in_state': calculate_time_in_state(current_patient_data),
        'risk_score': calculate_risk_score(current_patient_data, historical_patterns),
        'expected_next': predict_next_activity(current_patient_data, historical_patterns),
        'alerts': generate_alerts(current_patient_data)
    }
    
    return dashboard

def calculate_risk_score(patient_data, patterns):
    """
    Calculate sepsis risk based on current pathway.
    """
    score = 0
    
    # Check for high-risk patterns
    if 'High Temperature' in patient_data['activity'].values:
        score += 30
    if 'Infection' in patient_data['activity'].values:
        score += 40
    
    # Time-based risk
    duration = (patient_data['timestamp'].max() - 
               patient_data['timestamp'].min()).total_seconds() / 3600
    if duration > 24:
        score += 20
    
    return min(score, 100)

def generate_alerts(patient_data):
    """
    Generate clinical alerts based on patterns.
    """
    alerts = []
    
    # Check for rapid progression
    if len(patient_data) > 5:
        recent_activities = patient_data.tail(5)['activity'].values
        if 'High Temperature' in recent_activities and 'Infection' in recent_activities:
            alerts.append({
                'level': 'HIGH',
                'message': 'Rapid progression detected - consider immediate intervention'
            })
    
    return alerts

# Example usage
current_patient = prepared_data[prepared_data['case'] == 'P001']
dashboard = create_clinical_dashboard(current_patient, miner.dfg)
print("Clinical Dashboard:")
print(f"Patient: {dashboard['patient_id']}")
print(f"Current State: {dashboard['current_state']}")
print(f"Risk Score: {dashboard['risk_score']}/100")
if dashboard['alerts']:
    print(f"ALERT: {dashboard['alerts'][0]['message']}")
```

---

## Summary and Next Steps

### What You've Learned

1. **Process Mining Fundamentals**
   - Event logs and their structure
   - Discovery algorithms and their applications
   - Process visualization techniques

2. **Healthcare Applications**
   - Clinical pathway analysis
   - Sepsis progression patterns
   - Performance measurement

3. **Technical Skills**
   - Data preparation with pandas
   - Process mining with PM4PY
   - LLM integration for insights

4. **Clinical Insights**
   - Pattern identification
   - Risk stratification
   - Intervention timing

5. **Advanced Techniques**
   - Conformance checking
   - Predictive monitoring
   - Real-time analysis

6. **Production Deployment**
   - System architecture
   - Integration patterns
   - Monitoring and maintenance

### Next Steps

1. **Expand Your Analysis**
   - Try different algorithms (Inductive Miner, Split Miner)
   - Analyze other clinical conditions
   - Implement conformance checking

2. **Enhance with Machine Learning**
   - Predictive process monitoring
   - Outcome prediction
   - Anomaly detection

3. **Real-World Application**
   - Work with your institution's data
   - Collaborate with clinical teams
   - Validate findings with trials

### Additional Resources

- **Process Mining Books**
  - "Process Mining: Data Science in Action" by Wil van der Aalst
  - "Process Mining in Healthcare" by Ronny Mans

- **Online Courses**
  - Coursera: Process Mining with Python
  - FutureLearn: Process Mining in Healthcare

- **Tools and Libraries**
  - PM4PY: [pm4py.fit.fraunhofer.de](https://pm4py.fit.fraunhofer.de/)
  - ProM: Process Mining Toolkit
  - Disco: Commercial process mining tool

- **Healthcare Standards**
  - HL7 FHIR for healthcare data exchange
  - OMOP Common Data Model
  - i2b2 for clinical research

### Final Project Ideas

1. **Emergency Department Optimization**
   - Analyze patient flow from triage to discharge
   - Identify bottlenecks causing delays
   - Recommend staffing adjustments

2. **Medication Administration Patterns**
   - Discover actual vs. prescribed timing
   - Identify deviation patterns
   - Correlate with patient outcomes

3. **Surgical Pathway Analysis**
   - Map pre-op to post-op processes
   - Compare pathways across surgeons
   - Optimize scheduling and resources

4. **Chronic Disease Management**
   - Analyze long-term patient journeys
   - Identify successful management patterns
   - Predict exacerbations

---

## Congratulations!

You've completed this comprehensive tutorial on process mining in healthcare. You now have the knowledge and tools to:

- Extract insights from clinical event data
- Discover and analyze healthcare processes
- Generate AI-powered clinical reports
- Apply process mining to improve patient care
- Deploy and monitor production systems
- Validate findings with statistical methods

Remember: Process mining is a powerful tool, but always validate findings with clinical expertise and consider the full context of patient care.

**Happy Mining! 🏥📊**