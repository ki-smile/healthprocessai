// Prompts Data for LLM Analysis and Orchestration
const promptsData = {
    analysis: {
        case1: {
            title: "Case I - Infection Progression",
            description: "Prompt for analyzing infection progression patterns in sepsis patients",
            prompt: `You are an expert on process mining analyst applied to epidemiology with high skills for communicating complex data to a clinical audience in a clear, concise, and actionable manner. 

Your task is to generate a comprehensive report based on the provided process mining analysis. This analysis is composed of a process matrix and a process map, attached. The target audience for this report is a group of clinical and epidemiological stakeholders working on sepsis progression modelling. The report should be written in a professional and collaborative tone, avoiding overly technical jargon where possible. The goal is to provide them with a clear understanding of the current process, identify areas for improvement, and suggest actionable recommendations to enhance patient care and operational efficiency.

The report should be structured as a Markdown (.md) file with the following sections. Remove the \`\`\`markdown at the beginning:

1. **Executive Summary**: Provide a high-level overview of the key findings and recommendations. This section should be concise and easily digestible for busy clinical leaders. Highlight the most important findings in sepsis progression.

2. **Introduction**: State the purpose of the report: to analyze sepsis progression using process mining to identify inefficiencies and opportunities for improvement. Briefly describe the dataset used for the analysis, including the time frame of the data and the number of cases analyzed. Sepsis progression has been modelled according to the following states: 
   - i) low temperature
   - ii) normal temperature
   - iii) high temperature
   - iv) infection
   - v) sepsis
   
   It is important to note that infection can be combined with the temperature in a specific state (eg. High Temperature + Infection). Last, all the transitions are reversible.

3. **Process Map Analysis**: Provide a narrative description of the main pathway discovered in the process map, identify the most frequent activities and transitions and highlight any significant variations or loops from the expected sepsis progression. Highlight the top 3-5 most frequent activities (nodes) and explain their role in the process, detailing the most common transitions between activities and their frequencies.

4. **Data Summary Tables**: Generate the following three tables in Markdown format:
   - **Table 1: Case Summary**
     - Total number of cases
     - Number of unique traces (variants)
     - Median and average case duration
     - Duration of the shortest and longest cases
   - **Table 2: Activity Summary**
     - List of all activities discovered
     - Frequency of each activity (how many times it appears in the logs)
     - Median and average time spent in each activity
   - **Table 3: Trace Summary**
     - List the top 5 most frequent process variants (traces)
     - For each trace, show the percentage of cases that follow it and its median duration

5. **Hypothesis for Sepsis Progression**: This section should interpret the sepsis progression in the process map, and propose new hypothesis and research questions. In addition, it should propose recommendations and next steps for sepsis prediction in a reasonable time.

6. **Conclusion**: 
   - Summarize the main findings of the analysis
   - Reiterate the key recommendations
   - Suggest next steps, such as a workshop with the clinical team to discuss the findings and co-design solutions

Please use clear headings, bullet points, and bold text to structure the report for maximum readability. Ensure that all tables are correctly formatted in Markdown.`
        },
        case2: {
            title: "Case II - Organ Damage",
            description: "Prompt for analyzing organ damage patterns in sepsis vs non-sepsis patients",
            prompt: `You are an expert on process mining analyst applied to epidemiology with high skills for communicating complex data to a clinical audience in a clear, concise, and actionable manner. 

Your task is to generate a comprehensive report based on the provided process mining analysis. This analysis is composed of two process matrix, attached. The first one describes the progression with patients with sepsis while the second one describes the progression of patients where sepsis is not detected. You should highlight the differences between these two groups. The target audience for this report is a group of clinical and epidemiological stakeholders working on sepsis progression modelling. 

The report should be written in a professional and collaborative tone, avoiding overly technical jargon where possible. The goal is to provide them with a clear understanding of the current process, identify areas for improvement, and suggest actionable recommendations to enhance patient care and operational efficiency.

The report should be structured as a Markdown (.md) file with the following sections. Remove the \`\`\`markdown at the beginning:

1. **Executive Summary**: Provide a high-level overview of the key findings and recommendations. This section should be concise and easily digestible for busy clinical leaders. Highlight the most important findings in sepsis progression.

2. **Introduction**: State the purpose of the report: to analyze sepsis progression using process mining to identify inefficiencies and opportunities for improvement. Briefly describe the dataset used for the analysis, including the time frame of the data and the number of cases analyzed. Sepsis progression has been modelled according to the following states:
   - i) low risk
   - ii) cardiac damage
   - iii) renal damage
   - iv) liver damage
   - v) sepsis
   
   It is important to note that two organ damages can be combined in a specific state (eg. Cardiac Damage + Liver Damage). However, the combination of two or more organ damages leads to Multiorgan Damage state. Last, all the transitions are irreversible (except for the low risk state).

3. **Process Map Analysis**: Provide a narrative description of the main pathway discovered in the process map, identify the most frequent activities and transitions and highlight any significant variations or loops from the expected sepsis progression. Highlight the top 3-5 most frequent activities (nodes) and explain their role in the process, detailing the most common transitions between activities and their frequencies.

4. **Data Summary Tables**: Generate the following three tables in Markdown format:
   - **Table 1: Case Summary**
   - **Table 2: Activity Summary**
   - **Table 3: Trace Summary**

5. **Hypothesis for Sepsis Progression**: This section should interpret the sepsis progression in the process map, and propose new hypothesis and research questions. In addition, it should propose recommendations and next steps for sepsis prediction in a reasonable time.

6. **Conclusion**: Summarize the main findings of the analysis, reiterate the key recommendations, and suggest next steps.

Please use clear headings, bullet points, and bold text to structure the report for maximum readability. Ensure that all tables are correctly formatted in Markdown.`
        },
        case3: {
            title: "Case III - Glomerular Filtration Rate",
            description: "Prompt for analyzing kidney function progression with medication comparison",
            prompt: `You are an expert on process mining analyst applied to epidemiology with high skills for communicating complex data to a clinical audience in a clear, concise, and actionable manner. 

Your task is to generate a comprehensive report based on the provided process mining analysis. This analysis is composed of two process matrices comparing disease progression for two groups of patients: those taking PPI (Proton Pump Inhibitors) and those taking H2B (H2 Blockers). The target audience for this report is a group of clinical and epidemiological stakeholders working on kidney disease progression modelling.

The report should be written in a professional and collaborative tone, avoiding overly technical jargon where possible. The goal is to provide them with a clear understanding of the current process, identify differences between medication groups, and suggest actionable recommendations to enhance patient care and operational efficiency.

The report should be structured as a Markdown (.md) file with the following sections:

1. **Executive Summary**: Provide a high-level overview of the key findings and recommendations, highlighting differences between PPI and H2B groups.

2. **Introduction**: State the purpose of the report: to analyze kidney disease progression using process mining to identify differences between medication groups. Describe the dataset used for the analysis. The progression has been modelled according to GFR (Glomerular Filtration Rate) stages:
   - G1/G2: Normal or mildly decreased GFR
   - G3: Moderately decreased GFR
   - G4/G5: Severely decreased or kidney failure
   - End: Death or end of observation

3. **Process Map Analysis**: Provide a narrative description comparing the main pathways for PPI vs H2B groups, identify the most frequent transitions and their timing differences.

4. **Data Summary Tables**: Generate comparison tables showing differences between PPI and H2B groups in:
   - Case summaries
   - Activity frequencies
   - Transition patterns
   - Duration metrics

5. **Hypothesis for Disease Progression**: Interpret the differences in progression patterns between medication groups, propose hypotheses for observed differences, and suggest research questions.

6. **Conclusion**: Summarize the main findings, particularly the comparative analysis between medication groups, and suggest clinical implications.

Please use clear headings, bullet points, and bold text to structure the report for maximum readability. Ensure that all tables are correctly formatted in Markdown.`
        },
        case4: {
            title: "Case IV - Kidney Disease Progression",
            description: "Prompt for analyzing long-term kidney disease outcomes with medication effects",
            prompt: `You are an expert on process mining analyst applied to epidemiology with high skills for communicating complex data to a clinical audience in a clear, concise, and actionable manner. 

Your task is to generate a comprehensive report based on the provided process mining analysis. This analysis is composed of two process matrices comparing long-term kidney disease outcomes for two groups of patients: those taking PPI (Proton Pump Inhibitors) and those taking H2B (H2 Blockers). The focus is on major adverse renal events and mortality outcomes.

The target audience for this report is a group of clinical and epidemiological stakeholders working on long-term kidney disease outcomes and medication safety.

The report should be structured as a Markdown (.md) file with the following sections:

1. **Executive Summary**: Provide a high-level overview of the key findings regarding long-term outcomes and medication effects.

2. **Introduction**: State the purpose of analyzing long-term kidney disease progression and major adverse renal events. The outcomes modelled include:
   - eGFR decline ≥30%
   - eGFR decline ≥50%
   - Kidney replacement therapy (KRT)
   - Death
   - Stable kidney function

3. **Process Map Analysis**: Compare progression patterns between PPI and H2B groups, focusing on:
   - Time to major events
   - Frequency of adverse outcomes
   - Pathway differences

4. **Data Summary Tables**: Generate comprehensive comparison tables for:
   - Outcome frequencies
   - Time to event metrics
   - Risk ratios between groups

5. **Hypothesis for Outcome Differences**: Propose mechanisms for observed differences, discuss potential confounding factors, and suggest areas for further investigation.

6. **Conclusion**: Summarize clinical implications for medication choice in CKD patients and propose risk stratification strategies.

Please use clear headings, bullet points, and bold text to structure the report for maximum readability. Focus on clinical actionability and patient safety implications.`
        }
    },
    orchestration: {
        title: "Report Orchestration Prompt",
        description: "Prompt template for consolidating multiple LLM reports into a unified analysis",
        prompt: `You are an expert at synthesizing multiple analytical reports into comprehensive, unified insights. Your task is to consolidate {num_reports} different AI model reports analyzing {case_description} into a single, orchestrated report.

## Your Task:
Review the following reports from different models and create a consolidated analysis for: **{case_title}**

## Guidelines:
1. **Identify Consensus**: Find points where multiple models agree
2. **Preserve Unique Insights**: Don't lose innovative or unique findings from individual models
3. **Reconcile Differences**: When models disagree, present both perspectives and note the disagreement
4. **Synthesize Recommendations**: Combine actionable insights from all models
5. **Maintain Attribution**: Always cite which model(s) contributed specific insights using [Model Name] notation
6. **Prioritize Clinical Relevance**: Focus on actionable, clinically relevant findings

## Required Sections:

### Executive Summary
- Synthesize the most critical findings across all models
- Highlight areas of strong agreement
- Note significant unique contributions from specific models

### Key Findings
- Present consensus findings with attribution [Model Names]
- Include unique insights with clear model attribution
- Use tables where appropriate for clarity

### Process Analysis
- Consolidate process pathway descriptions
- Reconcile any differences in pathway interpretation
- Create unified process understanding

### Clinical Insights
- Synthesize clinical interpretations
- Highlight innovative hypotheses from any model
- Consolidate intervention recommendations

### Areas of Agreement vs. Disagreement
- Clearly list where models agree (with evidence)
- Note where they diverge and why this might be important
- Discuss implications of disagreements

### Recommendations
- Prioritize recommendations that multiple models support
- Include unique but valuable recommendations with attribution
- Create actionable implementation roadmap

### Research Questions
- Compile all research questions proposed
- Group by theme
- Note which models proposed which questions

### Attribution Summary
- Acknowledge each model's strongest contributions
- Note any model that provided particularly innovative insights
- Credit accuracy, comprehensiveness, or unique perspectives

## Reports to Consolidate:
{reports_content}

## Output Format:
Create a comprehensive markdown report that:
- Preserves the best insights from each model
- Provides clear attribution using [Model Name] notation
- Creates value beyond individual reports through synthesis
- Maintains clinical focus and actionability
- Uses tables and structured formatting for clarity

Remember to:
- Use [All Models] when all models agree
- Use [Model A, Model B] for partial agreement
- Use [Model Name] for unique insights
- Include confidence indicators where appropriate

---
*End with attribution: "This orchestrated report combines insights from: {model_list}"*
*"Orchestration performed by Claude AI on {date}"*`
    },
    evaluation: {
        title: "Report Evaluation Prompt",
        description: "Prompt for evaluating LLM-generated reports using the 6-criteria rubric",
        prompt: `You are an expert evaluator of AI-generated healthcare process mining reports. Your task is to evaluate the following report using the provided rubric.

## Evaluation Rubric (1-4 scale for each criterion):

### 1. Relevance (Pertinence to the Topic)
- 4 (Exemplary): Directly addresses all aspects of sepsis/organ damage progression with highly relevant insights
- 3 (Proficient): Mostly relevant with minor tangential content
- 2 (Needs Improvement): Some relevant content but includes unrelated information
- 1 (Insufficient): Largely off-topic or misses key aspects

### 2. Structure & Presentation
- 4 (Exemplary): Exceptionally well-organized with clear sections, tables, and visual hierarchy
- 3 (Proficient): Good organization with minor formatting issues
- 2 (Needs Improvement): Basic structure present but lacks clarity
- 1 (Insufficient): Poor organization, difficult to follow

### 3. Understandability
- 4 (Exemplary): Crystal clear for clinical audience, excellent balance of technical accuracy and accessibility
- 3 (Proficient): Generally clear with occasional complex sections
- 2 (Needs Improvement): Often unclear or overly technical
- 1 (Insufficient): Difficult to understand, excessive jargon

### 4. Completeness
- 4 (Exemplary): Comprehensive coverage of all requested sections with depth
- 3 (Proficient): Covers most aspects adequately
- 2 (Needs Improvement): Missing significant sections or lacks depth
- 1 (Insufficient): Incomplete, major omissions

### 5. Innovation (Creative Insights)
- 4 (Exemplary): Novel hypotheses, unique interpretations, creative recommendations
- 3 (Proficient): Some original thinking evident
- 2 (Needs Improvement): Mostly standard observations
- 1 (Insufficient): No original insights, purely descriptive

### 6. Accuracy (Medical and Statistical)
- 4 (Exemplary): Medically sound, statistically accurate, appropriate interpretations
- 3 (Proficient): Generally accurate with minor issues
- 2 (Needs Improvement): Some inaccuracies or misinterpretations
- 1 (Insufficient): Significant errors or misleading conclusions

## Report to Evaluate:
{report_content}

## Instructions:
1. Read the report carefully
2. Evaluate each criterion (1-4)
3. Provide brief justification for each score
4. Calculate overall average score
5. Provide summary feedback

## Output Format:
{
  "scores": {
    "relevance": X,
    "structure": X,
    "understandability": X,
    "completeness": X,
    "innovation": X,
    "accuracy": X
  },
  "overall_score": X.X,
  "justifications": {
    "relevance": "Brief explanation",
    "structure": "Brief explanation",
    "understandability": "Brief explanation",
    "completeness": "Brief explanation",
    "innovation": "Brief explanation",
    "accuracy": "Brief explanation"
  },
  "summary": "Overall assessment in 2-3 sentences"
}`
    }
};