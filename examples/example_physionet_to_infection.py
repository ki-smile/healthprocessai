#!/usr/bin/env python3
"""Module: example_physionet_to_infection"""

"""
================================================================================
EXAMPLE: TRANSFORMING PHYSIONET DATA TO INFECTION/INFLAMMATION PROGRESSION
================================================================================
This example demonstrates how raw PhysioNet Challenge 2019 sepsis data
is transformed into infection/inflammation progression event logs.

The transformation creates events like:
- "High Temperature" / "Normal Temperature"
- "Infection + High Temperature" / "Infection + Normal Temperature"

This matches the format in sepsisAgregated_Infection.csv

Based on PhysioNet Challenge 2019: Early Prediction of Sepsis from Clinical Data
https://physionet.org/content/challenge-2019/1.0.0/

Developed at SMAILE, Karolinska Institutet
================================================================================
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)


class PhysioNetToInfectionTransformer:
    """
    Transforms raw PhysioNet sepsis data to infection/inflammation progression events.

    This transformer focuses on:
    1. Temperature patterns (fever/hypothermia as inflammation markers)
    2. Infection indicators (WBC, temperature combined)
    3. Progression states showing infection + inflammation

    The output matches the structure of sepsisAgregated_Infection.csv
    """

    def __init__(self):
        """Initialize transformer with clinical thresholds."""

        # Temperature thresholds for inflammation detection
        self.temp_thresholds = {
            "high": 38.0,  # Fever threshold (°C)
            "low": 36.0,  # Hypothermia threshold (°C)
            "normal_low": 36.5,
            "normal_high": 37.5,
        }

        # WBC thresholds for infection detection
        self.wbc_thresholds = {
            "high": 12.0,  # Leukocytosis (×10^9/L)
            "low": 4.0,  # Leukopenia (×10^9/L)
            "normal_low": 4.5,
            "normal_high": 11.0,
        }

        # Combined criteria for infection state
        self.infection_criteria = {
            "temp_spike": 38.3,  # Higher temp for definite infection
            "wbc_spike": 15.0,  # Higher WBC for definite infection
            "crp_elevated": 10.0,  # CRP > 10 mg/L suggests infection
            "lactate_elevated": 2.0,  # Lactate > 2 mmol/L
        }

    def load_physionet_data(self, patient_file: str) -> pd.DataFrame:
        """
        Load a PhysioNet patient file (PSV format).

        PhysioNet files contain 40 columns of vital signs and lab values,
        plus demographic info and sepsis labels.

        Args:
            patient_file: Path to patient PSV file (e.g., 'p000001.psv')

        Returns:
            DataFrame with hourly clinical measurements
        """
        # PhysioNet column names
        columns = [
            "HR",
            "O2Sat",
            "Temp",
            "SBP",
            "MAP",
            "DBP",
            "Resp",
            "EtCO2",
            "BaseExcess",
            "HCO3",
            "FiO2",
            "pH",
            "PaCO2",
            "SaO2",
            "AST",
            "BUN",
            "Alkalinephos",
            "Calcium",
            "Chloride",
            "Creatinine",
            "Bilirubin_direct",
            "Glucose",
            "Lactate",
            "Magnesium",
            "Phosphate",
            "Potassium",
            "Bilirubin_total",
            "TroponinI",
            "Hct",
            "Hgb",
            "PTT",
            "WBC",
            "Fibrinogen",
            "Platelets",
            "Age",
            "Gender",
            "Unit1",
            "Unit2",
            "HospAdmTime",
            "ICULOS",
            "SepsisLabel",
        ]

        # Load data
        df = pd.read_csv(patient_file, sep="|", names=columns)

        # Add patient ID from filename
        patient_id = patient_file.split("/")[-1].split(".")[0]
        df["Patient_ID"] = patient_id

        return df

    def detect_temperature_state(self, temp: float) -> str:
        """
        Classify temperature into clinical states.

        Args:
            temp: Temperature in Celsius

        Returns:
            Temperature state: "High Temperature", "Normal Temperature", or "Low Temperature"
        """
        if pd.isna(temp):
            return None

        if temp >= self.temp_thresholds["high"]:
            return "High Temperature"
        elif temp <= self.temp_thresholds["low"]:
            return "Low Temperature"
        else:
            return "Normal Temperature"

    def detect_infection_state(self, row: pd.Series) -> bool:
        """
        Determine if patient shows signs of infection based on multiple indicators.

        Uses SIRS criteria and additional infection markers:
        - Temperature abnormality
        - WBC abnormality
        - Elevated lactate
        - Tachycardia
        - Tachypnea

        Args:
            row: Patient data at specific timepoint

        Returns:
            True if infection suspected, False otherwise
        """
        infection_score = 0

        # Check temperature (fever or hypothermia)
        if not pd.isna(row.get("Temp")):
            if (
                row["Temp"] >= self.temp_thresholds["high"]
                or row["Temp"] <= self.temp_thresholds["low"]
            ):
                infection_score += 1
                # Severe fever is stronger indicator
                if row["Temp"] >= self.infection_criteria["temp_spike"]:
                    infection_score += 1

        # Check WBC (leukocytosis or leukopenia)
        if not pd.isna(row.get("WBC")):
            if (
                row["WBC"] >= self.wbc_thresholds["high"]
                or row["WBC"] <= self.wbc_thresholds["low"]
            ):
                infection_score += 1
                # Severe leukocytosis is stronger indicator
                if row["WBC"] >= self.infection_criteria["wbc_spike"]:
                    infection_score += 1

        # Check heart rate (tachycardia)
        if not pd.isna(row.get("HR")):
            if row["HR"] > 90:
                infection_score += 0.5

        # Check respiratory rate (tachypnea)
        if not pd.isna(row.get("Resp")):
            if row["Resp"] > 20:
                infection_score += 0.5

        # Check lactate (tissue hypoperfusion)
        if not pd.isna(row.get("Lactate")):
            if row["Lactate"] > self.infection_criteria["lactate_elevated"]:
                infection_score += 1

        # Infection likely if score >= 2
        return infection_score >= 2

    def transform_to_infection_events(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Transform raw PhysioNet data to infection progression event log.

        Creates events that track:
        1. Temperature changes (inflammation marker)
        2. Infection states
        3. Combined infection + temperature states

        Args:
            df: Raw PhysioNet data for one patient

        Returns:
            Event log with infection/inflammation progression
        """
        events = []
        patient_id = df["Patient_ID"].iloc[0]

        # Track previous states to detect transitions
        prev_temp_state = None
        prev_infection_state = False
        activity_counter = 0

        # Base timestamp (admission time)
        base_time = datetime(2070, 1, 1) + timedelta(
            hours=float(df["HospAdmTime"].iloc[0])
        )

        for idx, row in df.iterrows():
            # Calculate timestamp (ICULOS = hours since ICU admission)
            timestamp = base_time + timedelta(hours=float(row["ICULOS"]))

            # Detect current states
            temp_state = self.detect_temperature_state(row["Temp"])
            infection_state = self.detect_infection_state(row)

            # Generate events based on state changes
            if temp_state and (temp_state != prev_temp_state or idx == 0):
                # Temperature state change event
                if infection_state:
                    # Combined infection + temperature event
                    activity = f"Infection + {temp_state}"
                else:
                    # Temperature only event
                    activity = temp_state

                event = {
                    "case": patient_id,
                    "activity": activity,
                    "timestamp": timestamp,
                    "lifecycle": "complete",
                    "resource": "A",  # Resource A as in original data
                    "activity_instance_id": activity_counter,
                    "SepsisLabel": int(row["SepsisLabel"]),
                    # Keep original PhysioNet columns for reference
                    "HR": row["HR"],
                    "O2Sat": row["O2Sat"],
                    "Temp": row["Temp"],
                    "WBC": row["WBC"],
                    "Lactate": row["Lactate"],
                    "ICULOS": row["ICULOS"],
                }
                events.append(event)
                activity_counter += 1
                prev_temp_state = temp_state

            # Check for new infection without temperature change
            elif infection_state and not prev_infection_state and prev_temp_state:
                # Infection started with existing temperature state
                activity = f"Infection + {prev_temp_state}"
                event = {
                    "case": patient_id,
                    "activity": activity,
                    "timestamp": timestamp,
                    "lifecycle": "complete",
                    "resource": "A",
                    "activity_instance_id": activity_counter,
                    "SepsisLabel": int(row["SepsisLabel"]),
                    "HR": row["HR"],
                    "O2Sat": row["O2Sat"],
                    "Temp": row["Temp"],
                    "WBC": row["WBC"],
                    "Lactate": row["Lactate"],
                    "ICULOS": row["ICULOS"],
                }
                events.append(event)
                activity_counter += 1

            prev_infection_state = infection_state

        return pd.DataFrame(events)

    def create_aggregated_infection_log(self, patient_files: List[str]) -> pd.DataFrame:
        """
        Process multiple patient files and create aggregated infection event log.

        This creates the final format matching sepsisAgregated_Infection.csv

        Args:
            patient_files: List of paths to PhysioNet patient files

        Returns:
            Aggregated event log for all patients
        """
        all_events = []

        for i, patient_file in enumerate(patient_files, 1):
            logger.info(f"Processing patient {i}/{len(patient_files)}: {patient_file}")

            # Load patient data
            df = self.load_physionet_data(patient_file)

            # Transform to infection events
            events = self.transform_to_infection_events(df)

            if not events.empty:
                all_events.append(events)

        # Combine all patient events
        if all_events:
            combined_log = pd.concat(all_events, ignore_index=True)

            # Sort by case and timestamp
            combined_log = combined_log.sort_values(["case", "timestamp"])

            # Reset index to match original format
            combined_log = combined_log.reset_index(drop=True)

            return combined_log
        else:
            return pd.DataFrame()

    def analyze_infection_patterns(self, event_log: pd.DataFrame) -> Dict:
        """
        Analyze infection/inflammation patterns in the event log.

        Returns:
            Dictionary with pattern statistics
        """
        patterns = {
            "total_cases": event_log["case"].nunique(),
            "total_events": len(event_log),
            "sepsis_cases": event_log[event_log["SepsisLabel"] == 1]["case"].nunique(),
            "activity_distribution": event_log["activity"].value_counts().to_dict(),
            "infection_events": len(
                event_log[event_log["activity"].str.contains("Infection")]
            ),
            "temperature_patterns": {
                "high_temp_events": len(
                    event_log[event_log["activity"].str.contains("High Temperature")]
                ),
                "normal_temp_events": len(
                    event_log[event_log["activity"].str.contains("Normal Temperature")]
                ),
                "low_temp_events": len(
                    event_log[event_log["activity"].str.contains("Low Temperature")]
                ),
            },
        }

        return patterns


def create_sample_data() -> pd.DataFrame:
    """
    Create sample data mimicking PhysioNet format for demonstration.

    Returns:
        Sample DataFrame with PhysioNet-style measurements
    """
    np.random.seed(42)

    # Create sample data for one patient
    hours = 48  # 48 hours of ICU stay

    data = []
    develops_sepsis = True
    sepsis_onset = 24  # Sepsis at hour 24

    for hour in range(hours):
        # Simulate vital signs with sepsis progression
        if develops_sepsis and hour >= sepsis_onset:
            # Post-sepsis: abnormal values
            temp = np.random.choice(
                [
                    np.random.normal(38.5, 0.5),  # Fever
                    np.random.normal(35.5, 0.3),  # Hypothermia (less common)
                ],
                p=[0.8, 0.2],
            )
            wbc = np.random.normal(15, 3)  # Elevated WBC
            lactate = np.random.normal(3, 1)  # Elevated lactate
            hr = np.random.normal(110, 10)  # Tachycardia
            resp = np.random.normal(24, 3)  # Tachypnea
        else:
            # Pre-sepsis: mostly normal with some variation
            temp = np.random.normal(37, 0.5)
            wbc = np.random.normal(8, 2)
            lactate = np.random.normal(1, 0.3)
            hr = np.random.normal(75, 10)
            resp = np.random.normal(16, 2)

        # Add missing values randomly (realistic for ICU data)
        if np.random.random() < 0.1:
            temp = np.nan
        if np.random.random() < 0.3:
            wbc = np.nan
        if np.random.random() < 0.5:
            lactate = np.nan

        data.append(
            {
                "HR": hr,
                "O2Sat": np.random.normal(97, 2),
                "Temp": temp,
                "SBP": np.random.normal(120, 15),
                "MAP": np.random.normal(80, 10),
                "DBP": np.random.normal(70, 10),
                "Resp": resp,
                "WBC": wbc,
                "Lactate": lactate,
                "ICULOS": hour + 1,
                "SepsisLabel": 1 if develops_sepsis and hour >= sepsis_onset else 0,
                "Patient_ID": "p000001",
                "HospAdmTime": -5.0,  # 5 hours before ICU
                "Age": 65,
                "Gender": 1,
            }
        )

    return pd.DataFrame(data)


def main():
    """
    Demonstrate transformation of PhysioNet data to infection progression events.
    """
    print("\n" + "=" * 80)
    print("PHYSIONET TO INFECTION/INFLAMMATION PROGRESSION TRANSFORMATION")
    print("=" * 80)
    print("\nThis example shows how raw PhysioNet Challenge 2019 data is transformed")
    print(
        "into infection/inflammation progression events as in sepsisAgregated_Infection.csv"
    )

    # Initialize transformer
    transformer = PhysioNetToInfectionTransformer()

    # Create sample data (in real use, load actual PhysioNet files)
    print("\n1. Creating sample PhysioNet-style data...")
    sample_data = create_sample_data()
    print(f"   Generated {len(sample_data)} hours of ICU data")

    # Transform to infection events
    print("\n2. Transforming to infection/inflammation events...")
    event_log = transformer.transform_to_infection_events(sample_data)

    print("\n   Transformation Results:")
    print(f"   - Original measurements: {len(sample_data)}")
    print(f"   - Generated events: {len(event_log)}")
    print(f"   - Unique activities: {event_log['activity'].nunique()}")

    # Show activity distribution
    print("\n3. Activity Distribution:")
    for activity, count in event_log["activity"].value_counts().head(10).items():
        print(f"   - {activity}: {count} events")

    # Analyze patterns
    print("\n4. Analyzing infection patterns...")
    patterns = transformer.analyze_infection_patterns(event_log)

    print("\n   Pattern Analysis:")
    print(f"   - Total cases: {patterns['total_cases']}")
    print(f"   - Sepsis cases: {patterns['sepsis_cases']}")
    print(f"   - Infection events: {patterns['infection_events']}")
    print(
        f"   - High temperature events: {patterns['temperature_patterns']['high_temp_events']}"
    )
    print(
        f"   - Normal temperature events: {patterns['temperature_patterns']['normal_temp_events']}"
    )

    # Save the transformed event log
    print("\n5. Saving transformed event log...")
    output_file = "infection_progression_events.csv"
    event_log.to_csv(output_file, index=False)
    print(f"   Saved to: {output_file}")

    # Show sample of final format
    print(
        "\n6. Sample of transformed data (matching sepsisAgregated_Infection.csv format):"
    )
    print(
        "\n" + str(event_log[["case", "timestamp", "activity", "SepsisLabel"]].head(10))
    )

    print("\n" + "=" * 80)
    print("TRANSFORMATION COMPLETE")
    print("=" * 80)
    print(
        "\nThe output format matches sepsisAgregated_Infection.csv with activities like:"
    )
    print("- 'High Temperature'")
    print("- 'Normal Temperature'")
    print("- 'Infection + High Temperature'")
    print("- 'Infection + Normal Temperature'")
    print("\nThis event log is ready for process mining analysis to discover")
    print("infection/inflammation progression patterns in sepsis patients.")

    return transformer, event_log


if __name__ == "__main__":
    transformer, event_log = main()
