#!/usr/bin/env python3
"""Module: step2_process_mining"""

"""
STEP 2: PROCESS MINING ANALYSIS
================================
This module handles the core process mining analysis using PM4PY library.
It converts prepared data into process mining formats and discovers process models.

Learning Goals:
- Understand PM4PY event log format requirements
- Learn different process discovery algorithms
- Generate process maps and performance metrics
- Export results for visualization

Key Concepts:
- Event logs in PM4PY use specific column naming conventions
- Directly-Follows Graphs (DFG) show activity sequences
- Process matrices quantify transitions between activities
- Different algorithms reveal different process perspectives
"""

import pandas as pd
import numpy as np
import json
import logging
from typing import Dict, Any, Tuple
from pathlib import Path

# PM4PY imports - the main process mining library for Python
import pm4py
from pm4py.objects.conversion.log import converter as log_converter
from pm4py.objects.log.obj import EventLog
from pm4py.algo.discovery.dfg import algorithm as dfg_discovery
from pm4py.algo.discovery.heuristics import algorithm as heuristics_miner
from pm4py.algo.discovery.alpha import algorithm as alpha_miner
from pm4py.statistics.traces.generic.log import case_statistics
from pm4py.algo.filtering.log.variants import variants_filter

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class ProcessMiner:
    """
    Performs process mining analysis on prepared event log data.

    This class provides methods to:
    1. Convert pandas DataFrames to PM4PY event logs
    2. Discover process models using various algorithms
    3. Calculate process metrics and statistics
    4. Export results for visualization and reporting
    """

    # PM4PY standard column names
    CASE_ID_KEY = "case:concept:name"
    ACTIVITY_KEY = "concept:name"
    TIMESTAMP_KEY = "time:timestamp"
    RESOURCE_KEY = "org:resource"

    def __init__(self):
        """Initialize the ProcessMiner."""
        self.event_log = None
        self.dfg = None  # Directly-Follows Graph
        self.process_matrix = None
        self.variants = None
        self.performance_dfg = None

        logger.info("Initialized ProcessMiner")

    def create_event_log(self, df: pd.DataFrame) -> EventLog:
        """
        Convert a pandas DataFrame to PM4PY EventLog format.

        PM4PY requires specific column names:
        - case:concept:name for case ID
        - concept:name for activity
        - time:timestamp for timestamp

        Args:
            df: DataFrame with columns: case, activity, timestamp

        Returns:
            PM4PY EventLog object

        Example:
            >>> miner = ProcessMiner()
            >>> event_log = miner.create_event_log(prepared_data)
            >>> print(f"Created event log with {len(event_log)} cases")
        """
        # Create a copy to avoid modifying original
        df_copy = df.copy()

        # Rename columns to PM4PY format
        column_mapping = {
            "case": self.CASE_ID_KEY,
            "activity": self.ACTIVITY_KEY,
            "timestamp": self.TIMESTAMP_KEY,
        }

        # Add optional columns if they exist
        if "resource" in df_copy.columns:
            column_mapping["resource"] = self.RESOURCE_KEY

        df_copy = df_copy.rename(columns=column_mapping)

        # Ensure timestamp is datetime
        df_copy[self.TIMESTAMP_KEY] = pd.to_datetime(df_copy[self.TIMESTAMP_KEY])

        # Convert to PM4PY event log
        self.event_log = log_converter.apply(df_copy)

        logger.info(f"Created event log with {len(self.event_log)} cases")

        return self.event_log

    def discover_dfg(self) -> Tuple[Dict, Dict, Dict]:
        """
        Discover a Directly-Follows Graph (DFG) from the event log.

        A DFG shows:
        - Which activities follow each other
        - How often these transitions occur
        - Start and end activities

        Returns:
            Tuple of (dfg, start_activities, end_activities)

        Example:
            >>> dfg, starts, ends = miner.discover_dfg()
            >>> print(f"Found {len(dfg)} transitions")
        """
        if self.event_log is None:
            raise ValueError("No event log created. Call create_event_log() first.")

        # Discover frequency DFG
        self.dfg = dfg_discovery.apply(self.event_log)

        # Get start and end activities
        start_activities = pm4py.get_start_activities(self.event_log)
        end_activities = pm4py.get_end_activities(self.event_log)

        logger.info(f"Discovered DFG with {len(self.dfg)} transitions")
        logger.info(f"Start activities: {list(start_activities.keys())}")
        logger.info(f"End activities: {list(end_activities.keys())}")

        return self.dfg, start_activities, end_activities

    def discover_heuristics_net(self, dependency_threshold: float = 0.5) -> Dict:
        """
        Discover a Heuristics Net from the event log.
        
        Heuristics Miner is more robust to noise than other algorithms.
        It uses frequency and dependency measures to build process models.
        
        Args:
            dependency_threshold: Threshold for dependencies (0.0 to 1.0)
            
        Returns:
            Dictionary containing heuristics net information
            
        Example:
            >>> heu_net = miner.discover_heuristics_net(dependency_threshold=0.7)
            >>> print(f"Discovered heuristics net with threshold {dependency_threshold}")
        """
        if self.event_log is None:
            raise ValueError("Event log not created. Call create_event_log() first.")

        # Configure parameters for heuristics miner
        parameters = {
            heuristics_miner.Variants.CLASSIC.value.Parameters.DEPENDENCY_THRESH: dependency_threshold,
            heuristics_miner.Variants.CLASSIC.value.Parameters.AND_MEASURE_THRESH: 0.65,
            heuristics_miner.Variants.CLASSIC.value.Parameters.LOOP_LENGTH_TWO_THRESH: 0.5
        }

        # Discover heuristics net
        heu_net = heuristics_miner.apply(self.event_log, parameters=parameters)
        
        # Convert to Petri net for analysis
        from pm4py.objects.conversion.heuristics_net import converter as hn_converter
        petri_net, initial_marking, final_marking = hn_converter.apply(heu_net)

        logger.info(f"Discovered heuristics net with dependency threshold {dependency_threshold}")
        
        return {
            'heuristics_net': heu_net,
            'petri_net': petri_net,
            'initial_marking': initial_marking,
            'final_marking': final_marking,
            'dependency_threshold': dependency_threshold
        }

    def discover_alpha_model(self) -> Dict:
        """
        Discover a process model using the Alpha Algorithm.
        
        Alpha algorithm is a classic process discovery technique that produces
        structured Petri nets. Best for well-structured processes.
        
        Returns:
            Dictionary containing Petri net, initial and final markings
            
        Example:
            >>> alpha_model = miner.discover_alpha_model()
            >>> print("Discovered Alpha model (Petri net)")
        """
        if self.event_log is None:
            raise ValueError("Event log not created. Call create_event_log() first.")

        # Discover using Alpha algorithm
        petri_net, initial_marking, final_marking = alpha_miner.apply(self.event_log)

        logger.info("Discovered Alpha algorithm Petri net")
        
        return {
            'petri_net': petri_net,
            'initial_marking': initial_marking,
            'final_marking': final_marking,
            'algorithm': 'alpha'
        }

    def discover_inductive_model(self, noise_threshold: float = 0.0) -> Dict:
        """
        Discover a process model using the Inductive Miner.
        
        Inductive Miner guarantees sound process models (no deadlocks).
        Can handle noise with noise_threshold parameter.
        
        Args:
            noise_threshold: Noise threshold for filtering (0.0 to 1.0)
            
        Returns:
            Dictionary containing process tree and converted Petri net
            
        Example:
            >>> inductive_model = miner.discover_inductive_model(noise_threshold=0.2)
            >>> print("Discovered Inductive Miner model (guaranteed sound)")
        """
        if self.event_log is None:
            raise ValueError("Event log not created. Call create_event_log() first.")

        # Discover process tree using Inductive Miner
        if noise_threshold > 0:
            # Use Inductive Miner - Infrequent (IMf) for noisy logs
            process_tree = pm4py.discover_process_tree_inductive(self.event_log, 
                                                               noise_threshold=noise_threshold)
            algorithm = 'inductive_miner_infrequent'
        else:
            # Use standard Inductive Miner
            process_tree = pm4py.discover_process_tree_inductive(self.event_log)
            algorithm = 'inductive_miner'

        # Convert to Petri net
        petri_net, initial_marking, final_marking = pm4py.convert_to_petri_net(process_tree)

        logger.info(f"Discovered {algorithm} model with noise threshold {noise_threshold}")
        
        return {
            'process_tree': process_tree,
            'petri_net': petri_net,
            'initial_marking': initial_marking,
            'final_marking': final_marking,
            'algorithm': algorithm,
            'noise_threshold': noise_threshold
        }

    def compare_discovery_algorithms(self) -> Dict:
        """
        Compare different process discovery algorithms on the same event log.
        
        This method runs multiple discovery algorithms and compares their results,
        useful for understanding which algorithm works best for your data.
        
        Returns:
            Dictionary containing results from all algorithms
            
        Example:
            >>> comparison = miner.compare_discovery_algorithms()
            >>> print(f"Compared {len(comparison)} different algorithms")
        """
        if self.event_log is None:
            raise ValueError("Event log not created. Call create_event_log() first.")

        results = {}
        
        # 1. DFG Discovery
        try:
            dfg, start_act, end_act = self.discover_dfg()
            results['dfg'] = {
                'transitions': len(dfg),
                'start_activities': len(start_act),
                'end_activities': len(end_act),
                'model_type': 'directly_follows_graph'
            }
        except Exception as e:
            results['dfg'] = {'error': str(e)}

        # 2. Heuristics Miner
        try:
            heu_result = self.discover_heuristics_net()
            results['heuristics'] = {
                'dependency_threshold': heu_result['dependency_threshold'],
                'model_type': 'heuristics_net',
                'places': len(heu_result['petri_net'].places),
                'transitions': len(heu_result['petri_net'].transitions)
            }
        except Exception as e:
            results['heuristics'] = {'error': str(e)}

        # 3. Alpha Algorithm
        try:
            alpha_result = self.discover_alpha_model()
            results['alpha'] = {
                'places': len(alpha_result['petri_net'].places),
                'transitions': len(alpha_result['petri_net'].transitions),
                'model_type': 'petri_net_alpha'
            }
        except Exception as e:
            results['alpha'] = {'error': str(e)}

        # 4. Inductive Miner
        try:
            inductive_result = self.discover_inductive_model()
            results['inductive'] = {
                'algorithm': inductive_result['algorithm'],
                'places': len(inductive_result['petri_net'].places),
                'transitions': len(inductive_result['petri_net'].transitions),
                'model_type': 'process_tree_inductive'
            }
        except Exception as e:
            results['inductive'] = {'error': str(e)}

        # 5. Inductive Miner with noise filtering
        try:
            inductive_noisy = self.discover_inductive_model(noise_threshold=0.2)
            results['inductive_filtered'] = {
                'algorithm': inductive_noisy['algorithm'],
                'noise_threshold': inductive_noisy['noise_threshold'],
                'places': len(inductive_noisy['petri_net'].places),
                'transitions': len(inductive_noisy['petri_net'].transitions),
                'model_type': 'process_tree_inductive_filtered'
            }
        except Exception as e:
            results['inductive_filtered'] = {'error': str(e)}

        logger.info(f"Compared {len([k for k in results.keys() if 'error' not in results[k]])} discovery algorithms")
        
        return results

    def discover_performance_dfg(self) -> Dict:
        """
        Discover a performance-annotated DFG showing time between activities.

        Instead of frequency, this shows average/median time between activities.

        Returns:
            Performance DFG with time measurements

        Example:
            >>> perf_dfg = miner.discover_performance_dfg()
            >>> # Shows average hours between "Admission" -> "Lab Test"
        """
        if self.event_log is None:
            raise ValueError("No event log created. Call create_event_log() first.")

        # Discover performance DFG (shows time between activities)
        self.performance_dfg = dfg_discovery.apply(
            self.event_log, variant=dfg_discovery.Variants.PERFORMANCE
        )

        # Convert seconds to hours for readability
        performance_dfg_hours = {}
        for edge, time_seconds in self.performance_dfg.items():
            performance_dfg_hours[edge] = round(
                time_seconds / 3600, 2
            )  # Convert to hours

        self.performance_dfg = performance_dfg_hours

        logger.info(
            f"Discovered performance DFG with {len(self.performance_dfg)} transitions"
        )

        return self.performance_dfg

    def create_process_matrix(self) -> pd.DataFrame:
        """
        Create a process matrix showing transitions between all activities.

        The matrix shows:
        - Rows: source activities
        - Columns: target activities
        - Values: frequency or time between activities

        Returns:
            DataFrame representing the process matrix

        Example:
            >>> matrix = miner.create_process_matrix()
            >>> print(matrix.loc["Admission", "Lab Test"])  # Transitions from Admission to Lab Test
        """
        if self.dfg is None:
            self.discover_dfg()

        # Get all unique activities
        activities = pm4py.get_event_attribute_values(self.event_log, self.ACTIVITY_KEY)
        activity_list = sorted(list(activities.keys()))

        # Initialize matrix with zeros
        matrix = pd.DataFrame(0, index=activity_list, columns=activity_list)

        # Fill matrix with DFG frequencies
        for (source, target), frequency in self.dfg.items():
            if source in matrix.index and target in matrix.columns:
                matrix.loc[source, target] = frequency

        self.process_matrix = matrix

        logger.info(f"Created process matrix of size {matrix.shape}")

        return self.process_matrix

    def discover_variants(self, top_k: int = 10) -> pd.DataFrame:
        """
        Discover the most common process variants (traces).

        A variant is a unique sequence of activities that cases follow.

        Args:
            top_k: Number of top variants to return

        Returns:
            DataFrame with variant information

        Example:
            >>> variants = miner.discover_variants(top_k=5)
            >>> print(f"Top variant: {variants.iloc[0]['variant']}")
        """
        if self.event_log is None:
            raise ValueError("No event log created. Call create_event_log() first.")

        # Get all variants
        variants = pm4py.get_variants(self.event_log)

        # Create DataFrame with variant information
        variant_data = []
        total_cases = len(self.event_log)

        for variant_str, cases in variants.items():
            variant_data.append(
                {
                    "variant": variant_str,
                    "cases": len(cases),
                    "percentage": round(100 * len(cases) / total_cases, 2),
                    "activities": variant_str.count(",") + 1 if variant_str else 0,
                }
            )

        # Sort by frequency and get top k
        variants_df = pd.DataFrame(variant_data)
        variants_df = variants_df.sort_values("cases", ascending=False).head(top_k)

        self.variants = variants_df

        logger.info(f"Found {len(variants)} unique variants")
        logger.info(f"Top variant covers {variants_df.iloc[0]['percentage']}% of cases")

        return variants_df

    def calculate_process_metrics(self) -> Dict[str, Any]:
        """
        Calculate various process metrics and KPIs.

        Returns:
            Dictionary containing process metrics

        Example:
            >>> metrics = miner.calculate_process_metrics()
            >>> print(f"Average case duration: {metrics['avg_case_duration_hours']} hours")
        """
        if self.event_log is None:
            raise ValueError("No event log created. Call create_event_log() first.")

        metrics = {}

        # Case duration statistics
        case_durations = []
        for case in self.event_log:
            if len(case) > 0:
                duration = (
                    case[-1]["time:timestamp"] - case[0]["time:timestamp"]
                ).total_seconds() / 3600
                case_durations.append(duration)

        if case_durations:
            metrics["avg_case_duration_hours"] = round(np.mean(case_durations), 2)
            metrics["median_case_duration_hours"] = round(np.median(case_durations), 2)
            metrics["min_case_duration_hours"] = round(np.min(case_durations), 2)
            metrics["max_case_duration_hours"] = round(np.max(case_durations), 2)

        # Activity statistics
        activities = pm4py.get_event_attribute_values(self.event_log, self.ACTIVITY_KEY)
        metrics["num_activities"] = len(activities)
        metrics["total_events"] = sum(activities.values())
        metrics["num_cases"] = len(self.event_log)
        metrics["avg_events_per_case"] = round(
            metrics["total_events"] / metrics["num_cases"], 2
        )

        # Most frequent activities
        top_activities = sorted(activities.items(), key=lambda x: x[1], reverse=True)[
            :5
        ]
        metrics["top_5_activities"] = [
            {"activity": act, "count": count} for act, count in top_activities
        ]

        # Variant statistics
        if self.variants is not None:
            metrics["num_variants"] = len(self.variants)
            metrics["top_variant_coverage"] = f"{self.variants.iloc[0]['percentage']}%"

        return metrics

    def export_results(self, output_dir: str = ".") -> Dict[str, str]:
        """
        Export all analysis results to files.

        Args:
            output_dir: Directory to save results

        Returns:
            Dictionary with paths to exported files

        Example:
            >>> paths = miner.export_results("./results")
            >>> print(f"Process map saved to: {paths['process_map']}")
        """
        output_dir = Path(output_dir)
        output_dir.mkdir(exist_ok=True)

        exported_files = {}

        # Export DFG as JSON
        if self.dfg is not None:
            dfg_data = {
                "dfg": {str(k): v for k, v in self.dfg.items()},
                "start_activities": pm4py.get_start_activities(self.event_log),
                "end_activities": pm4py.get_end_activities(self.event_log),
            }

            dfg_path = output_dir / "process_map.json"
            with open(dfg_path, "w") as f:
                json.dump(dfg_data, f, indent=2, default=str)
            exported_files["process_map"] = str(dfg_path)
            logger.info(f"Exported DFG to {dfg_path}")

        # Export process matrix
        if self.process_matrix is not None:
            matrix_path = output_dir / "process_matrix.csv"
            self.process_matrix.to_csv(matrix_path)
            exported_files["process_matrix"] = str(matrix_path)
            logger.info(f"Exported process matrix to {matrix_path}")

        # Export variants
        if self.variants is not None:
            variants_path = output_dir / "variants.csv"
            self.variants.to_csv(variants_path, index=False)
            exported_files["variants"] = str(variants_path)
            logger.info(f"Exported variants to {variants_path}")

        # Export metrics
        metrics = self.calculate_process_metrics()
        metrics_path = output_dir / "metrics.json"
        with open(metrics_path, "w") as f:
            json.dump(metrics, f, indent=2, default=str)
        exported_files["metrics"] = str(metrics_path)
        logger.info(f"Exported metrics to {metrics_path}")

        return exported_files

    def visualize_dfg(self, output_path: str = "process_map.png") -> None:
        """
        Visualize the DFG and save as image.

        Note: Requires Graphviz to be installed on the system.

        Args:
            output_path: Path to save the visualization

        Example:
            >>> miner.visualize_dfg("my_process.png")
        """
        if self.dfg is None:
            self.discover_dfg()

        try:
            # Get start and end activities for visualization
            start_activities = pm4py.get_start_activities(self.event_log)
            end_activities = pm4py.get_end_activities(self.event_log)

            # Create and save visualization
            pm4py.save_vis_dfg(self.dfg, start_activities, end_activities, output_path)

            logger.info(f"Saved DFG visualization to {output_path}")

        except Exception as e:
            logger.error(f"Error creating visualization: {e}")
            logger.info("Make sure Graphviz is installed on your system")


def main():
    """
    Example usage of the ProcessMiner class.

    This demonstrates the complete process mining pipeline.
    """
    # Import data loader from step 1
    from step1_data_loader import EventLogLoader

    print("=" * 60)
    print("STEP 2: PROCESS MINING ANALYSIS")
    print("=" * 60)

    # Load and prepare data (from Step 1)
    print("\n1. Loading data...")
    loader = EventLogLoader("sepsisAgregated_Infection.csv")
    loader.load_data()
    prepared_data = loader.prepare_data()

    # Filter for sepsis cases
    sepsis_data = loader.filter_by_outcome(sepsis_only=True)

    # Initialize process miner
    print("\n2. Initializing process miner...")
    miner = ProcessMiner()

    # Create PM4PY event log
    print("\n3. Creating PM4PY event log...")
    event_log = miner.create_event_log(sepsis_data)
    print(f"   Event log contains {len(event_log)} cases")

    # Discover DFG
    print("\n4. Discovering Directly-Follows Graph...")
    dfg, starts, ends = miner.discover_dfg()
    print(f"   Found {len(dfg)} transitions")
    print(f"   Start activities: {list(starts.keys())[:3]}...")

    # Discover performance DFG
    print("\n5. Discovering performance metrics...")
    perf_dfg = miner.discover_performance_dfg()
    print(f"   Calculated time for {len(perf_dfg)} transitions")

    # Create process matrix
    print("\n6. Creating process matrix...")
    matrix = miner.create_process_matrix()
    print(f"   Matrix shape: {matrix.shape}")

    # Discover variants
    print("\n7. Discovering process variants...")
    variants = miner.discover_variants(top_k=5)
    print(f"   Top variant covers {variants.iloc[0]['percentage']}% of cases")

    # Calculate metrics
    print("\n8. Calculating process metrics...")
    metrics = miner.calculate_process_metrics()
    print(f"   Average case duration: {metrics['avg_case_duration_hours']} hours")
    print(f"   Number of unique activities: {metrics['num_activities']}")

    # Export results
    print("\n9. Exporting results...")
    exported = miner.export_results("./process_mining_results")
    print(f"   Exported {len(exported)} files")

    # Try to visualize (if Graphviz is installed)
    print("\n10. Creating visualization...")
    try:
        miner.visualize_dfg("sepsis_process.png")
        print("   Visualization saved successfully")
    except:
        print("   Visualization failed (Graphviz may not be installed)")

    print("\n" + "=" * 60)
    print("Process mining analysis complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
