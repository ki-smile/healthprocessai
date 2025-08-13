#!/usr/bin/env python3
"""Module: complete_pipeline_example"""

"""
COMPLETE PIPELINE EXAMPLE: SEPSIS PROGRESSION ANALYSIS
======================================================
This script demonstrates the complete process mining pipeline for healthcare data,
incorporating all modules and advanced methodological approaches.

This example shows:
1. Data loading and preparation
2. Process discovery and visualization
3. Advanced analytics (clustering, bottlenecks, predictions)
4. LLM-powered clinical insights
5. Comprehensive report generation

Perfect for learning the end-to-end workflow of healthcare process mining.
"""

import os
import json
import pandas as pd
import numpy as np
from datetime import datetime
from pathlib import Path
import logging

# Import our modular components
from core.step1_data_loader import EventLogLoader
from core.step2_process_mining import ProcessMiner
from core.step3_llm_integration import LLMAnalyzer
from core.step4_advanced_analytics import AdvancedProcessAnalyzer

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class CompleteProcessMiningPipeline:
    """
    Complete pipeline for healthcare process mining analysis.

    This class orchestrates all steps of the analysis, from data loading
    to final report generation, incorporating advanced analytics and AI insights.
    """

    def __init__(
        self, data_path: str, api_key: str = None, output_dir: str = "./results"
    ):
        """
        Initialize the complete pipeline.

        Args:
            data_path: Path to the event log CSV file
            api_key: OpenRouter API key for LLM integration
            output_dir: Directory for saving results
        """
        self.data_path = data_path
        self.api_key = api_key
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)

        # Initialize components
        self.loader = None
        self.miner = None
        self.analyzer = None
        self.advanced_analyzer = None

        # Store results at each step
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "data_path": data_path,
            "steps_completed": [],
        }

        logger.info(f"Initialized pipeline for {Path(data_path).name}")

    def run_complete_analysis(
        self, sepsis_only: bool = True, use_llm: bool = True, llm_models: list = None
    ) -> dict:
        """
        Run the complete analysis pipeline.

        Args:
            sepsis_only: Whether to filter for sepsis cases only
            use_llm: Whether to use LLM for insights generation
            llm_models: List of LLM models to use

        Returns:
            Dictionary containing all analysis results
        """
        logger.info("=" * 60)
        logger.info("STARTING COMPLETE PROCESS MINING PIPELINE")
        logger.info("=" * 60)

        try:
            # Step 1: Data Loading and Preparation
            self._step1_load_data()

            # Step 2: Filter cases if needed
            self._step2_filter_cases(sepsis_only)

            # Step 3: Process Discovery
            self._step3_process_discovery()

            # Step 4: Advanced Analytics
            self._step4_advanced_analytics()

            # Step 5: Generate Clinical Insights
            if use_llm and self.api_key:
                self._step5_llm_insights(llm_models)
            else:
                logger.info("Skipping LLM insights (no API key provided)")

            # Step 6: Generate Final Report
            self._step6_generate_report()

            # Step 7: Export All Results
            self._step7_export_results()

            logger.info("=" * 60)
            logger.info("PIPELINE COMPLETED SUCCESSFULLY")
            logger.info("=" * 60)

        except Exception as e:
            logger.error(f"Pipeline failed: {e}")
            self.results["error"] = str(e)
            raise

        return self.results

    def _step1_load_data(self):
        """Step 1: Load and prepare event log data."""
        logger.info("\n" + "=" * 40)
        logger.info("STEP 1: DATA LOADING AND PREPARATION")
        logger.info("=" * 40)

        # Initialize loader
        self.loader = EventLogLoader(self.data_path)

        # Load raw data
        raw_data = self.loader.load_data()
        logger.info(f"✓ Loaded {len(raw_data)} events")

        # Prepare data
        self.prepared_data = self.loader.prepare_data()
        logger.info(f"✓ Prepared {len(self.prepared_data)} events")

        # Get statistics
        stats = self.loader.get_statistics()

        self.results["data_statistics"] = stats
        self.results["steps_completed"].append("data_loading")

        # Log summary
        logger.info("\nData Summary:")
        logger.info(f"  - Total cases: {stats['num_cases']}")
        logger.info(f"  - Total events: {stats['num_events']}")
        logger.info(f"  - Unique activities: {stats['num_activities']}")
        if "sepsis_rate" in stats:
            logger.info(f"  - Sepsis rate: {stats['sepsis_rate']:.1%}")

    def _step2_filter_cases(self, sepsis_only: bool):
        """Step 2: Filter cases based on outcome."""
        logger.info("\n" + "=" * 40)
        logger.info("STEP 2: CASE FILTERING")
        logger.info("=" * 40)

        if sepsis_only:
            self.filtered_data = self.loader.filter_by_outcome(sepsis_only=True)
            logger.info(
                f"✓ Filtered to {self.filtered_data['case'].nunique()} sepsis cases"
            )
        else:
            self.filtered_data = self.prepared_data
            logger.info("✓ Using all cases (no filtering)")

        self.results["filtering"] = {
            "sepsis_only": sepsis_only,
            "cases_after_filter": self.filtered_data["case"].nunique(),
        }
        self.results["steps_completed"].append("filtering")

    def _step3_process_discovery(self):
        """Step 3: Discover process model."""
        logger.info("\n" + "=" * 40)
        logger.info("STEP 3: PROCESS DISCOVERY")
        logger.info("=" * 40)

        # Initialize process miner
        self.miner = ProcessMiner()

        # Create PM4PY event log
        self.event_log = self.miner.create_event_log(self.filtered_data)
        logger.info(f"✓ Created event log with {len(self.event_log)} cases")

        # Discover DFG
        dfg, starts, ends = self.miner.discover_dfg()
        logger.info(f"✓ Discovered {len(dfg)} transitions")

        # Discover performance DFG
        perf_dfg = self.miner.discover_performance_dfg()
        logger.info(f"✓ Calculated performance for {len(perf_dfg)} transitions")

        # Create process matrix
        matrix = self.miner.create_process_matrix()
        logger.info(f"✓ Created process matrix ({matrix.shape[0]}x{matrix.shape[1]})")

        # Discover variants
        variants = self.miner.discover_variants(top_k=10)
        logger.info(f"✓ Discovered {len(variants)} top variants")

        # Calculate metrics
        metrics = self.miner.calculate_process_metrics()

        self.results["process_discovery"] = {
            "num_transitions": len(dfg),
            "num_variants": len(variants),
            "metrics": metrics,
        }
        self.results["steps_completed"].append("process_discovery")

        # Log key findings
        logger.info("\nProcess Discovery Results:")
        logger.info(
            f"  - Average case duration: {metrics['avg_case_duration_hours']:.1f} hours"
        )
        logger.info(
            f"  - Most common variant covers: {variants.iloc[0]['percentage']}% of cases"
        )

    def _step4_advanced_analytics(self):
        """Step 4: Perform advanced analytics."""
        logger.info("\n" + "=" * 40)
        logger.info("STEP 4: ADVANCED ANALYTICS")
        logger.info("=" * 40)

        # Initialize advanced analyzer
        self.advanced_analyzer = AdvancedProcessAnalyzer(self.event_log)

        # 4.1: Patient Clustering
        logger.info("\n4.1 Patient Pathway Clustering")
        clusters = self.advanced_analyzer.cluster_patient_pathways(
            n_clusters=3, method="kmeans"
        )
        logger.info(f"✓ Identified {clusters['n_clusters']} patient clusters")
        logger.info(f"  Silhouette score: {clusters['silhouette_score']:.3f}")

        # 4.2: Bottleneck Analysis
        logger.info("\n4.2 Bottleneck Analysis")
        bottlenecks = self.advanced_analyzer.analyze_bottlenecks()
        logger.info(f"✓ Identified {len(bottlenecks['bottlenecks'])} bottlenecks")
        if bottlenecks["bottlenecks"]:
            top_bottleneck = bottlenecks["bottlenecks"][0]
            logger.info(
                f"  Top bottleneck: {top_bottleneck['activity']} "
                f"(avg wait: {top_bottleneck['avg_wait_hours']:.1f} hours)"
            )

        # 4.3: Clinical KPIs
        logger.info("\n4.3 Clinical KPI Calculation")
        kpis = self.advanced_analyzer.calculate_clinical_kpis()
        logger.info(f"✓ Calculated {len(kpis)} KPIs")
        logger.info(f"  Average LOS: {kpis['avg_length_of_stay']:.1f} hours")
        logger.info(f"  Daily admissions: {kpis['daily_admissions']:.1f}")

        # 4.4: Predictive Monitoring (demonstration)
        logger.info("\n4.4 Predictive Monitoring Capability")
        if len(self.event_log) > 0:
            sample_trace = self.event_log[0][:3]  # First 3 events
            prediction = self.advanced_analyzer.predict_case_outcome(
                sample_trace, "sepsis"
            )
            logger.info(f"✓ Prediction demo - Risk level: {prediction['risk_level']}")

        self.results["advanced_analytics"] = {
            "clusters": clusters,
            "bottlenecks": bottlenecks,
            "kpis": kpis,
        }
        self.results["steps_completed"].append("advanced_analytics")

    def _step5_llm_insights(self, llm_models: list = None):
        """Step 5: Generate insights using LLMs."""
        logger.info("\n" + "=" * 40)
        logger.info("STEP 5: AI-POWERED CLINICAL INSIGHTS")
        logger.info("=" * 40)

        if not llm_models:
            llm_models = ["deepseek"]  # Default to free model

        # Initialize LLM analyzer
        self.analyzer = LLMAnalyzer(self.api_key)

        # Prepare process data for LLM
        process_data = {
            "num_cases": self.results["data_statistics"]["num_cases"],
            "avg_case_duration_hours": self.results["process_discovery"]["metrics"][
                "avg_case_duration_hours"
            ],
            "num_variants": self.results["process_discovery"]["metrics"][
                "num_variants"
            ],
            "num_activities": self.results["data_statistics"]["num_activities"],
            "total_events": self.results["data_statistics"]["num_events"],
            "top_5_activities": self.results["process_discovery"]["metrics"].get(
                "top_5_activities", []
            ),
            "key_findings": [
                f"Identified {self.results['advanced_analytics']['clusters']['n_clusters']} distinct patient clusters",
                (
                    f"Top bottleneck causes {self.results['advanced_analytics']['bottlenecks']['bottlenecks'][0]['avg_wait_hours']:.1f} hour delays"
                    if self.results["advanced_analytics"]["bottlenecks"]["bottlenecks"]
                    else "No significant bottlenecks"
                ),
                f"Average length of stay is {self.results['advanced_analytics']['kpis']['avg_length_of_stay']:.1f} hours",
            ],
        }

        # Create clinical prompt
        prompt = self.analyzer.create_clinical_prompt(process_data, "sepsis")

        # Query models
        logger.info(f"Querying {len(llm_models)} AI models...")
        llm_results = self.analyzer.analyze_with_multiple_models(
            prompt, models=llm_models, delay_seconds=1
        )

        # Log results
        for model, result in llm_results.items():
            status = "✓" if result["status"] == "success" else "✗"
            logger.info(f"  {status} {model}: {result['status']}")

        self.results["llm_insights"] = llm_results
        self.results["steps_completed"].append("llm_insights")

    def _step6_generate_report(self):
        """Step 6: Generate comprehensive clinical report."""
        logger.info("\n" + "=" * 40)
        logger.info("STEP 6: REPORT GENERATION")
        logger.info("=" * 40)

        # Create markdown report
        report = self._create_markdown_report()

        # Save report
        report_path = self.output_dir / "clinical_analysis_report.md"
        with open(report_path, "w", encoding="utf-8") as f:
            f.write(report)

        logger.info(f"✓ Report saved to {report_path}")

        self.results["report_path"] = str(report_path)
        self.results["steps_completed"].append("report_generation")

    def _step7_export_results(self):
        """Step 7: Export all results and artifacts."""
        logger.info("\n" + "=" * 40)
        logger.info("STEP 7: EXPORTING RESULTS")
        logger.info("=" * 40)

        # Export process mining results
        if self.miner:
            exported = self.miner.export_results(str(self.output_dir))
            logger.info(f"✓ Exported process mining results ({len(exported)} files)")

        # Export pipeline results as JSON
        results_path = self.output_dir / "pipeline_results.json"

        # Convert numpy/pandas objects for JSON serialization
        def convert_for_json(obj):
            if isinstance(obj, (np.integer, np.floating)):
                return float(obj)
            elif isinstance(obj, np.ndarray):
                return obj.tolist()
            elif isinstance(obj, pd.DataFrame):
                return obj.to_dict()
            elif hasattr(obj, "__dict__"):
                return str(obj)
            return obj

        # Save results
        with open(results_path, "w") as f:
            json.dump(self.results, f, indent=2, default=convert_for_json)

        logger.info(f"✓ Pipeline results saved to {results_path}")

        # Create visualization if possible
        try:
            if self.miner:
                viz_path = self.output_dir / "process_map.png"
                self.miner.visualize_dfg(str(viz_path))
                logger.info(f"✓ Process visualization saved to {viz_path}")
        except Exception as e:
            logger.warning(f"Could not create visualization: {e}")

        self.results["steps_completed"].append("export")

    def _create_markdown_report(self) -> str:
        """Create a comprehensive markdown report."""
        report = f"""# Clinical Process Mining Analysis Report

## Executive Summary

**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Data Source**: {Path(self.data_path).name}
**Analysis Type**: Sepsis Progression Analysis

### Key Findings

- Analyzed **{self.results['data_statistics']['num_cases']:,}** patient cases
- Identified **{self.results['advanced_analytics']['clusters']['n_clusters']}** distinct patient clusters
- Average length of stay: **{self.results['advanced_analytics']['kpis']['avg_length_of_stay']:.1f} hours**
- Sepsis rate: **{self.results['data_statistics'].get('sepsis_rate', 0):.1%}**

---

## 1. Data Overview

| Metric | Value |
|--------|-------|
| Total Cases | {self.results['data_statistics']['num_cases']:,} |
| Total Events | {self.results['data_statistics']['num_events']:,} |
| Unique Activities | {self.results['data_statistics']['num_activities']} |
| Date Range | {self.results['data_statistics']['date_range']['start']} to {self.results['data_statistics']['date_range']['end']} |

---

## 2. Process Discovery Results

### Process Characteristics
- **Number of transitions discovered**: {self.results['process_discovery']['num_transitions']}
- **Number of unique pathways**: {self.results['process_discovery']['num_variants']}
- **Average case duration**: {self.results['process_discovery']['metrics']['avg_case_duration_hours']:.1f} hours

### Top Activities
"""

        # Add top activities if available
        if "top_5_activities" in self.results["process_discovery"]["metrics"]:
            report += (
                "\n| Rank | Activity | Frequency |\n|------|----------|----------|\n"
            )
            for i, activity in enumerate(
                self.results["process_discovery"]["metrics"]["top_5_activities"], 1
            ):
                report += f"| {i} | {activity['activity']} | {activity['count']:,} |\n"

        report += f"""

---

## 3. Advanced Analytics

### Patient Clustering
- **Clusters identified**: {self.results['advanced_analytics']['clusters']['n_clusters']}
- **Clustering quality (Silhouette score)**: {self.results['advanced_analytics']['clusters']['silhouette_score']:.3f}

### Bottleneck Analysis
"""

        # Add top bottlenecks
        if self.results["advanced_analytics"]["bottlenecks"]["bottlenecks"]:
            report += "\n| Activity | Avg Wait (hours) | Cases Affected |\n|----------|-----------------|----------------|\n"
            for b in self.results["advanced_analytics"]["bottlenecks"]["bottlenecks"][
                :3
            ]:
                report += f"| {b['activity']} | {b['avg_wait_hours']:.1f} | {b['cases_affected']} |\n"

        report += f"""

### Clinical KPIs
- **Average Length of Stay**: {self.results['advanced_analytics']['kpis']['avg_length_of_stay']:.1f} hours
- **Daily Admissions**: {self.results['advanced_analytics']['kpis']['daily_admissions']:.1f}
- **Bed Turnover Rate**: {self.results['advanced_analytics']['kpis']['bed_turnover_rate']:.1f}

---

## 4. Recommendations

Based on the analysis, the following recommendations are provided:

1. **Process Optimization**: Focus on reducing wait times at identified bottleneck activities
2. **Patient Stratification**: Implement differentiated care pathways for the {self.results['advanced_analytics']['clusters']['n_clusters']} identified patient clusters
3. **Resource Allocation**: Optimize staffing during peak admission periods
4. **Monitoring**: Implement continuous process monitoring for early deviation detection

---

## 5. Methodology

This analysis employed:
- **Process Mining**: PM4PY library for process discovery and conformance checking
- **Advanced Analytics**: Clustering, bottleneck analysis, and KPI calculation
- **AI Integration**: Large Language Models for clinical insight generation
- **Statistical Methods**: Descriptive statistics and predictive modeling

---

*This report was generated automatically using advanced process mining techniques and AI-powered analysis.*
"""

        return report


def main():
    """
    Main function to demonstrate the complete pipeline.
    """
    # Configuration
    DATA_PATH = "data/sepsisAgregated_Infection.csv"  # Update with your data path
    API_KEY = os.getenv(
        "OPENROUTER_API_KEY"
    )  # Set your API key as environment variable
    OUTPUT_DIR = "./pipeline_results"

    # Print header
    print("\n" + "=" * 60)
    print("COMPLETE HEALTHCARE PROCESS MINING PIPELINE")
    print("=" * 60)
    print(f"\nData: {DATA_PATH}")
    print(f"Output: {OUTPUT_DIR}")
    print(f"LLM Integration: {'Enabled' if API_KEY else 'Disabled (no API key)'}")
    print("\n" + "=" * 60)

    # Initialize pipeline
    pipeline = CompleteProcessMiningPipeline(
        data_path=DATA_PATH, api_key=API_KEY, output_dir=OUTPUT_DIR
    )

    # Run complete analysis
    results = pipeline.run_complete_analysis(
        sepsis_only=True,
        use_llm=bool(API_KEY),
        llm_models=["deepseek"],  # Using free model for demo
    )

    # Print summary
    print("\n" + "=" * 60)
    print("PIPELINE SUMMARY")
    print("=" * 60)
    print(f"\nSteps completed: {', '.join(results['steps_completed'])}")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Report available at: {results.get('report_path', 'Not generated')}")

    if "error" in results:
        print(f"\n⚠️  Error occurred: {results['error']}")
    else:
        print("\n✅ Pipeline completed successfully!")

    print("\n" + "=" * 60)


if __name__ == "__main__":
    main()
