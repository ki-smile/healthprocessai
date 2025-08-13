#!/usr/bin/env python3
"""Module: example_physionet_to_organ"""

"""
================================================================================
EXAMPLE: TRANSFORMING PHYSIONET DATA TO ORGAN FAILURE PROGRESSION
================================================================================
This example demonstrates how raw PhysioNet Challenge 2019 sepsis data
is transformed into organ failure progression event logs.

The transformation creates events like:
- "Low Risk"
- "Liver + Cardiac Damage"
- "Renal + Cardiac Damage"
- "Multiorgan Damage"
- "Sepsis"

This matches the format in sepsisAgregated_Organ.csv

Based on SOFA (Sequential Organ Failure Assessment) score components:
- Respiratory: PaO2/FiO2 ratio, SpO2
- Cardiovascular: MAP, vasopressor requirement
- Liver: Bilirubin
- Coagulation: Platelets
- Renal: Creatinine, urine output
- CNS: Glasgow Coma Scale (GCS)

Developed at SMAILE, Karolinska Institutet
================================================================================
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import List, Dict, Tuple, Set
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)


class PhysioNetToOrganTransformer:
    """
    Transforms raw PhysioNet sepsis data to organ failure progression events.

    This transformer evaluates organ dysfunction using modified SOFA criteria
    and creates events that track single and multiple organ failures.

    The output matches the structure of sepsisAgregated_Organ.csv
    """

    def __init__(self):
        """Initialize transformer with organ failure thresholds."""

        # SOFA-based thresholds for organ dysfunction
        self.organ_thresholds = {
            "respiratory": {
                "spo2_low": 92,  # SpO2 < 92% indicates respiratory issues
                "resp_high": 22,  # Respiratory rate > 22
                "fio2_high": 0.4,  # Need for high oxygen
            },
            "cardiovascular": {
                "map_low": 65,  # MAP < 65 mmHg
                "sbp_low": 90,  # Systolic BP < 90
                "hr_high": 120,  # Severe tachycardia
                "lactate_high": 2.0,  # Tissue hypoperfusion
            },
            "liver": {
                "bilirubin_high": 2.0,  # Bilirubin > 2 mg/dL
                "ast_high": 100,  # AST elevation
                "alt_high": 100,  # ALT elevation (if available)
            },
            "coagulation": {
                "platelets_low": 100,  # Platelets < 100 ×10^9/L
                "ptt_high": 60,  # PTT > 60 seconds
                "fibrinogen_low": 100,  # Fibrinogen < 100 mg/dL
            },
            "renal": {
                "creatinine_high": 2.0,  # Creatinine > 2 mg/dL
                "bun_high": 40,  # BUN > 40 mg/dL
                "urine_low": 500,  # Oliguria (would need 24h data)
            },
            "cns": {"gcs_low": 13},  # GCS < 13 (if available)
        }

        # Mapping of organ combinations to event names
        self.organ_event_mapping = {
            frozenset(): "Low Risk",
            frozenset(["cardiovascular"]): "Cardiac Damage",
            frozenset(["liver"]): "Liver Damage",
            frozenset(["renal"]): "Renal Damage",
            frozenset(["respiratory"]): "Respiratory Damage",
            frozenset(["coagulation"]): "Coagulation Disorder",
            frozenset(["liver", "cardiovascular"]): "Liver + Cardiac Damage",
            frozenset(["renal", "cardiovascular"]): "Renal + Cardiac Damage",
            frozenset(
                ["respiratory", "cardiovascular"]
            ): "Respiratory + Cardiac Damage",
            frozenset(["liver", "renal"]): "Liver + Renal Damage",
            # Three or more organs = Multiorgan
        }

    def evaluate_respiratory_dysfunction(self, row: pd.Series) -> bool:
        """
        Evaluate respiratory system dysfunction.

        Criteria:
        - SpO2 < 92% on room air
        - Respiratory rate > 22
        - Need for high FiO2
        """
        dysfunction = False

        if (
            not pd.isna(row.get("O2Sat"))
            and row["O2Sat"] < self.organ_thresholds["respiratory"]["spo2_low"]
        ):
            dysfunction = True

        if (
            not pd.isna(row.get("Resp"))
            and row["Resp"] > self.organ_thresholds["respiratory"]["resp_high"]
        ):
            dysfunction = True

        if (
            not pd.isna(row.get("FiO2"))
            and row["FiO2"] > self.organ_thresholds["respiratory"]["fio2_high"]
        ):
            dysfunction = True

        return dysfunction

    def evaluate_cardiovascular_dysfunction(self, row: pd.Series) -> bool:
        """
        Evaluate cardiovascular system dysfunction.

        Criteria:
        - MAP < 65 mmHg
        - SBP < 90 mmHg
        - Severe tachycardia
        - Elevated lactate (tissue hypoperfusion)
        """
        dysfunction_score = 0

        if (
            not pd.isna(row.get("MAP"))
            and row["MAP"] < self.organ_thresholds["cardiovascular"]["map_low"]
        ):
            dysfunction_score += 1

        if (
            not pd.isna(row.get("SBP"))
            and row["SBP"] < self.organ_thresholds["cardiovascular"]["sbp_low"]
        ):
            dysfunction_score += 1

        if (
            not pd.isna(row.get("HR"))
            and row["HR"] > self.organ_thresholds["cardiovascular"]["hr_high"]
        ):
            dysfunction_score += 0.5

        if (
            not pd.isna(row.get("Lactate"))
            and row["Lactate"] > self.organ_thresholds["cardiovascular"]["lactate_high"]
        ):
            dysfunction_score += 1

        return dysfunction_score >= 1

    def evaluate_liver_dysfunction(self, row: pd.Series) -> bool:
        """
        Evaluate liver dysfunction.

        Criteria:
        - Bilirubin > 2 mg/dL
        - AST elevation
        - Alkaline phosphatase elevation
        """
        dysfunction = False

        if (
            not pd.isna(row.get("Bilirubin_total"))
            and row["Bilirubin_total"]
            > self.organ_thresholds["liver"]["bilirubin_high"]
        ):
            dysfunction = True

        if (
            not pd.isna(row.get("AST"))
            and row["AST"] > self.organ_thresholds["liver"]["ast_high"]
        ):
            dysfunction = True

        if (
            not pd.isna(row.get("Alkalinephos")) and row["Alkalinephos"] > 150
        ):  # Elevated ALP
            dysfunction = True

        return dysfunction

    def evaluate_coagulation_dysfunction(self, row: pd.Series) -> bool:
        """
        Evaluate coagulation system dysfunction.

        Criteria:
        - Platelets < 100 ×10^9/L
        - PTT prolongation
        - Fibrinogen low
        """
        dysfunction = False

        if (
            not pd.isna(row.get("Platelets"))
            and row["Platelets"] < self.organ_thresholds["coagulation"]["platelets_low"]
        ):
            dysfunction = True

        if (
            not pd.isna(row.get("PTT"))
            and row["PTT"] > self.organ_thresholds["coagulation"]["ptt_high"]
        ):
            dysfunction = True

        if (
            not pd.isna(row.get("Fibrinogen"))
            and row["Fibrinogen"]
            < self.organ_thresholds["coagulation"]["fibrinogen_low"]
        ):
            dysfunction = True

        return dysfunction

    def evaluate_renal_dysfunction(self, row: pd.Series) -> bool:
        """
        Evaluate renal dysfunction.

        Criteria:
        - Creatinine > 2 mg/dL
        - BUN > 40 mg/dL
        """
        dysfunction = False

        if (
            not pd.isna(row.get("Creatinine"))
            and row["Creatinine"] > self.organ_thresholds["renal"]["creatinine_high"]
        ):
            dysfunction = True

        if (
            not pd.isna(row.get("BUN"))
            and row["BUN"] > self.organ_thresholds["renal"]["bun_high"]
        ):
            dysfunction = True

        return dysfunction

    def evaluate_all_organ_systems(self, row: pd.Series) -> Set[str]:
        """
        Evaluate all organ systems and return set of dysfunctional organs.

        Args:
            row: Patient data at specific timepoint

        Returns:
            Set of organ systems with dysfunction
        """
        dysfunctional_organs = set()

        if self.evaluate_respiratory_dysfunction(row):
            dysfunctional_organs.add("respiratory")

        if self.evaluate_cardiovascular_dysfunction(row):
            dysfunctional_organs.add("cardiovascular")

        if self.evaluate_liver_dysfunction(row):
            dysfunctional_organs.add("liver")

        if self.evaluate_coagulation_dysfunction(row):
            dysfunctional_organs.add("coagulation")

        if self.evaluate_renal_dysfunction(row):
            dysfunctional_organs.add("renal")

        return dysfunctional_organs

    def get_organ_failure_event(self, organs: Set[str], sepsis_label: int) -> str:
        """
        Map organ dysfunction combination to event name.

        Args:
            organs: Set of dysfunctional organs
            sepsis_label: Whether patient has sepsis

        Returns:
            Event name describing organ failure state
        """
        # If patient has sepsis label, override with "Sepsis" event
        if sepsis_label == 1:
            return "Sepsis"

        # If 3+ organs affected, it's multiorgan failure
        if len(organs) >= 3:
            return "Multiorgan Damage"

        # Try to find specific combination in mapping
        frozen_organs = frozenset(organs)
        if frozen_organs in self.organ_event_mapping:
            return self.organ_event_mapping[frozen_organs]

        # For unmapped combinations, create descriptive name
        if len(organs) == 2:
            organ_names = sorted([o.capitalize() for o in organs])
            return f"{organ_names[0]} + {organ_names[1]} Damage"
        elif len(organs) == 1:
            return f"{list(organs)[0].capitalize()} Damage"
        else:
            return "Low Risk"

    def transform_to_organ_events(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Transform raw PhysioNet data to organ failure progression event log.

        Creates events that track:
        1. Single organ failures
        2. Multiple organ failures
        3. Progression to sepsis

        Args:
            df: Raw PhysioNet data for one patient

        Returns:
            Event log with organ failure progression
        """
        events = []
        patient_id = (
            df["Patient_ID"].iloc[0]
            if "Patient_ID" in df.columns
            else f"p{df.index[0]:06d}"
        )

        # Track previous state to detect changes
        prev_organs = set()
        prev_event = "Low Risk"
        activity_counter = 0

        # Base timestamp
        base_time = datetime(2070, 1, 1)
        if "HospAdmTime" in df.columns:
            base_time += timedelta(hours=float(df["HospAdmTime"].iloc[0]))

        # Process each hour of data
        for idx, row in df.iterrows():
            # Calculate timestamp
            if "ICULOS" in row:
                timestamp = base_time + timedelta(hours=float(row["ICULOS"]))
            else:
                timestamp = base_time + timedelta(hours=idx)

            # Evaluate organ systems
            current_organs = self.evaluate_all_organ_systems(row)

            # Get event name
            current_event = self.get_organ_failure_event(
                current_organs, int(row["SepsisLabel"]) if "SepsisLabel" in row else 0
            )

            # Generate event if state changed or first observation
            if current_event != prev_event or idx == 0:
                event = {
                    "case": patient_id,
                    "activity": current_event,
                    "timestamp": timestamp,
                    "lifecycle": "complete",
                    "resource": "A",
                    "activity_instance_id": activity_counter,
                    "SepsisLabel": (
                        int(row["SepsisLabel"]) if "SepsisLabel" in row else 0
                    ),
                    # Keep key measurements for reference
                    "HR": row.get("HR"),
                    "MAP": row.get("MAP"),
                    "Creatinine": row.get("Creatinine"),
                    "Bilirubin_total": row.get("Bilirubin_total"),
                    "Platelets": row.get("Platelets"),
                    "Lactate": row.get("Lactate"),
                    "O2Sat": row.get("O2Sat"),
                    "ICULOS": row.get("ICULOS", idx),
                }
                events.append(event)
                activity_counter += 1

                prev_event = current_event
                prev_organs = current_organs

        return pd.DataFrame(events)

    def create_aggregated_organ_log(
        self, patient_data_list: List[pd.DataFrame]
    ) -> pd.DataFrame:
        """
        Process multiple patients and create aggregated organ failure event log.

        This creates the final format matching sepsisAgregated_Organ.csv

        Args:
            patient_data_list: List of patient DataFrames

        Returns:
            Aggregated event log for all patients
        """
        all_events = []

        for i, patient_df in enumerate(patient_data_list, 1):
            logger.info(f"Processing patient {i}/{len(patient_data_list)}")

            # Transform to organ events
            events = self.transform_to_organ_events(patient_df)

            if not events.empty:
                all_events.append(events)

        # Combine all patient events
        if all_events:
            combined_log = pd.concat(all_events, ignore_index=True)

            # Sort by case and timestamp
            combined_log = combined_log.sort_values(["case", "timestamp"])

            # Reset index
            combined_log = combined_log.reset_index(drop=True)

            return combined_log
        else:
            return pd.DataFrame()

    def analyze_organ_patterns(self, event_log: pd.DataFrame) -> Dict:
        """
        Analyze organ failure patterns in the event log.

        Returns:
            Dictionary with pattern statistics
        """
        patterns = {
            "total_cases": event_log["case"].nunique(),
            "total_events": len(event_log),
            "sepsis_cases": event_log[event_log["SepsisLabel"] == 1]["case"].nunique(),
            "activity_distribution": event_log["activity"].value_counts().to_dict(),
            "organ_failure_types": {
                "single_organ": len(
                    event_log[
                        event_log["activity"].str.contains("Damage")
                        & ~event_log["activity"].str.contains("\\\+")
                    ]
                ),
                "dual_organ": len(
                    event_log[event_log["activity"].str.contains("\\\+")]
                ),
                "multiorgan": len(
                    event_log[event_log["activity"] == "Multiorgan Damage"]
                ),
                "low_risk": len(event_log[event_log["activity"] == "Low Risk"]),
                "sepsis": len(event_log[event_log["activity"] == "Sepsis"]),
            },
        }

        return patterns


def create_sample_patients() -> List[pd.DataFrame]:
    """
    Create sample patient data mimicking PhysioNet format for demonstration.

    Returns:
        List of patient DataFrames with different organ failure patterns
    """
    np.random.seed(42)
    patients = []

    # Patient 1: Progresses from Low Risk to Multiorgan to Sepsis
    patient1_data = []
    for hour in range(72):
        if hour < 24:
            # Normal phase
            row = {
                "HR": np.random.normal(75, 5),
                "MAP": np.random.normal(80, 5),
                "SBP": np.random.normal(120, 10),
                "O2Sat": np.random.normal(97, 1),
                "Resp": np.random.normal(16, 2),
                "Creatinine": np.random.normal(1.0, 0.2),
                "Bilirubin_total": np.random.normal(0.8, 0.2),
                "Platelets": np.random.normal(250, 30),
                "Lactate": np.random.normal(1.0, 0.2),
                "AST": np.random.normal(30, 10),
                "BUN": np.random.normal(15, 5),
                "PTT": np.random.normal(30, 5),
                "ICULOS": hour + 1,
                "SepsisLabel": 0,
                "Patient_ID": "p000001",
            }
        elif hour < 48:
            # Organ dysfunction phase
            row = {
                "HR": np.random.normal(110, 10),
                "MAP": np.random.normal(60, 5),
                "SBP": np.random.normal(85, 10),
                "O2Sat": np.random.normal(90, 3),
                "Resp": np.random.normal(24, 3),
                "Creatinine": np.random.normal(2.5, 0.5),
                "Bilirubin_total": np.random.normal(3.0, 0.5),
                "Platelets": np.random.normal(80, 20),
                "Lactate": np.random.normal(3.0, 0.5),
                "AST": np.random.normal(150, 30),
                "BUN": np.random.normal(50, 10),
                "PTT": np.random.normal(65, 10),
                "ICULOS": hour + 1,
                "SepsisLabel": 0,
                "Patient_ID": "p000001",
            }
        else:
            # Sepsis phase
            row = {
                "HR": np.random.normal(120, 10),
                "MAP": np.random.normal(55, 5),
                "SBP": np.random.normal(80, 10),
                "O2Sat": np.random.normal(88, 3),
                "Resp": np.random.normal(28, 3),
                "Creatinine": np.random.normal(3.5, 0.5),
                "Bilirubin_total": np.random.normal(4.0, 0.5),
                "Platelets": np.random.normal(60, 20),
                "Lactate": np.random.normal(4.5, 0.5),
                "AST": np.random.normal(200, 30),
                "BUN": np.random.normal(70, 10),
                "PTT": np.random.normal(80, 10),
                "ICULOS": hour + 1,
                "SepsisLabel": 1,
                "Patient_ID": "p000001",
            }
        patient1_data.append(row)
    patients.append(pd.DataFrame(patient1_data))

    # Patient 2: Cardiac + Liver damage, no sepsis
    patient2_data = []
    for hour in range(48):
        if hour < 12:
            # Normal phase
            row = {
                "HR": np.random.normal(75, 5),
                "MAP": np.random.normal(80, 5),
                "SBP": np.random.normal(120, 10),
                "Creatinine": np.random.normal(1.0, 0.2),
                "Bilirubin_total": np.random.normal(0.8, 0.2),
                "Platelets": np.random.normal(250, 30),
                "Lactate": np.random.normal(1.0, 0.2),
                "AST": np.random.normal(30, 10),
                "ICULOS": hour + 1,
                "SepsisLabel": 0,
                "Patient_ID": "p000002",
            }
        else:
            # Cardiac + Liver dysfunction
            row = {
                "HR": np.random.normal(100, 10),
                "MAP": np.random.normal(62, 5),
                "SBP": np.random.normal(88, 10),
                "Creatinine": np.random.normal(1.2, 0.2),
                "Bilirubin_total": np.random.normal(2.5, 0.5),
                "Platelets": np.random.normal(180, 30),
                "Lactate": np.random.normal(2.5, 0.3),
                "AST": np.random.normal(120, 20),
                "ICULOS": hour + 1,
                "SepsisLabel": 0,
                "Patient_ID": "p000002",
            }
        patient2_data.append(row)
    patients.append(pd.DataFrame(patient2_data))

    # Patient 3: Remains low risk throughout
    patient3_data = []
    for hour in range(24):
        row = {
            "HR": np.random.normal(70, 5),
            "MAP": np.random.normal(85, 5),
            "SBP": np.random.normal(125, 10),
            "Creatinine": np.random.normal(0.9, 0.1),
            "Bilirubin_total": np.random.normal(0.7, 0.1),
            "Platelets": np.random.normal(280, 20),
            "Lactate": np.random.normal(0.9, 0.1),
            "AST": np.random.normal(25, 5),
            "ICULOS": hour + 1,
            "SepsisLabel": 0,
            "Patient_ID": "p000003",
        }
        patient3_data.append(row)
    patients.append(pd.DataFrame(patient3_data))

    return patients


def main():
    """
    Demonstrate transformation of PhysioNet data to organ failure progression events.
    """
    print("\n" + "=" * 80)
    print("PHYSIONET TO ORGAN FAILURE PROGRESSION TRANSFORMATION")
    print("=" * 80)
    print("\nThis example shows how raw PhysioNet Challenge 2019 data is transformed")
    print("into organ failure progression events as in sepsisAgregated_Organ.csv")

    # Initialize transformer
    transformer = PhysioNetToOrganTransformer()

    # Create sample patient data
    print("\n1. Creating sample PhysioNet-style patient data...")
    sample_patients = create_sample_patients()
    print(f"   Generated data for {len(sample_patients)} patients:")
    print("   - Patient 1: 72 hours (progresses to sepsis)")
    print("   - Patient 2: 48 hours (cardiac + liver damage)")
    print("   - Patient 3: 24 hours (remains low risk)")

    # Transform each patient
    print("\n2. Transforming to organ failure events...")
    all_events = []
    for i, patient_df in enumerate(sample_patients, 1):
        events = transformer.transform_to_organ_events(patient_df)
        all_events.append(events)
        print(f"   Patient {i}: {len(patient_df)} measurements → {len(events)} events")

    # Combine into aggregated log
    print("\n3. Creating aggregated organ failure event log...")
    event_log = pd.concat(all_events, ignore_index=True)
    event_log = event_log.sort_values(["case", "timestamp"])

    print("\n   Aggregated Results:")
    print(f"   - Total events: {len(event_log)}")
    print(f"   - Total cases: {event_log['case'].nunique()}")
    print(f"   - Unique activities: {event_log['activity'].nunique()}")

    # Show activity distribution
    print("\n4. Activity Distribution:")
    for activity, count in event_log["activity"].value_counts().items():
        print(f"   - {activity}: {count} events")

    # Analyze patterns
    print("\n5. Analyzing organ failure patterns...")
    patterns = transformer.analyze_organ_patterns(event_log)

    print("\n   Pattern Analysis:")
    print(f"   - Low risk events: {patterns['organ_failure_types']['low_risk']}")
    print(
        f"   - Single organ damage: {patterns['organ_failure_types']['single_organ']}"
    )
    print(f"   - Dual organ damage: {patterns['organ_failure_types']['dual_organ']}")
    print(f"   - Multiorgan damage: {patterns['organ_failure_types']['multiorgan']}")
    print(f"   - Sepsis events: {patterns['organ_failure_types']['sepsis']}")

    # Save the transformed event log
    print("\n6. Saving transformed event log...")
    output_file = "organ_failure_progression_events.csv"
    event_log.to_csv(output_file, index=False)
    print(f"   Saved to: {output_file}")

    # Show sample of final format
    print(
        "\n7. Sample of transformed data (matching sepsisAgregated_Organ.csv format):"
    )
    display_cols = ["case", "timestamp", "activity", "SepsisLabel"]
    print("\n" + str(event_log[display_cols].head(15)))

    # Show progression for each patient
    print("\n8. Patient Progression Summaries:")
    for patient_id in event_log["case"].unique():
        patient_events = event_log[event_log["case"] == patient_id]
        progression = " → ".join(patient_events["activity"].values)
        print(f"\n   {patient_id}: {progression}")

    print("\n" + "=" * 80)
    print("TRANSFORMATION COMPLETE")
    print("=" * 80)
    print("\nThe output format matches sepsisAgregated_Organ.csv with activities like:")
    print("- 'Low Risk'")
    print("- 'Liver + Cardiac Damage'")
    print("- 'Renal + Cardiac Damage'")
    print("- 'Multiorgan Damage'")
    print("- 'Sepsis'")
    print("\nThis event log is ready for process mining analysis to discover")
    print(
        "organ failure progression patterns and compare sepsis vs non-sepsis pathways."
    )

    return transformer, event_log


if __name__ == "__main__":
    transformer, event_log = main()
