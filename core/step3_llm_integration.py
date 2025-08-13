#!/usr/bin/env python3
"""Module: step3_llm_integration"""

"""
STEP 3: LLM INTEGRATION FOR CLINICAL INSIGHTS
==============================================
This module integrates Large Language Models (LLMs) through OpenRouter API
to generate clinical insights from process mining results.

Learning Goals:
- Understand how to integrate LLMs with process mining
- Learn to structure prompts for clinical analysis
- Query multiple models and compare responses
- Generate professional reports from AI insights

Key Concepts:
- OpenRouter provides access to multiple LLM models
- Prompts should include context and specific questions
- Different models may provide different perspectives
- Results should be validated by domain experts
"""

import requests

# UNUSED: import json
import logging
from typing import List, Dict, Any, Optional
from pathlib import Path
from datetime import datetime
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class LLMAnalyzer:
    """
    Integrates Large Language Models for clinical process analysis.

    This class:
    1. Connects to OpenRouter API
    2. Structures prompts with process mining results
    3. Queries multiple LLM models
    4. Generates clinical reports
    """

    # Available models through OpenRouter (as of 2024)
    AVAILABLE_MODELS = {
        "claude": "anthropic/claude-sonnet-4",
        "gpt4": "openai/gpt-4.1",
        "gemini": "google/gemini-2.5-pro",
        "deepseek": "deepseek/deepseek-r1:free",  # Free tier
        "grok": "x-ai/grok-4",
    }

    def __init__(self, api_key: str):
        """
        Initialize the LLM analyzer with OpenRouter API key.

        Args:
            api_key: OpenRouter API key

        Example:
            >>> analyzer = LLMAnalyzer("your-api-key-here")
        """
        self.api_key = api_key
        self.base_url = "https://openrouter.ai/api/v1"

        # Set up headers for API requests
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost:8080",  # Required by OpenRouter
            "X-Title": "Process Mining Analysis",  # Optional app name
        }

        logger.info("Initialized LLM Analyzer with OpenRouter API")

    def create_clinical_prompt(
        self, process_data: Dict[str, Any], use_case: str = "sepsis"
    ) -> str:
        """
        Create a structured prompt for clinical analysis.

        This method creates prompts that:
        - Provide context about the process mining analysis
        - Include relevant metrics and patterns
        - Ask specific clinical questions
        - Request actionable insights

        Args:
            process_data: Dictionary containing process mining results
            use_case: Type of clinical analysis (sepsis, infection, organ)

        Returns:
            Formatted prompt string

        Example:
            >>> prompt = analyzer.create_clinical_prompt(metrics, "sepsis")
        """
        # Base prompt template
        base_prompt = """You are an expert clinical data analyst specializing in process mining
        and sepsis progression analysis. You're analyzing patient pathway data to identify
        patterns and provide actionable insights for healthcare improvement.

        CONTEXT:
        - Analysis type: {use_case} progression analysis
        - Data source: Electronic health records processed through process mining
        - Goal: Identify clinical patterns and improvement opportunities

        PROCESS MINING RESULTS:
        {process_summary}

        KEY METRICS:
        - Total cases analyzed: {num_cases}
        - Average case duration: {avg_duration} hours
        - Number of unique pathways: {num_variants}
        - Most common pathway coverage: {top_variant_coverage}

        TOP ACTIVITIES:
        {top_activities}

        CRITICAL TRANSITIONS:
        {critical_transitions}

        Please provide:
        1. Clinical interpretation of the discovered patterns
        2. Key risk factors identified in the process
        3. Potential early warning signs
        4. Recommendations for clinical intervention
        5. Suggestions for process improvement

        Format your response as a structured clinical report suitable for
        medical professionals."""

        # Extract data for prompt
        prompt_data = {
            "use_case": use_case.title(),
            "process_summary": self._format_process_summary(process_data),
            "num_cases": process_data.get("num_cases", "Unknown"),
            "avg_duration": process_data.get("avg_case_duration_hours", "Unknown"),
            "num_variants": process_data.get("num_variants", "Unknown"),
            "top_variant_coverage": process_data.get("top_variant_coverage", "Unknown"),
            "top_activities": self._format_top_activities(process_data),
            "critical_transitions": self._format_critical_transitions(process_data),
        }

        return base_prompt.format(**prompt_data)

    def _format_process_summary(self, process_data: Dict) -> str:
        """Format process data into readable summary."""
        summary_lines = []

        if "description" in process_data:
            summary_lines.append(process_data["description"])

        if "key_findings" in process_data:
            summary_lines.append("Key Findings:")
            for finding in process_data.get("key_findings", []):
                summary_lines.append(f"  - {finding}")

        return (
            "\n".join(summary_lines) if summary_lines else "Process analysis completed"
        )

    def _format_top_activities(self, process_data: Dict) -> str:
        """Format top activities list."""
        activities = process_data.get("top_5_activities", [])

        if not activities:
            return "No activity data available"

        lines = []
        for i, act in enumerate(activities, 1):
            lines.append(
                f"{i}. {act.get('activity', 'Unknown')}: "
                f"{act.get('count', 0)} occurrences"
            )

        return "\n".join(lines)

    def _format_critical_transitions(self, process_data: Dict) -> str:
        """Format critical transitions information."""
        transitions = process_data.get("critical_transitions", [])

        if not transitions:
            return "Transition analysis pending"

        lines = []
        for trans in transitions:
            lines.append(f"- {trans}")

        return "\n".join(lines)

    def query_model(
        self,
        model_name: str,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Query a specific LLM model through OpenRouter.

        Args:
            model_name: Model identifier (e.g., 'anthropic/claude-sonnet-4')
            messages: List of message dictionaries with 'role' and 'content'
            temperature: Creativity parameter (0=deterministic, 1=creative)
            max_tokens: Maximum response length

        Returns:
            API response dictionary

        Example:
            >>> messages = [{"role": "user", "content": "Analyze this sepsis data..."}]
            >>> response = analyzer.query_model("anthropic/claude-sonnet-4", messages)
        """
        # Prepare request payload
        payload = {
            "model": model_name,
            "messages": messages,
            "temperature": temperature,
        }

        if max_tokens:
            payload["max_tokens"] = max_tokens

        try:
            # Make API request
            response = requests.post(
                f"{self.base_url}/chat/completions",
                headers=self.headers,
                json=payload,
                timeout=60,  # 60 second timeout
            )

            # Check response status
            if response.status_code == 200:
                result = response.json()
                logger.info(f"Successfully queried {model_name}")
                return result
            else:
                error_msg = f"API error {response.status_code}: {response.text}"
                logger.error(error_msg)
                return {"error": error_msg}

        except requests.exceptions.Timeout:
            logger.error(f"Timeout querying {model_name}")
            return {"error": "Request timeout"}
        except Exception as e:
            logger.error(f"Error querying {model_name}: {e}")
            return {"error": str(e)}

    def analyze_with_multiple_models(
        self, prompt: str, models: Optional[List[str]] = None, delay_seconds: int = 1
    ) -> Dict[str, Dict]:
        """
        Query multiple models for comparative analysis.

        This is useful for:
        - Getting diverse perspectives
        - Validating insights across models
        - Comparing model capabilities

        Args:
            prompt: The analysis prompt
            models: List of model names to query (or None for defaults)
            delay_seconds: Delay between API calls to avoid rate limits

        Returns:
            Dictionary mapping model names to their responses

        Example:
            >>> results = analyzer.analyze_with_multiple_models(
            ...     prompt,
            ...     models=['claude', 'gpt4']
            ... )
        """
        if models is None:
            # Use free tier model by default
            models = ["deepseek"]

        results = {}

        for model_key in models:
            # Get full model name
            model_name = self.AVAILABLE_MODELS.get(model_key, model_key)

            logger.info(f"Querying {model_name}...")

            # Prepare messages
            messages = [{"role": "user", "content": prompt}]

            # Query model
            response = self.query_model(model_name, messages)

            # Extract content
            if "error" not in response:
                try:
                    content = response["choices"][0]["message"]["content"]
                    token_usage = response.get("usage", {})

                    results[model_key] = {
                        "status": "success",
                        "content": content,
                        "tokens": token_usage.get("total_tokens", 0),
                        "model": model_name,
                    }
                except (KeyError, IndexError) as e:
                    results[model_key] = {
                        "status": "error",
                        "content": f"Failed to parse response: {e}",
                        "model": model_name,
                    }
            else:
                results[model_key] = {
                    "status": "error",
                    "content": response["error"],
                    "model": model_name,
                }

            # Delay between requests
            if delay_seconds > 0 and model_key != models[-1]:
                time.sleep(delay_seconds)

        return results

    def generate_clinical_report(
        self,
        process_data: Dict[str, Any],
        model_response: str,
        metadata: Optional[Dict] = None,
    ) -> str:
        """
        Generate a formatted clinical report combining process mining and LLM insights.

        Args:
            process_data: Process mining results
            model_response: LLM analysis response
            metadata: Additional metadata for the report

        Returns:
            Formatted markdown report

        Example:
            >>> report = analyzer.generate_clinical_report(
            ...     metrics,
            ...     llm_response,
            ...     {'analyst': 'Dr. Smith', 'date': '2024-01-15'}
            ... )
        """
        # Report template
        report_template = """# Clinical Process Mining Analysis Report

## Report Metadata
- **Generated**: {timestamp}
- **Analysis Type**: {analysis_type}
- **Data Source**: Electronic Health Records
- **Process Mining Tool**: PM4PY
- **AI Model**: {ai_model}

---

## Executive Summary

{executive_summary}

---

## Process Mining Results

### Dataset Overview
- **Total Cases**: {num_cases}
- **Analysis Period**: {date_range}
- **Average Case Duration**: {avg_duration} hours
- **Unique Process Variants**: {num_variants}

### Key Process Metrics

| Metric | Value |
|--------|-------|
| Total Events | {total_events} |
| Unique Activities | {num_activities} |
| Most Common Pathway Coverage | {top_variant_coverage} |
| Minimum Case Duration | {min_duration} hours |
| Maximum Case Duration | {max_duration} hours |

### Top Activities

{top_activities_table}

---

## Clinical Analysis

{clinical_analysis}

---

## Recommendations

Based on the process mining analysis and clinical review, the following
recommendations are provided:

{recommendations}

---

## Appendix

### Methodology
- Process mining was performed using PM4PY library
- Directly-Follows Graphs were generated to identify activity sequences
- Performance metrics were calculated for all transitions
- Clinical interpretation was enhanced using large language models

### Limitations
- Analysis is based on available electronic health record data
- Process variations may reflect documentation practices
- Clinical validation is recommended before implementation

---

*This report was generated automatically using process mining and AI analysis.
Clinical validation is recommended before making treatment decisions.*
"""

        # Parse LLM response to extract sections
        executive_summary = self._extract_section(
            model_response, "summary", "Analysis completed successfully"
        )
        clinical_analysis = self._extract_section(
            model_response, "analysis", model_response
        )
        recommendations = self._extract_section(
            model_response, "recommendations", "See clinical analysis for details"
        )

        # Format top activities table
        activities_table = self._format_activities_table(process_data)

        # Prepare report data
        report_data = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "analysis_type": metadata.get("analysis_type", "Sepsis Progression"),
            "ai_model": metadata.get("ai_model", "Multiple Models"),
            "executive_summary": executive_summary,
            "num_cases": process_data.get("num_cases", "N/A"),
            "date_range": metadata.get("date_range", "See dataset"),
            "avg_duration": process_data.get("avg_case_duration_hours", "N/A"),
            "num_variants": process_data.get("num_variants", "N/A"),
            "total_events": process_data.get("total_events", "N/A"),
            "num_activities": process_data.get("num_activities", "N/A"),
            "top_variant_coverage": process_data.get("top_variant_coverage", "N/A"),
            "min_duration": process_data.get("min_case_duration_hours", "N/A"),
            "max_duration": process_data.get("max_case_duration_hours", "N/A"),
            "top_activities_table": activities_table,
            "clinical_analysis": clinical_analysis,
            "recommendations": recommendations,
        }

        return report_template.format(**report_data)

    def _extract_section(self, text: str, section: str, default: str) -> str:
        """Extract a specific section from LLM response."""
        # Simple extraction - can be enhanced with better parsing
        lines = text.split("\n")
        capturing = False
        section_lines = []

        for line in lines:
            lower_line = line.lower()
            if section in lower_line and any(
                marker in lower_line for marker in ["#", "**", ":"]
            ):
                capturing = True
                continue
            elif (
                capturing
                and line.startswith(("#", "**"))
                and section not in line.lower()
            ):
                break
            elif capturing:
                section_lines.append(line)

        return "\n".join(section_lines).strip() if section_lines else default

    def _format_activities_table(self, process_data: Dict) -> str:
        """Format activities as markdown table."""
        activities = process_data.get("top_5_activities", [])

        if not activities:
            return "No activity data available"

        lines = ["| Rank | Activity | Frequency |", "|------|----------|-----------|"]

        for i, act in enumerate(activities, 1):
            lines.append(
                f"| {i} | {act.get('activity', 'Unknown')} | "
                f"{act.get('count', 0)} |"
            )

        return "\n".join(lines)

    def save_report(self, report: str, filename: str, directory: str = ".") -> str:
        """
        Save report to markdown file.

        Args:
            report: Report content
            filename: Output filename
            directory: Output directory

        Returns:
            Path to saved file

        Example:
            >>> path = analyzer.save_report(report, "sepsis_analysis.md", "./reports")
        """
        output_dir = Path(directory)
        output_dir.mkdir(exist_ok=True)

        filepath = output_dir / filename

        # Ensure .md extension
        if not filepath.suffix == ".md":
            filepath = filepath.with_suffix(".md")

        with open(filepath, "w", encoding="utf-8") as f:
            f.write(report)

        logger.info(f"Report saved to {filepath}")

        return str(filepath)


def main():
    """
    Example usage of the LLM Analyzer.

    Demonstrates integration with process mining results.
    """
    print("=" * 60)
    print("STEP 3: LLM INTEGRATION FOR CLINICAL INSIGHTS")
    print("=" * 60)

    # Note: Replace with your actual API key
    API_KEY = "your-openrouter-api-key-here"

    # Simulated process mining results (would come from Step 2)
    process_data = {
        "num_cases": 1050,
        "avg_case_duration_hours": 36.5,
        "min_case_duration_hours": 12.3,
        "max_case_duration_hours": 148.7,
        "num_variants": 87,
        "top_variant_coverage": "23.5%",
        "num_activities": 15,
        "total_events": 15750,
        "top_5_activities": [
            {"activity": "Admission", "count": 1050},
            {"activity": "Lab Test", "count": 3150},
            {"activity": "Medication", "count": 2800},
            {"activity": "Vital Signs", "count": 4200},
            {"activity": "Discharge", "count": 980},
        ],
        "key_findings": [
            "High variation in treatment pathways",
            "Lab tests frequently repeated",
            "Medication timing varies significantly",
        ],
    }

    # Initialize analyzer
    print("\n1. Initializing LLM Analyzer...")
    analyzer = LLMAnalyzer(API_KEY)

    # Create clinical prompt
    print("\n2. Creating clinical analysis prompt...")
    prompt = analyzer.create_clinical_prompt(process_data, "sepsis")
    print(f"   Prompt length: {len(prompt)} characters")

    # Query models (using free tier for demo)
    print("\n3. Querying AI models...")
    print("   Note: Using free tier model for demonstration")
    results = analyzer.analyze_with_multiple_models(
        prompt, models=["deepseek"], delay_seconds=0  # Free model
    )

    # Check results
    print("\n4. Analysis results:")
    for model, result in results.items():
        status = result["status"]
        tokens = result.get("tokens", 0)
        print(f"   {model}: {status} (tokens: {tokens})")

    # Generate report
    print("\n5. Generating clinical report...")
    if results and "deepseek" in results and results["deepseek"]["status"] == "success":
        report = analyzer.generate_clinical_report(
            process_data,
            results["deepseek"]["content"],
            metadata={
                "analysis_type": "Sepsis Progression",
                "ai_model": "DeepSeek R1",
                "date_range": "2024-01 to 2024-03",
            },
        )

        # Save report
        saved_path = analyzer.save_report(
            report, "sepsis_clinical_report.md", "./reports"
        )
        print(f"   Report saved to: {saved_path}")
    else:
        print("   Note: API key required for actual analysis")
        print("   Please add your OpenRouter API key to test")

    print("\n" + "=" * 60)
    print("LLM integration complete!")
    print("Note: This is a demonstration. Add your API key for real analysis.")
    print("=" * 60)


if __name__ == "__main__":
    main()
