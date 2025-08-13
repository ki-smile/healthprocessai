# HealthProcessAI - PhysioNet to Organ Failure Progression (R Implementation)
# ============================================================================
#
# EXAMPLE: TRANSFORMING PHYSIONET DATA TO ORGAN FAILURE PROGRESSION
# ==================================================================
# This example demonstrates how raw PhysioNet Challenge 2019 sepsis data
# is transformed into organ failure progression event logs.
#
# The transformation creates events like:
# - "Low Risk"
# - "Liver + Cardiac Damage"
# - "Renal + Cardiac Damage"
# - "Multiorgan Damage"
# - "Sepsis"
#
# This matches the format in sepsisAgregated_Organ.csv
#
# Based on SOFA (Sequential Organ Failure Assessment) score components:
# - Respiratory: PaO2/FiO2 ratio, SpO2
# - Cardiovascular: MAP, vasopressor requirement
# - Liver: Bilirubin
# - Coagulation: Platelets
# - Renal: Creatinine, urine output
# - CNS: Glasgow Coma Scale (GCS)
#
# Developed at SMAILE, Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(glue)
  library(R6)
})

#' PhysioNet to Organ Failure Transformer R6 Class
#' 
#' @description
#' Transforms raw PhysioNet sepsis data to organ failure progression events.
#' 
#' This transformer evaluates organ dysfunction using modified SOFA criteria
#' and creates events that track single and multiple organ failures.
#' 
#' The output matches the structure of sepsisAgregated_Organ.csv
#' 
#' @import R6
#' @export
PhysioNetToOrganTransformer <- R6::R6Class(
  classname = "PhysioNetToOrganTransformer",
  
  public = list(
    
    # Organ failure thresholds
    organ_thresholds = NULL,
    organ_event_mapping = NULL,
    
    #' Initialize transformer with organ failure thresholds
    initialize = function() {
      # SOFA-based thresholds for organ dysfunction
      self$organ_thresholds <- list(
        respiratory = list(
          spo2_low = 92,      # SpO2 < 92% indicates respiratory issues
          resp_high = 22,     # Respiratory rate > 22
          fio2_high = 0.4     # Need for high oxygen
        ),
        cardiovascular = list(
          map_low = 65,       # MAP < 65 mmHg
          sbp_low = 90,       # Systolic BP < 90
          hr_high = 120,      # Severe tachycardia
          lactate_high = 2.0  # Tissue hypoperfusion
        ),
        liver = list(
          bilirubin_high = 2.0,  # Bilirubin > 2 mg/dL
          ast_high = 100,        # AST elevation
          alt_high = 100         # ALT elevation (if available)
        ),
        coagulation = list(
          platelets_low = 100,   # Platelets < 100 ×10^9/L
          ptt_high = 60,        # PTT > 60 seconds
          fibrinogen_low = 100  # Fibrinogen < 100 mg/dL
        ),
        renal = list(
          creatinine_high = 2.0,  # Creatinine > 2 mg/dL
          bun_high = 40,         # BUN > 40 mg/dL
          urine_low = 500        # Oliguria (would need 24h data)
        ),
        cns = list(
          gcs_low = 13           # GCS < 13 (if available)
        )
      )
      
      # Mapping of organ combinations to event names
      self$organ_event_mapping <- list(
        "none" = "Low Risk",
        "cardiovascular" = "Cardiac Damage",
        "liver" = "Liver Damage",
        "renal" = "Renal Damage",
        "respiratory" = "Respiratory Damage",
        "coagulation" = "Coagulation Disorder",
        "liver,cardiovascular" = "Liver + Cardiac Damage",
        "renal,cardiovascular" = "Renal + Cardiac Damage",
        "respiratory,cardiovascular" = "Respiratory + Cardiac Damage",
        "liver,renal" = "Liver + Renal Damage"
      )
      
      message("PhysioNetToOrganTransformer initialized")
    },
    
    #' Evaluate respiratory system dysfunction
    #' 
    #' @param row Patient data at specific timepoint
    #' @return Logical indicating dysfunction
    evaluate_respiratory_dysfunction = function(row) {
      dysfunction <- FALSE
      
      if (!is.na(row$O2Sat) && row$O2Sat < self$organ_thresholds$respiratory$spo2_low) {
        dysfunction <- TRUE
      }
      
      if (!is.na(row$Resp) && row$Resp > self$organ_thresholds$respiratory$resp_high) {
        dysfunction <- TRUE
      }
      
      if (!is.na(row$FiO2) && row$FiO2 > self$organ_thresholds$respiratory$fio2_high) {
        dysfunction <- TRUE
      }
      
      return(dysfunction)
    },
    
    #' Evaluate cardiovascular system dysfunction
    #' 
    #' @param row Patient data at specific timepoint
    #' @return Logical indicating dysfunction
    evaluate_cardiovascular_dysfunction = function(row) {
      dysfunction_score <- 0
      
      if (!is.na(row$MAP) && row$MAP < self$organ_thresholds$cardiovascular$map_low) {
        dysfunction_score <- dysfunction_score + 1
      }
      
      if (!is.na(row$SBP) && row$SBP < self$organ_thresholds$cardiovascular$sbp_low) {
        dysfunction_score <- dysfunction_score + 1
      }
      
      if (!is.na(row$HR) && row$HR > self$organ_thresholds$cardiovascular$hr_high) {
        dysfunction_score <- dysfunction_score + 0.5
      }
      
      if (!is.na(row$Lactate) && row$Lactate > self$organ_thresholds$cardiovascular$lactate_high) {
        dysfunction_score <- dysfunction_score + 1
      }
      
      return(dysfunction_score >= 1)
    },
    
    #' Evaluate liver dysfunction
    #' 
    #' @param row Patient data at specific timepoint
    #' @return Logical indicating dysfunction
    evaluate_liver_dysfunction = function(row) {
      dysfunction <- FALSE
      
      if (!is.na(row$Bilirubin_total) && 
          row$Bilirubin_total > self$organ_thresholds$liver$bilirubin_high) {
        dysfunction <- TRUE
      }
      
      if (!is.na(row$AST) && row$AST > self$organ_thresholds$liver$ast_high) {
        dysfunction <- TRUE
      }
      
      if (!is.na(row$Alkalinephos) && row$Alkalinephos > 150) {
        dysfunction <- TRUE
      }
      
      return(dysfunction)
    },
    
    #' Evaluate coagulation system dysfunction
    #' 
    #' @param row Patient data at specific timepoint
    #' @return Logical indicating dysfunction
    evaluate_coagulation_dysfunction = function(row) {
      dysfunction <- FALSE
      
      if (!is.na(row$Platelets) && 
          row$Platelets < self$organ_thresholds$coagulation$platelets_low) {
        dysfunction <- TRUE
      }
      
      if (!is.na(row$PTT) && row$PTT > self$organ_thresholds$coagulation$ptt_high) {
        dysfunction <- TRUE
      }
      
      if (!is.na(row$Fibrinogen) && 
          row$Fibrinogen < self$organ_thresholds$coagulation$fibrinogen_low) {
        dysfunction <- TRUE
      }
      
      return(dysfunction)
    },
    
    #' Evaluate renal dysfunction
    #' 
    #' @param row Patient data at specific timepoint
    #' @return Logical indicating dysfunction
    evaluate_renal_dysfunction = function(row) {
      dysfunction <- FALSE
      
      if (!is.na(row$Creatinine) && 
          row$Creatinine > self$organ_thresholds$renal$creatinine_high) {
        dysfunction <- TRUE
      }
      
      if (!is.na(row$BUN) && row$BUN > self$organ_thresholds$renal$bun_high) {
        dysfunction <- TRUE
      }
      
      return(dysfunction)
    },
    
    #' Evaluate all organ systems
    #' 
    #' @param row Patient data at specific timepoint
    #' @return Character vector of dysfunctional organs
    evaluate_all_organ_systems = function(row) {
      dysfunctional_organs <- character()
      
      if (self$evaluate_respiratory_dysfunction(row)) {
        dysfunctional_organs <- c(dysfunctional_organs, "respiratory")
      }
      
      if (self$evaluate_cardiovascular_dysfunction(row)) {
        dysfunctional_organs <- c(dysfunctional_organs, "cardiovascular")
      }
      
      if (self$evaluate_liver_dysfunction(row)) {
        dysfunctional_organs <- c(dysfunctional_organs, "liver")
      }
      
      if (self$evaluate_coagulation_dysfunction(row)) {
        dysfunctional_organs <- c(dysfunctional_organs, "coagulation")
      }
      
      if (self$evaluate_renal_dysfunction(row)) {
        dysfunctional_organs <- c(dysfunctional_organs, "renal")
      }
      
      return(dysfunctional_organs)
    },
    
    #' Map organ dysfunction combination to event name
    #' 
    #' @param organs Character vector of dysfunctional organs
    #' @param sepsis_label Whether patient has sepsis
    #' @return Event name string
    get_organ_failure_event = function(organs, sepsis_label) {
      # If patient has sepsis label, override with "Sepsis" event
      if (sepsis_label == 1) {
        return("Sepsis")
      }
      
      # If 3+ organs affected, it's multiorgan failure
      if (length(organs) >= 3) {
        return("Multiorgan Damage")
      }
      
      # Try to find specific combination in mapping
      if (length(organs) == 0) {
        return("Low Risk")
      }
      
      # Create key for mapping
      organs_key <- paste(sort(organs), collapse = ",")
      
      if (organs_key %in% names(self$organ_event_mapping)) {
        return(self$organ_event_mapping[[organs_key]])
      }
      
      # For unmapped combinations, create descriptive name
      if (length(organs) == 2) {
        organ_names <- str_to_title(organs)
        return(glue::glue("{organ_names[1]} + {organ_names[2]} Damage"))
      } else if (length(organs) == 1) {
        return(glue::glue("{str_to_title(organs)} Damage"))
      } else {
        return("Low Risk")
      }
    },
    
    #' Transform raw PhysioNet data to organ failure progression event log
    #' 
    #' @param df Raw PhysioNet data for one patient
    #' @return Event log with organ failure progression
    transform_to_organ_events = function(df) {
      events <- list()
      
      patient_id <- if ("Patient_ID" %in% names(df)) {
        df$Patient_ID[1]
      } else {
        glue::glue("p{sprintf('%06d', 1)}")
      }
      
      # Track previous state to detect changes
      prev_event <- "Low Risk"
      activity_counter <- 0
      
      # Base timestamp
      base_time <- as.POSIXct("2070-01-01 00:00:00")
      if ("HospAdmTime" %in% names(df)) {
        base_time <- base_time + hours(df$HospAdmTime[1])
      }
      
      # Process each hour of data
      for (i in 1:nrow(df)) {
        row <- df[i,]
        
        # Calculate timestamp
        if ("ICULOS" %in% names(row)) {
          timestamp <- base_time + hours(row$ICULOS)
        } else {
          timestamp <- base_time + hours(i - 1)
        }
        
        # Evaluate organ systems
        current_organs <- self$evaluate_all_organ_systems(row)
        
        # Get event name
        sepsis_label <- ifelse("SepsisLabel" %in% names(row), 
                               as.integer(row$SepsisLabel), 0)
        current_event <- self$get_organ_failure_event(current_organs, sepsis_label)
        
        # Generate event if state changed or first observation
        if (current_event != prev_event || i == 1) {
          event <- tibble(
            case = patient_id,
            activity = current_event,
            timestamp = timestamp,
            lifecycle = "complete",
            resource = "A",
            activity_instance_id = activity_counter,
            SepsisLabel = sepsis_label,
            # Keep key measurements for reference
            HR = row$HR,
            MAP = row$MAP,
            Creatinine = row$Creatinine,
            Bilirubin_total = row$Bilirubin_total,
            Platelets = row$Platelets,
            Lactate = row$Lactate,
            O2Sat = row$O2Sat,
            ICULOS = ifelse("ICULOS" %in% names(row), row$ICULOS, i - 1)
          )
          
          events <- append(events, list(event))
          activity_counter <- activity_counter + 1
          prev_event <- current_event
        }
      }
      
      if (length(events) > 0) {
        return(bind_rows(events))
      } else {
        return(tibble())
      }
    },
    
    #' Process multiple patients and create aggregated organ failure event log
    #' 
    #' @param patient_data_list List of patient data frames
    #' @return Aggregated event log for all patients
    create_aggregated_organ_log = function(patient_data_list) {
      all_events <- list()
      
      for (i in seq_along(patient_data_list)) {
        message(glue::glue("Processing patient {i}/{length(patient_data_list)}"))
        
        # Transform to organ events
        events <- self$transform_to_organ_events(patient_data_list[[i]])
        
        if (nrow(events) > 0) {
          all_events <- append(all_events, list(events))
        }
      }
      
      # Combine all patient events
      if (length(all_events) > 0) {
        combined_log <- bind_rows(all_events) %>%
          arrange(case, timestamp)
        
        return(combined_log)
      } else {
        return(tibble())
      }
    },
    
    #' Analyze organ failure patterns in the event log
    #' 
    #' @param event_log Event log data frame
    #' @return List with pattern statistics
    analyze_organ_patterns = function(event_log) {
      patterns <- list(
        total_cases = n_distinct(event_log$case),
        total_events = nrow(event_log),
        sepsis_cases = event_log %>%
          filter(SepsisLabel == 1) %>%
          pull(case) %>%
          n_distinct(),
        activity_distribution = event_log %>%
          count(activity, sort = TRUE) %>%
          deframe(),
        organ_failure_types = list(
          single_organ = event_log %>%
            filter(str_detect(activity, "Damage") & !str_detect(activity, "\\+")) %>%
            nrow(),
          dual_organ = event_log %>%
            filter(str_detect(activity, "\\+")) %>%
            nrow(),
          multiorgan = event_log %>%
            filter(activity == "Multiorgan Damage") %>%
            nrow(),
          low_risk = event_log %>%
            filter(activity == "Low Risk") %>%
            nrow(),
          sepsis = event_log %>%
            filter(activity == "Sepsis") %>%
            nrow()
        )
      )
      
      return(patterns)
    }
  )
)

#' Create sample patient data for demonstration
#' 
#' @return List of patient data frames with different organ failure patterns
create_sample_patients <- function() {
  set.seed(42)
  patients <- list()
  
  # Patient 1: Progresses from Low Risk to Multiorgan to Sepsis
  patient1_data <- tibble(
    HR = numeric(72),
    MAP = numeric(72),
    SBP = numeric(72),
    O2Sat = numeric(72),
    Resp = numeric(72),
    Creatinine = numeric(72),
    Bilirubin_total = numeric(72),
    Platelets = numeric(72),
    Lactate = numeric(72),
    AST = numeric(72),
    BUN = numeric(72),
    PTT = numeric(72),
    ICULOS = 1:72,
    SepsisLabel = integer(72),
    Patient_ID = "p000001"
  )
  
  for (hour in 1:72) {
    if (hour <= 24) {
      # Normal phase
      patient1_data$HR[hour] <- rnorm(1, 75, 5)
      patient1_data$MAP[hour] <- rnorm(1, 80, 5)
      patient1_data$SBP[hour] <- rnorm(1, 120, 10)
      patient1_data$O2Sat[hour] <- rnorm(1, 97, 1)
      patient1_data$Resp[hour] <- rnorm(1, 16, 2)
      patient1_data$Creatinine[hour] <- rnorm(1, 1.0, 0.2)
      patient1_data$Bilirubin_total[hour] <- rnorm(1, 0.8, 0.2)
      patient1_data$Platelets[hour] <- rnorm(1, 250, 30)
      patient1_data$Lactate[hour] <- rnorm(1, 1.0, 0.2)
      patient1_data$AST[hour] <- rnorm(1, 30, 10)
      patient1_data$BUN[hour] <- rnorm(1, 15, 5)
      patient1_data$PTT[hour] <- rnorm(1, 30, 5)
      patient1_data$SepsisLabel[hour] <- 0
    } else if (hour <= 48) {
      # Organ dysfunction phase
      patient1_data$HR[hour] <- rnorm(1, 110, 10)
      patient1_data$MAP[hour] <- rnorm(1, 60, 5)
      patient1_data$SBP[hour] <- rnorm(1, 85, 10)
      patient1_data$O2Sat[hour] <- rnorm(1, 90, 3)
      patient1_data$Resp[hour] <- rnorm(1, 24, 3)
      patient1_data$Creatinine[hour] <- rnorm(1, 2.5, 0.5)
      patient1_data$Bilirubin_total[hour] <- rnorm(1, 3.0, 0.5)
      patient1_data$Platelets[hour] <- rnorm(1, 80, 20)
      patient1_data$Lactate[hour] <- rnorm(1, 3.0, 0.5)
      patient1_data$AST[hour] <- rnorm(1, 150, 30)
      patient1_data$BUN[hour] <- rnorm(1, 50, 10)
      patient1_data$PTT[hour] <- rnorm(1, 65, 10)
      patient1_data$SepsisLabel[hour] <- 0
    } else {
      # Sepsis phase
      patient1_data$HR[hour] <- rnorm(1, 120, 10)
      patient1_data$MAP[hour] <- rnorm(1, 55, 5)
      patient1_data$SBP[hour] <- rnorm(1, 80, 10)
      patient1_data$O2Sat[hour] <- rnorm(1, 88, 3)
      patient1_data$Resp[hour] <- rnorm(1, 28, 3)
      patient1_data$Creatinine[hour] <- rnorm(1, 3.5, 0.5)
      patient1_data$Bilirubin_total[hour] <- rnorm(1, 4.0, 0.5)
      patient1_data$Platelets[hour] <- rnorm(1, 60, 20)
      patient1_data$Lactate[hour] <- rnorm(1, 4.5, 0.5)
      patient1_data$AST[hour] <- rnorm(1, 200, 30)
      patient1_data$BUN[hour] <- rnorm(1, 70, 10)
      patient1_data$PTT[hour] <- rnorm(1, 80, 10)
      patient1_data$SepsisLabel[hour] <- 1
    }
  }
  
  patients[[1]] <- patient1_data
  
  # Patient 2: Cardiac + Liver damage, no sepsis
  patient2_data <- tibble(
    HR = c(rep(rnorm(12, 75, 5), each = 1), rep(rnorm(36, 105, 10), each = 1)),
    MAP = c(rep(rnorm(12, 80, 5), each = 1), rep(rnorm(36, 62, 5), each = 1)),
    SBP = c(rep(rnorm(12, 120, 10), each = 1), rep(rnorm(36, 88, 8), each = 1)),
    O2Sat = rnorm(48, 96, 2),
    Resp = rnorm(48, 18, 3),
    Creatinine = rnorm(48, 1.1, 0.3),
    Bilirubin_total = c(rep(rnorm(12, 0.9, 0.2), each = 1), rep(rnorm(36, 2.8, 0.5), each = 1)),
    Platelets = rnorm(48, 180, 40),
    Lactate = c(rep(rnorm(12, 1.0, 0.2), each = 1), rep(rnorm(36, 2.3, 0.4), each = 1)),
    AST = c(rep(rnorm(12, 35, 10), each = 1), rep(rnorm(36, 120, 25), each = 1)),
    BUN = rnorm(48, 20, 8),
    PTT = rnorm(48, 35, 8),
    ICULOS = 1:48,
    SepsisLabel = 0,
    Patient_ID = "p000002"
  )
  
  patients[[2]] <- patient2_data
  
  return(patients)
}

# Main function to demonstrate transformation
run_physionet_to_organ_transformation <- function() {
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("PHYSIONET TO ORGAN FAILURE PROGRESSION TRANSFORMATION\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat("This example shows how raw PhysioNet Challenge 2019 data is transformed\n")
  cat("into organ failure progression events as in sepsisAgregated_Organ.csv\n")
  
  # Initialize transformer
  transformer <- PhysioNetToOrganTransformer$new()
  
  # Create sample patients
  cat("\n1. Creating sample PhysioNet-style patient data...\n")
  sample_patients <- create_sample_patients()
  cat(glue::glue("   Generated {length(sample_patients)} patients with organ failure patterns\n"))
  
  # Transform to organ events
  cat("\n2. Transforming to organ failure events...\n")
  organ_log <- transformer$create_aggregated_organ_log(sample_patients)
  
  cat("\n   Transformation Results:\n")
  cat(glue::glue("   - Total patients: {length(sample_patients)}\n"))
  cat(glue::glue("   - Generated events: {nrow(organ_log)}\n"))
  cat(glue::glue("   - Unique activities: {n_distinct(organ_log$activity)}\n"))
  
  # Show activity distribution
  cat("\n3. Activity Distribution:\n")
  activity_dist <- organ_log %>%
    count(activity, sort = TRUE)
  
  for (i in 1:min(10, nrow(activity_dist))) {
    cat(glue::glue("   - {activity_dist$activity[i]}: {activity_dist$n[i]} events\n"))
  }
  
  # Analyze patterns
  cat("\n4. Analyzing organ failure patterns...\n")
  patterns <- transformer$analyze_organ_patterns(organ_log)
  
  cat("\n   Pattern Analysis:\n")
  cat(glue::glue("   - Total cases: {patterns$total_cases}\n"))
  cat(glue::glue("   - Sepsis cases: {patterns$sepsis_cases}\n"))
  cat(glue::glue("   - Single organ failures: {patterns$organ_failure_types$single_organ}\n"))
  cat(glue::glue("   - Dual organ failures: {patterns$organ_failure_types$dual_organ}\n"))
  cat(glue::glue("   - Multiorgan failures: {patterns$organ_failure_types$multiorgan}\n"))
  cat(glue::glue("   - Low risk events: {patterns$organ_failure_types$low_risk}\n"))
  cat(glue::glue("   - Sepsis events: {patterns$organ_failure_types$sepsis}\n"))
  
  # Save the transformed event log
  cat("\n5. Saving transformed event log...\n")
  output_file <- "organ_failure_progression_events.csv"
  write_csv(organ_log, output_file)
  cat(glue::glue("   Saved to: {output_file}\n"))
  
  # Show sample of final format
  cat("\n6. Sample of transformed data (matching sepsisAgregated_Organ.csv format):\n\n")
  print(organ_log %>% 
          select(case, timestamp, activity, SepsisLabel) %>% 
          head(15))
  
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("TRANSFORMATION COMPLETE\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat("The output format matches sepsisAgregated_Organ.csv with activities like:\n")
  cat("- 'Low Risk'\n")
  cat("- 'Cardiac Damage', 'Liver Damage', 'Renal Damage'\n")
  cat("- 'Liver + Cardiac Damage', 'Renal + Cardiac Damage'\n")
  cat("- 'Multiorgan Damage'\n")
  cat("- 'Sepsis'\n")
  cat("\nThis event log tracks organ failure progression in sepsis patients.\n")
  
  return(list(transformer = transformer, organ_log = organ_log, patterns = patterns))
}

# Example usage
if (interactive()) {
  result <- run_physionet_to_organ_transformation()
  
  # Additional analysis
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("ADDITIONAL ANALYSIS\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  
  organ_log <- result$organ_log
  
  # Progression pathways
  cat("Common Organ Failure Progressions:\n")
  progressions <- organ_log %>%
    group_by(case) %>%
    summarise(
      pathway = paste(unique(activity), collapse = " → "),
      n_transitions = n() - 1,
      final_state = last(activity),
      developed_sepsis = any(SepsisLabel == 1)
    )
  
  common_pathways <- progressions %>%
    count(pathway, sort = TRUE) %>%
    head(5)
  
  for (i in 1:nrow(common_pathways)) {
    cat(glue::glue("  {i}. {common_pathways$pathway[i]}\n"))
    cat(glue::glue("     ({common_pathways$n[i]} patients)\n\n"))
  }
  
  # Time to organ failure
  cat("Time to First Organ Failure:\n")
  time_to_failure <- organ_log %>%
    filter(activity != "Low Risk") %>%
    group_by(case) %>%
    summarise(hours_to_failure = min(ICULOS))
  
  if (nrow(time_to_failure) > 0) {
    cat(glue::glue("  Mean: {round(mean(time_to_failure$hours_to_failure), 1)} hours\n"))
    cat(glue::glue("  Median: {round(median(time_to_failure$hours_to_failure), 1)} hours\n"))
  }
}