# Process Mining Analysis of eGFR Progression: PPI vs. H2 Blocker Cohorts

**To:** Clinical and Epidemiological Stakeholders  
**From:** Process Mining Analysis Team  
**Date:** October 26, 2023  
**Subject:** Comparative Analysis of CKD Progression in Patients Exposed to Proton Pump Inhibitors (PPIs) vs. H2 Blockers (H2Bs)

### 1. Executive Summary

This report presents a process mining analysis of renal function decline, measured by the estimated Glomerular Filtration Rate (eGFR), comparing two patient cohorts: those exposed to Proton Pump Inhibitors (PPIs) and those exposed to H2 Blockers (H2Bs). Our analysis reveals significant differences in the progression pathways of Chronic Kidney Disease (CKD) between these two groups.

**Key Findings:**

*   **Higher Disease Burden at Start:** A substantially larger cohort of patients was identified in the PPI group (11,486 cases vs. 557 in the H2B group). Critically, patients in the PPI group were more likely to start the observation period at a more advanced stage of CKD (11.3% starting in G4/G5 vs. 6.5% in the H2B group).
*   **Greater Volume of Progression:** While the proportional rate of progression to a worse CKD stage was similar between groups (~8-9%), the absolute number of patients experiencing a decline in renal function was dramatically higher in the PPI cohort.
*   **Faster Progression Dynamics in PPI Group:** Transitions towards more severe CKD stages occurred more rapidly in the PPI group. For instance, the average time to progress from G1/G2 to G3 was **9.4 weeks** for PPI users, compared to **12.1 weeks** for H2B users.
*   **Slightly Higher Recovery in H2B Group:** The H2B cohort demonstrated a slightly higher proportional rate of recovery (i.e., improvement in eGFR stage) compared to the PPI cohort (6.6% vs. 5.9% of all transitions).

**Key Recommendation:**

We recommend a targeted epidemiological investigation to determine if the observed association between PPI use and accelerated CKD progression is causal or confounded by other patient characteristics. In the interim, we suggest a review of monitoring protocols for patients on long-term PPI therapy, particularly those with pre-existing mild to moderate kidney disease.

---

### 2. Introduction

The purpose of this report is to leverage process mining to visualize and analyze the real-world patient journeys of Chronic Kidney Disease (CKD) progression. By mapping the transitions between different stages of kidney function, we aim to identify patterns, compare outcomes between patient groups, and generate data-driven hypotheses for improving patient care.

This analysis is based on retrospective longitudinal data of two distinct patient cohorts:
1.  **PPI Cohort:** 11,486 patients with a history of PPI exposure.
2.  **H2B Cohort:** 557 patients with a history of H2B exposure, serving as a comparator group.

eGFR progression has been modeled according to the KDIGO classification, grouped into the following states for this analysis:
*   **G1 or G2:** Normal to mildly decreased eGFR (≥ 60 mL/min/1.73 m²)
*   **G3:** Mildly to severely decreased eGFR (30-59 mL/min/1.73 m²)
*   **G4 or G5:** Severely decreased eGFR or kidney failure (< 30 mL/min/1.73 m²)

---

### 3. Process Map Analysis

The process maps reveal the common pathways of eGFR evolution over time. For both groups, the most frequent activity is remaining within the same CKD stage, highlighting the chronic nature of the condition. However, critical differences emerge when comparing the transitions between the PPI and H2B cohorts.

**PPI Cohort - Key Observations:**

*   **Most Frequent State:** The `G3` state is the central hub of activity, with patients frequently entering, leaving, and remaining in this stage. The transition **`G3` -> `G3`** is the most common path, occurring **82,638 times**. This indicates that once patients reach moderate CKD, they often experience a prolonged period in this stage.
*   **Significant Progression Pathway:** A high volume of patients progress to more severe CKD. The transition from **`G3` -> `G4 or G5`** is a highly frequent pathway, observed **8,485 times**.
*   **Rapid Progression Time:** The average time for progression appears shorter than in the H2B group. The transition from **`G1 or G2` -> `G3`** takes an average of **9.4 weeks**, and from **`G3` -> `G4 or G5`** takes **7.5 weeks**.

**H2B Cohort - Key Observations:**

*   **Similar Central Hub:** The `G3` state is also the most common state, with **`G3` -> `G3`** being the most frequent transition (**4,397 times**).
*   **Lower Volume of Progression:** While progression occurs, the absolute number of transitions to worse stages is significantly lower. The transition from **`G3` -> `G4 or G5`** was observed only **329 times**.
*   **Slower Progression Time:** Transitions representing a decline in kidney function take longer on average. Progressing from **`G1 or G2` -> `G3`** took **12.1 weeks**, nearly 3 weeks longer than in the PPI group.
*   **Slower Recovery Time:** Interestingly, transitions representing an improvement in kidney function also took longer. The average time for **`G3` -> `G1 or G2`** was **13.1 weeks**, compared to 10.7 weeks in the PPI cohort. This may reflect different monitoring intervals or underlying biological differences.

---

### 4. Data Summary Tables

***Note on Data Limitations:*** *The provided process matrices summarize transitions between states, not complete end-to-end patient traces. Therefore, metrics like "unique traces" and overall "case duration" cannot be calculated. The tables below have been adapted to present the most relevant information derivable from the data.*

#### Table 1: Case Summary

| Metric | PPI Cohort | H2B Cohort | Key Insight |
| :--- | :--- | :--- | :--- |
| **Total Number of Cases** | 11,486 | 557 | The PPI cohort is over 20 times larger. |
| **Cases Starting in G3** | 10,187 (88.7%) | 521 (93.5%) | Both groups predominantly start in G3. |
| **Cases Starting in G4/G5** | 1,299 (11.3%) | 36 (6.5%) | PPI patients are more likely to start at a severe stage. |
| **Unique Traces (Variants)** | N/A from data | N/A from data | - |
| **Median/Average Case Duration** | N/A from data | N/A from data | - |

#### Table 2: Activity Summary (CKD Stages)

| Activity (State) | Metric | PPI Cohort | H2B Cohort |
| :--- | :--- | :--- | :--- |
| **G1 or G2** | Frequency (Times Entered) | 33,424 | 1,842 |
| | Avg. Duration of Stay (Weeks) | 6.7 | 8.5 |
| **G3** | Frequency (Times Entered) | 98,158 | 5,144 |
| | Avg. Duration of Stay (Weeks) | 8.3 | 10.4 |
| **G4 or G5** | Frequency (Times Entered) | 47,075 | 1,590 |
| | Avg. Duration of Stay (Weeks) | 3.1 | 2.8 |

*Avg. Duration of Stay is calculated from self-loop transitions (e.g., G3 -> G3) and represents the average time between two consecutive measurements within the same stage.*

#### Table 3: Top 5 Most Frequent Transitions

| Rank | PPI Cohort Transition | Frequency | H2B Cohort Transition | Frequency |
| :--- | :--- | :--- | :--- | :--- |
| **1** | `G3` -> `G3` | 82,638 | `G3` -> `G3` | 4,397 |
| **2** | `G4 or G5` -> `G4 or G5` | 38,313 | `G4 or G5` -> `G4 or G5` | 1,250 |
| **3** | `G1 or G2` -> `G1 or G2` | 22,484 | `G1 or G2` -> `G1 or G2` | 1,234 |
| **4** | `G3` -> `G1 or G2` (Recovery) | 10,829 | `G3` -> `G1 or G2` (Recovery) | 603 |
| **5** | `Start` -> `G3` | 10,187 | `Start` -> `G3` | 521 |

---

### 5. Hypothesis for eGFR Progression

The process mining analysis provides a clear, quantitative foundation for generating new hypotheses regarding the association between acid-suppressive therapy and CKD.

**Hypotheses & Research Questions:**

1.  **Hypothesis of Association:** Long-term PPI exposure is associated with an accelerated progression of CKD compared to H2B exposure. The shorter transition times for progression in the PPI group strongly support this hypothesis.
    *   **Research Question:** Is this association causal? Does PPI use directly contribute to kidney injury (e.g., via acute interstitial nephritis), or is it a marker for a sicker patient population?

2.  **Hypothesis of Confounding by Indication:** Patients prescribed PPIs may have a higher burden of comorbidities (e.g., diabetes, cardiovascular disease, obesity) that are independent risk factors for CKD progression. The finding that PPI patients start at more advanced CKD stages lends weight to this hypothesis.
    *   **Research Question:** Does the association between PPI use and CKD progression persist after rigorous adjustment for baseline eGFR, comorbidities, and concomitant medications in a matched-cohort study?

3.  **Hypothesis on Monitoring and Detection:** The shorter transition times in the PPI group could reflect more frequent clinical monitoring due to a higher perceived risk, leading to earlier detection of eGFR changes. Conversely, it could reflect a more aggressive underlying biological process.
    *   **Research Question:** Are clinical follow-up intervals different between long-term PPI and H2B users? Can we model the true rate of eGFR decline to distinguish between biological progression and measurement frequency?

**Recommendations for eGFR Prediction:**

*   **Enhance Prediction Models:** Current eGFR prediction models should be evaluated to see if including PPI exposure as a variable improves their accuracy.
*   **Risk Stratification:** Develop a risk score for patients initiating PPI therapy to identify those at high risk for CKD progression who may benefit from more intensive monitoring or alternative therapies.
*   **Time-to-Event Analysis:** The next logical step is to perform a time-to-event (survival) analysis to formally model the time to transition to a worse CKD stage, adjusting for potential confounders.

---

### 6. Conclusion

This process mining analysis has successfully visualized and quantified the differing pathways of CKD progression between patients exposed to PPIs and H2Bs. The data clearly shows that the **PPI cohort is not only larger but also appears to follow a more aggressive and rapid trajectory of renal function decline.** While these findings are associative and not causal, they raise important questions about patient safety and management.

**Summary of Main Findings:**

*   Patients in the PPI cohort start with a higher burden of kidney disease.
*   The absolute number of patients progressing to worse CKD stages is substantially higher in the PPI group.
*   The speed of progression, measured by the average time between stages, is faster in the PPI group.

**Key Recommendations:**

1.  **Initiate a Formal Epidemiological Study:** Conduct a robust, adjusted analysis (e.g., propensity score matching) to disentangle the effects of PPIs from underlying patient risk factors.
2.  **Review Clinical Monitoring Guidelines:** Consider recommending more frequent eGFR monitoring (e.g., annually) for patients on long-term PPIs, especially those with baseline eGFR < 60.
3.  **Promote Prescribing Stewardship:** Encourage periodic review of the need for long-term PPI therapy ("deprescribing") in patients where the indication is no longer strong, particularly those at risk for CKD.

**Next Steps:**

We propose a collaborative workshop with the clinical and epidemiology teams to discuss these findings in greater detail. The goal of this workshop will be to review the patient-level data, refine the research questions, and co-design the protocol for the recommended follow-up study.
