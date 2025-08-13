#!/usr/bin/env python3
"""
Comprehensive Health Check for HealthProcessAI
==============================================
This script performs a complete health check of the codebase including:
- Code quality checks (Black, flake8, mypy)
- Unit tests
- Integration tests
- Import verification
- Pipeline functionality
"""

import subprocess
import sys
import os
from pathlib import Path
from typing import Tuple, List, Dict
import json
import time
from datetime import datetime


class ComprehensiveHealthChecker:
    """Comprehensive health check for the entire codebase"""

    def __init__(self):
        self.results = {}
        self.start_time = time.time()
        self.passed_checks = 0
        self.failed_checks = 0
        self.warnings = 0

    def run_command(self, cmd: List[str], description: str) -> Tuple[bool, str]:
        """Run a command and return success status and output"""
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            return result.returncode == 0, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return False, f"Command timed out: {' '.join(cmd)}"
        except Exception as e:
            return False, str(e)

    def check_imports(self) -> Dict:
        """Check if all modules can be imported"""
        print("\n🔍 Checking Python imports...")
        results = {"passed": [], "failed": []}

        modules = [
            "core.step1_data_loader",
            "core.step2_process_mining",
            "core.step3_llm_integration",
            "core.step4_advanced_analytics",
            "core.step5_orchestrator",
            "core.report_generator",
        ]

        for module in modules:
            try:
                exec(f"import {module}")
                results["passed"].append(module)
                print(f"  ✅ {module}")
            except ImportError as e:
                results["failed"].append({"module": module, "error": str(e)})
                print(f"  ❌ {module}: {e}")
            except Exception as e:
                results["failed"].append({"module": module, "error": str(e)})
                print(f"  ⚠️  {module}: {e}")

        return results

    def check_black_formatting(self) -> Dict:
        """Check if code is Black formatted"""
        print("\n🎨 Checking Black formatting...")
        success, output = self.run_command(
            [
                "black",
                "--check",
                ".",
                "--exclude",
                "venv|build|dist|website|legacy_original",
            ],
            "Black formatting check",
        )

        if success:
            print("  ✅ All files are properly formatted")
            return {
                "status": "passed",
                "files_checked": output.count("would be left unchanged"),
            }
        else:
            unformatted = output.count("would be reformatted")
            print(f"  ⚠️  {unformatted} files need formatting")
            return {
                "status": "warning",
                "files_need_formatting": unformatted,
                "output": output,
            }

    def check_flake8(self) -> Dict:
        """Run flake8 linting"""
        print("\n📝 Running flake8 linting...")
        success, output = self.run_command(
            [
                "flake8",
                "--count",
                "--statistics",
                "--exit-zero",
                "core",
                "examples",
                "tests",
            ],
            "Flake8 linting",
        )

        # Count issues
        lines = output.strip().split("\n")
        issue_count = 0
        if lines and lines[-1].isdigit():
            issue_count = int(lines[-1])

        if issue_count == 0:
            print("  ✅ No flake8 issues found")
            return {"status": "passed", "issues": 0}
        else:
            print(f"  ⚠️  {issue_count} flake8 issues found")
            # Get statistics
            stats = {}
            for line in lines:
                # Statistics lines look like: "79    E402 module level import not at top of file"
                line = line.strip()
                if line and line[0].isdigit() and "    " in line:
                    parts = line.split("    ")
                    if len(parts) >= 2:
                        try:
                            count = int(parts[0])
                            code = parts[1].split()[0] if parts[1] else "Unknown"
                            stats[code] = count
                        except (ValueError, IndexError):
                            continue

            return {"status": "warning", "issues": issue_count, "statistics": stats}

    def check_mypy(self) -> Dict:
        """Run mypy type checking"""
        print("\n🔎 Running mypy type checking...")
        success, output = self.run_command(
            ["mypy", "--ignore-missing-imports", "--no-error-summary", "core"],
            "MyPy type checking",
        )

        if success:
            print("  ✅ No type errors found")
            return {"status": "passed", "errors": 0}
        else:
            error_count = output.count("error:")
            print(f"  ⚠️  {error_count} type errors found")
            return {"status": "warning", "errors": error_count, "sample": output[:500]}

    def run_unit_tests(self) -> Dict:
        """Run unit tests"""
        print("\n🧪 Running unit tests...")

        # Check if pytest is available
        success, _ = self.run_command(["pytest", "--version"], "Check pytest")
        if not success:
            print("  ⚠️  pytest not installed, trying unittest...")
            success, output = self.run_command(
                [
                    "python",
                    "-m",
                    "unittest",
                    "discover",
                    "-s",
                    "tests",
                    "-p",
                    "test*.py",
                ],
                "Unit tests",
            )
        else:
            success, output = self.run_command(
                ["pytest", "tests/", "-v", "--tb=short"], "Unit tests"
            )

        if success:
            print("  ✅ All unit tests passed")
            return {"status": "passed", "output": output}
        elif "Ran 0 tests" in output or "no tests ran" in output.lower():
            print("  ℹ️  No tests found to run")
            return {"status": "skipped", "reason": "No tests found"}
        else:
            print("  ❌ Some unit tests failed")
            return {"status": "failed", "output": output}

    def test_basic_pipeline(self) -> Dict:
        """Test basic process mining pipeline"""
        print("\n⚙️  Testing basic pipeline functionality...")

        test_script = """
import sys
import warnings
warnings.filterwarnings("ignore")

try:
    # Test data loading
    from core.step1_data_loader import EventLogLoader
    loader = EventLogLoader("data/sepsisAgregated_Infection.csv")
    data = loader.load_data()
    print(f"  ✓ Data loaded: {len(data)} rows")
    
    # Test data preparation
    prepared = loader.prepare_data()
    print(f"  ✓ Data prepared: {len(prepared)} rows")
    
    # Test process mining
    from core.step2_process_mining import ProcessMiner
    miner = ProcessMiner()
    event_log = miner.create_event_log(prepared)
    print(f"  ✓ Event log created: {len(event_log)} cases")
    
    # Test statistics
    stats = miner.calculate_process_metrics()
    print(f"  ✓ Statistics calculated: {stats.get('num_cases', 0)} cases, {stats.get('num_events', 0)} events")
    
    # Test variant analysis
    variants = miner.discover_variants()
    print(f"  ✓ Variants analyzed: {len(variants)} unique variants")
    
    print("SUCCESS")
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
"""

        # Write test script
        test_file = Path("test_pipeline_temp.py")
        test_file.write_text(test_script)

        try:
            success, output = self.run_command(
                ["python", str(test_file)], "Pipeline test"
            )

            if success and "SUCCESS" in output:
                print("  ✅ Pipeline functionality verified")
                # Parse output for details
                details = {}
                for line in output.split("\n"):
                    if "✓" in line:
                        print(f"  {line.strip()}")

                return {"status": "passed", "details": output}
            else:
                print("  ❌ Pipeline test failed")
                return {"status": "failed", "error": output}
        finally:
            # Clean up
            if test_file.exists():
                test_file.unlink()

    def test_example_scripts(self) -> Dict:
        """Test that example scripts can at least be imported"""
        print("\n📚 Testing example scripts...")

        examples = [
            "examples/example_patient_flow.py",
            "examples/example_transform_raw_to_eventlog.py",
            "examples/example_physionet_to_infection.py",
            "examples/example_physionet_to_organ.py",
        ]

        results = {"passed": [], "failed": []}

        for example in examples:
            if Path(example).exists():
                # Try to compile the script
                try:
                    with open(example, "r") as f:
                        compile(f.read(), example, "exec")
                    print(f"  ✅ {Path(example).name} - syntax OK")
                    results["passed"].append(example)
                except SyntaxError as e:
                    print(f"  ❌ {Path(example).name} - syntax error: {e}")
                    results["failed"].append({"file": example, "error": str(e)})
            else:
                print(f"  ⚠️  {example} not found")

        return results

    def check_dependencies(self) -> Dict:
        """Check if all required dependencies are installed"""
        print("\n📦 Checking dependencies...")

        required = [
            "pandas",
            "numpy",
            "pm4py",
            "requests",
            "matplotlib",
            "graphviz",
        ]

        results = {"installed": [], "missing": []}

        for package in required:
            try:
                __import__(package)
                print(f"  ✅ {package}")
                results["installed"].append(package)
            except ImportError:
                print(f"  ❌ {package} - not installed")
                results["missing"].append(package)

        return results

    def run_all_checks(self):
        """Run all health checks"""
        print("=" * 60)
        print("🏥 COMPREHENSIVE HEALTH CHECK")
        print("=" * 60)
        print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

        # Check dependencies
        dep_results = self.check_dependencies()
        self.results["dependencies"] = dep_results
        if dep_results["missing"]:
            self.failed_checks += 1
        else:
            self.passed_checks += 1

        # Check imports
        import_results = self.check_imports()
        self.results["imports"] = import_results
        if import_results["failed"]:
            self.failed_checks += 1
        else:
            self.passed_checks += 1

        # Check Black formatting
        black_results = self.check_black_formatting()
        self.results["black"] = black_results
        if black_results["status"] == "passed":
            self.passed_checks += 1
        elif black_results["status"] == "warning":
            self.warnings += 1
        else:
            self.failed_checks += 1

        # Check flake8
        flake8_results = self.check_flake8()
        self.results["flake8"] = flake8_results
        if flake8_results["status"] == "passed":
            self.passed_checks += 1
        elif flake8_results["status"] == "warning":
            self.warnings += 1
        else:
            self.failed_checks += 1

        # Check mypy
        mypy_results = self.check_mypy()
        self.results["mypy"] = mypy_results
        if mypy_results["status"] == "passed":
            self.passed_checks += 1
        elif mypy_results["status"] == "warning":
            self.warnings += 1
        else:
            self.failed_checks += 1

        # Run unit tests
        test_results = self.run_unit_tests()
        self.results["unit_tests"] = test_results
        if test_results["status"] == "passed":
            self.passed_checks += 1
        elif test_results["status"] == "skipped":
            self.warnings += 1
        else:
            self.failed_checks += 1

        # Test pipeline
        pipeline_results = self.test_basic_pipeline()
        self.results["pipeline"] = pipeline_results
        if pipeline_results["status"] == "passed":
            self.passed_checks += 1
        else:
            self.failed_checks += 1

        # Test examples
        example_results = self.test_example_scripts()
        self.results["examples"] = example_results
        if not example_results["failed"]:
            self.passed_checks += 1
        else:
            self.failed_checks += 1

        # Summary
        self.print_summary()

        # Save results
        self.save_results()

        return self.failed_checks == 0

    def print_summary(self):
        """Print health check summary"""
        elapsed = time.time() - self.start_time

        print("\n" + "=" * 60)
        print("📊 HEALTH CHECK SUMMARY")
        print("=" * 60)

        total_checks = self.passed_checks + self.failed_checks + self.warnings

        print(f"\n✅ Passed:  {self.passed_checks}/{total_checks}")
        print(f"⚠️  Warnings: {self.warnings}/{total_checks}")
        print(f"❌ Failed:  {self.failed_checks}/{total_checks}")

        print(f"\n⏱️  Time elapsed: {elapsed:.2f} seconds")

        # Overall status
        if self.failed_checks == 0:
            if self.warnings == 0:
                print("\n🎉 PERFECT HEALTH - All checks passed!")
            else:
                print("\n✅ GOOD HEALTH - All critical checks passed (with warnings)")
        else:
            print("\n⚠️  NEEDS ATTENTION - Some checks failed")

        # Specific issues
        if self.results.get("dependencies", {}).get("missing"):
            print("\n📦 Missing dependencies:")
            for pkg in self.results["dependencies"]["missing"]:
                print(f"  - {pkg}")

        if self.results.get("flake8", {}).get("issues", 0) > 0:
            print(
                f"\n📝 Code quality: {self.results['flake8']['issues']} flake8 issues"
            )
            if "statistics" in self.results["flake8"]:
                top_issues = sorted(
                    self.results["flake8"]["statistics"].items(),
                    key=lambda x: x[1],
                    reverse=True,
                )[:3]
                print("  Top issues:")
                for code, count in top_issues:
                    print(f"    - {code}: {count} occurrences")

    def save_results(self):
        """Save results to JSON file"""
        results_file = Path("health_check_results.json")

        # Convert results to JSON-serializable format
        json_results = {
            "timestamp": datetime.now().isoformat(),
            "summary": {
                "passed": self.passed_checks,
                "warnings": self.warnings,
                "failed": self.failed_checks,
            },
            "results": self.results,
        }

        with open(results_file, "w") as f:
            json.dump(json_results, f, indent=2, default=str)

        print(f"\n📄 Detailed results saved to: {results_file}")


def main():
    """Run comprehensive health check"""
    checker = ComprehensiveHealthChecker()
    success = checker.run_all_checks()

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
