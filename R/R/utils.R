#' Utility Functions for HealthProcessAI
#'
#' @description
#' Collection of utility functions to support healthcare process mining workflows.
#' These functions provide common operations for data validation, transformation,
#' and analysis across the HealthProcessAI package.
#'
#' @name utils
NULL

#' Validate Event Log Data Structure
#'
#' @description
#' Validates that a data frame contains the required columns and data types
#' for healthcare process mining analysis.
#'
#' @param df Data frame to validate
#' @param required_cols Character vector of required column names
#' @param check_types Logical, whether to check data types
#'
#' @return Logical value indicating whether the data is valid
#' @export
#'
#' @examples
#' df <- data.frame(
#'   case = c("P001", "P001", "P002"),
#'   activity = c("Start", "End", "Start"),
#'   timestamp = as.POSIXct(c("2024-01-01 10:00", "2024-01-01 12:00", "2024-01-02 09:00"))
#' )
#' validate_event_log(df)
validate_event_log <- function(df, 
                              required_cols = c("case", "activity", "timestamp"),
                              check_types = TRUE) {
  # Check if input is a data frame
  if (!is.data.frame(df)) {
    warning("Input is not a data frame")
    return(FALSE)
  }
  
  # Check for empty data frame
  if (nrow(df) == 0) {
    warning("Data frame is empty")
    return(FALSE)
  }
  
  # Check required columns
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    warning("Missing required columns: ", paste(missing_cols, collapse = ", "))
    return(FALSE)
  }
  
  # Check data types if requested
  if (check_types) {
    if ("timestamp" %in% names(df) && !inherits(df$timestamp, c("POSIXct", "POSIXt", "Date"))) {
      warning("timestamp column should be of type POSIXct, POSIXt, or Date")
      return(FALSE)
    }
    
    if ("case" %in% names(df) && !is.character(df$case) && !is.factor(df$case)) {
      warning("case column should be character or factor")
      return(FALSE)
    }
    
    if ("activity" %in% names(df) && !is.character(df$activity) && !is.factor(df$activity)) {
      warning("activity column should be character or factor")
      return(FALSE)
    }
  }
  
  return(TRUE)
}

#' Calculate Basic Process Metrics
#'
#' @description
#' Calculate fundamental process mining metrics from an event log.
#'
#' @param event_log Data frame containing event log data
#'
#' @return List containing basic process metrics
#' @export
#'
#' @examples
#' \dontrun{
#' event_log <- data.frame(
#'   case = c("P001", "P001", "P002", "P002"),
#'   activity = c("Start", "End", "Start", "End"),
#'   timestamp = as.POSIXct(c("2024-01-01 10:00", "2024-01-01 12:00",
#'                           "2024-01-02 09:00", "2024-01-02 11:00"))
#' )
#' metrics <- calculate_process_metrics(event_log)
#' }
calculate_process_metrics <- function(event_log) {
  if (!validate_event_log(event_log)) {
    stop("Invalid event log format")
  }
  
  metrics <- list(
    n_cases = n_distinct(event_log$case),
    n_events = nrow(event_log),
    n_activities = n_distinct(event_log$activity),
    date_range = list(
      start = min(event_log$timestamp, na.rm = TRUE),
      end = max(event_log$timestamp, na.rm = TRUE)
    )
  )
  
  # Calculate average case duration
  case_durations <- event_log %>%
    group_by(case) %>%
    summarise(
      duration = as.numeric(difftime(max(timestamp), min(timestamp), units = "hours")),
      .groups = "drop"
    )
  
  metrics$avg_case_duration_hours <- mean(case_durations$duration, na.rm = TRUE)
  metrics$median_case_duration_hours <- median(case_durations$duration, na.rm = TRUE)
  
  # Calculate activity frequencies
  metrics$activity_frequencies <- event_log %>%
    count(activity, sort = TRUE) %>%
    mutate(frequency = n / sum(n))
  
  return(metrics)
}

#' Create Sample Sepsis Event Log
#'
#' @description
#' Generate synthetic sepsis patient data for testing and demonstration purposes.
#'
#' @param n_patients Integer, number of patients to generate
#' @param sepsis_rate Numeric, proportion of patients who develop sepsis (0-1)
#' @param seed Integer, random seed for reproducibility
#'
#' @return Data frame containing synthetic sepsis event log
#' @export
#'
#' @examples
#' # Generate sample data for 10 patients
#' sample_data <- create_sample_sepsis_data(n_patients = 10, sepsis_rate = 0.3)
#' head(sample_data)
create_sample_sepsis_data <- function(n_patients = 50, sepsis_rate = 0.3, seed = 42) {
  set.seed(seed)
  
  sepsis_cases <- sample(1:n_patients, size = floor(n_patients * sepsis_rate))
  all_events <- list()
  
  activities <- list(
    normal = c("Admission", "Vital_Signs_Normal", "Lab_Test_Normal", "Discharge"),
    sepsis = c("Admission", "Vital_Signs_Normal", "Vital_Signs_Abnormal", 
              "Lab_Test_Abnormal", "SIRS_Alert", "Sepsis_Suspected", 
              "Antibiotic_Admin", "ICU_Transfer", "Sepsis_Confirmed", "Discharge")
  )
  
  for (i in 1:n_patients) {
    patient_id <- paste0("Patient_", sprintf("%03d", i))
    is_sepsis <- i %in% sepsis_cases
    
    if (is_sepsis) {
      patient_activities <- activities$sepsis
      base_duration <- runif(1, 72, 168)  # 3-7 days
    } else {
      patient_activities <- activities$normal
      base_duration <- runif(1, 24, 96)   # 1-4 days
    }
    
    # Create timestamps
    start_time <- as.POSIXct("2024-01-01") + days(sample(0:365, 1))
    intervals <- cumsum(c(0, rexp(length(patient_activities) - 1, rate = 24/base_duration)))
    timestamps <- start_time + hours(intervals)
    
    patient_events <- tibble(
      case = patient_id,
      activity = patient_activities,
      timestamp = timestamps,
      resource = sample(c("ER", "Ward", "ICU", "Lab"), length(patient_activities), replace = TRUE),
      sepsis_label = as.integer(is_sepsis)
    )
    
    all_events <- append(all_events, list(patient_events))
  }
  
  bind_rows(all_events) %>%
    arrange(case, timestamp)
}

#' Format Clinical Prompt for LLM Analysis
#'
#' @description
#' Format process mining results into structured prompts for clinical LLM analysis.
#'
#' @param process_data List or character string containing process mining results
#' @param clinical_context Character string specifying clinical context
#'
#' @return Formatted prompt string for LLM analysis
#' @export
#'
#' @examples
#' process_data <- list(n_cases = 100, sepsis_rate = 0.25)
#' prompt <- format_clinical_prompt(process_data, "sepsis")
format_clinical_prompt <- function(process_data, clinical_context = "general") {
  # Convert process data to JSON if it's a list
  if (is.list(process_data)) {
    process_json <- jsonlite::toJSON(process_data, auto_unbox = TRUE, pretty = TRUE)
  } else {
    process_json <- as.character(process_data)
  }
  
  # Context-specific templates
  context_templates <- list(
    sepsis = "
You are a clinical expert analyzing sepsis patient journey data. Based on the following process mining results, provide clinical insights focusing on:

1. Sepsis progression patterns and risk factors
2. Critical intervention points and timing
3. Resource allocation and bottleneck analysis
4. Quality improvement recommendations
5. Early warning system opportunities

Process Mining Results:
{data}

Please provide your analysis in a structured format with clear clinical implications and actionable recommendations for healthcare teams.",
    
    organ_failure = "
You are analyzing organ failure progression patterns in critically ill patients. Based on the process mining results below, provide insights on:

1. Organ dysfunction progression patterns
2. Multi-organ failure trajectories
3. Critical care resource utilization
4. Prognostic indicators and outcomes
5. Treatment protocol optimization

Process Mining Results:
{data}

Focus on clinical significance and provide evidence-based recommendations for critical care management.",
    
    infection = "
You are reviewing infection progression and treatment pathways. Analyze the following data for:

1. Infection progression patterns and stages
2. Antimicrobial therapy effectiveness
3. Healthcare-associated infection risks
4. Infection control protocol adherence
5. Outcome prediction and risk stratification

Process Mining Results:
{data}

Provide infection control and treatment optimization recommendations.",
    
    general = "
You are a healthcare process improvement expert. Analyze the following clinical pathway data and provide insights on:

1. Key process patterns and variations
2. Efficiency bottlenecks and delays
3. Resource utilization optimization
4. Quality indicators and outcomes
5. Process improvement opportunities

Process Mining Results:
{data}

Focus on actionable insights for healthcare administrators and clinical teams."
  )
  
  # Select appropriate template
  template <- context_templates[[clinical_context]] %||% context_templates$general
  
  # Format the prompt
  glue::glue(template, data = process_json)
}

#' NULL-default operator
#'
#' @description
#' Returns the left-hand side if not NULL, otherwise returns the right-hand side.
#'
#' @param x Left-hand side value
#' @param y Right-hand side default value
#'
#' @return Either x (if not NULL) or y
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Check Package Availability
#'
#' @description
#' Check if suggested packages are available and provide informative messages.
#'
#' @param package Character string, package name to check
#' @param feature Character string, feature that requires the package
#'
#' @return Logical, TRUE if package is available
#' @keywords internal
check_package <- function(package, feature = NULL) {
  available <- requireNamespace(package, quietly = TRUE)
  
  if (!available && !is.null(feature)) {
    message(glue::glue("Package '{package}' not available. {feature} functionality will be limited."))
    message(glue::glue("Install with: install.packages('{package}')"))
  }
  
  return(available)
}

#' Safe Division
#'
#' @description
#' Perform division with protection against division by zero.
#'
#' @param x Numerator
#' @param y Denominator  
#' @param default Default value when denominator is zero
#'
#' @return Result of x/y or default if y is zero
#' @keywords internal
safe_divide <- function(x, y, default = 0) {
  ifelse(y == 0 | is.na(y), default, x / y)
}

#' Clean Text for Analysis
#'
#' @description
#' Clean and standardize text data for analysis.
#'
#' @param text Character vector to clean
#' @param remove_punctuation Logical, remove punctuation
#' @param to_lower Logical, convert to lowercase
#'
#' @return Cleaned character vector
#' @keywords internal
clean_text <- function(text, remove_punctuation = TRUE, to_lower = TRUE) {
  if (to_lower) {
    text <- tolower(text)
  }
  
  if (remove_punctuation) {
    text <- gsub("[[:punct:]]", " ", text)
  }
  
  # Remove extra whitespace
  text <- trimws(gsub("\\s+", " ", text))
  
  return(text)
}