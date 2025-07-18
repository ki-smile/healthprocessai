# -*- coding: utf-8 -*-
"""
Created on Mon Jul 14 14:25:27 2025

@author: edillu
"""

#!/usr/bin/env python3
"""
OpenRouter Free Models Comparison Script - Python Translation
This script compares responses from free models using OpenRouter API
Translated from R to Python using PM4PY library for process discovery
"""

import requests
import json
import pandas as pd
import numpy as np
import os
from datetime import datetime
from typing import List, Dict, Any, Optional
import logging
from pathlib import Path
import graphviz

import os
os.environ["PATH"] += ';C:\\Program Files\\Graphviz\\bin'

# PM4PY imports for process mining
import pm4py
from pm4py.objects.conversion.log import converter as log_converter
from pm4py.objects.log.importer.xes import importer as xes_importer
from pm4py.algo.discovery.dfg import algorithm as dfg_discovery
from pm4py.visualization.dfg import visualizer as dfg_visualization
from pm4py.algo.filtering.log.cases import case_filter
from pm4py.statistics.traces.generic.log import case_statistics
from pm4py.statistics.traces.generic.log import case_statistics as trace_stats
from pm4py.algo.discovery.heuristics import algorithm as heuristics_miner
from pm4py.visualization.heuristics_net import visualizer as hn_visualizer
from pm4py.algo.discovery.alpha import algorithm as alpha_miner
from pm4py.visualization.petri_net import visualizer as pn_visualizer
from pm4py.statistics.attributes.log import get as attributes_get
from pm4py.util import constants
from pm4py.objects.log.util import dataframe_utils
from pm4py.objects.conversion.log import converter as log_converter
from pm4py.objects.log.obj import EventLog

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ProcessMiningAnalyzer:
    """Class to handle process mining analysis using PM4PY"""
    
    def __init__(self, event_log_path: str):
        self.event_log_path = event_log_path
        self.event_log = None
        self.process_matrix = None
        self.process_map = None
        
    def load_and_prepare_data(self) -> None:
        """Load CSV data and convert to PM4PY event log format"""
        try:
            # Read CSV file
            df = pd.read_csv(self.event_log_path)
            
            # Convert timestamp to datetime
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            
            # Rename columns to PM4PY standard format
            df = df.rename(columns={
                'case': 'case:concept:name',
                'activity': 'concept:name',
                'timestamp': 'time:timestamp',
                'resource': 'org:resource',
                'lifecycle': 'lifecycle:transition'
            })
            
            # Convert to event log
            self.event_log = log_converter.apply(df)
            
            logger.info(f"Successfully loaded event log with {len(self.event_log)} cases")
            
        except Exception as e:
            logger.error(f"Error loading data: {e}")
            raise
    
    def filter_sepsis_cases(self, sepsis: bool) -> None:
        """Filter cases based on SepsisLabel == 1"""
        try:
            # Read original CSV to get SepsisLabel
            df = pd.read_csv(self.event_log_path)
            
            print(len(df['case'].unique()))
                  
            # Get case IDs with SepsisLabel == 1
            if sepsis:
                sepsis_cases = df[df['SepsisLabel'] == 1]['case'].unique()
            else:
                selection = df[df['SepsisLabel'] == 1]['case'].unique()
                sepsis_cases = df[~(df['case'].isin(selection))]['case'].unique()
                
            print(len(sepsis_cases))
            # Filter event log
            filtered_traces = []
            for trace in self.event_log:
                if trace.attributes['concept:name'] in sepsis_cases:
                    filtered_traces.append(trace)
            
            # Create new event log with filtered traces
            
            self.event_log = EventLog(filtered_traces)
            
            logger.info(f"Filtered to {len(self.event_log)} sepsis cases")
            
        except Exception as e:
            logger.error(f"Error filtering cases: {e}")
            raise
    
    def generate_process_discovery(self, use_case: str, proces_path: str) -> None:
        """Generate process map and matrix using PM4PY"""
        try:
            # Generate DFG (Directly-Follows Graph)
            dfg = dfg_discovery.apply(self.event_log)
            
            # Get start and end activities
            start_activities = pm4py.get_start_activities(self.event_log)
            end_activities = pm4py.get_end_activities(self.event_log)
            
            pm4py.view_dfg(dfg, start_activities, end_activities)
            
            
            # Create process map data structure
            process_map_data = {
                'dfg': {str(k): v for k, v in dfg.items()},
                'start_activities': start_activities,
                'end_activities': end_activities
            }
            
            # Save process map to JSON
            with open(proces_path, 'w') as f:
                json.dump(process_map_data, f, indent=2)
            
            # Generate process matrix (activity frequency matrix)
            activities = pm4py.get_event_attribute_values(self.event_log, "concept:name")
            
            # Create frequency matrix
            activity_list = list(activities.keys())
            matrix_data = []
            
            for activity in activity_list:
                row_data = {'activity': activity}
                for target_activity in activity_list:
                    # Count direct follows between activities
                    count = dfg.get((activity, target_activity), 0)
                    row_data[target_activity] = count
                matrix_data.append(row_data)
            
            # Convert to DataFrame and save
            matrix_df = pd.DataFrame(matrix_data)
            matrix_df.to_csv('process_matrix.csv', index=False)
            
            self.process_matrix = matrix_df
            self.process_map = process_map_data
            
            logger.info("Process discovery completed successfully")
            
        except Exception as e:
            logger.error(f"Error in process discovery: {e}")
            raise

class OpenRouterClient:
    """Client for interacting with OpenRouter API"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://openrouter.ai/api/v1"
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost:8080",
            "X-Title": "Process Mining Analysis"
        }
    
    def query_model(self, model_name: str, messages: List[Dict], temperature: float = 0.7) -> Dict:
        """Query a model through OpenRouter API"""
        try:
            payload = {
                "model": model_name,
                "messages": messages,
                "temperature": temperature
            }
            
            response = requests.post(
                f"{self.base_url}/chat/completions",
                headers=self.headers,
                json=payload
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"API request failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            logger.error(f"Error querying model {model_name}: {e}")
            raise

def read_file_content(filepath: str) -> str:
    """Read file content safely"""
    try:
        if os.path.exists(filepath):
            with open(filepath, 'r', encoding='utf-8') as f:
                return f.read()
        else:
            logger.warning(f"File {filepath} not found")
            return ""
    except Exception as e:
        logger.error(f"Error reading file {filepath}: {e}")
        return ""

def save_string_to_md(text_string: str, filename: str = "output.md", directory: str = None) -> str:
    """Save string to markdown file"""
    if directory is None:
        directory = os.getcwd()
    
    filepath = Path(directory) / filename
    
    # Ensure .md extension
    if not filepath.suffix == '.md':
        filepath = filepath.with_suffix('.md')
    
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(text_string)
        
        logger.info(f"Markdown file saved to: {filepath}")
        return str(filepath)
        
    except Exception as e:
        logger.error(f"Error saving file {filepath}: {e}")
        raise

def query_model_safe(client: OpenRouterClient, model_name: str, prompt: str, use_case: str) -> Dict:
    """Safely query a model with error handling"""
    try:
        logger.info(f"Querying model: {model_name}")
        
        if use_case == "Infection":
            # Read file contents
            map_content = read_file_content('processMap.json')
            
            # Prepare messages
            messages = [
                {"role": "user", "content": prompt},
                {"role": "user", "content": f"Process Map JSON:\n{map_content}"}
            ]
            
        else:
            # Read file contents
            map_content_1 = read_file_content('processMap_1.json')
            map_content_2 = read_file_content('processMap_2.json')
            
            # Prepare messages
            messages = [
                {"role": "user", "content": prompt},
                {"role": "user", "content": f"Process Map (with Sepsis) JSON:\n{map_content_1}"},
                {"role": "user", "content": f"Process Map (without Sepsis) JSON:\n{map_content_2}"}
            ]
            
        
        # Query the model
        response = client.query_model(model_name, messages)
        
        # Extract response content
        content = response['choices'][0]['message']['content']
        
        return {
            'model': model_name,
            'status': 'success',
            'response': content,
            'tokens_used': response.get('usage', {}).get('total_tokens', None)
        }
        
    except Exception as e:
        logger.error(f"Error querying model {model_name}: {e}")
        return {
            'model': model_name,
            'status': 'error',
            'response': f"Error: {str(e)}",
            'tokens_used': None
        }

def workflow(event_log_path: str, models: List[str], prompt: str, api_key: str, use_case: str) -> None:
    """Main workflow function"""
    try:
        logger.info("Starting model comparison...")
        logger.info(f"Testing {len(models)} models")
        
        if use_case == "Infection":
            # Initialize process mining analyzer
            analyzer = ProcessMiningAnalyzer(event_log_path)
            
            # Load and prepare data
            analyzer.load_and_prepare_data()
            
            # Filter sepsis cases
            analyzer.filter_sepsis_cases(use_case)
            
            # Generate process discovery
            analyzer.generate_process_discovery(use_case, "processMap.json")
        
        elif use_case == "Organ":
            
            # Initialize process mining analyzer
            analyzer = ProcessMiningAnalyzer(event_log_path)
            
            # Load and prepare data
            analyzer.load_and_prepare_data()
            
            # Filter sepsis cases
            analyzer.filter_sepsis_cases(sepsis=True)
            
            # Generate process discovery
            analyzer.generate_process_discovery(use_case, "processMap_1.json")
            
            # Initialize process mining analyzer
            analyzer = ProcessMiningAnalyzer(event_log_path)
            
            # Load and prepare data
            analyzer.load_and_prepare_data()
            
            # Filter sepsis cases
            analyzer.filter_sepsis_cases(sepsis=False)
            
            # Generate process discovery
            analyzer.generate_process_discovery(use_case, "processMap_2.json")
        
        else:
            logger.info("Unknown use case")
        
        # Initialize OpenRouter client
        client = OpenRouterClient(api_key)
        
        # Query all models
        results = []
        for model in models:
            result = query_model_safe(client, model, prompt, use_case)
            results.append(result)
        
        # Convert results to DataFrame
        results_df = pd.DataFrame(results)
        
        # Save individual reports for successful models
        successful_models = results_df[results_df['status'] == 'success']
        
        if len(successful_models) > 0:
            logger.info("=== SAVING INDIVIDUAL REPORTS ===")
            for _, row in successful_models.iterrows():
                model_name_clean = "".join(c if c.isalnum() or c in "_-" else "_" for c in row['model'])
                filename = f'Report_{model_name_clean}.md'
                save_string_to_md(row['response'], filename)
        
        logger.info("Workflow completed successfully!")
        
    except Exception as e:
        logger.error(f"Error in workflow: {e}")
        raise

def main():
    """Main function"""
    # Configuration
    
    use_case = "Organ"
    
    OPENROUTER_API_KEY = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" #REPLACE BY YOUR OPEN ROUTER API KEY
    fileName = "prompt_infection.txt"
    
    # Define the prompt
    with open(fileName, 'r', encoding='utf-8') as f:
        test_prompt = f.read() 
    
    # Define models to test
    models = [
        "deepseek/deepseek-r1:free"
    ]
    
    # Event log file
    event_log_path = "sepsisAgregated_Organ.csv"
    
    # Run workflow
    workflow(event_log_path, models, test_prompt, OPENROUTER_API_KEY, use_case)

if __name__ == "__main__":
    main()