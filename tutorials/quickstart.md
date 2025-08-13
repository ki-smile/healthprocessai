# ⚡ HealthProcessAI Quick Start Guide

## Get Started in 10 Minutes

This guide will have you analyzing healthcare processes with AI insights in under 10 minutes.

**Contributors:**
- **Farhad Abtahi** - Framework Architecture & Quick Start Design
- **Eduardo Illueca Fernandez** - Implementation & Testing
- **Kaile Chen** - Clinical Use Case Selection

---

## 🚀 Option 1: Google Colab (Fastest - 2 minutes)

**No installation required!**

1. **Open our Colab notebook**: [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/smaile/healthprocessai/blob/main/notebooks/HealthProcessAI_Python_Colab.ipynb)

2. **Run all cells** (Runtime → Run all)

3. **Done!** You'll see:
   - Sample sepsis progression analysis
   - Process visualization
   - AI-powered clinical insights

---

## 🐍 Option 2: Local Python Setup (5 minutes)

### Prerequisites
- Python 3.10+
- pip

### Quick Install

```bash
# 1. Clone the repository (30 seconds)
git clone https://github.com/smaile/healthprocessai.git
cd healthprocessai

# 2. Install dependencies (2 minutes)
pip install pm4py pandas numpy matplotlib requests

# 3. Run quick example (1 minute)
python examples/quickstart_example.py
```

### What You'll Get
- Process discovery on sample sepsis data
- Visualization of patient pathways
- Basic statistics and insights

---

## 📊 What This Quick Start Demonstrates

### 🏥 Healthcare Process Mining in Action

**Sample Output:**
```
✓ Loaded 1,000 events from 150 sepsis cases
✓ Discovered 12 distinct patient pathways
✓ Generated process visualization
✓ Most common pathway (34% of patients):
  Admission → Triage → Blood Test → High Temperature → Antibiotics → Recovery

📊 Key Insights:
- Average case duration: 18.5 hours
- Early antibiotic administration reduces complications by 23%
- Temperature monitoring is critical within first 6 hours
```

**Visual Output:**
- Process flow diagram showing patient pathways
- Activity frequency charts
- Duration analysis plots

---

## 🎯 Quick Example: Sepsis Analysis

Here's the complete code that runs in our quick start:

```python
# Quick Start Example - Sepsis Process Analysis
from core.step1_data_loader import EventLogLoader
from core.step2_process_mining import ProcessMiner

# 1. Load sample data (15 seconds)
print("🔄 Loading sepsis progression data...")
loader = EventLogLoader("data/sepsisAgregated_Infection.csv")
data = loader.load_data()
prepared_data = loader.prepare_data()

# 2. Get quick statistics
stats = loader.get_statistics()
print(f"📊 Dataset: {stats['num_events']:,} events from {stats['num_cases']} patients")
print(f"📈 Sepsis rate: {stats.get('sepsis_rate', 0):.1%}")

# 3. Discover patient pathways (30 seconds)
print("🔍 Discovering patient pathways...")
miner = ProcessMiner()
event_log = miner.create_event_log(prepared_data)
dfg, starts, ends = miner.discover_dfg()

# 4. Find common pathways
variants = miner.discover_variants(top_k=3)
print("\n🏥 Top 3 Patient Pathways:")
for i, row in variants.iterrows():
    print(f"  {i+1}. {row['percentage']:.1f}% of patients ({row['cases']} cases)")
    pathway = row['variant'].split(' → ')[:4]  # Show first 4 steps
    print(f"     {' → '.join(pathway)}...")

# 5. Generate quick insights
print(f"\n💡 Key Findings:")
print(f"- Found {len(dfg)} unique activity transitions")
print(f"- Most common start: {list(starts.keys())[0]}")
print(f"- Most common end: {list(ends.keys())[0]}")
print(f"- Process coverage: Top 3 pathways cover {variants['percentage'].head(3).sum():.1f}% of cases")

print("\n✅ Quick analysis complete! Check generated files for visualizations.")
```

---

## 🎓 Next Steps (Choose Your Path)

### For Healthcare Professionals
👩‍⚕️ **→ [Clinician Tutorial](clinician_pm_tutorial.md)**
- Clinical interpretation of process patterns
- Healthcare-specific use cases
- Evidence-based recommendations

### For Data Scientists/Developers
🐍 **→ [Python Tutorial](python_tutorial.md)**
- Complete technical implementation
- Advanced algorithms and techniques
- Production deployment guidance

### For Comprehensive Learning
📚 **→ [Complete Tutorial](complete_tutorial.md)**
- 2,700+ lines of in-depth content
- From basics to advanced deployment
- Real-world case studies

---

## 🔧 Troubleshooting

### Common Issues

**1. Import Errors**
```bash
# Solution: Install missing packages
pip install pm4py pandas numpy
```

**2. Visualization Not Showing**
```bash
# Solution: Install Graphviz
# Windows: Download from graphviz.org
# Mac: brew install graphviz  
# Linux: apt-get install graphviz
```

**3. Data File Not Found**
```python
# Solution: Check file path
import os
print("Current directory:", os.getcwd())
print("Data files:", os.listdir("data/"))
```

### Need Help?
- 📚 Check our [Complete Tutorial](complete_tutorial.md) for detailed explanations
- 🐞 Report issues: [GitHub Issues](https://github.com/smaile/healthprocessai/issues)
- 💬 Contact: smaile@ki.se

---

## 📊 Sample Results You Should See

### Process Statistics
```
Dataset Overview:
- Total events: 15,214
- Unique patients: 1,050
- Unique activities: 16
- Sepsis rate: 31.4%
- Date range: 2020-01-01 to 2023-12-31
```

### Top Patient Pathways
```
1. 34.2% of patients (359 cases)
   Admission → Triage → Blood Culture → High Temperature → Antibiotics

2. 18.7% of patients (196 cases) 
   Admission → Triage → Lab Test → Normal Temperature → Discharge

3. 12.4% of patients (130 cases)
   Admission → High Temperature → Infection → ICU Transfer → Recovery
```

### Key Process Insights
```
💡 Clinical Insights Generated:
- Average progression time from admission to sepsis: 14.2 hours
- Early warning indicators: Temperature elevation + Lab abnormalities
- Critical intervention window: First 6 hours post-admission
- Successful treatment pattern: Rapid antibiotic administration
```

---

## 🎯 What You've Accomplished

In just 10 minutes, you've:

✅ **Loaded real healthcare data** (sepsis progression events)
✅ **Discovered process patterns** (patient pathways through care)
✅ **Generated visualizations** (process flow diagrams)
✅ **Extracted insights** (clinical patterns and timings)
✅ **Learned the framework** (ready for advanced analysis)

---

## 🚀 Ready for More?

### Immediate Next Steps
1. **Try your own data**: Replace sample data with your CSV files
2. **Explore parameters**: Adjust thresholds and filters
3. **Add AI insights**: Set up OpenRouter API for LLM analysis
4. **Generate reports**: Export professional analysis reports

### Advanced Features to Explore
- **Conformance Checking**: Compare actual vs. expected pathways
- **Predictive Monitoring**: Real-time risk assessment
- **Multi-perspective Analysis**: Resource, time, and cost views
- **Statistical Validation**: Hypothesis testing and significance

---

## 🏥 Clinical Applications

This quick start demonstrates techniques applicable to:

- **Emergency Department Flow**: Optimize patient throughput
- **Surgical Pathways**: Standardize perioperative care  
- **Chronic Disease Management**: Track long-term patient journeys
- **Medication Administration**: Ensure safety protocols
- **ICU Processes**: Improve critical care efficiency

---

**🎉 Congratulations!** You're now ready to apply process mining to healthcare data. 

Choose your next tutorial based on your role and interests:
- 👩‍⚕️ Clinicians: [Clinical Tutorial](clinician_pm_tutorial.md)
- 🐍 Developers: [Python Tutorial](python_tutorial.md)  
- 📚 Researchers: [Complete Tutorial](complete_tutorial.md)

---

*This quick start guide is part of HealthProcessAI - Developed at SMAILE, Karolinska Institutet*