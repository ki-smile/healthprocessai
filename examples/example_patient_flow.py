#!/usr/bin/env python3
"""Module: example_patient_flow"""

"""
EXAMPLE: PATIENT FLOW ANALYSIS
===============================
This example demonstrates patient flow analysis similar to bupaR's approach,
but implemented in Python using PM4PY.

Based on bupaR's patient flow examples, this shows:
1. Loading and exploring event logs
2. Calculating performance metrics
3. Discovering process variants
4. Visualizing patient journeys

The sepsis patient flow represents real-life management from admission to discharge.

Developed at SMAILE, Karolinska Institutet
"""

import pandas as pd
import numpy as np
import pm4py
from datetime import datetime, timedelta

# UNUSED: import matplotlib.pyplot as plt
# UNUSED: import seaborn as sns
from typing import Dict, List, Tuple
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)


class PatientFlowAnalyzer:
    """
    Analyzes patient flow through healthcare processes.

    Similar to bupaR's approach but in Python, focusing on:
    - Patient journey mapping
    - Performance metrics (throughput, waiting times)
    - Resource utilization
    - Process variant discovery
    """

    def __init__(self, event_log_path: str = None):
        """
        Initialize patient flow analyzer.

        Args:
            event_log_path: Path to event log CSV file
        """
        self.event_log_path = event_log_path
        self.event_log = None
        self.df = None

    def create_sample_sepsis_data(self) -> pd.DataFrame:
        """
        Create sample sepsis patient flow data similar to bupaR's sepsis dataset.

        This represents real-life sepsis management from admission to discharge.

        Returns:
            DataFrame with sepsis patient events
        """
        logger.info(
            "Creating sample sepsis patient flow data (similar to bupaR dataset)..."
        )

        # Define typical sepsis patient journey activities
        sepsis_activities = {
            "ER Registration": {"dept": "Emergency", "typical_duration": 0.25},
            "Triage": {"dept": "Emergency", "typical_duration": 0.5},
            "Initial Assessment": {"dept": "Emergency", "typical_duration": 1},
            "Blood Culture": {"dept": "Laboratory", "typical_duration": 0.5},
            "CBC Test": {"dept": "Laboratory", "typical_duration": 0.5},
            "Lactate Test": {"dept": "Laboratory", "typical_duration": 0.25},
            "Chest X-Ray": {"dept": "Radiology", "typical_duration": 0.75},
            "IV Access": {"dept": "Emergency", "typical_duration": 0.25},
            "Fluid Resuscitation": {"dept": "Emergency", "typical_duration": 1},
            "Antibiotic Administration": {"dept": "Emergency", "typical_duration": 0.5},
            "ICU Admission": {"dept": "ICU", "typical_duration": 0.5},
            "Vasopressor Start": {"dept": "ICU", "typical_duration": 0.5},
            "Continuous Monitoring": {"dept": "ICU", "typical_duration": 24},
            "Antibiotic Adjustment": {"dept": "ICU", "typical_duration": 0.5},
            "Clinical Improvement": {"dept": "ICU", "typical_duration": 2},
            "Transfer to Ward": {"dept": "Ward", "typical_duration": 0.5},
            "Ward Care": {"dept": "Ward", "typical_duration": 48},
            "Discharge Planning": {"dept": "Ward", "typical_duration": 2},
            "Discharge": {"dept": "Ward", "typical_duration": 0.5},
        }

        # Define common patient pathways (variants)
        pathways = [
            # Severe sepsis pathway (ICU required)
            [
                "ER Registration",
                "Triage",
                "Initial Assessment",
                "Blood Culture",
                "CBC Test",
                "Lactate Test",
                "IV Access",
                "Fluid Resuscitation",
                "Antibiotic Administration",
                "Chest X-Ray",
                "ICU Admission",
                "Vasopressor Start",
                "Continuous Monitoring",
                "Antibiotic Adjustment",
                "Clinical Improvement",
                "Transfer to Ward",
                "Ward Care",
                "Discharge Planning",
                "Discharge",
            ],
            # Moderate sepsis pathway (no ICU)
            [
                "ER Registration",
                "Triage",
                "Initial Assessment",
                "Blood Culture",
                "CBC Test",
                "IV Access",
                "Antibiotic Administration",
                "Fluid Resuscitation",
                "Transfer to Ward",
                "Ward Care",
                "Discharge Planning",
                "Discharge",
            ],
            # Quick response pathway
            [
                "ER Registration",
                "Triage",
                "Blood Culture",
                "IV Access",
                "Antibiotic Administration",
                "Transfer to Ward",
                "Ward Care",
                "Discharge",
            ],
            # Complex case with complications
            [
                "ER Registration",
                "Triage",
                "Initial Assessment",
                "Blood Culture",
                "CBC Test",
                "Lactate Test",
                "Chest X-Ray",
                "IV Access",
                "Antibiotic Administration",
                "Fluid Resuscitation",
                "ICU Admission",
                "Vasopressor Start",
                "Continuous Monitoring",
                "Lactate Test",
                "Antibiotic Adjustment",
                "Continuous Monitoring",
                "Clinical Improvement",
                "Transfer to Ward",
                "Ward Care",
                "Discharge Planning",
                "Discharge",
            ],
        ]

        # Generate patient cases
        events = []
        base_time = datetime(2024, 1, 1)

        # Distribution of pathway types
        pathway_weights = [0.3, 0.4, 0.2, 0.1]  # Severe, Moderate, Quick, Complex

        for case_id in range(1, 101):  # Generate 100 cases
            # Select pathway based on weights - use indices instead of direct array choice
            pathway_idx = np.random.choice(len(pathways), p=pathway_weights)
            pathway = pathways[pathway_idx]

            # Starting time for this case
            case_start = base_time + timedelta(days=np.random.uniform(0, 30))
            current_time = case_start

            # Generate events for this pathway
            for activity in pathway:
                # Add some variation to typical duration
                duration = sepsis_activities[activity]["typical_duration"]
                actual_duration = duration * np.random.uniform(0.7, 1.3)

                # Create event
                event = {
                    "case": f"Patient_{case_id:03d}",
                    "activity": activity,
                    "timestamp": current_time,
                    "complete_timestamp": current_time
                    + timedelta(hours=actual_duration),
                    "resource": sepsis_activities[activity]["dept"],
                    "lifecycle": "complete",
                    "SepsisLabel": (
                        1 if "ICU" in activity else 0
                    ),  # Simplified sepsis indicator
                    "variant": pathways.index(pathway) + 1,
                }
                events.append(event)

                # Move to next activity with some waiting time
                waiting_time = np.random.exponential(
                    0.5
                )  # Random waiting between activities
                current_time = event["complete_timestamp"] + timedelta(
                    hours=waiting_time
                )

        df = pd.DataFrame(events)
        logger.info(f"Created {len(df)} events for {df['case'].nunique()} patients")

        return df

    def load_event_log(self, df: pd.DataFrame = None) -> None:
        """
        Load event log from DataFrame or file.

        Args:
            df: DataFrame with event log data (if None, loads from file or creates sample)
        """
        if df is not None:
            self.df = df
        elif self.event_log_path:
            self.df = pd.read_csv(self.event_log_path)
            self.df["timestamp"] = pd.to_datetime(self.df["timestamp"])
            if "complete_timestamp" in self.df.columns:
                self.df["complete_timestamp"] = pd.to_datetime(
                    self.df["complete_timestamp"]
                )
        else:
            # Create sample data
            self.df = self.create_sample_sepsis_data()

        # Convert to PM4PY event log
        self.df_pm4py = self.df.copy()
        self.df_pm4py = self.df_pm4py.rename(
            columns={
                "case": "case:concept:name",
                "activity": "concept:name",
                "timestamp": "time:timestamp",
                "resource": "org:resource",
            }
        )

        self.event_log = pm4py.convert_to_event_log(self.df_pm4py)
        logger.info(f"Event log loaded: {len(self.event_log)} cases")

    def describe_log_structure(self) -> Dict:
        """
        Describe the structure of the event log (similar to bupaR's functions).

        Returns:
            Dictionary with log statistics
        """
        logger.info("\n" + "=" * 60)
        logger.info("EVENT LOG STRUCTURE")
        logger.info("=" * 60)

        structure = {
            "n_cases": self.df["case"].nunique(),
            "n_events": len(self.df),
            "n_activities": self.df["activity"].nunique(),
            "n_resources": self.df["resource"].nunique(),
            "activities": list(self.df["activity"].unique()),
            "resources": list(self.df["resource"].unique()),
            "time_range": {
                "start": self.df["timestamp"].min(),
                "end": self.df["timestamp"].max(),
            },
        }

        # Print summary
        logger.info(f"Cases (patients): {structure['n_cases']}")
        logger.info(f"Events: {structure['n_events']}")
        logger.info(f"Activities: {structure['n_activities']}")
        logger.info(f"Resources (departments): {structure['n_resources']}")
        logger.info(
            f"Time range: {structure['time_range']['start']} to {structure['time_range']['end']}"
        )

        return structure

    def calculate_performance_metrics(self) -> pd.DataFrame:
        """
        Calculate performance metrics like throughput time and waiting time.
        Similar to bupaR's performance functions.

        Returns:
            DataFrame with performance metrics per case
        """
        logger.info("\n" + "=" * 60)
        logger.info("PERFORMANCE METRICS")
        logger.info("=" * 60)

        metrics = []

        for case_id in self.df["case"].unique():
            case_events = self.df[self.df["case"] == case_id].sort_values("timestamp")

            # Throughput time (admission to discharge)
            throughput = (
                case_events["timestamp"].max() - case_events["timestamp"].min()
            ).total_seconds() / 3600

            # Number of activities
            n_activities = len(case_events)

            # Unique activities (complexity indicator)
            n_unique = case_events["activity"].nunique()

            # Time to first antibiotic (if applicable)
            antibiotic_events = case_events[
                case_events["activity"].str.contains("Antibiotic", na=False)
            ]
            time_to_antibiotic = None
            if not antibiotic_events.empty:
                time_to_antibiotic = (
                    antibiotic_events["timestamp"].min()
                    - case_events["timestamp"].min()
                ).total_seconds() / 3600

            # ICU admission
            icu_admission = any(
                "ICU" in str(act) for act in case_events["activity"].values
            )

            metrics.append(
                {
                    "case": case_id,
                    "throughput_hours": throughput,
                    "n_activities": n_activities,
                    "n_unique_activities": n_unique,
                    "time_to_antibiotic_hours": time_to_antibiotic,
                    "icu_admission": icu_admission,
                    "variant": (
                        case_events["variant"].iloc[0]
                        if "variant" in case_events.columns
                        else None
                    ),
                }
            )

        metrics_df = pd.DataFrame(metrics)

        # Print summary statistics
        logger.info("\nThroughput Time Statistics:")
        logger.info(f"  Mean: {metrics_df['throughput_hours'].mean():.2f} hours")
        logger.info(f"  Median: {metrics_df['throughput_hours'].median():.2f} hours")
        logger.info(f"  Min: {metrics_df['throughput_hours'].min():.2f} hours")
        logger.info(f"  Max: {metrics_df['throughput_hours'].max():.2f} hours")

        if metrics_df["time_to_antibiotic_hours"].notna().any():
            logger.info("\nTime to First Antibiotic:")
            logger.info(
                f"  Mean: {metrics_df['time_to_antibiotic_hours'].mean():.2f} hours"
            )
            logger.info(
                f"  Median: {metrics_df['time_to_antibiotic_hours'].median():.2f} hours"
            )

        logger.info(f"\nICU Admission Rate: {metrics_df['icu_admission'].mean():.1%}")

        return metrics_df

    def discover_process_variants(self, top_k: int = 5) -> pd.DataFrame:
        """
        Discover common process variants (patient pathways).
        Similar to bupaR's trace exploration.

        Args:
            top_k: Number of top variants to return

        Returns:
            DataFrame with variant information
        """
        logger.info("\n" + "=" * 60)
        logger.info("PROCESS VARIANTS (PATIENT PATHWAYS)")
        logger.info("=" * 60)

        # Get variants using PM4PY
        variants = pm4py.get_variants(self.event_log)

        # Create DataFrame with variant information
        variant_data = []
        for variant_str, cases in variants.items():
            # Handle both string and tuple formats
            if isinstance(variant_str, str):
                activities = variant_str.split(",")
            else:
                # Convert tuple to list
                activities = list(variant_str)
            variant_data.append(
                {
                    "variant": str(variant_str),  # Convert to string for consistency
                    "n_cases": len(cases),
                    "percentage": len(cases) / len(self.event_log) * 100,
                    "n_activities": len(activities),
                    "activities": activities,
                }
            )

        variants_df = pd.DataFrame(variant_data)
        variants_df = variants_df.sort_values("n_cases", ascending=False).head(top_k)

        # Print top variants
        logger.info(f"\nTop {top_k} Patient Pathways:")
        for idx, row in variants_df.iterrows():
            logger.info(
                f"\nVariant {idx+1}: {row['n_cases']} cases ({row['percentage']:.1f}%)"
            )
            logger.info(f"  Activities: {row['n_activities']}")
            logger.info(f"  Path: {' → '.join(row['activities'][:5])}...")

        return variants_df

    def analyze_resource_utilization(self) -> pd.DataFrame:
        """
        Analyze resource (department) utilization.

        Returns:
            DataFrame with resource utilization metrics
        """
        logger.info("\n" + "=" * 60)
        logger.info("RESOURCE UTILIZATION")
        logger.info("=" * 60)

        # Count events per resource
        resource_counts = (
            self.df.groupby("resource")
            .agg({"case": "count", "activity": "nunique", "timestamp": ["min", "max"]})
            .round(2)
        )

        resource_counts.columns = [
            "n_events",
            "n_activities",
            "first_event",
            "last_event",
        ]
        resource_counts["percentage"] = (
            resource_counts["n_events"] / resource_counts["n_events"].sum() * 100
        ).round(1)

        resource_counts = resource_counts.sort_values("n_events", ascending=False)

        logger.info("\nDepartment Utilization:")
        for dept, row in resource_counts.iterrows():
            logger.info(f"  {dept}: {row['n_events']} events ({row['percentage']}%)")

        return resource_counts

    def visualize_patient_flow(self, save_path: str = None):
        """
        Create visualizations of patient flow.

        Args:
            save_path: Path to save visualization
        """
        # Create process map using PM4PY
        dfg, start_activities, end_activities = pm4py.discover_dfg(self.event_log)

        if save_path:
            pm4py.save_vis_dfg(dfg, start_activities, end_activities, save_path)
            logger.info(f"\nProcess map saved to: {save_path}")
        else:
            pm4py.view_dfg(dfg, start_activities, end_activities)

    def augment_log_with_metrics(self) -> pd.DataFrame:
        """
        Augment the event log with additional calculated metrics.
        Similar to bupaR's augment functions.

        Returns:
            Augmented DataFrame
        """
        augmented_df = self.df.copy()

        # Add throughput time for each case
        case_throughput = augmented_df.groupby("case")["timestamp"].agg(["min", "max"])
        case_throughput["throughput_hours"] = (
            case_throughput["max"] - case_throughput["min"]
        ).dt.total_seconds() / 3600

        # Merge back to main DataFrame
        augmented_df = augmented_df.merge(
            case_throughput[["throughput_hours"]], left_on="case", right_index=True
        )

        # Add time since case start
        augmented_df["time_since_start"] = augmented_df.groupby("case")[
            "timestamp"
        ].transform(lambda x: (x - x.min()).dt.total_seconds() / 3600)

        # Add activity position in case
        augmented_df["activity_position"] = augmented_df.groupby("case").cumcount() + 1

        logger.info("\nLog augmented with:")
        logger.info("  - throughput_hours: Total case duration")
        logger.info("  - time_since_start: Hours since case began")
        logger.info("  - activity_position: Position of activity in case")

        return augmented_df


def main():
    """
    Demonstrate patient flow analysis similar to bupaR examples.
    """
    print("\n" + "=" * 70)
    print("PATIENT FLOW ANALYSIS - Python Implementation of bupaR Approach")
    print("=" * 70)
    print("\nThis example demonstrates patient flow analysis for sepsis cases,")
    print("similar to the bupaR package in R but implemented in Python.")

    # Initialize analyzer
    analyzer = PatientFlowAnalyzer()

    # Load event log (creates sample data similar to bupaR's sepsis dataset)
    analyzer.load_event_log()

    # 1. Describe log structure
    structure = analyzer.describe_log_structure()

    # 2. Calculate performance metrics
    performance = analyzer.calculate_performance_metrics()

    # 3. Discover process variants
    variants = analyzer.discover_process_variants(top_k=5)

    # 4. Analyze resource utilization
    resources = analyzer.analyze_resource_utilization()

    # 5. Augment log with calculated metrics
    augmented_log = analyzer.augment_log_with_metrics()

    # 6. Visualize patient flow (optional)
    # analyzer.visualize_patient_flow("patient_flow_map.png")

    print("\n" + "=" * 70)
    print("ANALYSIS COMPLETE")
    print("=" * 70)
    print("\nThis analysis provides insights similar to bupaR's capabilities:")
    print("- Patient pathway discovery")
    print("- Performance metrics calculation")
    print("- Resource utilization analysis")
    print("- Process variant identification")
    print("\nFor R users familiar with bupaR, this Python implementation")
    print("offers equivalent functionality using PM4PY.")

    return analyzer, augmented_log


if __name__ == "__main__":
    analyzer, augmented_log = main()

    # Additional analysis examples
    print("\n" + "=" * 70)
    print("ADDITIONAL ANALYSIS EXAMPLES")
    print("=" * 70)

    # Example: Count cases per activity (similar to bupaR's group_by)
    print("\nCases per Activity:")
    activity_counts = (
        augmented_log.groupby("activity")["case"].nunique().sort_values(ascending=False)
    )
    for activity, count in activity_counts.head(5).items():
        print(f"  {activity}: {count} cases")

    # Example: Average time per activity
    print("\nAverage Time Since Start per Activity:")
    avg_times = (
        augmented_log.groupby("activity")["time_since_start"].mean().sort_values()
    )
    for activity, time in avg_times.head(5).items():
        print(f"  {activity}: {time:.2f} hours")
