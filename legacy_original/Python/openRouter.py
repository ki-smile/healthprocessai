# -*- coding: utf-8 -*-
"""
================================================================================
HEALTHPROCESSAI - PROCESS MINING WITH LLM INTEGRATION FOR HEALTHCARE
================================================================================
This script demonstrates the integration of process mining techniques with 
Large Language Models (LLMs) for analyzing healthcare data, specifically 
focusing on sepsis progression patterns.

Created on Mon Jul 14 14:25:27 2025
@author: edillu
Developed at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet

LEARNING OBJECTIVES:
1. Understand how to convert healthcare event logs to PM4PY format
2. Learn process discovery techniques (DFG, process maps, matrices)
3. Integrate multiple LLM models via OpenRouter API
4. Generate clinical insights from process mining results

KEY CONCEPTS:
- Event Logs: Records of healthcare activities with timestamps
- Process Mining: Extracting knowledge from event logs
- DFG (Directly-Follows Graph): Shows activity sequences
- LLM Integration: Using AI to interpret process patterns
================================================================================
"""

#!/usr/bin/env python3
"""
OpenRouter Free Models Comparison Script - Python Translation
This script compares responses from free models using OpenRouter API
Translated from R to Python using PM4PY library for process discovery
"""

# ========== IMPORTS SECTION ==========
# Standard library imports for basic functionality
import requests        # For making HTTP requests to OpenRouter API
import json           # For handling JSON data (API responses, process maps)
import pandas as pd   # For data manipulation and CSV handling
import numpy as np    # For numerical operations
import os            # For file system operations
from datetime import datetime  # For timestamp handling
from typing import List, Dict, Any, Optional  # For type hints (helps with code clarity)
import logging        # For structured logging throughout the application
from pathlib import Path  # For cross-platform file path handling
import graphviz      # For visualization (required by PM4PY)

# IMPORTANT: Graphviz configuration for Windows
# This adds Graphviz binary path to system PATH for visualization
# Modify this path based on your Graphviz installation location
# Mac/Linux users can comment this out if Graphviz is in system PATH
import os
os.environ["PATH"] += ';C:\\Program Files\\Graphviz\\bin'

# ========== PM4PY IMPORTS ==========
# PM4PY is the leading Python library for process mining
# It provides algorithms for process discovery, conformance checking, and enhancement
import pm4py
# Specific PM4PY modules for different process mining tasks
from pm4py.objects.conversion.log import converter as log_converter  # Converts dataframes to event logs
from pm4py.objects.log.importer.xes import importer as xes_importer  # Imports XES format logs
from pm4py.algo.discovery.dfg import algorithm as dfg_discovery  # Discovers Directly-Follows Graphs
from pm4py.visualization.dfg import visualizer as dfg_visualization  # Visualizes DFGs
from pm4py.algo.filtering.log.cases import case_filter  # Filters cases in event logs
from pm4py.statistics.traces.generic.log import case_statistics  # Computes trace statistics
from pm4py.statistics.traces.generic.log import case_statistics as trace_stats  # Alternative import
from pm4py.algo.discovery.heuristics import algorithm as heuristics_miner  # Heuristics mining algorithm
from pm4py.visualization.heuristics_net import visualizer as hn_visualizer  # Visualizes heuristics nets
from pm4py.algo.discovery.alpha import algorithm as alpha_miner  # Alpha mining algorithm
from pm4py.visualization.petri_net import visualizer as pn_visualizer  # Visualizes Petri nets
from pm4py.statistics.attributes.log import get as attributes_get  # Gets attribute statistics
from pm4py.util import constants  # PM4PY constants for column names
from pm4py.objects.log.util import dataframe_utils  # Utilities for dataframe handling
from pm4py.objects.conversion.log import converter as log_converter  # Duplicate import (can be removed)
from pm4py.objects.log.obj import EventLog  # EventLog object class

# ========== LOGGING CONFIGURATION ==========
# Set up logging to track script execution and debug issues
# INFO level shows important events, change to DEBUG for more detail
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ProcessMiningAnalyzer:
    """
    ProcessMiningAnalyzer - Core class for healthcare process mining
    
    This class handles the complete process mining workflow:
    1. Loading healthcare event data from CSV files
    2. Converting to PM4PY event log format
    3. Filtering cases based on clinical outcomes (e.g., sepsis)
    4. Discovering process patterns using DFG algorithm
    5. Creating process matrices for quantitative analysis
    
    Attributes:
        event_log_path (str): Path to the CSV file containing event data
        event_log (EventLog): PM4PY EventLog object after conversion
        process_matrix (DataFrame): Matrix showing activity transitions
        process_map (dict): JSON-serializable process map data
    
    Example usage:
        analyzer = ProcessMiningAnalyzer("sepsis_events.csv")
        analyzer.load_and_prepare_data()
        analyzer.filter_sepsis_cases(sepsis=True)
        analyzer.generate_process_discovery("Infection", "map.json")
    """
    
    def __init__(self, event_log_path: str):
        """
        Initialize the analyzer with path to event log CSV file.
        
        Args:
            event_log_path: Path to CSV file with columns:
                - case: Patient/case identifier
                - activity: Clinical activity/state
                - timestamp: When the activity occurred
                - resource: Department/clinician
                - SepsisLabel: Outcome (0=no sepsis, 1=sepsis)
        """
        self.event_log_path = event_log_path
        self.event_log = None        # Will store PM4PY EventLog object
        self.process_matrix = None   # Will store activity transition matrix
        self.process_map = None      # Will store process map as dict
        
    def load_and_prepare_data(self) -> None:
        """
        Load CSV data and convert to PM4PY event log format.
        
        This method performs crucial data preparation steps:
        1. Reads the CSV file into a pandas DataFrame
        2. Converts timestamp strings to datetime objects
        3. Renames columns to PM4PY's expected format
        4. Converts DataFrame to PM4PY EventLog object
        
        PM4PY Column Naming Convention:
        - 'case:concept:name': Case/patient identifier
        - 'concept:name': Activity name
        - 'time:timestamp': Timestamp of the event
        - 'org:resource': Resource that performed the activity
        - 'lifecycle:transition': Event lifecycle (start/complete)
        
        Raises:
            Exception: If file cannot be read or conversion fails
        """
        try:
            # Step 1: Read the CSV file containing event data
            # Expected columns: case, activity, timestamp, resource, SepsisLabel
            df = pd.read_csv(self.event_log_path)
            
            # Step 2: Convert timestamp column from string to datetime
            # This is essential for PM4PY to correctly order events
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            
            # Step 3: Rename columns to PM4PY standard format
            # PM4PY uses specific column names based on XES standard
            df = df.rename(columns={
                'case': 'case:concept:name',      # Patient/case ID
                'activity': 'concept:name',       # Clinical activity
                'timestamp': 'time:timestamp',    # Event timestamp
                'resource': 'org:resource',       # Department/resource
                'lifecycle': 'lifecycle:transition'  # Event lifecycle
            })
            
            # Step 4: Convert DataFrame to PM4PY EventLog
            # This creates a structured event log for process mining
            self.event_log = log_converter.apply(df)
            
            # Log success message with case count
            logger.info(f"Successfully loaded event log with {len(self.event_log)} cases")
            
        except Exception as e:
            logger.error(f"Error loading data: {e}")
            raise
    
    def filter_sepsis_cases(self, sepsis: bool) -> None:
        """
        Filter event log to include only sepsis or non-sepsis cases.
        
        This method is crucial for comparative analysis:
        - Allows comparison between patients who developed sepsis vs those who didn't
        - Helps identify process differences that lead to different outcomes
        - Essential for discovering risk factors and intervention points
        
        Args:
            sepsis (bool): If True, keep only sepsis cases (SepsisLabel==1)
                          If False, keep only non-sepsis cases (SepsisLabel==0)
        
        Process:
        1. Re-read original CSV to access SepsisLabel column
        2. Identify case IDs based on sepsis outcome
        3. Filter event log to keep only selected cases
        4. Create new filtered EventLog object
        
        Note: SepsisLabel is typically assigned at case level, not event level
        """
        try:
            # Step 1: Read original CSV to get SepsisLabel information
            # We need to re-read because SepsisLabel might not be in event log
            df = pd.read_csv(self.event_log_path)
            
            # Debug: Print total unique cases before filtering
            print(f"Total cases before filtering: {len(df['case'].unique())}")
                  
            # Step 2: Identify cases based on sepsis outcome
            if sepsis:
                # Get case IDs where patient developed sepsis
                sepsis_cases = df[df['SepsisLabel'] == 1]['case'].unique()
            else:
                # Get case IDs where patient did NOT develop sepsis
                # First find sepsis cases, then select all others
                selection = df[df['SepsisLabel'] == 1]['case'].unique()
                sepsis_cases = df[~(df['case'].isin(selection))]['case'].unique()
            
            # Debug: Print filtered case count
            print(f"Cases after filtering: {len(sepsis_cases)}")
            
            # Step 3: Filter event log to keep only selected cases
            # Each trace in event log represents one case/patient
            filtered_traces = []
            for trace in self.event_log:
                # Check if this trace's case ID is in our selected cases
                if trace.attributes['concept:name'] in sepsis_cases:
                    filtered_traces.append(trace)
            
            # Step 4: Create new EventLog with only filtered traces
            self.event_log = EventLog(filtered_traces)
            
            # Log the filtering result
            outcome_type = "sepsis" if sepsis else "non-sepsis"
            logger.info(f"Filtered to {len(self.event_log)} {outcome_type} cases")
            
        except Exception as e:
            logger.error(f"Error filtering cases: {e}")
            raise
    
    def generate_process_discovery(self, use_case: str, proces_path: str) -> None:
        """
        Generate process map and transition matrix using PM4PY's DFG algorithm.
        
        This is the core process mining method that discovers patterns in the data:
        1. Creates a Directly-Follows Graph (DFG) showing activity sequences
        2. Identifies start and end activities in patient journeys
        3. Visualizes the discovered process
        4. Creates a transition matrix for quantitative analysis
        5. Saves results for LLM analysis
        
        Args:
            use_case (str): Type of analysis ("Infection" or "Organ")
            proces_path (str): Path to save the process map JSON file
        
        Output Files:
            - Process map JSON: Contains DFG, start/end activities
            - process_matrix.csv: Activity transition frequency matrix
        
        Key Concepts:
            - DFG: Graph where edges show how often activity B follows activity A
            - Start activities: First activities in patient journeys
            - End activities: Final activities before discharge/outcome
            - Transition matrix: Quantifies frequency of activity transitions
        """
        try:
            # Step 1: Generate DFG (Directly-Follows Graph)
            # This discovers which activities follow each other and how often
            # Returns dict like {('Activity_A', 'Activity_B'): frequency}
            dfg = dfg_discovery.apply(self.event_log)
            
            # Step 2: Identify start and end activities
            # Start: Activities that begin patient journeys (e.g., "Admission")
            # End: Activities that conclude journeys (e.g., "Discharge", "Death")
            start_activities = pm4py.get_start_activities(self.event_log)
            end_activities = pm4py.get_end_activities(self.event_log)
            
            # Step 3: Visualize the discovered process
            # This creates an interactive graph showing the clinical pathways
            pm4py.view_dfg(dfg, start_activities, end_activities)
            
            # Step 4: Create JSON-serializable process map
            # Convert DFG tuples to strings for JSON compatibility
            process_map_data = {
                'dfg': {str(k): v for k, v in dfg.items()},  # Activity transitions
                'start_activities': start_activities,         # Journey starts
                'end_activities': end_activities             # Journey ends
            }
            
            # Step 5: Save process map to JSON for LLM analysis
            with open(proces_path, 'w') as f:
                json.dump(process_map_data, f, indent=2)
            
            # Step 6: Generate process matrix (activity frequency matrix)
            # This creates a matrix showing transition frequencies between all activities
            activities = pm4py.get_event_attribute_values(self.event_log, "concept:name")
            
            # Step 7: Build the transition matrix
            # Rows = source activities, Columns = target activities
            # Cell[i,j] = frequency of activity j following activity i
            activity_list = list(activities.keys())
            matrix_data = []
            
            for activity in activity_list:
                row_data = {'activity': activity}  # Row header
                for target_activity in activity_list:
                    # Look up frequency in DFG, default to 0 if transition doesn't exist
                    count = dfg.get((activity, target_activity), 0)
                    row_data[target_activity] = count
                matrix_data.append(row_data)
            
            # Step 8: Save matrix as CSV for further analysis
            matrix_df = pd.DataFrame(matrix_data)
            matrix_df.to_csv('process_matrix.csv', index=False)
            
            # Store results in instance variables
            self.process_matrix = matrix_df
            self.process_map = process_map_data
            
            logger.info("Process discovery completed successfully")
            
        except Exception as e:
            logger.error(f"Error in process discovery: {e}")
            raise

class OpenRouterClient:
    """
    OpenRouterClient - Interface for querying multiple LLM models
    
    OpenRouter provides unified access to various LLM models including:
    - Anthropic Claude
    - OpenAI GPT-4
    - Google Gemini
    - DeepSeek
    - X.AI Grok
    
    This client handles:
    1. API authentication
    2. Request formatting
    3. Response parsing
    4. Error handling
    
    Benefits of using OpenRouter:
    - Single API for multiple models
    - Consistent interface across providers
    - Built-in rate limiting and fallbacks
    - Free tier available for testing
    
    Example:
        client = OpenRouterClient("your-api-key")
        response = client.query_model("anthropic/claude-sonnet-4", messages)
    """
    
    def __init__(self, api_key: str):
        """
        Initialize the OpenRouter client with API credentials.
        
        Args:
            api_key: Your OpenRouter API key from https://openrouter.ai
        
        Headers explained:
        - Authorization: Bearer token for API authentication
        - Content-Type: Indicates JSON payload
        - HTTP-Referer: Required by OpenRouter (can be localhost for testing)
        - X-Title: Optional title for your application
        """
        self.api_key = api_key
        self.base_url = "https://openrouter.ai/api/v1"  # OpenRouter API endpoint
        self.headers = {
            "Authorization": f"Bearer {api_key}",       # API authentication
            "Content-Type": "application/json",         # JSON request/response
            "HTTP-Referer": "http://localhost:8080",    # Required field
            "X-Title": "Process Mining Analysis"        # Application identifier
        }
    
    def query_model(self, model_name: str, messages: List[Dict], temperature: float = 0.7) -> Dict:
        """
        Query a specific LLM model through OpenRouter API.
        
        This method sends the process mining results to an LLM for analysis
        and interpretation, generating clinical insights.
        
        Args:
            model_name (str): Model identifier (e.g., "anthropic/claude-sonnet-4")
            messages (List[Dict]): Conversation history in OpenAI format:
                [{'role': 'user', 'content': 'prompt text'}]
            temperature (float): Controls randomness (0=deterministic, 1=creative)
                0.7 is good balance for analytical tasks
        
        Returns:
            Dict: API response containing:
                - choices: List of model responses
                - usage: Token usage statistics
                - model: Model that was used
        
        Raises:
            Exception: If API request fails or returns error status
        
        Temperature guidelines:
        - 0.0-0.3: Factual, analytical tasks
        - 0.4-0.7: Balanced creativity and accuracy
        - 0.8-1.0: Creative writing, brainstorming
        """
        try:
            # Construct the API request payload
            payload = {
                "model": model_name,        # Which LLM to use
                "messages": messages,       # Conversation/prompt
                "temperature": temperature  # Response variability
            }
            
            # Make POST request to OpenRouter chat completions endpoint
            response = requests.post(
                f"{self.base_url}/chat/completions",  # Standard OpenAI-compatible endpoint
                headers=self.headers,                   # Authentication headers
                json=payload                           # Request body
            )
            
            # Check if request was successful
            if response.status_code == 200:
                return response.json()  # Return parsed JSON response
            else:
                # Raise exception with error details for debugging
                raise Exception(f"API request failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            logger.error(f"Error querying model {model_name}: {e}")
            raise

def read_file_content(filepath: str) -> str:
    """
    Safely read content from a text file.
    
    This utility function is used to read:
    - Process map JSON files for LLM analysis
    - Prompt templates for different use cases
    - Generated reports
    
    Args:
        filepath (str): Path to the file to read
    
    Returns:
        str: File content as string, or empty string if error
    
    Error Handling:
        - Returns empty string if file doesn't exist
        - Logs warning/error messages for debugging
        - Never raises exceptions (returns empty string instead)
    
    Note: Uses UTF-8 encoding to handle special characters in prompts
    """
    try:
        # Check if file exists before attempting to read
        if os.path.exists(filepath):
            # Open file with UTF-8 encoding for international characters
            with open(filepath, 'r', encoding='utf-8') as f:
                return f.read()
        else:
            # File doesn't exist - log warning but don't crash
            logger.warning(f"File {filepath} not found")
            return ""
    except Exception as e:
        # Any other error (permissions, encoding, etc.)
        logger.error(f"Error reading file {filepath}: {e}")
        return ""

def save_string_to_md(text_string: str, filename: str = "output.md", directory: str = None) -> str:
    """
    Save text content to a Markdown (.md) file.
    
    This function saves LLM-generated reports as Markdown files,
    which can be easily viewed, shared, and converted to other formats.
    
    Args:
        text_string (str): Content to save (typically LLM response)
        filename (str): Output filename (default: "output.md")
        directory (str): Output directory (default: current directory)
    
    Returns:
        str: Full path to the saved file
    
    Features:
        - Automatically adds .md extension if missing
        - Creates directory if it doesn't exist
        - Uses UTF-8 encoding for compatibility
        - Returns full path for logging/reference
    
    Example:
        report = "# Sepsis Analysis\n\n## Key Findings..."
        path = save_string_to_md(report, "sepsis_report.md", "./reports")
    """
    # Use current directory if none specified
    if directory is None:
        directory = os.getcwd()
    
    # Create Path object for cross-platform compatibility
    filepath = Path(directory) / filename
    
    # Ensure file has .md extension for proper rendering
    if not filepath.suffix == '.md':
        filepath = filepath.with_suffix('.md')
    
    try:
        # Write content to file with UTF-8 encoding
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(text_string)
        
        # Log success and return path
        logger.info(f"Markdown file saved to: {filepath}")
        return str(filepath)
        
    except Exception as e:
        logger.error(f"Error saving file {filepath}: {e}")
        raise

def query_model_safe(client: OpenRouterClient, model_name: str, prompt: str, use_case: str) -> Dict:
    """
    Safely query an LLM model with comprehensive error handling.
    
    This wrapper function handles the complete LLM query workflow:
    1. Loads appropriate process maps based on use case
    2. Constructs message format for the LLM
    3. Sends query through OpenRouter
    4. Parses and structures the response
    5. Handles errors gracefully
    
    Args:
        client (OpenRouterClient): Initialized API client
        model_name (str): LLM model identifier
        prompt (str): Clinical analysis prompt
        use_case (str): Analysis type ("Infection" or "Organ")
    
    Returns:
        Dict containing:
            - model: Model name that was queried
            - status: 'success' or 'error'
            - response: Model's analysis or error message
            - tokens_used: API token consumption (for cost tracking)
    
    Use Cases:
        - "Infection": Analyzes single process map for infection progression
        - "Organ": Compares two maps (with/without sepsis) for organ damage
    
    Error Handling:
        - Returns structured error dict instead of crashing
        - Logs all errors for debugging
        - Allows workflow to continue with other models
    """
    try:
        logger.info(f"Querying model: {model_name}")
        
        # Different analysis approaches based on use case
        if use_case == "Infection":
            # Single process map analysis for infection progression
            # Load the process map generated from sepsis cases
            map_content = read_file_content('processMap.json')
            
            # Construct messages for LLM
            # Prompt contains clinical context and questions
            # Process map contains discovered patterns
            messages = [
                {"role": "user", "content": prompt},  # Clinical analysis prompt
                {"role": "user", "content": f"Process Map JSON:\n{map_content}"}  # Data
            ]
            
        else:  # "Organ" or other comparative analyses
            # Comparative analysis between sepsis and non-sepsis cases
            # Load both process maps for comparison
            map_content_1 = read_file_content('processMap_1.json')  # Sepsis cases
            map_content_2 = read_file_content('processMap_2.json')  # Non-sepsis cases
            
            # Provide both maps to LLM for comparative analysis
            messages = [
                {"role": "user", "content": prompt},  # Comparative analysis prompt
                {"role": "user", "content": f"Process Map (with Sepsis) JSON:\n{map_content_1}"},
                {"role": "user", "content": f"Process Map (without Sepsis) JSON:\n{map_content_2}"}
            ]
        
        # Send query to LLM through OpenRouter
        response = client.query_model(model_name, messages)
        
        # Extract the model's analysis from response
        # OpenRouter uses OpenAI-compatible response format
        content = response['choices'][0]['message']['content']
        
        # Return structured success response
        return {
            'model': model_name,
            'status': 'success',
            'response': content,  # Clinical analysis from LLM
            'tokens_used': response.get('usage', {}).get('total_tokens', None)  # For cost tracking
        }
        
    except Exception as e:
        # Handle any errors gracefully
        logger.error(f"Error querying model {model_name}: {e}")
        # Return structured error response
        return {
            'model': model_name,
            'status': 'error',
            'response': f"Error: {str(e)}",
            'tokens_used': None
        }

def workflow(event_log_path: str, models: List[str], prompt: str, api_key: str, use_case: str) -> None:
    """
    Main workflow orchestrator for process mining and LLM analysis.
    
    This function coordinates the entire analysis pipeline:
    1. Process Mining Phase:
       - Load healthcare event data
       - Filter cases based on clinical outcomes
       - Discover process patterns using PM4PY
       - Generate process maps and matrices
    
    2. LLM Analysis Phase:
       - Query multiple AI models with discovered patterns
       - Generate clinical insights and hypotheses
       - Compare responses across models
       - Save individual reports
    
    Args:
        event_log_path (str): Path to CSV file with event data
        models (List[str]): List of LLM models to query
        prompt (str): Clinical analysis prompt template
        api_key (str): OpenRouter API key
        use_case (str): Analysis type:
            - "Infection": Single cohort infection progression
            - "Organ": Comparative sepsis vs non-sepsis
    
    Workflow Variations:
        - Infection: Analyzes all sepsis cases for progression patterns
        - Organ: Compares pathways between sepsis and non-sepsis groups
    
    Output:
        - Process maps (JSON files)
        - Process matrices (CSV files)
        - LLM analysis reports (Markdown files)
    """
    try:
        logger.info("Starting model comparison...")
        logger.info(f"Testing {len(models)} models")
        
        # === PROCESS MINING PHASE ===
        
        if use_case == "Infection":
            # INFECTION USE CASE: Analyze sepsis progression patterns
            # Focus: How do infections progress to sepsis?
            
            # Step 1: Initialize process mining analyzer
            analyzer = ProcessMiningAnalyzer(event_log_path)
            
            # Step 2: Load and convert data to PM4PY format
            analyzer.load_and_prepare_data()
            
            # Step 3: Filter to keep only sepsis cases
            # Note: filter_sepsis_cases expects boolean, not string
            analyzer.filter_sepsis_cases(sepsis=True)  # Keep sepsis cases
            
            # Step 4: Discover process patterns and save to JSON
            analyzer.generate_process_discovery(use_case, "processMap.json")
        
        elif use_case == "Organ":
            # ORGAN USE CASE: Compare sepsis vs non-sepsis pathways
            # Focus: What process differences lead to organ damage?
            
            # === Part 1: Analyze SEPSIS cases ===
            logger.info("Analyzing sepsis cases...")
            
            # Initialize analyzer for sepsis cohort
            analyzer = ProcessMiningAnalyzer(event_log_path)
            
            # Load and prepare data
            analyzer.load_and_prepare_data()
            
            # Filter to keep ONLY sepsis cases
            analyzer.filter_sepsis_cases(sepsis=True)
            
            # Generate process map for sepsis cases
            analyzer.generate_process_discovery(use_case, "processMap_1.json")
            
            # === Part 2: Analyze NON-SEPSIS cases ===
            logger.info("Analyzing non-sepsis cases...")
            
            # Re-initialize analyzer for non-sepsis cohort
            # (Need fresh instance to reload all data)
            analyzer = ProcessMiningAnalyzer(event_log_path)
            
            # Load and prepare data again
            analyzer.load_and_prepare_data()
            
            # Filter to keep ONLY non-sepsis cases
            analyzer.filter_sepsis_cases(sepsis=False)
            
            # Generate process map for non-sepsis cases
            analyzer.generate_process_discovery(use_case, "processMap_2.json")
            
            logger.info("Comparative process maps generated")
        
        else:
            # Handle unknown use cases
            logger.warning(f"Unknown use case: {use_case}")
            logger.info("Supported use cases: 'Infection', 'Organ'")
            return
        
        # === LLM ANALYSIS PHASE ===
        logger.info("\n" + "="*50)
        logger.info("Starting LLM analysis phase...")
        
        # Initialize OpenRouter client for API access
        client = OpenRouterClient(api_key)
        
        # Query each model and collect results
        results = []
        for i, model in enumerate(models, 1):
            logger.info(f"\nQuerying model {i}/{len(models)}: {model}")
            # Query model with error handling
            result = query_model_safe(client, model, prompt, use_case)
            results.append(result)
            
            # Log result status
            if result['status'] == 'success':
                logger.info(f"✓ {model} - Success (Tokens: {result['tokens_used']})") 
            else:
                logger.warning(f"✗ {model} - Failed")
        
        # Convert results to DataFrame for analysis
        results_df = pd.DataFrame(results)
        
        # === REPORT GENERATION PHASE ===
        # Save individual reports for successful models
        successful_models = results_df[results_df['status'] == 'success']
        
        if len(successful_models) > 0:
            logger.info("\n" + "="*50)
            logger.info("=== SAVING INDIVIDUAL REPORTS ===")
            
            for idx, row in successful_models.iterrows():
                # Clean model name for filename (remove special characters)
                model_name_clean = "".join(c if c.isalnum() or c in "_-" else "_" for c in row['model'])
                filename = f'Report_{model_name_clean}.md'
                
                # Save report to markdown file
                save_string_to_md(row['response'], filename)
                logger.info(f"Saved: {filename}")
        else:
            logger.warning("No successful model responses to save")
        
        # Final summary
        logger.info("\n" + "="*50)
        logger.info(f"Workflow completed successfully!")
        logger.info(f"Process maps generated: {'processMap.json' if use_case == 'Infection' else 'processMap_1.json, processMap_2.json'}")
        logger.info(f"Models queried: {len(models)}")
        logger.info(f"Successful responses: {len(successful_models)}")
        
    except Exception as e:
        logger.error(f"Error in workflow: {e}")
        raise

def main():
    """
    Main entry point for the HealthProcessAI analysis pipeline.
    
    This function sets up the configuration and launches the analysis.
    Modify the configuration variables below to customize your analysis.
    
    Configuration Guide:
    1. use_case: Choose analysis type
       - "Infection": Analyze infection-to-sepsis progression
       - "Organ": Compare organ damage in sepsis vs non-sepsis
    
    2. OPENROUTER_API_KEY: Your API key from https://openrouter.ai
       - Sign up for free account
       - Generate key in dashboard
       - Replace placeholder below
    
    3. fileName: Prompt template file
       - prompt_infection.txt: For infection analysis
       - prompt_organ.txt: For organ damage analysis
       - Create custom prompts for specific analyses
    
    4. models: LLM models to query
       - Free tier: deepseek-r1:free
       - Premium: claude-sonnet-4, gpt-4, gemini-pro
       - Add multiple models for comparison
    
    5. event_log_path: Input data file
       - Must be CSV with required columns
       - Examples provided: sepsisAgregated_*.csv
    """
    
    # ========== CONFIGURATION SECTION ==========
    # Modify these variables to customize your analysis
    
    # Choose analysis type: "Infection" or "Organ"
    use_case = "Organ"
    
    # CRITICAL: Replace with your OpenRouter API key
    OPENROUTER_API_KEY = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # REPLACE BY YOUR OPEN ROUTER API KEY
    
    # Select appropriate prompt file for your use case
    fileName = "prompt_infection.txt"  # Change based on use_case
    
    # Load the clinical analysis prompt
    logger.info(f"Loading prompt from: {fileName}")
    with open(fileName, 'r', encoding='utf-8') as f:
        test_prompt = f.read() 
    
    # Define models to test
    # Free tier models for testing:
    models = [
        "deepseek/deepseek-r1:free"  # Free model for testing
    ]
    
    # Premium models (require credits):
    # models = [
    #     "anthropic/claude-sonnet-4",      # Best for clinical analysis
    #     "openai/gpt-4",                   # Strong general reasoning
    #     "google/gemini-2.0-flash-exp",    # Fast and capable
    #     "deepseek/deepseek-r1:free",      # Free alternative
    #     "x-ai/grok-2-1212"                # Good for complex reasoning
    # ]
    
    # Input event log file
    # Ensure this matches your use_case:
    # - Infection: "sepsisAgregated_Infection.csv"
    # - Organ: "sepsisAgregated_Organ.csv"
    event_log_path = "sepsisAgregated_Organ.csv"
    
    # ========== EXECUTION ==========
    logger.info("="*60)
    logger.info("HEALTHPROCESSAI - Process Mining with LLM Integration")
    logger.info("="*60)
    logger.info(f"Use Case: {use_case}")
    logger.info(f"Data File: {event_log_path}")
    logger.info(f"Models: {len(models)} configured")
    logger.info("="*60 + "\n")
    
    # Run the complete workflow
    workflow(event_log_path, models, test_prompt, OPENROUTER_API_KEY, use_case)

# ========== SCRIPT ENTRY POINT ==========
# This ensures main() only runs when script is executed directly,
# not when imported as a module
if __name__ == "__main__":
    main()