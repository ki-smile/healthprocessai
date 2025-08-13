"""
HealthProcessAI - Process Mining Framework for Healthcare & Life Sciences
=========================================================================
Setup configuration for HealthProcessAI package.

Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments),
Karolinska Institutet
"""

from setuptools import setup, find_packages

# UNUSED: import os

# Read the README file
with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()


# Read requirements
def read_requirements(filename):
    """Read requirements from file."""
    with open(filename, "r") as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


# Core requirements
install_requires = [
    "pm4py>=2.7.0",
    "pandas>=1.5.0",
    "numpy>=1.23.0",
    "scikit-learn>=1.2.0",
    "requests>=2.28.0",
    "graphviz>=0.20",
    "scipy>=1.9.0",
]

# Optional requirements for different use cases
extras_require = {
    "dev": [
        "pytest>=7.2.0",
        "pytest-cov>=4.0.0",
        "black>=22.0.0",
        "flake8>=5.0.0",
        "mypy>=0.990",
    ],
    "llm": [
        "openai>=1.0.0",
        "anthropic>=0.5.0",
        "google-generativeai>=0.3.0",
    ],
    "viz": [
        "matplotlib>=3.6.0",
        "seaborn>=0.12.0",
        "plotly>=5.11.0",
    ],
    "r-bridge": [
        "rpy2>=3.5.0",
    ],
}

# All optional dependencies
extras_require["all"] = sum(extras_require.values(), [])

setup(
    name="healthprocessai",
    version="0.1.0",
    author="SMAILE Lab",
    author_email="smaile@ki.se",
    description="Process Mining Framework for Healthcare & Life Sciences with AI Integration",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/ki-smile/HealthProcessAI",
    project_urls={
        "Bug Tracker": "https://github.com/ki-smile/HealthProcessAI/issues",
        "Documentation": "https://healthprocessai.readthedocs.io",
        "Source Code": "https://github.com/ki-smile/HealthProcessAI",
        "Lab Website": "https://ki.se/smaile",
    },
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Healthcare Industry",
        "Intended Audience :: Science/Research",
        "Intended Audience :: Education",
        "Topic :: Scientific/Engineering :: Medical Science Apps.",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "Topic :: Scientific/Engineering :: Information Analysis",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.8",
    install_requires=install_requires,
    extras_require=extras_require,
    entry_points={
        "console_scripts": [
            "healthprocessai=healthprocessai.cli:main",
            "hpai=healthprocessai.cli:main",
        ],
    },
    include_package_data=True,
    package_data={
        "healthprocessai": [
            "data/*.csv",
            "prompts/*.txt",
            "templates/*.md",
        ],
    },
    keywords=[
        "process mining",
        "healthcare",
        "clinical pathways",
        "disease progression",
        "epidemiology",
        "medical AI",
        "health analytics",
        "sepsis",
        "patient journey",
        "clinical processes",
        "LLM",
        "artificial intelligence",
    ],
    license="MIT",
)
