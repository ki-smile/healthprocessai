#!/usr/bin/env python3
"""Module: example_transform_raw_to_eventlog"""

"""
EXAMPLE: TRANSFORMING RAW HEALTHCARE DATA TO EVENT LOGS
========================================================
This example demonstrates how to transform raw healthcare/epidemiological data
into event logs suitable for process mining, following the approach from
PhysioNet Challenge 2019 and similar to methods proposed by Kaile Chen et al.

The PhysioNet Challenge 2019 focused on early prediction of sepsis from clinical data.
This example shows how to transform such raw clinical measurements into event logs
for process mining analysis.

Data source reference: https://physionet.org/content/challenge-2019/1.0.0/

Developed at SMAILE, Karolinska Institutet
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
import logging
from scipy import stats

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)


class HealthcareDataTransformer:
    """
    Transforms raw healthcare data (vital signs, lab results, etc.) into event logs.

    This class implements methods to:
    1. Process time-series clinical data
    2. Detect clinical events from continuous measurements
    3. Create event logs from state transitions
    4. Handle missing data and irregular sampling

    Based on approaches from PhysioNet Challenge and research papers on
    healthcare process mining.
    """

    def __init__(self):
        """Initialize the transformer."""
        self.raw_data = None
        self.event_log = None

        # Define clinical thresholds (based on medical literature)
        self.thresholds = {
            "HR": {"low": 60, "high": 100},  # Heart rate
            "BP_sys": {"low": 90, "high": 140},  # Systolic BP
            "BP_dias": {"low": 60, "high": 90},  # Diastolic BP
            "Temp": {"low": 36.0, "high": 38.0},  # Temperature
            "SpO2": {"low": 95, "high": 100},  # Oxygen saturation
            "Resp": {"low": 12, "high": 20},  # Respiratory rate
            "WBC": {"low": 4.5, "high": 11.0},  # White blood cells
            "Lactate": {"low": 0, "high": 2.0},  # Lactate
            "Creatinine": {"low": 0.6, "high": 1.2},  # Creatinine
            "Platelets": {"low": 150, "high": 400},  # Platelets
            "Bilirubin": {"low": 0, "high": 1.2},  # Bilirubin
        }

        # SOFA score components for sepsis detection
        self.sofa_components = {
            "respiratory": ["SpO2", "FiO2"],
            "coagulation": ["Platelets"],
            "liver": ["Bilirubin"],
            "cardiovascular": ["BP_sys", "BP_dias"],
            "cns": ["GCS"],
            "renal": ["Creatinine", "Urine"],
        }

    def create_physionet_style_data(self, n_patients: int = 50) -> pd.DataFrame:
        """
        Create synthetic data similar to PhysioNet Challenge 2019 format.

        The PhysioNet data contains:
        - Time-series vital signs and lab values
        - Irregular sampling intervals
        - Missing values
        - Sepsis labels

        Args:
            n_patients: Number of patients to simulate

        Returns:
            DataFrame with raw clinical time-series data
        """
        logger.info(
            f"Creating synthetic PhysioNet-style data for {n_patients} patients..."
        )

        all_data = []

        for patient_id in range(1, n_patients + 1):
            # Determine if patient develops sepsis
            develops_sepsis = np.random.random() < 0.3

            # Generate time points (irregular sampling)
            n_timepoints = np.random.randint(20, 100)
            hours = np.sort(np.random.uniform(0, 72, n_timepoints))

            # Initialize patient data
            patient_data = []

            # Generate vital signs with trends
            base_hr = np.random.normal(75, 10)
            base_temp = np.random.normal(37, 0.5)
            base_bp_sys = np.random.normal(120, 15)
            base_spo2 = np.random.normal(97, 2)
            base_resp = np.random.normal(16, 3)

            # Sepsis progression parameters
            if develops_sepsis:
                sepsis_onset = np.random.uniform(12, 48)
                sepsis_severity = np.random.uniform(0.5, 1.5)

            for i, hour in enumerate(hours):
                # Create deterioration if sepsis
                if develops_sepsis and hour > sepsis_onset:
                    deterioration = (hour - sepsis_onset) * sepsis_severity / 10
                else:
                    deterioration = 0

                # Generate measurements with missing values
                measurements = {
                    "Patient_ID": f"P{patient_id:04d}",
                    "Hour": hour,
                    "HR": (
                        base_hr + np.random.normal(0, 5) + deterioration * 15
                        if np.random.random() > 0.1
                        else np.nan
                    ),
                    "Temp": (
                        base_temp + np.random.normal(0, 0.3) + deterioration * 0.5
                        if np.random.random() > 0.15
                        else np.nan
                    ),
                    "BP_sys": (
                        base_bp_sys - np.random.normal(0, 8) - deterioration * 10
                        if np.random.random() > 0.1
                        else np.nan
                    ),
                    "BP_dias": (
                        (base_bp_sys * 0.6) - np.random.normal(0, 5) - deterioration * 5
                        if np.random.random() > 0.1
                        else np.nan
                    ),
                    "SpO2": (
                        base_spo2 - np.random.normal(0, 2) - deterioration * 3
                        if np.random.random() > 0.1
                        else np.nan
                    ),
                    "Resp": (
                        base_resp + np.random.normal(0, 2) + deterioration * 4
                        if np.random.random() > 0.1
                        else np.nan
                    ),
                }

                # Lab values (less frequent)
                if np.random.random() < 0.2:  # 20% chance of lab values
                    measurements.update(
                        {
                            "WBC": (
                                np.random.normal(7, 3) + deterioration * 4
                                if develops_sepsis
                                else np.random.normal(7, 2)
                            ),
                            "Lactate": (
                                np.random.normal(1, 0.5) + deterioration * 2
                                if develops_sepsis
                                else np.random.normal(1, 0.3)
                            ),
                            "Creatinine": (
                                np.random.normal(0.9, 0.3) + deterioration * 0.3
                                if develops_sepsis
                                else np.random.normal(0.9, 0.2)
                            ),
                            "Platelets": (
                                np.random.normal(250, 50) - deterioration * 30
                                if develops_sepsis
                                else np.random.normal(250, 40)
                            ),
                        }
                    )
                else:
                    measurements.update(
                        {
                            "WBC": np.nan,
                            "Lactate": np.nan,
                            "Creatinine": np.nan,
                            "Platelets": np.nan,
                        }
                    )

                # Sepsis label
                measurements["SepsisLabel"] = (
                    1 if develops_sepsis and hour > sepsis_onset else 0
                )

                patient_data.append(measurements)

            all_data.extend(patient_data)

        df = pd.DataFrame(all_data)
        logger.info(f"Created {len(df)} time points for {n_patients} patients")

        return df

    def detect_state_transitions(self, df: pd.DataFrame, variable: str) -> List[Dict]:
        """
        Detect state transitions in a clinical variable.

        States are defined as: Low, Normal, High based on clinical thresholds.

        Args:
            df: DataFrame with time-series data for one patient
            variable: Variable name to analyze

        Returns:
            List of state transition events
        """
        if variable not in self.thresholds:
            return []

        events = []
        thresholds = self.thresholds[variable]

        # Get non-null values
        valid_data = df[df[variable].notna()].copy()
        if valid_data.empty:
            return []

        # Classify states
        valid_data["state"] = "Normal"
        valid_data.loc[valid_data[variable] < thresholds["low"], "state"] = "Low"
        valid_data.loc[valid_data[variable] > thresholds["high"], "state"] = "High"

        # Detect transitions
        previous_state = None
        for idx, row in valid_data.iterrows():
            current_state = row["state"]

            if previous_state and current_state != previous_state:
                # State transition detected
                event = {
                    "timestamp": row["Hour"],
                    "activity": f"{variable}_{previous_state}_to_{current_state}",
                    "resource": "Monitoring_System",
                    "value": row[variable],
                }
                events.append(event)

            # Also record abnormal states as events
            if current_state != "Normal" and (
                previous_state != current_state or previous_state is None
            ):
                event = {
                    "timestamp": row["Hour"],
                    "activity": f"{variable}_{current_state}",
                    "resource": "Alert_System",
                    "value": row[variable],
                }
                events.append(event)

            previous_state = current_state

        return events

    def calculate_risk_scores(self, df: pd.DataFrame) -> List[Dict]:
        """
        Calculate clinical risk scores (SIRS, qSOFA) and create events.

        Args:
            df: DataFrame with patient data

        Returns:
            List of risk score events
        """
        events = []

        for idx, row in df.iterrows():
            # SIRS criteria
            sirs_score = 0
            if not pd.isna(row.get("Temp", np.nan)):
                if row["Temp"] < 36 or row["Temp"] > 38:
                    sirs_score += 1
            if not pd.isna(row.get("HR", np.nan)):
                if row["HR"] > 90:
                    sirs_score += 1
            if not pd.isna(row.get("Resp", np.nan)):
                if row["Resp"] > 20:
                    sirs_score += 1
            if not pd.isna(row.get("WBC", np.nan)):
                if row["WBC"] < 4 or row["WBC"] > 12:
                    sirs_score += 1

            # Create event if SIRS >= 2
            if sirs_score >= 2:
                events.append(
                    {
                        "timestamp": row["Hour"],
                        "activity": f"SIRS_Alert_Score_{sirs_score}",
                        "resource": "Clinical_Decision_Support",
                        "value": sirs_score,
                    }
                )

            # qSOFA criteria
            qsofa_score = 0
            if not pd.isna(row.get("Resp", np.nan)):
                if row["Resp"] >= 22:
                    qsofa_score += 1
            if not pd.isna(row.get("BP_sys", np.nan)):
                if row["BP_sys"] <= 100:
                    qsofa_score += 1
            # GCS would be needed for complete qSOFA

            # Create event if qSOFA >= 2
            if qsofa_score >= 2:
                events.append(
                    {
                        "timestamp": row["Hour"],
                        "activity": "qSOFA_Alert",
                        "resource": "Clinical_Decision_Support",
                        "value": qsofa_score,
                    }
                )

        return events

    def transform_to_event_log(self, raw_data: pd.DataFrame) -> pd.DataFrame:
        """
        Transform raw healthcare data to event log format.

        This is the main transformation function that converts time-series
        clinical data into discrete events suitable for process mining.

        Args:
            raw_data: Raw clinical time-series data

        Returns:
            Event log DataFrame
        """
        logger.info("\n" + "=" * 60)
        logger.info("TRANSFORMING RAW DATA TO EVENT LOG")
        logger.info("=" * 60)

        all_events = []

        # Process each patient
        for patient_id in raw_data["Patient_ID"].unique():
            patient_data = raw_data[raw_data["Patient_ID"] == patient_id].copy()
            patient_data = patient_data.sort_values("Hour")

            logger.info(f"\nProcessing {patient_id}...")

            # 1. Add admission event
            all_events.append(
                {
                    "case": patient_id,
                    "activity": "Admission",
                    "timestamp": patient_data["Hour"].min(),
                    "resource": "Admissions",
                    "lifecycle": "complete",
                }
            )

            # 2. Detect state transitions for each vital sign
            for variable in ["HR", "Temp", "BP_sys", "SpO2", "Resp"]:
                transitions = self.detect_state_transitions(patient_data, variable)
                for trans in transitions:
                    all_events.append(
                        {
                            "case": patient_id,
                            "activity": trans["activity"],
                            "timestamp": trans["timestamp"],
                            "resource": trans["resource"],
                            "lifecycle": "complete",
                        }
                    )

            # 3. Lab test events
            lab_vars = ["WBC", "Lactate", "Creatinine", "Platelets"]
            for lab in lab_vars:
                lab_data = patient_data[patient_data[lab].notna()]
                for idx, row in lab_data.iterrows():
                    all_events.append(
                        {
                            "case": patient_id,
                            "activity": f"Lab_Test_{lab}",
                            "timestamp": row["Hour"],
                            "resource": "Laboratory",
                            "lifecycle": "complete",
                        }
                    )

                    # Check if abnormal
                    if lab in self.thresholds:
                        if row[lab] < self.thresholds[lab]["low"]:
                            all_events.append(
                                {
                                    "case": patient_id,
                                    "activity": f"{lab}_Low_Alert",
                                    "timestamp": row["Hour"]
                                    + 0.1,  # Slightly after test
                                    "resource": "Alert_System",
                                    "lifecycle": "complete",
                                }
                            )
                        elif row[lab] > self.thresholds[lab]["high"]:
                            all_events.append(
                                {
                                    "case": patient_id,
                                    "activity": f"{lab}_High_Alert",
                                    "timestamp": row["Hour"] + 0.1,
                                    "resource": "Alert_System",
                                    "lifecycle": "complete",
                                }
                            )

            # 4. Risk score events
            risk_events = self.calculate_risk_scores(patient_data)
            for event in risk_events:
                all_events.append(
                    {
                        "case": patient_id,
                        "activity": event["activity"],
                        "timestamp": event["timestamp"],
                        "resource": event["resource"],
                        "lifecycle": "complete",
                    }
                )

            # 5. Sepsis onset event
            sepsis_data = patient_data[patient_data["SepsisLabel"] == 1]
            if not sepsis_data.empty:
                sepsis_onset = sepsis_data["Hour"].min()
                all_events.append(
                    {
                        "case": patient_id,
                        "activity": "Sepsis_Onset",
                        "timestamp": sepsis_onset,
                        "resource": "Clinical_Team",
                        "lifecycle": "complete",
                    }
                )

                # Add treatment events (simulated)
                all_events.extend(
                    [
                        {
                            "case": patient_id,
                            "activity": "Antibiotic_Administration",
                            "timestamp": sepsis_onset + 1,
                            "resource": "Pharmacy",
                            "lifecycle": "complete",
                        },
                        {
                            "case": patient_id,
                            "activity": "Fluid_Resuscitation",
                            "timestamp": sepsis_onset + 0.5,
                            "resource": "Nursing",
                            "lifecycle": "complete",
                        },
                    ]
                )

            # 6. Discharge or outcome event
            all_events.append(
                {
                    "case": patient_id,
                    "activity": "Discharge" if not sepsis_data.empty else "Recovery",
                    "timestamp": patient_data["Hour"].max(),
                    "resource": "Discharge_Planning",
                    "lifecycle": "complete",
                }
            )

        # Create event log DataFrame
        event_log = pd.DataFrame(all_events)

        # Convert timestamp to datetime
        base_time = datetime(2024, 1, 1)
        event_log["timestamp"] = event_log["timestamp"].apply(
            lambda x: base_time + timedelta(hours=x)
        )

        # Sort by case and timestamp
        event_log = event_log.sort_values(["case", "timestamp"])

        # Add sepsis label to all events
        sepsis_cases = raw_data.groupby("Patient_ID")["SepsisLabel"].max()
        event_log["SepsisLabel"] = event_log["case"].map(sepsis_cases)

        logger.info("\nTransformation complete:")
        logger.info(f"  - Original data points: {len(raw_data)}")
        logger.info(f"  - Generated events: {len(event_log)}")
        logger.info(f"  - Patients: {event_log['case'].nunique()}")
        logger.info(f"  - Unique activities: {event_log['activity'].nunique()}")

        self.event_log = event_log
        return event_log

    def compare_process_maps(self, event_log: pd.DataFrame) -> Tuple[Dict, Dict]:
        """
        Create and compare process maps for sepsis vs non-sepsis patients.

        This demonstrates the comparison approach mentioned in the project,
        showing how different patient groups follow different pathways.

        Args:
            event_log: Event log DataFrame

        Returns:
            Tuple of (sepsis_stats, non_sepsis_stats)
        """
        logger.info("\n" + "=" * 60)
        logger.info("COMPARING PROCESS MAPS: SEPSIS VS NON-SEPSIS")
        logger.info("=" * 60)

        # Separate sepsis and non-sepsis cases
        sepsis_log = event_log[event_log["SepsisLabel"] == 1]
        non_sepsis_log = event_log[event_log["SepsisLabel"] == 0]

        logger.info(f"\nSepsis cases: {sepsis_log['case'].nunique()}")
        logger.info(f"Non-sepsis cases: {non_sepsis_log['case'].nunique()}")

        # Analyze sepsis pathway
        logger.info("\n--- SEPSIS PATHWAY CHARACTERISTICS ---")
        sepsis_activities = sepsis_log["activity"].value_counts().head(10)
        logger.info("Top activities in sepsis cases:")
        for activity, count in sepsis_activities.items():
            logger.info(f"  {activity}: {count}")

        # Analyze non-sepsis pathway
        logger.info("\n--- NON-SEPSIS PATHWAY CHARACTERISTICS ---")
        non_sepsis_activities = non_sepsis_log["activity"].value_counts().head(10)
        logger.info("Top activities in non-sepsis cases:")
        for activity, count in non_sepsis_activities.items():
            logger.info(f"  {activity}: {count}")

        # Find unique activities
        sepsis_unique = set(sepsis_log["activity"].unique()) - set(
            non_sepsis_log["activity"].unique()
        )
        non_sepsis_unique = set(non_sepsis_log["activity"].unique()) - set(
            sepsis_log["activity"].unique()
        )

        logger.info(f"\nActivities unique to sepsis cases: {len(sepsis_unique)}")
        for act in list(sepsis_unique)[:5]:
            logger.info(f"  - {act}")

        logger.info(
            f"\nActivities unique to non-sepsis cases: {len(non_sepsis_unique)}"
        )
        for act in list(non_sepsis_unique)[:5]:
            logger.info(f"  - {act}")

        # Calculate statistics
        sepsis_stats = {
            "n_cases": sepsis_log["case"].nunique(),
            "n_events": len(sepsis_log),
            "avg_events_per_case": len(sepsis_log) / sepsis_log["case"].nunique(),
            "unique_activities": len(sepsis_log["activity"].unique()),
            "top_activities": sepsis_activities.to_dict(),
        }

        non_sepsis_stats = {
            "n_cases": non_sepsis_log["case"].nunique(),
            "n_events": len(non_sepsis_log),
            "avg_events_per_case": len(non_sepsis_log)
            / non_sepsis_log["case"].nunique(),
            "unique_activities": len(non_sepsis_log["activity"].unique()),
            "top_activities": non_sepsis_activities.to_dict(),
        }

        return sepsis_stats, non_sepsis_stats


def main():
    """
    Demonstrate transformation of raw healthcare data to event logs.
    """
    print("\n" + "=" * 70)
    print("HEALTHCARE DATA TO EVENT LOG TRANSFORMATION")
    print("=" * 70)
    print("\nThis example demonstrates how to transform raw clinical data")
    print("(like PhysioNet Challenge 2019 data) into event logs for process mining.")
    print("\nApproach based on methods from Kaile Chen et al. and PhysioNet Challenge.")

    # Initialize transformer
    transformer = HealthcareDataTransformer()

    # Step 1: Create or load raw clinical data
    print("\n1. Creating synthetic clinical time-series data...")
    print("   (Similar to PhysioNet Challenge 2019 format)")
    raw_data = transformer.create_physionet_style_data(n_patients=50)

    print(f"\nRaw data shape: {raw_data.shape}")
    print(f"Columns: {list(raw_data.columns)}")
    print(f"Missing values: {raw_data.isnull().sum().sum()}")

    # Step 2: Transform to event log
    print("\n2. Transforming raw data to event log...")
    event_log = transformer.transform_to_event_log(raw_data)

    # Step 3: Compare process maps
    print("\n3. Comparing sepsis vs non-sepsis pathways...")
    sepsis_stats, non_sepsis_stats = transformer.compare_process_maps(event_log)

    # Step 4: Save event logs
    print("\n4. Saving transformed event logs...")

    # Save full event log
    event_log.to_csv("transformed_event_log.csv", index=False)
    print("   Full event log saved to: transformed_event_log.csv")

    # Save sepsis and non-sepsis logs separately
    sepsis_log = event_log[event_log["SepsisLabel"] == 1]
    non_sepsis_log = event_log[event_log["SepsisLabel"] == 0]

    sepsis_log.to_csv("sepsis_event_log.csv", index=False)
    non_sepsis_log.to_csv("non_sepsis_event_log.csv", index=False)
    print("   Sepsis event log saved to: sepsis_event_log.csv")
    print("   Non-sepsis event log saved to: non_sepsis_event_log.csv")

    # Summary
    print("\n" + "=" * 70)
    print("TRANSFORMATION SUMMARY")
    print("=" * 70)
    print(f"\nInput: {len(raw_data)} raw clinical measurements")
    print(f"Output: {len(event_log)} process mining events")
    print("\nKey insights:")
    print(
        f"- Sepsis cases have {sepsis_stats['avg_events_per_case']:.1f} events on average"
    )
    print(
        f"- Non-sepsis cases have {non_sepsis_stats['avg_events_per_case']:.1f} events on average"
    )
    print(f"- Sepsis cases show {sepsis_stats['unique_activities']} unique activities")
    print(
        f"- Non-sepsis cases show {non_sepsis_stats['unique_activities']} unique activities"
    )

    print("\n" + "=" * 70)
    print("READY FOR PROCESS MINING ANALYSIS")
    print("=" * 70)
    print("\nThe transformed event logs can now be analyzed using:")
    print("- Process discovery algorithms")
    print("- Conformance checking")
    print("- Performance analysis")
    print("- Predictive monitoring")
    print("\nThis transformation approach enables process mining on any")
    print("time-series healthcare data, including ICU monitoring,")
    print("epidemiological surveillance, and clinical trials.")

    return transformer, event_log


if __name__ == "__main__":
    transformer, event_log = main()

    # Additional example: Create aggregated event logs
    print("\n" + "=" * 70)
    print("CREATING AGGREGATED EVENT LOGS")
    print("=" * 70)
    print("\nSimilar to sepsisAgregated_Infection.csv and sepsisAgregated_Organ.csv,")
    print("we can create aggregated views focusing on specific aspects:")

    # Infection-focused event log
    infection_events = [
        "Temp_High",
        "WBC_High_Alert",
        "WBC_Low_Alert",
        "Lactate_High_Alert",
        "SIRS_Alert",
    ]
    infection_log = event_log[
        event_log["activity"].str.contains("|".join(infection_events), na=False)
        | event_log["activity"].isin(
            ["Admission", "Discharge", "Sepsis_Onset", "Antibiotic_Administration"]
        )
    ]

    print(f"\nInfection-focused log: {len(infection_log)} events")
    print(f"Activities: {infection_log['activity'].nunique()}")

    # Organ dysfunction-focused event log
    organ_events = [
        "BP_sys_Low",
        "SpO2_Low",
        "Creatinine_High_Alert",
        "Platelets_Low_Alert",
        "qSOFA_Alert",
    ]
    organ_log = event_log[
        event_log["activity"].str.contains("|".join(organ_events), na=False)
        | event_log["activity"].isin(
            ["Admission", "Discharge", "Sepsis_Onset", "Fluid_Resuscitation"]
        )
    ]

    print(f"\nOrgan dysfunction-focused log: {len(organ_log)} events")
    print(f"Activities: {organ_log['activity'].nunique()}")

    print("\nThese aggregated logs enable focused analysis on specific")
    print("clinical aspects while maintaining the process mining structure.")
