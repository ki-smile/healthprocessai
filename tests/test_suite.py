#!/usr/bin/env python3
"""
================================================================================
COMPREHENSIVE TEST SUITE FOR HEALTHPROCESSAI
================================================================================
This test suite covers all modules of the HealthProcessAI framework:
1. Data Loading (step1_data_loader.py)
2. Process Mining (step2_process_mining.py)
3. LLM Integration (step3_llm_integration.py)
4. Advanced Analytics (step4_advanced_analytics.py)
5. PhysioNet Transformations (example files)

Developed at SMAILE, Karolinska Institutet
================================================================================
"""

import unittest
import pandas as pd

# UNUSED: import numpy as np
from datetime import datetime, timedelta
import tempfile

# UNUSED: import os
# UNUSED: import json
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock
import sys

# Add project root to path for imports
project_root = Path(__file__).parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

# Import all modules to test
try:
    from core.step1_data_loader import EventLogLoader
    from core.step2_process_mining import ProcessMiner
    from core.step3_llm_integration import LLMAnalyzer
    from core.step4_advanced_analytics import AdvancedProcessAnalyzer
    from examples.example_physionet_to_infection import PhysioNetToInfectionTransformer
    from examples.example_physionet_to_organ import PhysioNetToOrganTransformer
except ImportError as e:
    print(f"Warning: Could not import module: {e}")
    print("Some tests may be skipped.")


class TestDataLoader(unittest.TestCase):
    """Test cases for EventLogLoader (step1_data_loader.py)"""

    def setUp(self):
        """Set up test data."""
        self.test_dir = tempfile.mkdtemp()
        self.test_file = Path(self.test_dir) / "test_data.csv"
        self.create_test_data()

    def create_test_data(self):
        """Create test event log data."""
        data = {
            "case": ["P001", "P001", "P001", "P002", "P002"],
            "activity": ["Admission", "Test", "Discharge", "Admission", "ICU"],
            "timestamp": [
                "2024-01-01 10:00",
                "2024-01-01 12:00",
                "2024-01-01 18:00",
                "2024-01-02 09:00",
                "2024-01-02 15:00",
            ],
            "resource": ["Nurse", "Lab", "Doctor", "Nurse", "ICU_Team"],
            "SepsisLabel": [0, 0, 0, 1, 1],
        }
        pd.DataFrame(data).to_csv(self.test_file, index=False)

    def test_load_data(self):
        """Test data loading functionality."""
        loader = EventLogLoader(self.test_file)
        data = loader.load_data()

        self.assertIsNotNone(data)
        self.assertEqual(len(data), 5)
        self.assertIn("case", data.columns)
        self.assertIn("activity", data.columns)

    def test_prepare_data(self):
        """Test data preparation."""
        loader = EventLogLoader(self.test_file)
        loader.load_data()
        prepared = loader.prepare_data()

        # Check timestamp conversion
        self.assertEqual(prepared["timestamp"].dtype, "datetime64[ns]")

        # Check derived features
        self.assertIn("time_since_start", prepared.columns)
        self.assertEqual(prepared["time_since_start"].iloc[0], 0)

    def test_filter_by_outcome(self):
        """Test filtering by sepsis outcome."""
        loader = EventLogLoader(self.test_file)
        loader.load_data()
        loader.prepare_data()

        # Test sepsis filtering
        sepsis_data = loader.filter_by_outcome(sepsis_only=True)
        self.assertEqual(sepsis_data["case"].nunique(), 1)  # Only P002

        # Test non-sepsis filtering
        non_sepsis_data = loader.filter_by_outcome(sepsis_only=False)
        self.assertEqual(non_sepsis_data["case"].nunique(), 1)  # Only P001

    def tearDown(self):
        """Clean up test files."""
        import shutil

        shutil.rmtree(self.test_dir)


class TestProcessMining(unittest.TestCase):
    """Test cases for ProcessMiner (step2_process_mining.py)"""

    def setUp(self):
        """Set up test data."""
        self.test_data = pd.DataFrame(
            {
                "case": ["P001", "P001", "P001", "P002", "P002", "P002"],
                "activity": ["A", "B", "C", "A", "B", "D"],
                "timestamp": pd.date_range("2024-01-01", periods=6, freq="H").tolist()[
                    :3
                ]
                + pd.date_range("2024-01-02", periods=6, freq="H").tolist()[:3],
                "resource": ["R1", "R2", "R3", "R1", "R2", "R4"],
            }
        )

    def test_create_event_log(self):
        """Test event log creation."""
        miner = ProcessMiner()
        event_log = miner.create_event_log(self.test_data)

        self.assertIsNotNone(event_log)
        self.assertEqual(len(event_log), 2)  # Two cases

    def test_discover_dfg(self):
        """Test DFG discovery."""
        miner = ProcessMiner()
        event_log = miner.create_event_log(self.test_data)
        miner.set_event_log(event_log)

        dfg, starts, ends = miner.discover_dfg()

        self.assertIsNotNone(dfg)
        self.assertIn("A", starts)  # A is a start activity
        self.assertIn(("A", "B"), dfg)  # A->B transition exists
        self.assertEqual(dfg[("A", "B")], 2)  # Frequency is 2

    def test_create_process_matrix(self):
        """Test process matrix creation."""
        miner = ProcessMiner()
        event_log = miner.create_event_log(self.test_data)
        miner.set_event_log(event_log)
        miner.discover_dfg()

        matrix = miner.create_process_matrix()

        self.assertIsNotNone(matrix)
        self.assertIn("A", matrix.index)
        self.assertIn("B", matrix.columns)
        self.assertEqual(matrix.loc["A", "B"], 2)  # A->B frequency

    def test_discover_variants(self):
        """Test variant discovery."""
        miner = ProcessMiner()
        event_log = miner.create_event_log(self.test_data)
        miner.set_event_log(event_log)

        variants = miner.discover_variants()

        self.assertIsNotNone(variants)
        self.assertEqual(len(variants), 2)  # Two unique variants
        self.assertIn("A,B,C", variants)
        self.assertIn("A,B,D", variants)


class TestLLMIntegration(unittest.TestCase):
    """Test cases for LLMAnalyzer (step3_llm_integration.py)"""

    def setUp(self):
        """Set up test configuration."""
        self.api_key = "test_api_key"
        self.analyzer = LLMAnalyzer(self.api_key)

    def test_initialization(self):
        """Test LLM analyzer initialization."""
        self.assertEqual(self.analyzer.api_key, self.api_key)
        self.assertEqual(self.analyzer.base_url, "https://openrouter.ai/api/v1")

    def test_create_clinical_prompt(self):
        """Test clinical prompt creation."""
        process_data = {
            "num_cases": 100,
            "sepsis_rate": 0.3,
            "top_activities": ["Admission", "Test", "ICU"],
            "avg_duration": 24.5,
        }

        prompt = self.analyzer.create_clinical_prompt(process_data, "infection")

        self.assertIsNotNone(prompt)
        self.assertIn("100", prompt)  # Contains case count
        self.assertIn("infection", prompt.lower())  # Contains use case

    @patch("requests.post")
    def test_query_model(self, mock_post):
        """Test model querying with mocked API."""
        # Mock API response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "choices": [{"message": {"content": "Test response"}}],
            "usage": {"total_tokens": 100},
        }
        mock_post.return_value = mock_response

        messages = [{"role": "user", "content": "Test prompt"}]
        response = self.analyzer.query_model("test-model", messages)

        self.assertEqual(response["choices"][0]["message"]["content"], "Test response")
        mock_post.assert_called_once()

    def test_generate_clinical_report(self):
        """Test clinical report generation."""
        process_data = {
            "num_cases": 100,
            "sepsis_rate": 0.3,
            "top_activities": ["Admission", "Test", "ICU"],
        }
        model_response = "The analysis shows high sepsis risk in ICU patients."

        report = self.analyzer.generate_clinical_report(process_data, model_response)

        self.assertIn("Clinical Process Mining Report", report)
        self.assertIn("100 cases", report)
        self.assertIn("30.0%", report)  # Sepsis rate
        self.assertIn(model_response, report)


class TestAdvancedAnalytics(unittest.TestCase):
    """Test cases for AdvancedProcessAnalyzer (step4_advanced_analytics.py)"""

    def setUp(self):
        """Set up test event log."""
        # Create test event log data
        self.test_data = pd.DataFrame(
            {
                "case:concept:name": ["P001", "P001", "P001", "P002", "P002", "P002"],
                "concept:name": ["A", "B", "C", "A", "B", "D"],
                "time:timestamp": pd.date_range(
                    "2024-01-01", periods=6, freq="H"
                ).tolist()[:3]
                + pd.date_range("2024-01-02", periods=6, freq="H").tolist()[:3],
                "org:resource": ["R1", "R2", "R3", "R1", "R2", "R4"],
            }
        )

        # Create PM4PY event log
        import pm4py

        self.event_log = pm4py.convert_to_event_log(self.test_data)
        self.analyzer = AdvancedProcessAnalyzer(self.event_log)

    def test_initialization(self):
        """Test analyzer initialization."""
        self.assertIsNotNone(self.analyzer.event_log)
        self.assertIsNone(self.analyzer.process_model)

    def test_cluster_patient_pathways(self):
        """Test patient pathway clustering."""
        result = self.analyzer.cluster_patient_pathways(n_clusters=2)

        self.assertIn("clusters", result)
        self.assertIn("cluster_sizes", result)
        self.assertEqual(len(result["clusters"]), 2)  # Two cases

    def test_analyze_bottlenecks(self):
        """Test bottleneck analysis."""
        result = self.analyzer.analyze_bottlenecks(threshold_percentile=75)

        self.assertIn("bottlenecks", result)
        self.assertIn("statistics", result)
        self.assertIsInstance(result["bottlenecks"], list)

    def test_predict_case_outcome(self):
        """Test case outcome prediction."""
        partial_trace = [
            {"activity": "A", "timestamp": datetime(2024, 1, 1, 10, 0)},
            {"activity": "B", "timestamp": datetime(2024, 1, 1, 11, 0)},
        ]

        result = self.analyzer.predict_case_outcome(partial_trace)

        self.assertIn("prediction", result)
        self.assertIn("confidence", result)
        self.assertIn("next_activities", result)


class TestPhysioNetTransformations(unittest.TestCase):
    """Test cases for PhysioNet data transformations."""

    def test_infection_transformer(self):
        """Test infection/inflammation transformation."""
        transformer = PhysioNetToInfectionTransformer()

        # Test temperature state detection
        self.assertEqual(transformer.detect_temperature_state(38.5), "High Temperature")
        self.assertEqual(
            transformer.detect_temperature_state(37.0), "Normal Temperature"
        )
        self.assertEqual(transformer.detect_temperature_state(35.5), "Low Temperature")

        # Test infection state detection
        test_row = pd.Series(
            {"Temp": 39.0, "WBC": 15.0, "HR": 95, "Resp": 22, "Lactate": 2.5}
        )
        self.assertTrue(transformer.detect_infection_state(test_row))

    def test_organ_transformer(self):
        """Test organ failure transformation."""
        transformer = PhysioNetToOrganTransformer()

        # Test organ dysfunction evaluation
        test_row = pd.Series(
            {
                "MAP": 60,  # Low MAP -> cardiovascular
                "Creatinine": 2.5,  # High creatinine -> renal
                "Bilirubin_total": 3.0,  # High bilirubin -> liver
                "Platelets": 80,  # Low platelets -> coagulation
                "O2Sat": 90,  # Low O2 -> respiratory
                "SepsisLabel": 0,
            }
        )

        organs = transformer.evaluate_all_organ_systems(test_row)
        self.assertIn("cardiovascular", organs)
        self.assertIn("renal", organs)
        self.assertIn("liver", organs)

        # Test event naming
        event = transformer.get_organ_failure_event(organs, 0)
        self.assertEqual(event, "Multiorgan Damage")  # 3+ organs

        # Test sepsis override
        event_sepsis = transformer.get_organ_failure_event(organs, 1)
        self.assertEqual(event_sepsis, "Sepsis")


class TestIntegration(unittest.TestCase):
    """Integration tests for the complete pipeline."""

    def setUp(self):
        """Set up integration test environment."""
        self.test_dir = tempfile.mkdtemp()
        self.create_integration_data()

    def create_integration_data(self):
        """Create comprehensive test data for integration testing."""
        # Create event log
        data = []
        for case_id in range(5):
            base_time = datetime(2024, 1, 1) + timedelta(days=case_id)
            activities = ["Admission", "Triage", "Blood Test", "Treatment", "Discharge"]

            for i, activity in enumerate(activities):
                data.append(
                    {
                        "case": f"P{case_id:03d}",
                        "activity": activity,
                        "timestamp": base_time + timedelta(hours=i * 2),
                        "resource": f"Resource_{i}",
                        "SepsisLabel": 1 if case_id < 2 else 0,
                    }
                )

        self.test_file = Path(self.test_dir) / "integration_test.csv"
        pd.DataFrame(data).to_csv(self.test_file, index=False)

    def test_complete_pipeline(self):
        """Test the complete analysis pipeline."""
        # Step 1: Load data
        loader = EventLogLoader(self.test_file)
        data = loader.load_data()
        prepared = loader.prepare_data()

        # Step 2: Process mining
        miner = ProcessMiner()
        event_log = miner.create_event_log(prepared)
        dfg, starts, ends = miner.discover_dfg()

        # Step 3: Advanced analytics
        analyzer = AdvancedProcessAnalyzer(event_log)
        clusters = analyzer.cluster_patient_pathways()

        # Verify results
        self.assertIsNotNone(data)
        self.assertIsNotNone(event_log)
        self.assertIsNotNone(dfg)
        self.assertIsNotNone(clusters)
        self.assertEqual(len(event_log), 5)  # 5 cases

    def tearDown(self):
        """Clean up test files."""
        import shutil

        shutil.rmtree(self.test_dir)


class TestEdgeCases(unittest.TestCase):
    """Test edge cases and error handling."""

    def test_empty_data(self):
        """Test handling of empty data."""
        empty_df = pd.DataFrame()
        miner = ProcessMiner()

        with self.assertRaises(Exception):
            miner.create_event_log(empty_df)

    def test_missing_columns(self):
        """Test handling of missing required columns."""
        incomplete_df = pd.DataFrame(
            {
                "case": ["P001"],
                "activity": ["Test"],
                # Missing timestamp
            }
        )

        miner = ProcessMiner()
        with self.assertRaises(Exception):
            miner.create_event_log(incomplete_df)

    def test_invalid_timestamps(self):
        """Test handling of invalid timestamps."""
        df = pd.DataFrame(
            {"case": ["P001"], "activity": ["Test"], "timestamp": ["invalid_date"]}
        )

        # Should handle gracefully or raise appropriate error
        loader = EventLogLoader.__new__(EventLogLoader)
        loader.raw_data = df

        with self.assertRaises(Exception):
            loader.prepare_data()

    def test_null_values(self):
        """Test handling of null values."""
        df = pd.DataFrame(
            {
                "case": ["P001", None, "P002"],
                "activity": ["A", "B", None],
                "timestamp": ["2024-01-01", "2024-01-02", "2024-01-03"],
            }
        )

        # Should handle nulls appropriately
        # Implementation depends on module's null handling strategy


def run_all_tests():
    """Run all test suites with detailed reporting."""
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Add all test classes
    test_classes = [
        TestDataLoader,
        TestProcessMining,
        TestLLMIntegration,
        TestAdvancedAnalytics,
        TestPhysioNetTransformations,
        TestIntegration,
        TestEdgeCases,
    ]

    for test_class in test_classes:
        suite.addTests(loader.loadTestsFromTestCase(test_class))

    # Run tests with detailed output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    # Print summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Tests run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print(f"Skipped: {len(result.skipped)}")

    if result.wasSuccessful():
        print("\n✅ ALL TESTS PASSED!")
    else:
        print("\n❌ SOME TESTS FAILED")
        if result.failures:
            print("\nFailed tests:")
            for test, traceback in result.failures:
                print(f"  - {test}")
        if result.errors:
            print("\nTests with errors:")
            for test, traceback in result.errors:
                print(f"  - {test}")

    print("=" * 70)

    return result.wasSuccessful()


if __name__ == "__main__":
    # Run all tests
    success = run_all_tests()

    # Exit with appropriate code
    sys.exit(0 if success else 1)
