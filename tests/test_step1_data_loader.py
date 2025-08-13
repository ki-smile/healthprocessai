#!/usr/bin/env python3
"""
Unit Tests for Step 1: Data Loading and Preparation
====================================================
Tests the EventLogLoader class functionality including:
- Data loading and validation
- Data preparation and cleaning
- Filtering and sampling
- Statistics calculation
"""

import unittest
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import tempfile
import sys
from pathlib import Path

# Add project root to path for imports
project_root = Path(__file__).parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

# Import the module to test
from core.step1_data_loader import EventLogLoader


class TestEventLogLoader(unittest.TestCase):
    """Test cases for the EventLogLoader class."""

    @classmethod
    def setUpClass(cls):
        """Set up test data files."""
        cls.test_dir = tempfile.mkdtemp()

        # Create a valid test CSV file
        cls.valid_csv_path = Path(cls.test_dir) / "valid_test.csv"
        cls.create_valid_test_data(cls.valid_csv_path)

        # Create an invalid test CSV file (missing required columns)
        cls.invalid_csv_path = Path(cls.test_dir) / "invalid_test.csv"
        cls.create_invalid_test_data(cls.invalid_csv_path)

        # Create a CSV with edge cases
        cls.edge_cases_csv_path = Path(cls.test_dir) / "edge_cases.csv"
        cls.create_edge_cases_data(cls.edge_cases_csv_path)

    @classmethod
    def create_valid_test_data(cls, filepath):
        """Create a valid test dataset."""
        # Generate synthetic sepsis data
        np.random.seed(42)

        cases = []
        for i in range(10):
            case_id = f"P{i:03d}"
            start_time = datetime(2024, 1, 1) + timedelta(days=i)

            # Create events for each case
            events = [
                {
                    "case": case_id,
                    "activity": "Admission",
                    "timestamp": start_time,
                    "resource": "ER_Nurse",
                    "SepsisLabel": 0,
                },
                {
                    "case": case_id,
                    "activity": "Triage",
                    "timestamp": start_time + timedelta(hours=0.5),
                    "resource": "ER_Nurse",
                    "SepsisLabel": 0,
                },
                {
                    "case": case_id,
                    "activity": "Blood Test",
                    "timestamp": start_time + timedelta(hours=2),
                    "resource": "Lab_Tech",
                    "SepsisLabel": 0,
                },
            ]

            # Half of the cases develop sepsis
            if i < 5:
                events.append(
                    {
                        "case": case_id,
                        "activity": "Antibiotics",
                        "timestamp": start_time + timedelta(hours=4),
                        "resource": "Doctor",
                        "SepsisLabel": 1,
                    }
                )
                events.append(
                    {
                        "case": case_id,
                        "activity": "ICU Transfer",
                        "timestamp": start_time + timedelta(hours=6),
                        "resource": "Transport",
                        "SepsisLabel": 1,
                    }
                )
            else:
                events.append(
                    {
                        "case": case_id,
                        "activity": "Discharge",
                        "timestamp": start_time + timedelta(hours=8),
                        "resource": "Nurse",
                        "SepsisLabel": 0,
                    }
                )

            cases.extend(events)

        df = pd.DataFrame(cases)
        df.to_csv(filepath, index=False)

    @classmethod
    def create_invalid_test_data(cls, filepath):
        """Create an invalid test dataset (missing required columns)."""
        data = {
            "patient_id": ["P001", "P002"],  # Wrong column name
            "event": ["Admission", "Discharge"],  # Wrong column name
            "time": ["2024-01-01", "2024-01-02"],  # Wrong column name
        }
        df = pd.DataFrame(data)
        df.to_csv(filepath, index=False)

    @classmethod
    def create_edge_cases_data(cls, filepath):
        """Create a dataset with edge cases."""
        data = {
            "case": ["P001", "P002", "P003", None, "P004"],
            "activity": ["Admission", None, "Discharge", "Test", "Lab Work"],
            "timestamp": [
                "2024-01-01 10:00:00",
                "2024-01-01 11:00:00",
                "invalid_date",
                "2024-01-01 12:00:00",
                "2024-01-01 13:00:00",
            ],
            "resource": ["Nurse", "Doctor", None, "Tech", "Lab"],
            "SepsisLabel": [0, 1, 0, None, 1],
        }
        df = pd.DataFrame(data)
        df.to_csv(filepath, index=False)

    def test_initialization_with_valid_file(self):
        """Test initialization with a valid file path."""
        loader = EventLogLoader(self.valid_csv_path)
        self.assertEqual(loader.filepath, Path(self.valid_csv_path))
        self.assertIsNone(loader.raw_data)
        self.assertIsNone(loader.prepared_data)

    def test_initialization_with_nonexistent_file(self):
        """Test initialization with a non-existent file."""
        with self.assertRaises(FileNotFoundError):
            EventLogLoader("nonexistent_file.csv")

    def test_load_data_success(self):
        """Test successful data loading."""
        loader = EventLogLoader(self.valid_csv_path)
        data = loader.load_data()

        self.assertIsNotNone(data)
        self.assertIsInstance(data, pd.DataFrame)
        self.assertGreater(len(data), 0)

        # Check required columns are present
        for col in EventLogLoader.REQUIRED_COLUMNS:
            self.assertIn(col, data.columns)

    def test_load_data_invalid_columns(self):
        """Test loading data with missing required columns."""
        loader = EventLogLoader(self.invalid_csv_path)

        with self.assertRaises(ValueError) as context:
            loader.load_data()

        self.assertIn("Missing required columns", str(context.exception))

    def test_prepare_data(self):
        """Test data preparation."""
        loader = EventLogLoader(self.valid_csv_path)
        loader.load_data()
        prepared = loader.prepare_data()

        # Check data is prepared correctly
        self.assertIsNotNone(prepared)
        self.assertEqual(
            len(prepared.columns), len(loader.raw_data.columns) + 3
        )  # Added derived features

        # Check timestamp conversion
        self.assertEqual(prepared["timestamp"].dtype, "datetime64[ns]")

        # Check sorting
        for case in prepared["case"].unique():
            case_data = prepared[prepared["case"] == case]
            timestamps = case_data["timestamp"].values
            self.assertTrue(
                all(
                    timestamps[i] <= timestamps[i + 1]
                    for i in range(len(timestamps) - 1)
                )
            )

        # Check derived features
        self.assertIn("hour", prepared.columns)
        self.assertIn("day_of_week", prepared.columns)
        self.assertIn("time_since_start", prepared.columns)

    def test_prepare_data_with_edge_cases(self):
        """Test data preparation with edge cases."""
        loader = EventLogLoader(self.edge_cases_csv_path)
        loader.load_data()
        prepared = loader.prepare_data()

        # Should handle null values by removing them
        self.assertFalse(
            prepared[["case", "activity", "timestamp"]].isnull().any().any()
        )

        # Should handle invalid timestamps
        self.assertTrue(all(pd.notna(prepared["timestamp"])))

    def test_get_statistics(self):
        """Test statistics calculation."""
        loader = EventLogLoader(self.valid_csv_path)
        loader.load_data()
        loader.prepare_data()

        stats = loader.get_statistics()

        # Check statistics structure
        self.assertIn("num_events", stats)
        self.assertIn("num_cases", stats)
        self.assertIn("num_activities", stats)
        self.assertIn("activities", stats)
        self.assertIn("date_range", stats)
        self.assertIn("avg_events_per_case", stats)

        # Check statistics values
        self.assertGreater(stats["num_events"], 0)
        self.assertGreater(stats["num_cases"], 0)
        self.assertEqual(stats["num_cases"], 10)  # We created 10 cases
        self.assertIsInstance(stats["activities"], list)

        # Check sepsis statistics
        self.assertIn("sepsis_rate", stats)
        self.assertIn("num_sepsis_cases", stats)
        self.assertEqual(stats["num_sepsis_cases"], 5)  # Half have sepsis

    def test_filter_by_outcome_sepsis(self):
        """Test filtering for sepsis cases."""
        loader = EventLogLoader(self.valid_csv_path)
        loader.load_data()
        loader.prepare_data()

        sepsis_data = loader.filter_by_outcome(sepsis_only=True)

        # Check all filtered cases have sepsis
        sepsis_cases = sepsis_data.groupby("case")["SepsisLabel"].max()
        self.assertTrue(all(sepsis_cases == 1))

        # Check we have the right number of sepsis cases
        self.assertEqual(sepsis_data["case"].nunique(), 5)

    def test_filter_by_outcome_non_sepsis(self):
        """Test filtering for non-sepsis cases."""
        loader = EventLogLoader(self.valid_csv_path)
        loader.load_data()
        loader.prepare_data()

        non_sepsis_data = loader.filter_by_outcome(sepsis_only=False)

        # Check all filtered cases don't have sepsis
        non_sepsis_cases = non_sepsis_data.groupby("case")["SepsisLabel"].max()
        self.assertTrue(all(non_sepsis_cases == 0))

        # Check we have the right number of non-sepsis cases
        self.assertEqual(non_sepsis_data["case"].nunique(), 5)

    def test_sample_cases(self):
        """Test case sampling."""
        loader = EventLogLoader(self.valid_csv_path)
        loader.load_data()
        loader.prepare_data()

        # Sample 3 cases
        sample = loader.sample_cases(n=3, random_state=42)

        self.assertEqual(sample["case"].nunique(), 3)

        # Test reproducibility with same random state
        sample2 = loader.sample_cases(n=3, random_state=42)
        pd.testing.assert_frame_equal(sample, sample2)

        # Test different random state gives different results
        sample3 = loader.sample_cases(n=3, random_state=123)
        self.assertFalse(sample.equals(sample3))

    def test_sample_cases_more_than_available(self):
        """Test sampling more cases than available."""
        loader = EventLogLoader(self.valid_csv_path)
        loader.load_data()
        loader.prepare_data()

        # Try to sample more cases than available
        sample = loader.sample_cases(n=100, random_state=42)

        # Should return all available cases
        self.assertEqual(sample["case"].nunique(), 10)

    @classmethod
    def tearDownClass(cls):
        """Clean up test files."""
        import shutil

        shutil.rmtree(cls.test_dir)


class TestDataLoaderIntegration(unittest.TestCase):
    """Integration tests for the complete data loading pipeline."""

    def setUp(self):
        """Set up integration test data."""
        self.test_dir = tempfile.mkdtemp()
        self.test_file = Path(self.test_dir) / "integration_test.csv"
        self.create_integration_test_data()

    def create_integration_test_data(self):
        """Create a comprehensive test dataset."""
        # Create realistic sepsis progression data
        events = []
        base_time = datetime(2024, 1, 1)

        for case_num in range(20):
            case_id = f"PATIENT_{case_num:04d}"
            case_start = base_time + timedelta(days=case_num)

            # Common pathway
            pathway = [
                ("ED Arrival", 0, "ED_Staff"),
                ("Triage", 0.5, "Triage_Nurse"),
                ("Initial Assessment", 1, "ED_Doctor"),
                ("Blood Culture", 2, "Lab_Tech"),
                ("CBC Test", 2.5, "Lab_Tech"),
            ]

            # Add variation based on case
            if case_num % 3 == 0:  # Sepsis progression
                pathway.extend(
                    [
                        ("High Temperature", 3, "Nurse"),
                        ("Lactate Test", 3.5, "Lab_Tech"),
                        ("Antibiotics Started", 4, "Doctor"),
                        ("Fluid Resuscitation", 4.5, "Nurse"),
                        ("ICU Admission", 6, "ICU_Team"),
                        ("Vasopressors", 8, "ICU_Doctor"),
                    ]
                )
                sepsis_label = 1
            elif case_num % 3 == 1:  # Infection without sepsis
                pathway.extend(
                    [
                        ("Antibiotics Started", 4, "Doctor"),
                        ("Ward Admission", 6, "Ward_Nurse"),
                        ("Recovery", 24, "Ward_Doctor"),
                        ("Discharge", 48, "Discharge_Nurse"),
                    ]
                )
                sepsis_label = 0
            else:  # No infection
                pathway.extend(
                    [
                        ("Observation", 4, "ED_Nurse"),
                        ("Discharge", 6, "Discharge_Nurse"),
                    ]
                )
                sepsis_label = 0

            # Create events
            for activity, hours_offset, resource in pathway:
                events.append(
                    {
                        "case": case_id,
                        "activity": activity,
                        "timestamp": case_start + timedelta(hours=hours_offset),
                        "resource": resource,
                        "lifecycle": "complete",
                        "SepsisLabel": sepsis_label,
                        "activity_instance_id": f"{case_id}_{activity}_{hours_offset}",
                    }
                )

        df = pd.DataFrame(events)
        df.to_csv(self.test_file, index=False)

    def test_complete_pipeline(self):
        """Test the complete data loading and preparation pipeline."""
        # Initialize loader
        loader = EventLogLoader(self.test_file)

        # Load data
        raw_data = loader.load_data()
        self.assertIsNotNone(raw_data)
        self.assertGreater(len(raw_data), 0)

        # Prepare data
        prepared_data = loader.prepare_data()
        self.assertIsNotNone(prepared_data)

        # Get statistics
        stats = loader.get_statistics()
        self.assertEqual(stats["num_cases"], 20)
        self.assertAlmostEqual(stats["sepsis_rate"], 1 / 3, places=1)

        # Filter sepsis cases
        sepsis_data = loader.filter_by_outcome(sepsis_only=True)
        self.assertGreater(len(sepsis_data), 0)

        # Sample cases
        sample = loader.sample_cases(n=5)
        self.assertEqual(sample["case"].nunique(), 5)

    def test_pipeline_with_real_world_scenarios(self):
        """Test pipeline with real-world data scenarios."""
        loader = EventLogLoader(self.test_file)
        loader.load_data()
        prepared = loader.prepare_data()

        # Test that all cases have chronological timestamps
        for case in prepared["case"].unique():
            case_data = prepared[prepared["case"] == case]
            timestamps = case_data["timestamp"].tolist()
            self.assertEqual(timestamps, sorted(timestamps))

        # Test that derived features are calculated correctly
        for case in prepared["case"].unique():
            case_data = prepared[prepared["case"] == case]
            time_since_start = case_data["time_since_start"].values

            # First event should have time_since_start = 0
            self.assertEqual(time_since_start[0], 0)

            # Time should be monotonically increasing
            self.assertTrue(
                all(
                    time_since_start[i] <= time_since_start[i + 1]
                    for i in range(len(time_since_start) - 1)
                )
            )

    def tearDown(self):
        """Clean up integration test files."""
        import shutil

        shutil.rmtree(self.test_dir)


def run_tests():
    """Run all tests with verbose output."""
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Add test classes
    suite.addTests(loader.loadTestsFromTestCase(TestEventLogLoader))
    suite.addTests(loader.loadTestsFromTestCase(TestDataLoaderIntegration))

    # Run tests with verbose output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    # Return success status
    return result.wasSuccessful()


if __name__ == "__main__":
    # Run tests
    success = run_tests()

    # Print summary
    print("\n" + "=" * 60)
    if success:
        print("✅ All tests passed successfully!")
    else:
        print("❌ Some tests failed. Please review the output above.")
    print("=" * 60)
