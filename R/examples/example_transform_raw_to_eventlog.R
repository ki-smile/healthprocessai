# HealthProcessAI - Transform Raw Healthcare Data to Event Logs (R Implementation)
# ==================================================================================
#
# EXAMPLE: TRANSFORMING RAW HEALTHCARE DATA TO EVENT LOGS
# ========================================================
# This example demonstrates how to transform raw healthcare/epidemiological data
# into event logs suitable for process mining, following the approach from
# PhysioNet Challenge 2019 and similar to methods proposed by Kaile Chen et al.
#
# The PhysioNet Challenge 2019 focused on early prediction of sepsis from clinical data.
# This example shows how to transform such raw clinical measurements into event logs
# for process mining analysis.
#
# Data source reference: https://physionet.org/content/challenge-2019/1.0.0/
#
# Developed at SMAILE, Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(glue)
  library(R6)
})

#' Healthcare Data Transformer R6 Class
#' 
#' @description
#' Transforms raw healthcare data (vital signs, lab results, etc.) into event logs.
#' 
#' This class implements methods to:
#' 1. Process time-series clinical data
#' 2. Detect clinical events from continuous measurements
#' 3. Create event logs from state transitions
#' 4. Handle missing data and irregular sampling
#' 
#' Based on approaches from PhysioNet Challenge and research papers on
#' healthcare process mining.
#' 
#' @import R6
#' @export
HealthcareDataTransformer <- R6::R6Class(
  classname = "HealthcareDataTransformer",
  
  public = list(
    
    # Data storage
    raw_data = NULL,
    event_log = NULL,
    thresholds = NULL,
    sofa_components = NULL,
    
    #' Initialize the transformer
    initialize = function() {
      # Define clinical thresholds (based on medical literature)
      self$thresholds <- list(
        HR = list(low = 60, high = 100),           # Heart rate
        BP_sys = list(low = 90, high = 140),       # Systolic BP
        BP_dias = list(low = 60, high = 90),       # Diastolic BP
        Temp = list(low = 36.0, high = 38.0),      # Temperature
        SpO2 = list(low = 95, high = 100),         # Oxygen saturation
        Resp = list(low = 12, high = 20),          # Respiratory rate
        WBC = list(low = 4.5, high = 11.0),        # White blood cells
        Lactate = list(low = 0, high = 2.0),       # Lactate
        Creatinine = list(low = 0.6, high = 1.2),  # Creatinine
        Platelets = list(low = 150, high = 400),   # Platelets
        Bilirubin = list(low = 0, high = 1.2)      # Bilirubin
      )
      
      # SOFA score components for sepsis detection
      self$sofa_components <- list(
        respiratory = c("SpO2", "FiO2"),
        coagulation = c("Platelets"),
        liver = c("Bilirubin"),
        cardiovascular = c("BP_sys", "BP_dias"),
        cns = c("GCS"),
        renal = c("Creatinine", "Urine")
      )
      
      message("HealthcareDataTransformer initialized")
    },
    
    #' Create synthetic data similar to PhysioNet Challenge 2019 format
    #' 
    #' @param n_patients Number of patients to simulate
    #' @return Data frame with raw clinical time-series data
    create_physionet_style_data = function(n_patients = 50) {
      message(glue::glue("Creating synthetic PhysioNet-style data for {n_patients} patients..."))
      
      all_data <- list()
      
      for (patient_id in 1:n_patients) {
        # Determine if patient develops sepsis
        develops_sepsis <- runif(1) < 0.3
        
        # Generate time points (irregular sampling)
        n_timepoints <- sample(20:100, 1)
        hours <- sort(runif(n_timepoints, 0, 72))
        
        # Initialize patient data
        patient_data <- list()
        
        # Generate vital signs with trends
        base_hr <- rnorm(1, 75, 10)
        base_temp <- rnorm(1, 37, 0.5)
        base_bp_sys <- rnorm(1, 120, 15)
        base_spo2 <- rnorm(1, 97, 2)
        base_resp <- rnorm(1, 16, 3)
        
        # Sepsis progression parameters
        if (develops_sepsis) {
          sepsis_onset <- runif(1, 12, 48)
          sepsis_severity <- runif(1, 0.5, 1.5)
        } else {
          sepsis_onset <- Inf
          sepsis_severity <- 0
        }
        
        for (i in seq_along(hours)) {
          hour <- hours[i]
          
          # Create deterioration if sepsis
          if (develops_sepsis && hour > sepsis_onset) {
            deterioration <- (hour - sepsis_onset) * sepsis_severity / 10
          } else {
            deterioration <- 0
          }
          
          # Generate measurements with missing values
          measurements <- tibble(
            Patient_ID = glue::glue("P{sprintf('%04d', patient_id)}"),
            Hour = hour,
            HR = ifelse(runif(1) > 0.1, 
                       base_hr + rnorm(1, 0, 5) + deterioration * 15,
                       NA_real_),
            Temp = ifelse(runif(1) > 0.15,
                         base_temp + rnorm(1, 0, 0.3) + deterioration * 0.5,
                         NA_real_),
            BP_sys = ifelse(runif(1) > 0.1,
                           base_bp_sys - rnorm(1, 0, 8) - deterioration * 10,
                           NA_real_),
            BP_dias = ifelse(runif(1) > 0.1,
                            (base_bp_sys * 0.6) - rnorm(1, 0, 5) - deterioration * 5,
                            NA_real_),
            SpO2 = ifelse(runif(1) > 0.1,
                         base_spo2 - rnorm(1, 0, 2) - deterioration * 3,
                         NA_real_),
            Resp = ifelse(runif(1) > 0.1,
                         base_resp + rnorm(1, 0, 2) + deterioration * 4,
                         NA_real_)
          )
          
          # Lab values (less frequent)
          if (runif(1) < 0.2) {  # 20% chance of lab values
            measurements$WBC <- ifelse(develops_sepsis,
                                       rnorm(1, 7, 3) + deterioration * 4,
                                       rnorm(1, 7, 2))
            measurements$Lactate <- ifelse(develops_sepsis,
                                           rnorm(1, 1, 0.5) + deterioration * 2,
                                           rnorm(1, 1, 0.3))
            measurements$Creatinine <- ifelse(develops_sepsis,
                                              rnorm(1, 0.9, 0.3) + deterioration * 0.3,
                                              rnorm(1, 0.9, 0.2))
            measurements$Platelets <- ifelse(develops_sepsis,
                                             rnorm(1, 250, 50) - deterioration * 30,
                                             rnorm(1, 250, 40))
          } else {
            measurements$WBC <- NA_real_
            measurements$Lactate <- NA_real_
            measurements$Creatinine <- NA_real_
            measurements$Platelets <- NA_real_
          }
          
          # Sepsis label
          measurements$SepsisLabel <- ifelse(develops_sepsis && hour > sepsis_onset, 1, 0)
          
          patient_data <- append(patient_data, list(measurements))
        }
        
        all_data <- append(all_data, patient_data)
      }
      
      df <- bind_rows(all_data)
      message(glue::glue("Created {nrow(df)} time points for {n_patients} patients"))
      
      return(df)
    },
    
    #' Detect state transitions in a clinical variable
    #' 
    #' @param df Data frame with time-series data for one patient
    #' @param variable Variable name to analyze
    #' @return List of state transition events
    detect_state_transitions = function(df, variable) {
      if (!(variable %in% names(self$thresholds))) {
        return(tibble())
      }
      
      thresholds <- self$thresholds[[variable]]
      
      # Get non-null values
      valid_data <- df %>%
        filter(!is.na(!!sym(variable))) %>%
        arrange(Hour)
      
      if (nrow(valid_data) == 0) {
        return(tibble())
      }
      
      # Classify states
      valid_data <- valid_data %>%
        mutate(
          state = case_when(
            !!sym(variable) < thresholds$low ~ "Low",
            !!sym(variable) > thresholds$high ~ "High",
            TRUE ~ "Normal"
          )
        )
      
      # Detect transitions
      events <- list()
      previous_state <- NULL
      
      for (i in 1:nrow(valid_data)) {
        row <- valid_data[i,]
        current_state <- row$state
        
        if (!is.null(previous_state) && current_state != previous_state) {
          # State transition detected
          event <- tibble(
            timestamp = row$Hour,
            activity = glue::glue("{variable}_{previous_state}_to_{current_state}"),
            resource = "Monitoring_System",
            value = row[[variable]]
          )
          events <- append(events, list(event))
        }
        
        # Also record abnormal states as events
        if (current_state != "Normal" && 
            (is.null(previous_state) || previous_state != current_state)) {
          event <- tibble(
            timestamp = row$Hour,
            activity = glue::glue("{variable}_{current_state}"),
            resource = "Alert_System",
            value = row[[variable]]
          )
          events <- append(events, list(event))
        }
        
        previous_state <- current_state
      }
      
      if (length(events) > 0) {
        return(bind_rows(events))
      } else {
        return(tibble())
      }
    },
    
    #' Calculate clinical risk scores (SIRS, qSOFA) and create events
    #' 
    #' @param df Data frame with patient data
    #' @return Data frame of risk score events
    calculate_risk_scores = function(df) {
      events <- list()
      
      for (i in 1:nrow(df)) {
        row <- df[i,]
        
        # SIRS criteria
        sirs_score <- 0
        if (!is.na(row$Temp)) {
          if (row$Temp < 36 || row$Temp > 38) {
            sirs_score <- sirs_score + 1
          }
        }
        if (!is.na(row$HR)) {
          if (row$HR > 90) {
            sirs_score <- sirs_score + 1
          }
        }
        if (!is.na(row$Resp)) {
          if (row$Resp > 20) {
            sirs_score <- sirs_score + 1
          }
        }
        if (!is.na(row$WBC)) {
          if (row$WBC < 4 || row$WBC > 12) {
            sirs_score <- sirs_score + 1
          }
        }
        
        # Create event if SIRS >= 2
        if (sirs_score >= 2) {
          event <- tibble(
            timestamp = row$Hour,
            activity = glue::glue("SIRS_Alert_Score_{sirs_score}"),
            resource = "Clinical_Decision_Support",
            value = sirs_score
          )
          events <- append(events, list(event))
        }
        
        # qSOFA criteria
        qsofa_score <- 0
        if (!is.na(row$Resp)) {
          if (row$Resp >= 22) {
            qsofa_score <- qsofa_score + 1
          }
        }
        if (!is.na(row$BP_sys)) {
          if (row$BP_sys <= 100) {
            qsofa_score <- qsofa_score + 1
          }
        }
        # GCS would be needed for complete qSOFA
        
        # Create event if qSOFA >= 2
        if (qsofa_score >= 2) {
          event <- tibble(
            timestamp = row$Hour,
            activity = "qSOFA_Alert",
            resource = "Clinical_Decision_Support",
            value = qsofa_score
          )
          events <- append(events, list(event))
        }
      }
      
      if (length(events) > 0) {
        return(bind_rows(events))
      } else {
        return(tibble())
      }
    },
    
    #' Transform raw healthcare data to event log format
    #' 
    #' @param raw_data Raw clinical time-series data
    #' @return Event log data frame
    transform_to_event_log = function(raw_data) {
      cat("\n", paste(rep("=", 60), collapse = ""), "\n")
      cat("TRANSFORMING RAW DATA TO EVENT LOG\n")
      cat(paste(rep("=", 60), collapse = ""), "\n\n")
      
      all_events <- list()
      
      # Process each patient
      patient_ids <- unique(raw_data$Patient_ID)
      
      for (patient_id in patient_ids) {
        patient_data <- raw_data %>%
          filter(Patient_ID == patient_id) %>%
          arrange(Hour)
        
        message(glue::glue("Processing {patient_id}..."))
        
        # 1. Add admission event
        admission_event <- tibble(
          case = patient_id,
          activity = "Admission",
          timestamp = min(patient_data$Hour),
          resource = "Admissions",
          lifecycle = "complete"
        )
        all_events <- append(all_events, list(admission_event))
        
        # 2. Detect state transitions for each vital sign
        for (variable in c("HR", "Temp", "BP_sys", "SpO2", "Resp")) {
          transitions <- self$detect_state_transitions(patient_data, variable)
          if (nrow(transitions) > 0) {
            transitions <- transitions %>%
              mutate(
                case = patient_id,
                lifecycle = "complete"
              ) %>%
              select(case, activity, timestamp, resource, lifecycle)
            all_events <- append(all_events, list(transitions))
          }
        }
        
        # 3. Lab test events
        lab_vars <- c("WBC", "Lactate", "Creatinine", "Platelets")
        for (lab in lab_vars) {
          lab_data <- patient_data %>%
            filter(!is.na(!!sym(lab)))
          
          if (nrow(lab_data) > 0) {
            lab_events <- lab_data %>%
              mutate(
                case = patient_id,
                activity = glue::glue("Lab_Test_{lab}"),
                timestamp = Hour,
                resource = "Laboratory",
                lifecycle = "complete"
              ) %>%
              select(case, activity, timestamp, resource, lifecycle)
            all_events <- append(all_events, list(lab_events))
          }
        }
        
        # 4. Risk score events
        risk_events <- self$calculate_risk_scores(patient_data)
        if (nrow(risk_events) > 0) {
          risk_events <- risk_events %>%
            mutate(
              case = patient_id,
              lifecycle = "complete"
            ) %>%
            select(case, activity, timestamp, resource, lifecycle)
          all_events <- append(all_events, list(risk_events))
        }
        
        # 5. Sepsis onset event
        sepsis_data <- patient_data %>%
          filter(SepsisLabel == 1)
        
        if (nrow(sepsis_data) > 0) {
          sepsis_event <- tibble(
            case = patient_id,
            activity = "Sepsis_Onset",
            timestamp = min(sepsis_data$Hour),
            resource = "Clinical_Team",
            lifecycle = "complete"
          )
          all_events <- append(all_events, list(sepsis_event))
        }
        
        # 6. Discharge/outcome event
        outcome_event <- tibble(
          case = patient_id,
          activity = ifelse(any(patient_data$SepsisLabel == 1), 
                           "Discharge_Sepsis", 
                           "Discharge_NoSepsis"),
          timestamp = max(patient_data$Hour),
          resource = "Discharge_Unit",
          lifecycle = "complete"
        )
        all_events <- append(all_events, list(outcome_event))
      }
      
      # Combine all events
      event_log <- bind_rows(all_events) %>%
        arrange(case, timestamp)
      
      self$event_log <- event_log
      
      message(glue::glue("\nCreated event log with {nrow(event_log)} events"))
      message(glue::glue("Unique activities: {n_distinct(event_log$activity)}"))
      
      return(event_log)
    },
    
    #' Analyze the transformed event log
    #' 
    #' @param event_log Event log data frame
    #' @return List with analysis results
    analyze_event_log = function(event_log = NULL) {
      if (is.null(event_log)) {
        event_log <- self$event_log
      }
      
      analysis <- list(
        total_cases = n_distinct(event_log$case),
        total_events = nrow(event_log),
        unique_activities = n_distinct(event_log$activity),
        activity_frequency = event_log %>%
          count(activity, sort = TRUE) %>%
          head(10),
        resource_utilization = event_log %>%
          count(resource, sort = TRUE),
        sepsis_cases = event_log %>%
          filter(str_detect(activity, "Sepsis")) %>%
          pull(case) %>%
          n_distinct(),
        alert_events = event_log %>%
          filter(str_detect(activity, "Alert|High|Low")) %>%
          nrow()
      )
      
      return(analysis)
    }
  )
)

# Main function to demonstrate transformation
run_raw_to_eventlog_transformation <- function() {
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("HEALTHCARE DATA TO EVENT LOG TRANSFORMATION\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat("This example demonstrates transformation of raw clinical time-series data\n")
  cat("into event logs suitable for process mining analysis.\n")
  
  # Initialize transformer
  transformer <- HealthcareDataTransformer$new()
  
  # Step 1: Create synthetic data
  cat("\n1. Creating synthetic PhysioNet-style clinical data...\n")
  raw_data <- transformer$create_physionet_style_data(n_patients = 20)
  cat(glue::glue("   Generated {nrow(raw_data)} measurements for {n_distinct(raw_data$Patient_ID)} patients\n"))
  
  # Step 2: Transform to event log
  cat("\n2. Transforming to event log...\n")
  event_log <- transformer$transform_to_event_log(raw_data)
  
  # Step 3: Analyze the event log
  cat("\n3. Analyzing transformed event log...\n")
  analysis <- transformer$analyze_event_log(event_log)
  
  cat("\n   Event Log Statistics:\n")
  cat(glue::glue("   - Total cases: {analysis$total_cases}\n"))
  cat(glue::glue("   - Total events: {analysis$total_events}\n"))
  cat(glue::glue("   - Unique activities: {analysis$unique_activities}\n"))
  cat(glue::glue("   - Sepsis cases: {analysis$sepsis_cases}\n"))
  cat(glue::glue("   - Alert events: {analysis$alert_events}\n"))
  
  # Step 4: Show top activities
  cat("\n4. Top 10 Activities:\n")
  for (i in 1:min(10, nrow(analysis$activity_frequency))) {
    row <- analysis$activity_frequency[i,]
    cat(glue::glue("   {sprintf('%-30s', row$activity)}: {row$n} events\n"))
  }
  
  # Step 5: Show resource utilization
  cat("\n5. Resource Utilization:\n")
  for (i in 1:nrow(analysis$resource_utilization)) {
    row <- analysis$resource_utilization[i,]
    cat(glue::glue("   {sprintf('%-25s', row$resource)}: {row$n} events\n"))
  }
  
  # Step 6: Save event log
  cat("\n6. Saving event log...\n")
  output_file <- "transformed_event_log.csv"
  write_csv(event_log, output_file)
  cat(glue::glue("   Saved to: {output_file}\n"))
  
  # Step 7: Show sample events
  cat("\n7. Sample Events:\n\n")
  print(event_log %>% 
          head(15) %>%
          select(case, timestamp, activity, resource))
  
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("TRANSFORMATION COMPLETE\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat("The event log is now ready for process mining analysis using bupaR or similar tools.\n")
  cat("Key transformations applied:\n")
  cat("- Vital sign state transitions (Normal/High/Low)\n")
  cat("- Clinical alerts (SIRS, qSOFA)\n")
  cat("- Lab test events\n")
  cat("- Sepsis onset detection\n")
  cat("- Patient journey milestones (Admission, Discharge)\n")
  
  return(list(transformer = transformer, event_log = event_log, analysis = analysis))
}

# Example usage
if (interactive()) {
  result <- run_raw_to_eventlog_transformation()
  
  # Additional analysis with bupaR (if available)
  if (require(bupaR, quietly = TRUE)) {
    cat("\n", paste(rep("=", 80), collapse = ""), "\n")
    cat("BUPAR PROCESS MINING ANALYSIS\n")
    cat(paste(rep("=", 80), collapse = ""), "\n\n")
    
    # Convert to bupaR event log
    bupar_log <- result$event_log %>%
      mutate(
        timestamp = as.POSIXct(timestamp * 3600, origin = "2024-01-01"),
        activity_instance_id = row_number()
      ) %>%
      eventlog(
        case_id = "case",
        activity_id = "activity",
        activity_instance_id = "activity_instance_id",
        timestamp = "timestamp",
        resource_id = "resource",
        lifecycle_id = "lifecycle"
      )
    
    # Basic statistics
    cat("Event Log Summary:\n")
    print(bupar_log)
    
    # Activity frequency
    cat("\nActivity Frequency:\n")
    print(activity_frequency(bupar_log, level = "activity") %>% head(10))
    
    # Process variants
    cat("\nTop Process Variants:\n")
    print(trace_explorer(bupar_log, n_traces = 5))
  }
}