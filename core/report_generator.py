#!/usr/bin/env python3
"""Module: report_generator"""

"""
Report Generator Module for HealthProcessAI
============================================
This module handles the generation of analysis reports in multiple formats:
- Markdown (.md)
- HTML (.html)
- PDF (.pdf)

The reports are automatically saved to the appropriate directories:
- reports/markdown/ - Markdown reports
- reports/pdf/ - PDF reports
- reports/html/ - HTML reports (intermediate)

Developed at SMAILE, Karolinska Institutet
"""

# UNUSED: import os
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any
import pandas as pd
import markdown
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Try to import PDF generation libraries
try:
    from weasyprint import HTML as WeasyHTML

    WEASYPRINT_AVAILABLE = True
except ImportError:
    WEASYPRINT_AVAILABLE = False
    logger.warning("WeasyPrint not available. PDF generation will be limited.")

try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.platypus import (
        SimpleDocTemplate,
        Table,
        TableStyle,
        Paragraph,
        Spacer,
        PageBreak,
    )
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY

    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False
    logger.warning("ReportLab not available. Alternative PDF generation disabled.")


class ReportGenerator:
    """
    Generates comprehensive reports from process mining analysis results.

    Supports multiple output formats and automatically organizes reports
    in the appropriate directory structure.
    """

    def __init__(self, output_base_dir: str = "reports"):
        """
        Initialize the report generator.

        Args:
            output_base_dir: Base directory for saving reports
        """
        self.output_base_dir = Path(output_base_dir)
        self.setup_directories()

        # Report metadata
        self.metadata = {
            "generated_at": datetime.now().isoformat(),
            "framework": "HealthProcessAI",
            "version": "1.0.0",
            "organization": "SMAILE, Karolinska Institutet",
        }

    def setup_directories(self):
        """Create report directory structure if it doesn't exist."""
        directories = [
            self.output_base_dir / "markdown",
            self.output_base_dir / "pdf",
            self.output_base_dir / "html",
            self.output_base_dir / "data",
        ]

        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)

        logger.info(f"Report directories initialized at: {self.output_base_dir}")

    def generate_report(
        self,
        analysis_results: Dict[str, Any],
        report_name: str,
        formats: List[str] = ["markdown", "pdf"],
    ) -> Dict[str, str]:
        """
        Generate reports in multiple formats.

        Args:
            analysis_results: Dictionary containing analysis results
            report_name: Base name for the report files
            formats: List of output formats ('markdown', 'html', 'pdf')

        Returns:
            Dictionary mapping format to file path
        """
        output_files = {}
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        base_name = f"{report_name}_{timestamp}"

        # Generate Markdown report (base format)
        if "markdown" in formats or "pdf" in formats or "html" in formats:
            md_content = self.create_markdown_report(analysis_results)
            md_path = self.save_markdown(md_content, base_name)
            output_files["markdown"] = str(md_path)
            logger.info(f"✅ Markdown report saved: {md_path}")

        # Generate HTML if needed
        if "html" in formats or "pdf" in formats:
            html_content = self.markdown_to_html(md_content)
            html_path = self.save_html(html_content, base_name)
            output_files["html"] = str(html_path)

        # Generate PDF if requested
        if "pdf" in formats:
            if WEASYPRINT_AVAILABLE:
                pdf_path = self.generate_pdf_weasyprint(html_content, base_name)
                output_files["pdf"] = str(pdf_path)
                logger.info(f"✅ PDF report saved: {pdf_path}")
            elif REPORTLAB_AVAILABLE:
                pdf_path = self.generate_pdf_reportlab(analysis_results, base_name)
                output_files["pdf"] = str(pdf_path)
                logger.info(f"✅ PDF report saved (ReportLab): {pdf_path}")
            else:
                logger.warning(
                    "PDF generation not available. Install weasyprint or reportlab."
                )

        # Save raw data as JSON
        data_path = self.save_data(analysis_results, base_name)
        output_files["data"] = str(data_path)

        return output_files

    def create_markdown_report(self, results: Dict[str, Any]) -> str:
        """
        Create a comprehensive Markdown report from analysis results.

        Args:
            results: Analysis results dictionary

        Returns:
            Markdown formatted report string
        """
        # Extract key information
        stats = results.get("statistics", {})
        variants = results.get("variants", {})
        insights = results.get("llm_insights", "")
        process_map = results.get("process_map", {})

        # Build report
        report = f"""# 🏥 HealthProcessAI Analysis Report

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Framework:** HealthProcessAI - Process Mining Framework for Healthcare
**Developed at:** SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet

---

## 📋 Executive Summary

This report presents a comprehensive process mining analysis of healthcare data,
focusing on patient pathways and clinical processes.

### Key Findings
- **Total Cases Analyzed:** {stats.get('num_cases', 'N/A')}
- **Total Events Processed:** {stats.get('num_events', 'N/A')}
- **Sepsis Rate:** {stats.get('sepsis_rate', 0)*100:.1f}%
- **Average Case Duration:** {stats.get('avg_case_duration', 0):.1f} hours
- **Process Complexity:** {stats.get('num_activities', 'N/A')} unique activities

---

## 📊 Process Statistics

### Overview
| Metric | Value |
|--------|-------|
| Total Cases | {stats.get('num_cases', 'N/A')} |
| Total Events | {stats.get('num_events', 'N/A')} |
| Unique Activities | {stats.get('num_activities', 'N/A')} |
| Unique Resources | {stats.get('num_resources', 'N/A')} |
| Start Activities | {stats.get('num_start_activities', 'N/A')} |
| End Activities | {stats.get('num_end_activities', 'N/A')} |

### Temporal Analysis
| Metric | Value |
|--------|-------|
| Average Duration | {stats.get('avg_case_duration', 0):.2f} hours |
| Min Duration | {stats.get('min_case_duration', 0):.2f} hours |
| Max Duration | {stats.get('max_case_duration', 0):.2f} hours |
| Std Dev Duration | {stats.get('std_case_duration', 0):.2f} hours |

---

## 🔄 Process Variants

The analysis identified **{len(variants)}** unique process variants.

### Top Process Variants
"""

        # Add top variants
        if variants:
            for i, (variant_key, variant_info) in enumerate(
                list(variants.items())[:5], 1
            ):
                count = variant_info.get("count", 0)
                percentage = variant_info.get("percentage", 0)
                activities = variant_info.get("activities", [])

                report += f"""
#### Variant {i}
- **Frequency:** {count} cases ({percentage:.1f}%)
- **Path Length:** {len(activities)} activities
- **Path:** {' → '.join(activities[:8])}{'...' if len(activities) > 8 else ''}
"""

        # Add process map analysis
        if process_map:
            report += """
---

## 🗺️ Process Map Analysis

### Key Transitions
The process map reveals the following critical transitions:

| From Activity | To Activity | Frequency | Percentage |
|--------------|-------------|-----------|------------|
"""
            # Add top transitions
            if "transitions" in process_map:
                for trans in process_map["transitions"][:10]:
                    report += f"| {trans.get('from', '')} | {trans.get('to', '')} | {trans.get('count', 0)} | {trans.get('percentage', 0):.1f}% |\n"

        # Add clinical insights if available
        if insights:
            report += f"""
---

## 🤖 Clinical Insights (AI-Generated)

{insights}
"""

        # Add recommendations
        report += """
---

## 💡 Recommendations

Based on the process mining analysis, we recommend:

### Process Optimization
1. **Reduce Bottlenecks:** Focus on activities with highest waiting times
2. **Standardize Pathways:** Implement clinical guidelines for common variants
3. **Resource Allocation:** Optimize staff distribution based on activity frequency

### Clinical Improvements
1. **Early Intervention:** Identify critical decision points for early intervention
2. **Risk Stratification:** Use process patterns for patient risk assessment
3. **Quality Metrics:** Monitor adherence to clinical pathways

### Data-Driven Actions
1. **Continuous Monitoring:** Implement real-time process monitoring
2. **Predictive Analytics:** Develop models for outcome prediction
3. **Feedback Loops:** Create mechanisms for continuous improvement

---

## 📎 Appendix

### Data Quality
- **Completeness:** {:.1f}%
- **Missing Values:** {:.1f}%
- **Data Period:** {} to {}

### Methodology
- **Process Discovery:** Directly-Follows Graph (DFG)
- **Conformance Checking:** Token-based replay
- **Enhancement:** Performance and frequency analysis
- **LLM Models:** Multiple models via OpenRouter API

---

*This report was automatically generated by HealthProcessAI*
*For questions or support, visit: https://github.com/smaile/healthprocessai*
""".format(
            stats.get("data_completeness", 95.0),
            stats.get("missing_percentage", 5.0),
            stats.get("start_date", "2024-01-01"),
            stats.get("end_date", "2024-12-31"),
        )

        return report

    def markdown_to_html(self, md_content: str) -> str:
        """
        Convert Markdown to HTML with styling.

        Args:
            md_content: Markdown content

        Returns:
            HTML string with embedded CSS
        """
        # Convert markdown to HTML
        html_body = markdown.markdown(md_content, extensions=["tables", "fenced_code"])

        # Add CSS styling
        html = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthProcessAI Report</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

        body {{
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }}

        h1 {{
            color: #232C65;
            border-bottom: 3px solid #A6249D;
            padding-bottom: 10px;
        }}

        h2 {{
            color: #232C65;
            margin-top: 30px;
        }}

        h3 {{
            color: #A6249D;
        }}

        table {{
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
            background: white;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}

        th {{
            background: #232C65;
            color: white;
            padding: 12px;
            text-align: left;
        }}

        td {{
            padding: 10px;
            border-bottom: 1px solid #ddd;
        }}

        tr:hover {{
            background: #f5f5f5;
        }}

        code {{
            background: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 0.9em;
        }}

        pre {{
            background: #f4f4f4;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }}

        blockquote {{
            border-left: 4px solid #A6249D;
            padding-left: 20px;
            margin: 20px 0;
            color: #666;
        }}

        .header {{
            background: linear-gradient(135deg, #232C65 0%, #A6249D 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }}

        .footer {{
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }}
    </style>
</head>
<body>
    <div class="content">
        {html_body}
    </div>
    <div class="footer">
        <p>Generated by HealthProcessAI | SMAILE, Karolinska Institutet</p>
    </div>
</body>
</html>
"""
        return html

    def generate_pdf_weasyprint(self, html_content: str, base_name: str) -> Path:
        """
        Generate PDF from HTML using WeasyPrint.

        Args:
            html_content: HTML content
            base_name: Base filename

        Returns:
            Path to generated PDF
        """
        pdf_path = self.output_base_dir / "pdf" / f"{base_name}.pdf"

        # Generate PDF
        WeasyHTML(string=html_content).write_pdf(pdf_path)

        return pdf_path

    def generate_pdf_reportlab(self, results: Dict[str, Any], base_name: str) -> Path:
        """
        Generate PDF using ReportLab (alternative method).

        Args:
            results: Analysis results
            base_name: Base filename

        Returns:
            Path to generated PDF
        """
        pdf_path = self.output_base_dir / "pdf" / f"{base_name}.pdf"

        # Create PDF document
        doc = SimpleDocTemplate(str(pdf_path), pagesize=A4)
        story = []
        styles = getSampleStyleSheet()

        # Title
        title_style = ParagraphStyle(
            "CustomTitle",
            parent=styles["Title"],
            fontSize=24,
            textColor=colors.HexColor("#232C65"),
            spaceAfter=30,
        )
        story.append(Paragraph("HealthProcessAI Analysis Report", title_style))
        story.append(Spacer(1, 20))

        # Add content sections
        stats = results.get("statistics", {})

        # Executive Summary
        story.append(Paragraph("Executive Summary", styles["Heading1"]))
        summary_text = f"""
        This report presents a comprehensive process mining analysis of {stats.get('num_cases', 'N/A')}
        patient cases with {stats.get('num_events', 'N/A')} total events.
        The sepsis rate is {stats.get('sepsis_rate', 0)*100:.1f}%.
        """
        story.append(Paragraph(summary_text, styles["Normal"]))
        story.append(Spacer(1, 20))

        # Statistics Table
        story.append(Paragraph("Process Statistics", styles["Heading1"]))
        data = [
            ["Metric", "Value"],
            ["Total Cases", str(stats.get("num_cases", "N/A"))],
            ["Total Events", str(stats.get("num_events", "N/A"))],
            ["Unique Activities", str(stats.get("num_activities", "N/A"))],
            ["Average Duration", f"{stats.get('avg_case_duration', 0):.1f} hours"],
            ["Sepsis Rate", f"{stats.get('sepsis_rate', 0)*100:.1f}%"],
        ]

        table = Table(data)
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#232C65")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, 0), 14),
                    ("BOTTOMPADDING", (0, 0), (-1, 0), 12),
                    ("BACKGROUND", (0, 1), (-1, -1), colors.beige),
                    ("GRID", (0, 0), (-1, -1), 1, colors.black),
                ]
            )
        )
        story.append(table)

        # Build PDF
        doc.build(story)

        return pdf_path

    def save_markdown(self, content: str, base_name: str) -> Path:
        """Save Markdown content to file."""
        file_path = self.output_base_dir / "markdown" / f"{base_name}.md"
        file_path.write_text(content)
        return file_path

    def save_html(self, content: str, base_name: str) -> Path:
        """Save HTML content to file."""
        file_path = self.output_base_dir / "html" / f"{base_name}.html"
        file_path.write_text(content)
        return file_path

    def save_data(self, data: Dict[str, Any], base_name: str) -> Path:
        """Save raw data as JSON."""
        file_path = self.output_base_dir / "data" / f"{base_name}.json"

        # Convert any non-serializable objects
        def convert(obj):
            if isinstance(obj, (pd.Timestamp, datetime)):
                return obj.isoformat()
            elif isinstance(obj, pd.DataFrame):
                return obj.to_dict("records")
            elif hasattr(obj, "__dict__"):
                return str(obj)
            return obj

        with open(file_path, "w") as f:
            json.dump(data, f, indent=2, default=convert)

        return file_path


def main():
    """Example usage of the ReportGenerator."""
    # Sample analysis results
    sample_results = {
        "statistics": {
            "num_cases": 1000,
            "num_events": 15000,
            "num_activities": 25,
            "num_resources": 10,
            "sepsis_rate": 0.35,
            "avg_case_duration": 48.5,
            "min_case_duration": 12.0,
            "max_case_duration": 168.0,
            "std_case_duration": 24.3,
        },
        "variants": {
            "variant_1": {
                "count": 250,
                "percentage": 25.0,
                "activities": [
                    "Admission",
                    "Triage",
                    "Assessment",
                    "Lab Test",
                    "Treatment",
                    "Discharge",
                ],
            },
            "variant_2": {
                "count": 150,
                "percentage": 15.0,
                "activities": [
                    "Admission",
                    "Triage",
                    "Lab Test",
                    "ICU",
                    "Treatment",
                    "Ward",
                    "Discharge",
                ],
            },
        },
        "llm_insights": """
        The analysis reveals that patients following variant 1 have significantly better outcomes
        with shorter hospital stays. The ICU admission in variant 2 is associated with higher
        sepsis rates and longer recovery times. Early lab testing appears to be a critical
        decision point in the patient pathway.
        """,
        "process_map": {
            "transitions": [
                {"from": "Admission", "to": "Triage", "count": 950, "percentage": 95.0},
                {
                    "from": "Triage",
                    "to": "Assessment",
                    "count": 750,
                    "percentage": 75.0,
                },
            ]
        },
    }

    # Generate reports
    generator = ReportGenerator()
    output_files = generator.generate_report(
        sample_results, "sepsis_analysis", formats=["markdown", "pdf"]
    )

    print("\n✅ Reports generated successfully!")
    for format_type, file_path in output_files.items():
        print(f"   {format_type}: {file_path}")


if __name__ == "__main__":
    main()
