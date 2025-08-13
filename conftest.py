"""
Pytest configuration file
"""

import sys
import os
from pathlib import Path

# Add the project root to Python path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

# Ensure core module is importable
if str(project_root) not in sys.path:
    sys.path.append(str(project_root))
