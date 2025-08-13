"""
HealthProcessAI - Process Mining Framework for Healthcare & Life Sciences
=========================================================================

A comprehensive framework for applying process mining techniques to healthcare data,
with integrated AI capabilities for generating clinical insights.

Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments), Karolinska Institutet

Main Components:
- Data Loading and Preparation
- Process Discovery and Mining
- Advanced Analytics (Clustering, Bottlenecks, Predictions)
- LLM Integration for Clinical Insights
- Comprehensive Reporting

Example:
    >>> import healthprocessai as hpai
    >>> 
    >>> # Load clinical event data
    >>> loader = hpai.EventLogLoader("sepsis_events.csv")
    >>> data = loader.load_and_prepare()
    >>> 
    >>> # Discover clinical processes
    >>> miner = hpai.ProcessMiner()
    >>> event_log = miner.create_event_log(data)
    >>> dfg = miner.discover_dfg()
    >>> 
    >>> # Advanced analytics
    >>> analyzer = hpai.AdvancedAnalyzer(event_log)
    >>> clusters = analyzer.cluster_patient_pathways()
    >>> 
    >>> # Generate AI insights
    >>> ai = hpai.LLMAnalyzer(api_key)
    >>> report = ai.generate_clinical_report(results)
"""

__version__ = "0.1.0"
__author__ = "SMAILE Lab, Karolinska Institutet"
__email__ = "smaile@ki.se"

# Import main classes for easy access
from .data_loader import EventLogLoader
from .process_mining import ProcessMiner
from .llm_integration import LLMAnalyzer
from .advanced_analytics import AdvancedProcessAnalyzer
from .pipeline import CompleteProcessMiningPipeline

# Import specialized modules
from . import clinical
from . import epidemiology
from . import disease_progression
from . import utils

# Define what's available at package level
__all__ = [
    # Core classes
    "EventLogLoader",
    "ProcessMiner",
    "LLMAnalyzer",
    "AdvancedProcessAnalyzer",
    "CompleteProcessMiningPipeline",
    # Modules
    "clinical",
    "epidemiology",
    "disease_progression",
    "utils",
    # Version info
    "__version__",
    "__author__",
]

# Package metadata
PACKAGE_NAME = "HealthProcessAI"
PACKAGE_DESCRIPTION = "Process Mining Framework for Healthcare & Life Sciences"
PACKAGE_URL = "https://github.com/ki-smile/HealthProcessAI"


def get_version():
    """Return the package version."""
    return __version__


def about():
    """Print information about HealthProcessAI."""
    info = f"""
    {PACKAGE_NAME} v{__version__}
    {PACKAGE_DESCRIPTION}
    
    Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments)
    Karolinska Institutet, Stockholm, Sweden
    
    For more information, visit: {PACKAGE_URL}
    """
    print(info)


# Configure logging for the package
import logging

# Create package logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Create console handler with formatting
handler = logging.StreamHandler()
formatter = logging.Formatter(
    "%(asctime)s - HealthProcessAI - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
handler.setFormatter(formatter)
logger.addHandler(handler)

# Welcome message when package is imported
logger.debug(f"HealthProcessAI v{__version__} loaded successfully")
