#!/usr/bin/env python3
"""Module: step1_data_loader"""

"""
STEP 1: DATA LOADING AND PREPARATION
====================================
This module handles the first step of the process mining pipeline:
loading event log data from CSV files and preparing it for analysis.

Learning Goals:
- Understand event log structure and requirements
- Learn how to load and validate healthcare data
- Convert raw data into process mining format

Key Concepts:
- Event logs contain: case ID, activity, timestamp, resource
- Each row represents one event in a patient's journey
- Cases are individual patient episodes
"""

import pandas as pd
import numpy as np
import logging
from typing import Dict, Any
from pathlib import Path

# Configure logging for debugging and learning
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class EventLogLoader:
    """
    Loads and validates event log data from CSV files.

    This class is responsible for:
    1. Reading CSV files containing event logs
    2. Validating required columns exist
    3. Converting data types appropriately
    4. Providing basic statistics about the loaded data
    """

    # Required columns for process mining analysis
    REQUIRED_COLUMNS = ["case", "activity", "timestamp"]

    # Optional but useful columns
    OPTIONAL_COLUMNS = ["resource", "lifecycle", "SepsisLabel"]

    def __init__(self, filepath: str):
        """
        Initialize the event log loader.

        Args:
            filepath: Path to the CSV file containing event log data
        """
        self.filepath = Path(filepath)
        self.raw_data = None
        self.prepared_data = None

        # Validate file exists
        if not self.filepath.exists():
            raise FileNotFoundError(f"Event log file not found: {filepath}")

        logger.info(f"Initialized EventLogLoader for: {self.filepath.name}")

    def load_data(self) -> pd.DataFrame:
        """
        Load raw data from CSV file.

        Returns:
            DataFrame containing the raw event log data

        Example:
            >>> loader = EventLogLoader("sepsis_events.csv")
            >>> data = loader.load_data()
            >>> print(f"Loaded {len(data)} events")
        """
        try:
            # Load CSV with pandas
            self.raw_data = pd.read_csv(self.filepath)

            # Log basic information for learning
            logger.info(f"Successfully loaded {len(self.raw_data)} events")
            logger.info(f"Columns found: {list(self.raw_data.columns)}")

            # Validate required columns
            self._validate_columns()

            return self.raw_data

        except Exception as e:
            logger.error(f"Error loading data: {e}")
            raise

    def _validate_columns(self) -> None:
        """
        Validate that required columns exist in the dataset.

        Raises:
            ValueError: If required columns are missing
        """
        missing_columns = []

        for col in self.REQUIRED_COLUMNS:
            if col not in self.raw_data.columns:
                missing_columns.append(col)

        if missing_columns:
            raise ValueError(
                f"Missing required columns: {missing_columns}. "
                f"Required columns are: {self.REQUIRED_COLUMNS}"
            )

        # Log optional columns that were found
        found_optional = [
            col for col in self.OPTIONAL_COLUMNS if col in self.raw_data.columns
        ]
        if found_optional:
            logger.info(f"Optional columns found: {found_optional}")

    def prepare_data(self) -> pd.DataFrame:
        """
        Prepare data for process mining analysis.

        This method:
        1. Converts timestamp to datetime format
        2. Removes any null values in required columns
        3. Sorts events by case and timestamp
        4. Adds derived features if needed

        Returns:
            DataFrame ready for process mining analysis
        """
        if self.raw_data is None:
            raise ValueError("No data loaded. Call load_data() first.")

        # Create a copy to avoid modifying original data
        self.prepared_data = self.raw_data.copy()

        # Step 1: Convert timestamp to datetime
        logger.info("Converting timestamps to datetime format...")
        self.prepared_data["timestamp"] = pd.to_datetime(
            self.prepared_data["timestamp"], errors="coerce"  # Invalid dates become NaT
        )

        # Step 2: Remove rows with null values in required columns
        initial_count = len(self.prepared_data)
        self.prepared_data = self.prepared_data.dropna(subset=self.REQUIRED_COLUMNS)
        removed_count = initial_count - len(self.prepared_data)

        if removed_count > 0:
            logger.warning(f"Removed {removed_count} events with missing data")

        # Step 3: Sort by case and timestamp for chronological order
        self.prepared_data = self.prepared_data.sort_values(by=["case", "timestamp"])

        # Step 4: Add derived features
        self._add_derived_features()

        logger.info(
            f"Data preparation complete: {len(self.prepared_data)} events ready"
        )

        return self.prepared_data

    def _add_derived_features(self) -> None:
        """
        Add useful derived features to the dataset.

        Examples of derived features:
        - Hour of day when event occurred
        - Day of week
        - Time since case start
        """
        if "timestamp" in self.prepared_data.columns:
            # Extract time-based features
            self.prepared_data["hour"] = self.prepared_data["timestamp"].dt.hour
            self.prepared_data["day_of_week"] = self.prepared_data[
                "timestamp"
            ].dt.dayofweek

            # Calculate time since case start for each event
            self.prepared_data["time_since_start"] = self.prepared_data.groupby("case")[
                "timestamp"
            ].transform(
                lambda x: (x - x.min()).dt.total_seconds() / 3600
            )  # in hours

            logger.info(
                "Added derived time features: hour, day_of_week, time_since_start"
            )

    def get_statistics(self) -> Dict[str, Any]:
        """
        Get basic statistics about the loaded event log.

        Returns:
            Dictionary containing various statistics

        Example:
            >>> stats = loader.get_statistics()
            >>> print(f"Total cases: {stats['num_cases']}")
            >>> print(f"Total events: {stats['num_events']}")
        """
        if self.prepared_data is None:
            raise ValueError("No data prepared. Call prepare_data() first.")

        stats = {
            "num_events": len(self.prepared_data),
            "num_cases": self.prepared_data["case"].nunique(),
            "num_activities": self.prepared_data["activity"].nunique(),
            "activities": list(self.prepared_data["activity"].unique()),
            "date_range": {
                "start": self.prepared_data["timestamp"].min(),
                "end": self.prepared_data["timestamp"].max(),
            },
            "avg_events_per_case": len(self.prepared_data)
            / self.prepared_data["case"].nunique(),
        }

        # Add resource statistics if available
        if "resource" in self.prepared_data.columns:
            stats["num_resources"] = self.prepared_data["resource"].nunique()

        # Add sepsis statistics if available
        if "SepsisLabel" in self.prepared_data.columns:
            sepsis_cases = self.prepared_data.groupby("case")["SepsisLabel"].max()
            stats["sepsis_rate"] = (sepsis_cases == 1).mean()
            stats["num_sepsis_cases"] = (sepsis_cases == 1).sum()

        return stats

    def filter_by_outcome(self, sepsis_only: bool = True) -> pd.DataFrame:
        """
        Filter cases based on sepsis outcome.

        Args:
            sepsis_only: If True, keep only sepsis cases; if False, keep non-sepsis cases

        Returns:
            Filtered DataFrame

        Example:
            >>> sepsis_events = loader.filter_by_outcome(sepsis_only=True)
            >>> print(f"Sepsis cases: {sepsis_events['case'].nunique()}")
        """
        if "SepsisLabel" not in self.prepared_data.columns:
            logger.warning("SepsisLabel column not found. Returning all data.")
            return self.prepared_data

        # Get cases with desired outcome
        case_outcomes = self.prepared_data.groupby("case")["SepsisLabel"].max()

        if sepsis_only:
            target_cases = case_outcomes[case_outcomes == 1].index
            logger.info(f"Filtering for sepsis cases: {len(target_cases)} cases")
        else:
            target_cases = case_outcomes[case_outcomes == 0].index
            logger.info(f"Filtering for non-sepsis cases: {len(target_cases)} cases")

        # Filter events for target cases
        filtered_data = self.prepared_data[
            self.prepared_data["case"].isin(target_cases)
        ]

        return filtered_data

    def sample_cases(self, n: int = 100, random_state: int = 42) -> pd.DataFrame:
        """
        Sample a subset of cases for testing and learning.

        Args:
            n: Number of cases to sample
            random_state: Random seed for reproducibility

        Returns:
            DataFrame with sampled cases

        Example:
            >>> sample = loader.sample_cases(n=50)
            >>> print(f"Sampled {sample['case'].nunique()} cases")
        """
        if self.prepared_data is None:
            raise ValueError("No data prepared. Call prepare_data() first.")

        # Get unique case IDs
        all_cases = self.prepared_data["case"].unique()

        # Sample n cases (or all if n is larger)
        n_sample = min(n, len(all_cases))
        sampled_cases = np.random.RandomState(random_state).choice(
            all_cases, size=n_sample, replace=False
        )

        # Filter events for sampled cases
        sampled_data = self.prepared_data[
            self.prepared_data["case"].isin(sampled_cases)
        ]

        logger.info(f"Sampled {n_sample} cases with {len(sampled_data)} total events")

        return sampled_data


def main():
    """
    Example usage of the EventLogLoader class.

    This demonstrates the complete data loading pipeline.
    """
    # Example: Load sepsis event log
    print("=" * 60)
    print("STEP 1: DATA LOADING AND PREPARATION")
    print("=" * 60)

    # Initialize loader
    loader = EventLogLoader("sepsisAgregated_Infection.csv")

    # Load raw data
    print("\n1. Loading raw data...")
    raw_data = loader.load_data()
    print(f"   Loaded {len(raw_data)} events")

    # Prepare data for analysis
    print("\n2. Preparing data...")
    prepared_data = loader.prepare_data()
    print(f"   Prepared {len(prepared_data)} events")

    # Get statistics
    print("\n3. Event log statistics:")
    stats = loader.get_statistics()
    for key, value in stats.items():
        if key != "activities":  # Skip long list of activities
            print(f"   {key}: {value}")

    # Filter for sepsis cases
    print("\n4. Filtering for sepsis cases...")
    sepsis_data = loader.filter_by_outcome(sepsis_only=True)
    print(f"   Sepsis events: {len(sepsis_data)}")
    print(f"   Sepsis cases: {sepsis_data['case'].nunique()}")

    # Create a small sample for testing
    print("\n5. Creating sample dataset...")
    sample = loader.sample_cases(n=10)
    print(f"   Sample contains {len(sample)} events from 10 cases")

    print("\n" + "=" * 60)
    print("Data loading complete! Ready for process mining analysis.")
    print("=" * 60)


if __name__ == "__main__":
    main()
