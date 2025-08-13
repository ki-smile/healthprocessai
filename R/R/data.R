#' Sample Sepsis Event Log Data
#'
#' @description
#' A sample dataset containing synthetic sepsis patient journey data for
#' demonstration and testing purposes. The data represents typical sepsis
#' progression patterns in a hospital setting.
#'
#' @format A data frame with event log structure:
#' \describe{
#'   \item{case}{Character. Unique patient identifier (e.g., "Patient_001")}
#'   \item{activity}{Character. Clinical activity or event name}
#'   \item{timestamp}{POSIXct. Date and time of the event}
#'   \item{resource}{Character. Healthcare resource involved (e.g., "ER", "ICU")}
#'   \item{sepsis_label}{Integer. Binary indicator (0 = no sepsis, 1 = sepsis)}
#' }
#'
#' @details
#' This synthetic dataset includes:
#' \itemize{
#'   \item 50 patient cases with varying journey lengths
#'   \item 30% sepsis rate (15 patients develop sepsis)
#'   \item Realistic clinical activities and progression patterns
#'   \item Multiple healthcare resources and departments
#'   \item Temporal patterns reflecting actual clinical workflows
#' }
#'
#' Common activities in the dataset:
#' \itemize{
#'   \item Admission, Vital_Signs_Normal/Abnormal
#'   \item Lab_Test_Normal/Abnormal, SIRS_Alert
#'   \item Sepsis_Suspected/Confirmed, Antibiotic_Admin
#'   \item ICU_Transfer, Discharge
#' }
#'
#' @source Generated using \code{\link{create_sample_sepsis_data}} function
#'
#' @examples
#' \dontrun{
#' # Load the sample data
#' data(sample_sepsis_data)
#' 
#' # Basic exploration
#' head(sample_sepsis_data)
#' summary(sample_sepsis_data)
#' 
#' # Check sepsis rate
#' table(sample_sepsis_data$sepsis_label)
#' 
#' # Activity frequency
#' table(sample_sepsis_data$activity)
#' 
#' # Use with HealthProcessAI
#' loader <- EventLogLoader$new()
#' processed_data <- loader$load_from_data_frame(sample_sepsis_data)
#' stats <- loader$get_basic_statistics(processed_data)
#' }
"sample_sepsis_data"

#' Sample PhysioNet-Style Clinical Data
#'
#' @description
#' Synthetic time-series clinical data in PhysioNet Challenge format,
#' suitable for demonstrating raw data transformation to event logs.
#'
#' @format A data frame with clinical measurements:
#' \describe{
#'   \item{Patient_ID}{Character. Patient identifier}
#'   \item{Hour}{Numeric. Hours since ICU admission}
#'   \item{HR}{Numeric. Heart rate (beats per minute)}
#'   \item{MAP}{Numeric. Mean arterial pressure (mmHg)}
#'   \item{Temp}{Numeric. Temperature (Celsius)}
#'   \item{Resp}{Numeric. Respiratory rate (breaths per minute)}
#'   \item{SpO2}{Numeric. Oxygen saturation (%)}
#'   \item{WBC}{Numeric. White blood cell count (×10³/μL)}
#'   \item{Lactate}{Numeric. Lactate level (mmol/L)}
#'   \item{Creatinine}{Numeric. Creatinine level (mg/dL)}
#'   \item{Platelets}{Numeric. Platelet count (×10³/μL)}
#'   \item{SepsisLabel}{Integer. Sepsis label (0 = no sepsis, 1 = sepsis)}
#' }
#'
#' @details
#' This dataset demonstrates:
#' \itemize{
#'   \item Irregular sampling patterns typical of ICU monitoring
#'   \item Missing data patterns common in clinical datasets
#'   \item Physiological deterioration patterns in sepsis progression
#'   \item Multiple patients with varying progression trajectories
#' }
#'
#' @source Generated using synthetic physiological models
#'
#' @examples
#' \dontrun{
#' # Load the sample PhysioNet data
#' data(sample_physionet_data)
#' 
#' # Explore the structure
#' str(sample_physionet_data)
#' 
#' # Check sepsis cases
#' sepsis_patients <- unique(sample_physionet_data$Patient_ID[
#'   sample_physionet_data$SepsisLabel == 1
#' ])
#' 
#' # Transform to event log
#' transformer <- HealthcareDataTransformer$new()
#' event_log <- transformer$transform_to_event_log(sample_physionet_data)
#' }
"sample_physionet_data"

#' Process Mining Evaluation Metrics
#'
#' @description
#' Standard evaluation metrics and benchmarks for healthcare process mining
#' analysis, useful for comparing analysis results against established standards.
#'
#' @format A named list containing:
#' \describe{
#'   \item{sepsis_benchmarks}{List of sepsis-related clinical benchmarks}
#'   \item{icu_metrics}{Common ICU performance indicators}
#'   \item{process_quality}{Process quality assessment criteria}
#'   \item{clinical_thresholds}{Standard clinical threshold values}
#' }
#'
#' @details
#' Benchmark categories include:
#' \itemize{
#'   \item \strong{Sepsis Benchmarks}: Mortality rates, length of stay, time to treatment
#'   \item \strong{ICU Metrics}: Occupancy rates, readmission rates, resource utilization
#'   \item \strong{Process Quality}: Conformance rates, variation coefficients, bottleneck thresholds
#'   \item \strong{Clinical Thresholds}: Vital sign ranges, laboratory value limits, SOFA scores
#' }
#'
#' @source Compiled from medical literature and clinical guidelines
#'
#' @examples
#' \dontrun{
#' # Load evaluation metrics
#' data(evaluation_metrics)
#' 
#' # Access sepsis benchmarks
#' sepsis_benchmarks <- evaluation_metrics$sepsis_benchmarks
#' 
#' # Compare analysis results
#' mortality_rate <- 0.15
#' if (mortality_rate <= sepsis_benchmarks$mortality_rate$acceptable) {
#'   message("Mortality rate within acceptable range")
#' }
#' 
#' # Use in analysis
#' advanced_analyzer <- AdvancedProcessAnalyzer$new(event_log)
#' kpis <- advanced_analyzer$calculate_clinical_kpis()
#' 
#' # Compare against benchmarks
#' benchmark_comparison <- list(
#'   los_benchmark = evaluation_metrics$sepsis_benchmarks$avg_los,
#'   actual_los = kpis$avg_los,
#'   within_range = kpis$avg_los <= evaluation_metrics$sepsis_benchmarks$avg_los * 1.2
#' )
#' }
"evaluation_metrics"

#' Clinical Activity Mapping
#'
#' @description
#' Standardized mapping of clinical activities to categories and clinical
#' significance levels for consistent process mining analysis.
#'
#' @format A data frame with activity classifications:
#' \describe{
#'   \item{activity}{Character. Standardized activity name}
#'   \item{category}{Character. Activity category (diagnostic, therapeutic, administrative, etc.)}
#'   \item{clinical_significance}{Character. Clinical significance level (high, medium, low)}
#'   \item{department}{Character. Typical department or unit}
#'   \item{duration_estimate}{Numeric. Typical duration in hours}
#'   \item{cost_category}{Character. Cost classification (low, medium, high)}
#' }
#'
#' @details
#' Activity categories include:
#' \itemize{
#'   \item \strong{Diagnostic}: Lab tests, imaging, assessments
#'   \item \strong{Therapeutic}: Medications, procedures, interventions
#'   \item \strong{Monitoring}: Vital signs, observations, checks
#'   \item \strong{Administrative}: Admission, discharge, transfers
#'   \item \strong{Emergency}: Critical interventions, alerts, rapid response
#' }
#'
#' @source Based on standard healthcare workflows and clinical protocols
#'
#' @examples
#' \dontrun{
#' # Load activity mapping
#' data(clinical_activity_mapping)
#' 
#' # View activity categories
#' table(clinical_activity_mapping$category)
#' 
#' # Filter high-significance activities
#' critical_activities <- clinical_activity_mapping[
#'   clinical_activity_mapping$clinical_significance == "high",
#' ]
#' 
#' # Use in process analysis
#' event_log_enhanced <- event_log %>%
#'   left_join(clinical_activity_mapping, by = "activity") %>%
#'   mutate(is_critical = clinical_significance == "high")
#' }
"clinical_activity_mapping"