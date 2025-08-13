#!/usr/bin/env python3
"""Module: step4_advanced_analytics"""

"""
STEP 4: ADVANCED ANALYTICS AND METHODOLOGICAL APPROACHES
=========================================================
This module implements advanced process mining techniques inspired by
state-of-the-art healthcare research methodologies.

Learning Goals:
- Implement conformance checking for clinical guidelines
- Apply trace clustering for patient stratification
- Perform bottleneck analysis and resource optimization
- Calculate clinical performance indicators
- Implement predictive process monitoring

Based on methodological approaches from recent healthcare process mining research,
including techniques for analyzing complex clinical pathways and outcome prediction.
"""

# UNUSED: import pandas as pd
import numpy as np
from typing import Dict, List, Tuple, Any, Optional
from datetime import datetime, timedelta
import logging
from sklearn.cluster import KMeans, DBSCAN
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score

# UNUSED: import pm4py
from pm4py.algo.conformance.tokenreplay import algorithm as token_replay
from pm4py.algo.evaluation.replay_fitness import algorithm as replay_fitness

# from pm4py.algo.enhancement import algorithm as enhancement  # Removed in newer pm4py
# Modern pm4py API for statistics
import pm4py.stats as pm4py_stats
from scipy import stats
import warnings

warnings.filterwarnings("ignore")

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class AdvancedProcessAnalyzer:
    """
    Implements advanced process mining techniques for healthcare data.

    This class provides methods for:
    1. Conformance checking against clinical guidelines
    2. Patient cohort clustering and stratification
    3. Bottleneck and performance analysis
    4. Predictive monitoring and outcome prediction
    5. Resource utilization analysis
    """

    def __init__(self, event_log):
        """
        Initialize the advanced analyzer.

        Args:
            event_log: PM4PY event log object
        """
        self.event_log = event_log
        self.conformance_results = None
        self.clusters = None
        self.performance_metrics = None

        logger.info("Initialized Advanced Process Analyzer")

    def check_guideline_conformance(
        self, reference_model: Any, guideline_name: str = "Clinical Guideline"
    ) -> Dict:
        """
        Check conformance of actual processes against clinical guidelines.

        This method implements token-based replay to identify deviations
        from expected clinical pathways, similar to approaches used in
        sepsis guideline compliance studies.

        Args:
            reference_model: The reference process model (Petri net, BPMN, etc.)
            guideline_name: Name of the clinical guideline

        Returns:
            Dictionary containing conformance metrics and violations
        """
        logger.info(f"Checking conformance against {guideline_name}")

        # Perform token-based replay
        replayed_traces = token_replay.apply(
            self.event_log,
            reference_model["net"],
            reference_model["initial_marking"],
            reference_model["final_marking"],
        )

        # Calculate fitness metrics
        fitness = replay_fitness.evaluate(
            replayed_traces, variant=replay_fitness.Variants.TOKEN_BASED
        )

        # Analyze deviations
        deviations = self._analyze_deviations(replayed_traces)

        # Calculate compliance rate
        compliant_cases = sum(1 for trace in replayed_traces if trace["trace_is_fit"])
        total_cases = len(replayed_traces)
        compliance_rate = compliant_cases / total_cases if total_cases > 0 else 0

        self.conformance_results = {
            "guideline": guideline_name,
            "fitness": fitness,
            "compliance_rate": compliance_rate,
            "compliant_cases": compliant_cases,
            "total_cases": total_cases,
            "deviations": deviations,
            "timestamp": datetime.now(),
        }

        logger.info(f"Conformance check complete: {compliance_rate:.1%} compliance")

        return self.conformance_results

    def _analyze_deviations(self, replayed_traces: List) -> Dict:
        """
        Analyze and categorize deviations from the reference model.

        Returns:
            Dictionary of deviation types and their frequencies
        """
        deviation_types = {
            "missing_activities": [],
            "additional_activities": [],
            "wrong_order": [],
            "timing_violations": [],
        }

        for trace in replayed_traces:
            if not trace["trace_is_fit"]:
                # Analyze missing tokens (missing activities)
                if trace.get("missing_tokens", 0) > 0:
                    deviation_types["missing_activities"].append(
                        {
                            "case": trace["trace"]["attributes"]["concept:name"],
                            "count": trace["missing_tokens"],
                        }
                    )

                # Analyze remaining tokens (additional activities)
                if trace.get("remaining_tokens", 0) > 0:
                    deviation_types["additional_activities"].append(
                        {
                            "case": trace["trace"]["attributes"]["concept:name"],
                            "count": trace["remaining_tokens"],
                        }
                    )

        return deviation_types

    def cluster_patient_pathways(
        self,
        n_clusters: Optional[int] = None,
        method: str = "kmeans",
        features: List[str] = None,
    ) -> Dict:
        """
        Cluster patients based on their process patterns.

        This implements patient stratification based on pathway similarity,
        useful for identifying subgroups with different care patterns or outcomes.

        Args:
            n_clusters: Number of clusters (None for automatic detection)
            method: Clustering method ('kmeans', 'dbscan', 'hierarchical')
            features: List of features to use for clustering

        Returns:
            Dictionary containing cluster assignments and characteristics
        """
        logger.info(f"Clustering patient pathways using {method}")

        # Extract features for clustering
        feature_matrix = self._extract_pathway_features(features)

        # Standardize features
        scaler = StandardScaler()
        scaled_features = scaler.fit_transform(feature_matrix)

        # Determine optimal number of clusters if not specified
        if n_clusters is None and method == "kmeans":
            n_clusters = self._find_optimal_clusters(scaled_features)

        # Perform clustering
        if method == "kmeans":
            clusterer = KMeans(n_clusters=n_clusters, random_state=42)
            clusters = clusterer.fit_predict(scaled_features)
        elif method == "dbscan":
            clusterer = DBSCAN(eps=0.5, min_samples=5)
            clusters = clusterer.fit_predict(scaled_features)
        else:
            raise ValueError(f"Unsupported clustering method: {method}")

        # Calculate cluster quality metrics
        if len(set(clusters)) > 1:
            silhouette = silhouette_score(scaled_features, clusters)
        else:
            silhouette = -1

        # Analyze cluster characteristics
        cluster_profiles = self._analyze_clusters(clusters, feature_matrix)

        self.clusters = {
            "method": method,
            "n_clusters": len(set(clusters)) - (1 if -1 in clusters else 0),
            "assignments": clusters,
            "silhouette_score": silhouette,
            "cluster_profiles": cluster_profiles,
            "feature_importance": self._calculate_feature_importance(
                scaled_features, clusters
            ),
        }

        logger.info(f"Identified {self.clusters['n_clusters']} patient clusters")

        return self.clusters

    def _extract_pathway_features(
        self, feature_list: Optional[List[str]] = None
    ) -> np.ndarray:
        """
        Extract features from event log for clustering.

        Features include:
        - Process complexity metrics
        - Temporal patterns
        - Activity frequencies
        - Resource utilization
        """
        features = []

        for case in self.event_log:
            case_features = []

            # Basic metrics
            case_features.append(len(case))  # Number of events

            # Time-based features
            if len(case) > 0:
                duration = (
                    case[-1]["time:timestamp"] - case[0]["time:timestamp"]
                ).total_seconds() / 3600
                case_features.append(duration)
            else:
                case_features.append(0)

            # Activity diversity
            unique_activities = len(set(event["concept:name"] for event in case))
            case_features.append(unique_activities)

            # Loop detection (activity repetitions)
            activities = [event["concept:name"] for event in case]
            repetitions = len(activities) - len(set(activities))
            case_features.append(repetitions)

            # Add clinical features if available
            if "SepsisLabel" in case[0]:
                case_features.append(case[0]["SepsisLabel"])

            features.append(case_features)

        return np.array(features)

    def _find_optimal_clusters(self, data: np.ndarray, max_k: int = 10) -> int:
        """
        Find optimal number of clusters using elbow method and silhouette analysis.
        """
        scores = []
        k_range = range(2, min(max_k, len(data)))

        for k in k_range:
            kmeans = KMeans(n_clusters=k, random_state=42)
            labels = kmeans.fit_predict(data)
            score = silhouette_score(data, labels)
            scores.append(score)

        # Find elbow point
        if scores:
            optimal_k = k_range[np.argmax(scores)]
        else:
            optimal_k = 3  # Default

        return optimal_k

    def _analyze_clusters(self, clusters: np.ndarray, features: np.ndarray) -> Dict:
        """
        Analyze characteristics of each cluster.
        """
        cluster_profiles = {}

        for cluster_id in set(clusters):
            if cluster_id == -1:  # Skip noise in DBSCAN
                continue

            cluster_mask = clusters == cluster_id
            cluster_features = features[cluster_mask]

            profile = {
                "size": np.sum(cluster_mask),
                "percentage": np.mean(cluster_mask) * 100,
                "avg_length": np.mean(cluster_features[:, 0]),
                "avg_duration": np.mean(cluster_features[:, 1]),
                "avg_activities": np.mean(cluster_features[:, 2]),
                "avg_repetitions": np.mean(cluster_features[:, 3]),
            }

            # Add outcome statistics if available
            if features.shape[1] > 4:
                profile["sepsis_rate"] = np.mean(cluster_features[:, 4])

            cluster_profiles[f"cluster_{cluster_id}"] = profile

        return cluster_profiles

    def _calculate_feature_importance(
        self, features: np.ndarray, clusters: np.ndarray
    ) -> Dict:
        """
        Calculate which features best distinguish clusters.
        """
        importance = {}
        feature_names = [
            "event_count",
            "duration",
            "unique_activities",
            "repetitions",
            "sepsis_label",
        ]

        for i, name in enumerate(feature_names[: features.shape[1]]):
            # Calculate F-statistic for each feature
            groups = [features[clusters == c, i] for c in set(clusters) if c != -1]
            if len(groups) > 1:
                f_stat, p_value = stats.f_oneway(*groups)
                importance[name] = {
                    "f_statistic": f_stat,
                    "p_value": p_value,
                    "significant": p_value < 0.05,
                }

        return importance

    def analyze_bottlenecks(self, threshold_percentile: float = 75) -> Dict:
        """
        Identify bottlenecks in the clinical process.

        This method identifies activities and transitions that cause delays,
        similar to emergency department flow analysis.

        Args:
            threshold_percentile: Percentile to define bottleneck threshold

        Returns:
            Dictionary containing bottleneck analysis results
        """
        logger.info("Analyzing process bottlenecks")

        # Calculate sojourn times (waiting times at each activity)
        # Using simplified approach for newer pm4py API
        sojourn_times = {}
        for case in self.event_log:
            prev_time = None
            for event in case:
                activity = event["concept:name"]
                if prev_time is not None:
                    wait_time = (event["time:timestamp"] - prev_time).total_seconds()
                    if activity not in sojourn_times:
                        sojourn_times[activity] = []
                    sojourn_times[activity].append(wait_time)
                prev_time = event["time:timestamp"]

        # Identify bottlenecks based on threshold
        bottlenecks = []

        for activity, times in sojourn_times.items():
            if times:
                avg_time = np.mean(times)
                max_time = np.max(times)
                p75_time = np.percentile(times, threshold_percentile)

                bottlenecks.append(
                    {
                        "activity": activity,
                        "avg_wait_hours": avg_time / 3600,
                        "max_wait_hours": max_time / 3600,
                        "p75_wait_hours": p75_time / 3600,
                        "cases_affected": len(times),
                    }
                )

        # Sort by average wait time
        bottlenecks.sort(key=lambda x: x["avg_wait_hours"], reverse=True)

        # Calculate overall process efficiency
        total_time = sum(b["avg_wait_hours"] * b["cases_affected"] for b in bottlenecks)
        total_cases = sum(b["cases_affected"] for b in bottlenecks)

        results = {
            "bottlenecks": bottlenecks[:10],  # Top 10 bottlenecks
            "avg_total_wait": total_time / total_cases if total_cases > 0 else 0,
            "critical_activities": [b["activity"] for b in bottlenecks[:5]],
            "improvement_potential": self._calculate_improvement_potential(bottlenecks),
        }

        logger.info(f"Identified {len(bottlenecks)} bottleneck activities")

        return results

    def _calculate_improvement_potential(self, bottlenecks: List[Dict]) -> Dict:
        """
        Calculate potential time savings from bottleneck optimization.
        """
        if not bottlenecks:
            return {"hours_saveable": 0, "percentage_reduction": 0}

        # Calculate potential savings if top bottlenecks reduced to median
        total_current = sum(
            b["avg_wait_hours"] * b["cases_affected"] for b in bottlenecks
        )

        # Simulate improvement: reduce top 3 bottlenecks by 50%
        total_improved = total_current
        for b in bottlenecks[:3]:
            savings = b["avg_wait_hours"] * b["cases_affected"] * 0.5
            total_improved -= savings

        return {
            "hours_saveable": total_current - total_improved,
            "percentage_reduction": (
                ((total_current - total_improved) / total_current * 100)
                if total_current > 0
                else 0
            ),
        }

    def calculate_clinical_kpis(self) -> Dict:
        """
        Calculate key performance indicators relevant to clinical processes.

        Returns:
            Dictionary of clinical KPIs
        """
        logger.info("Calculating clinical KPIs")

        kpis = {}

        # Process efficiency metrics
        case_durations = []
        for case in self.event_log:
            if len(case) > 0:
                duration = (
                    case[-1]["time:timestamp"] - case[0]["time:timestamp"]
                ).total_seconds() / 3600
                case_durations.append(duration)

        if case_durations:
            kpis["avg_length_of_stay"] = np.mean(case_durations)
            kpis["median_length_of_stay"] = np.median(case_durations)
            kpis["p90_length_of_stay"] = np.percentile(case_durations, 90)

        # Throughput metrics
        kpis["daily_admissions"] = self._calculate_daily_admissions()
        kpis["bed_turnover_rate"] = len(self.event_log) / 30  # Assuming 30-day period

        # Clinical outcome metrics
        kpis["readmission_rate"] = self._calculate_readmission_rate()
        kpis["mortality_rate"] = self._calculate_mortality_rate()

        # Resource utilization
        kpis["resource_utilization"] = self._calculate_resource_utilization()

        # Compliance and quality
        if self.conformance_results:
            kpis["guideline_compliance"] = self.conformance_results["compliance_rate"]

        self.performance_metrics = kpis

        logger.info("Clinical KPI calculation complete")

        return kpis

    def _calculate_daily_admissions(self) -> float:
        """Calculate average daily admissions."""
        admission_dates = []

        for case in self.event_log:
            if len(case) > 0:
                admission_dates.append(case[0]["time:timestamp"].date())

        if admission_dates:
            unique_dates = len(set(admission_dates))
            return len(admission_dates) / unique_dates if unique_dates > 0 else 0

        return 0

    def _calculate_readmission_rate(self) -> float:
        """
        Calculate 30-day readmission rate.

        Note: This is a simplified calculation. Real implementation would
        need patient identifiers and discharge dates.
        """
        # Placeholder implementation
        # In real scenario, track patient readmissions within 30 days
        return 0.15  # Example: 15% readmission rate

    def _calculate_mortality_rate(self) -> float:
        """Calculate in-hospital mortality rate."""
        mortality_count = 0
        total_cases = len(self.event_log)

        for case in self.event_log:
            # Check if last event indicates mortality
            if len(case) > 0:
                last_event = case[-1]["concept:name"]
                if "death" in last_event.lower() or "mortality" in last_event.lower():
                    mortality_count += 1

        return mortality_count / total_cases if total_cases > 0 else 0

    def _calculate_resource_utilization(self) -> Dict:
        """Calculate resource utilization metrics."""
        resource_events = {}

        for case in self.event_log:
            for event in case:
                if "org:resource" in event:
                    resource = event["org:resource"]
                    if resource not in resource_events:
                        resource_events[resource] = 0
                    resource_events[resource] += 1

        # Calculate utilization percentages
        total_events = sum(resource_events.values())
        utilization = {}

        for resource, count in resource_events.items():
            utilization[resource] = {
                "events": count,
                "percentage": (count / total_events * 100) if total_events > 0 else 0,
            }

        return utilization

    def predict_case_outcome(
        self, partial_trace: List[Dict], outcome_type: str = "sepsis"
    ) -> Dict:
        """
        Predict the outcome of an ongoing case based on partial trace.

        This implements predictive process monitoring for early warning systems.

        Args:
            partial_trace: List of events that have occurred so far
            outcome_type: Type of outcome to predict

        Returns:
            Dictionary containing prediction and confidence
        """
        logger.info(f"Predicting {outcome_type} outcome for partial trace")

        # Extract features from partial trace
        features = self._extract_trace_features(partial_trace)

        # Simple rule-based prediction (replace with ML model in production)
        risk_score = 0
        risk_factors = []

        # Check for high-risk patterns
        activities = [event["concept:name"] for event in partial_trace]

        if "High Temperature" in activities:
            risk_score += 30
            risk_factors.append("High temperature detected")

        if "Infection" in activities:
            risk_score += 40
            risk_factors.append("Infection present")

        if len(partial_trace) > 5:
            risk_score += 15
            risk_factors.append("Extended length of stay")

        # Calculate time in hospital
        if len(partial_trace) > 0:
            time_elapsed = (
                partial_trace[-1]["time:timestamp"] - partial_trace[0]["time:timestamp"]
            ).total_seconds() / 3600
            if time_elapsed > 24:
                risk_score += 15
                risk_factors.append("Over 24 hours in hospital")

        prediction = {
            "outcome": outcome_type,
            "risk_score": min(risk_score, 100),
            "risk_level": self._categorize_risk(risk_score),
            "risk_factors": risk_factors,
            "confidence": 0.75,  # Placeholder confidence
            "recommended_actions": self._get_recommendations(risk_score, outcome_type),
        }

        return prediction

    def _extract_trace_features(self, trace: List[Dict]) -> np.ndarray:
        """Extract features from a trace for prediction."""
        features = []

        # Number of events
        features.append(len(trace))

        # Unique activities
        unique_activities = len(set(event["concept:name"] for event in trace))
        features.append(unique_activities)

        # Time elapsed
        if len(trace) > 0:
            duration = (
                trace[-1]["time:timestamp"] - trace[0]["time:timestamp"]
            ).total_seconds() / 3600
            features.append(duration)
        else:
            features.append(0)

        return np.array(features)

    def _categorize_risk(self, risk_score: float) -> str:
        """Categorize risk level based on score."""
        if risk_score >= 70:
            return "HIGH"
        elif risk_score >= 40:
            return "MODERATE"
        else:
            return "LOW"

    def _get_recommendations(self, risk_score: float, outcome_type: str) -> List[str]:
        """Get clinical recommendations based on risk assessment."""
        recommendations = []

        if risk_score >= 70:
            recommendations.extend(
                [
                    "Immediate clinical review required",
                    "Consider ICU consultation",
                    "Initiate sepsis protocol",
                    "Order comprehensive lab panel",
                ]
            )
        elif risk_score >= 40:
            recommendations.extend(
                [
                    "Increase monitoring frequency",
                    "Review antibiotic therapy",
                    "Consider specialist consultation",
                    "Monitor vital signs closely",
                ]
            )
        else:
            recommendations.extend(
                ["Continue standard care", "Regular monitoring", "Document progress"]
            )

        return recommendations


def demonstrate_advanced_analytics():
    """
    Demonstrate advanced analytics capabilities.
    """
    from step1_data_loader import EventLogLoader
    from step2_process_mining import ProcessMiner

    print("=" * 60)
    print("ADVANCED PROCESS MINING ANALYTICS")
    print("=" * 60)

    # Load and prepare data
    print("\n1. Loading sepsis event data...")
    loader = EventLogLoader("sepsisAgregated_Infection.csv")
    data = loader.load_data()
    prepared_data = loader.prepare_data()

    # Create event log
    print("\n2. Creating PM4PY event log...")
    miner = ProcessMiner()
    event_log = miner.create_event_log(prepared_data)

    # Initialize advanced analyzer
    print("\n3. Initializing advanced analytics...")
    analyzer = AdvancedProcessAnalyzer(event_log)

    # Cluster patient pathways
    print("\n4. Clustering patient pathways...")
    clusters = analyzer.cluster_patient_pathways(n_clusters=3, method="kmeans")
    print(f"   Found {clusters['n_clusters']} patient clusters")
    print(f"   Silhouette score: {clusters['silhouette_score']:.3f}")

    for cluster_id, profile in clusters["cluster_profiles"].items():
        print(f"\n   {cluster_id}:")
        print(f"     Size: {profile['size']} patients ({profile['percentage']:.1f}%)")
        print(f"     Avg duration: {profile['avg_duration']:.1f} hours")
        if "sepsis_rate" in profile:
            print(f"     Sepsis rate: {profile['sepsis_rate']:.1%}")

    # Analyze bottlenecks
    print("\n5. Analyzing process bottlenecks...")
    bottlenecks = analyzer.analyze_bottlenecks()
    print("   Top bottlenecks:")
    for bottleneck in bottlenecks["bottlenecks"][:3]:
        print(
            f"     {bottleneck['activity']}: avg wait {bottleneck['avg_wait_hours']:.1f} hours"
        )
    print(
        f"   Improvement potential: {bottlenecks['improvement_potential']['percentage_reduction']:.1f}% reduction possible"
    )

    # Calculate clinical KPIs
    print("\n6. Calculating clinical KPIs...")
    kpis = analyzer.calculate_clinical_kpis()
    print(f"   Average length of stay: {kpis['avg_length_of_stay']:.1f} hours")
    print(f"   Daily admissions: {kpis['daily_admissions']:.1f}")
    print(f"   Bed turnover rate: {kpis['bed_turnover_rate']:.1f}")

    # Predict outcome for a sample case
    print("\n7. Demonstrating predictive monitoring...")
    if len(event_log) > 0:
        # Take first 3 events of first case as partial trace
        sample_case = event_log[0][:3]
        prediction = analyzer.predict_case_outcome(sample_case, "sepsis")
        print(f"   Risk score: {prediction['risk_score']}/100")
        print(f"   Risk level: {prediction['risk_level']}")
        print(f"   Risk factors: {', '.join(prediction['risk_factors'])}")
        print("   Recommendations:")
        for rec in prediction["recommended_actions"][:2]:
            print(f"     - {rec}")

    print("\n" + "=" * 60)
    print("Advanced analytics demonstration complete!")
    print("=" * 60)


if __name__ == "__main__":
    demonstrate_advanced_analytics()
