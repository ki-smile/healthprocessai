# HealthProcessAI - PhysioNet to Infection Progression Transformation (R Implementation)
# ====================================================================================
#
# EXAMPLE: TRANSFORMING PHYSIONET DATA TO INFECTION/INFLAMMATION PROGRESSION
# ===========================================================================
# This example demonstrates how raw PhysioNet Challenge 2019 sepsis data
# is transformed into infection/inflammation progression event logs.
#
# The transformation creates events like:
# - "High Temperature" / "Normal Temperature"
# - "Infection + High Temperature" / "Infection + Normal Temperature"
#
# This matches the format in sepsisAgregated_Infection.csv
#
# Based on PhysioNet Challenge 2019: Early Prediction of Sepsis from Clinical Data
# https://physionet.org/content/challenge-2019/1.0.0/
#
# Developed at SMAILE, Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(glue)
  library(R6)
})

#' PhysioNet to Infection Transformer R6 Class
#' 
#' @description
#' Transforms raw PhysioNet sepsis data to infection/inflammation progression events.
#' 
#' This transformer focuses on:
#' 1. Temperature patterns (fever/hypothermia as inflammation markers)
#' 2. Infection indicators (WBC, temperature combined)
#' 3. Progression states showing infection + inflammation
#' 
#' The output matches the structure of sepsisAgregated_Infection.csv
#' 
#' @import R6
#' @export
PhysioNetToInfectionTransformer <- R6::R6Class(
  classname = "PhysioNetToInfectionTransformer",
  
  public = list(
    
    # Clinical thresholds
    temp_thresholds = NULL,
    wbc_thresholds = NULL,
    infection_criteria = NULL,
    
    #' Initialize transformer with clinical thresholds
    initialize = function() {
      # Temperature thresholds for inflammation detection
      self$temp_thresholds <- list(
        high = 38.0,        # Fever threshold (°C)
        low = 36.0,         # Hypothermia threshold (°C)
        normal_low = 36.5,
        normal_high = 37.5
      )
      
      # WBC thresholds for infection detection
      self$wbc_thresholds <- list(
        high = 12.0,        # Leukocytosis (×10^9/L)
        low = 4.0,          # Leukopenia (×10^9/L)
        normal_low = 4.5,
        normal_high = 11.0
      )
      
      # Combined criteria for infection state
      self$infection_criteria <- list(
        temp_spike = 38.3,      # Higher temp for definite infection
        wbc_spike = 15.0,       # Higher WBC for definite infection
        crp_elevated = 10.0,    # CRP > 10 mg/L suggests infection
        lactate_elevated = 2.0  # Lactate > 2 mmol/L
      )
      
      message("PhysioNetToInfectionTransformer initialized")
    },
    
    #' Load PhysioNet patient file (PSV format)
    #' 
    #' @param patient_file Path to patient PSV file (e.g., 'p000001.psv')
    #' @return Data frame with hourly clinical measurements
    load_physionet_data = function(patient_file) {
      # PhysioNet column names
      columns <- c(
        "HR", "O2Sat", "Temp", "SBP", "MAP", "DBP", "Resp", "EtCO2",
        "BaseExcess", "HCO3", "FiO2", "pH", "PaCO2", "SaO2", "AST", "BUN",
        "Alkalinephos", "Calcium", "Chloride", "Creatinine", "Bilirubin_direct",
        "Glucose", "Lactate", "Magnesium", "Phosphate", "Potassium",
        "Bilirubin_total", "TroponinI", "Hct", "Hgb", "PTT", "WBC",
        "Fibrinogen", "Platelets", "Age", "Gender", "Unit1", "Unit2",
        "HospAdmTime", "ICULOS", "SepsisLabel"
      )
      
      # Load data
      df <- read_delim(patient_file, delim = "|", col_names = columns, 
                       show_col_types = FALSE)
      
      # Add patient ID from filename
      patient_id <- basename(patient_file) %>% 
        str_remove("\\.psv$")
      df$Patient_ID <- patient_id
      
      return(df)
    },
    
    #' Classify temperature into clinical states
    #' 
    #' @param temp Temperature in Celsius
    #' @return Temperature state string
    detect_temperature_state = function(temp) {
      if (is.na(temp)) {
        return(NA_character_)
      }
      
      if (temp >= self$temp_thresholds$high) {
        return("High Temperature")
      } else if (temp <= self$temp_thresholds$low) {
        return("Low Temperature")
      } else {
        return("Normal Temperature")
      }
    },
    
    #' Determine if patient shows signs of infection
    #' 
    #' @description
    #' Uses SIRS criteria and additional infection markers:
    #' - Temperature abnormality
    #' - WBC abnormality
    #' - Elevated lactate
    #' - Tachycardia
    #' - Tachypnea
    #' 
    #' @param row Patient data at specific timepoint
    #' @return Logical indicating infection presence
    detect_infection_state = function(row) {
      infection_score <- 0
      
      # Check temperature (fever or hypothermia)
      if (!is.na(row$Temp)) {
        if (row$Temp >= self$temp_thresholds$high || 
            row$Temp <= self$temp_thresholds$low) {
          infection_score <- infection_score + 1
          # Severe fever is stronger indicator
          if (row$Temp >= self$infection_criteria$temp_spike) {
            infection_score <- infection_score + 1
          }
        }
      }
      
      # Check WBC (leukocytosis or leukopenia)
      if (!is.na(row$WBC)) {
        if (row$WBC >= self$wbc_thresholds$high || 
            row$WBC <= self$wbc_thresholds$low) {
          infection_score <- infection_score + 1
          # Severe leukocytosis is stronger indicator
          if (row$WBC >= self$infection_criteria$wbc_spike) {
            infection_score <- infection_score + 1
          }
        }
      }
      
      # Check heart rate (tachycardia)
      if (!is.na(row$HR)) {
        if (row$HR > 90) {
          infection_score <- infection_score + 0.5
        }
      }
      
      # Check respiratory rate (tachypnea)
      if (!is.na(row$Resp)) {
        if (row$Resp > 20) {
          infection_score <- infection_score + 0.5
        }
      }
      
      # Check lactate (tissue hypoperfusion)
      if (!is.na(row$Lactate)) {
        if (row$Lactate > self$infection_criteria$lactate_elevated) {
          infection_score <- infection_score + 1
        }
      }
      
      # Infection likely if score >= 2
      return(infection_score >= 2)
    },
    
    #' Transform raw PhysioNet data to infection progression event log
    #' 
    #' @param df Raw PhysioNet data for one patient
    #' @return Event log with infection/inflammation progression
    transform_to_infection_events = function(df) {
      events <- list()
      patient_id <- df$Patient_ID[1]
      
      # Track previous states to detect transitions
      prev_temp_state <- NA_character_
      prev_infection_state <- FALSE
      activity_counter <- 0
      
      # Base timestamp (admission time)
      base_time <- as.POSIXct("2070-01-01 00:00:00") + 
        hours(df$HospAdmTime[1])
      
      for (i in 1:nrow(df)) {
        row <- df[i,]
        
        # Calculate timestamp (ICULOS = hours since ICU admission)
        timestamp <- base_time + hours(row$ICULOS)
        
        # Detect current states
        temp_state <- self$detect_temperature_state(row$Temp)
        infection_state <- self$detect_infection_state(row)
        
        # Generate events based on state changes
        if (!is.na(temp_state) && (is.na(prev_temp_state) || 
                                   temp_state != prev_temp_state || i == 1)) {
          # Temperature state change event
          if (infection_state) {
            # Combined infection + temperature event
            activity <- glue::glue("Infection + {temp_state}")
          } else {
            # Temperature only event
            activity <- temp_state
          }
          
          event <- tibble(
            case = patient_id,
            activity = as.character(activity),
            timestamp = timestamp,
            lifecycle = "complete",
            resource = "A",  # Resource A as in original data
            activity_instance_id = activity_counter,
            SepsisLabel = as.integer(row$SepsisLabel),
            # Keep original PhysioNet columns for reference
            HR = row$HR,
            O2Sat = row$O2Sat,
            Temp = row$Temp,
            WBC = row$WBC,
            Lactate = row$Lactate,
            ICULOS = row$ICULOS
          )
          
          events <- append(events, list(event))
          activity_counter <- activity_counter + 1
          prev_temp_state <- temp_state
          
        } else if (infection_state && !prev_infection_state && !is.na(prev_temp_state)) {
          # Infection started with existing temperature state
          activity <- glue::glue("Infection + {prev_temp_state}")
          
          event <- tibble(
            case = patient_id,
            activity = as.character(activity),
            timestamp = timestamp,
            lifecycle = "complete",
            resource = "A",
            activity_instance_id = activity_counter,
            SepsisLabel = as.integer(row$SepsisLabel),
            HR = row$HR,
            O2Sat = row$O2Sat,
            Temp = row$Temp,
            WBC = row$WBC,
            Lactate = row$Lactate,
            ICULOS = row$ICULOS
          )
          
          events <- append(events, list(event))
          activity_counter <- activity_counter + 1
        }
        
        prev_infection_state <- infection_state
      }
      
      if (length(events) > 0) {
        return(bind_rows(events))
      } else {
        return(tibble())
      }
    },
    
    #' Process multiple patient files and create aggregated infection event log
    #' 
    #' @param patient_files List of paths to PhysioNet patient files
    #' @return Aggregated event log for all patients
    create_aggregated_infection_log = function(patient_files) {
      all_events <- list()
      
      for (i in seq_along(patient_files)) {
        patient_file <- patient_files[i]
        message(glue::glue("Processing patient {i}/{length(patient_files)}: {patient_file}"))
        
        # Load patient data
        df <- self$load_physionet_data(patient_file)
        
        # Transform to infection events
        events <- self$transform_to_infection_events(df)
        
        if (nrow(events) > 0) {
          all_events <- append(all_events, list(events))
        }
      }
      
      # Combine all patient events
      if (length(all_events) > 0) {
        combined_log <- bind_rows(all_events)
        
        # Sort by case and timestamp
        combined_log <- combined_log %>%
          arrange(case, timestamp)
        
        return(combined_log)
      } else {
        return(tibble())
      }
    },
    
    #' Analyze infection/inflammation patterns in the event log
    #' 
    #' @param event_log Event log data frame
    #' @return List with pattern statistics
    analyze_infection_patterns = function(event_log) {
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
        infection_events = event_log %>%
          filter(str_detect(activity, "Infection")) %>%
          nrow(),
        temperature_patterns = list(
          high_temp_events = event_log %>%
            filter(str_detect(activity, "High Temperature")) %>%
            nrow(),
          normal_temp_events = event_log %>%
            filter(str_detect(activity, "Normal Temperature")) %>%
            nrow(),
          low_temp_events = event_log %>%
            filter(str_detect(activity, "Low Temperature")) %>%
            nrow()
        )
      )
      
      return(patterns)
    }
  )
)

#' Create sample data mimicking PhysioNet format
#' 
#' @return Data frame with PhysioNet-style measurements
create_sample_data <- function() {
  set.seed(42)
  
  # Create sample data for one patient
  hours <- 48  # 48 hours of ICU stay
  develops_sepsis <- TRUE
  sepsis_onset <- 24  # Sepsis at hour 24
  
  data <- tibble(
    HR = numeric(hours),
    O2Sat = numeric(hours),
    Temp = numeric(hours),
    SBP = numeric(hours),
    MAP = numeric(hours),
    DBP = numeric(hours),
    Resp = numeric(hours),
    WBC = numeric(hours),
    Lactate = numeric(hours),
    ICULOS = 1:hours,
    SepsisLabel = integer(hours),
    Patient_ID = "p000001",
    HospAdmTime = -5.0,  # 5 hours before ICU
    Age = 65,
    Gender = 1
  )
  
  for (hour in 1:hours) {
    # Simulate vital signs with sepsis progression
    if (develops_sepsis && hour >= sepsis_onset) {
      # Post-sepsis: abnormal values
      data$Temp[hour] <- sample(c(
        rnorm(1, 38.5, 0.5),  # Fever (80% chance)
        rnorm(1, 35.5, 0.3)   # Hypothermia (20% chance)
      ), 1, prob = c(0.8, 0.2))
      
      data$WBC[hour] <- rnorm(1, 15, 3)      # Elevated WBC
      data$Lactate[hour] <- rnorm(1, 3, 1)   # Elevated lactate
      data$HR[hour] <- rnorm(1, 110, 10)     # Tachycardia
      data$Resp[hour] <- rnorm(1, 24, 3)     # Tachypnea
      data$SepsisLabel[hour] <- 1
    } else {
      # Pre-sepsis: mostly normal with some variation
      data$Temp[hour] <- rnorm(1, 37, 0.5)
      data$WBC[hour] <- rnorm(1, 8, 2)
      data$Lactate[hour] <- rnorm(1, 1, 0.3)
      data$HR[hour] <- rnorm(1, 75, 10)
      data$Resp[hour] <- rnorm(1, 16, 2)
      data$SepsisLabel[hour] <- 0
    }
    
    # Other vitals
    data$O2Sat[hour] <- rnorm(1, 97, 2)
    data$SBP[hour] <- rnorm(1, 120, 15)
    data$MAP[hour] <- rnorm(1, 80, 10)
    data$DBP[hour] <- rnorm(1, 70, 10)
    
    # Add missing values randomly (realistic for ICU data)
    if (runif(1) < 0.1) data$Temp[hour] <- NA
    if (runif(1) < 0.3) data$WBC[hour] <- NA
    if (runif(1) < 0.5) data$Lactate[hour] <- NA
  }
  
  return(data)
}

# Main function to demonstrate transformation
run_physionet_to_infection_transformation <- function() {
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("PHYSIONET TO INFECTION/INFLAMMATION PROGRESSION TRANSFORMATION\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat("This example shows how raw PhysioNet Challenge 2019 data is transformed\n")
  cat("into infection/inflammation progression events as in sepsisAgregated_Infection.csv\n")
  
  # Initialize transformer
  transformer <- PhysioNetToInfectionTransformer$new()
  
  # Create sample data (in real use, load actual PhysioNet files)
  cat("\n1. Creating sample PhysioNet-style data...\n")
  sample_data <- create_sample_data()
  cat(glue::glue("   Generated {nrow(sample_data)} hours of ICU data\n"))
  
  # Transform to infection events
  cat("\n2. Transforming to infection/inflammation events...\n")
  event_log <- transformer$transform_to_infection_events(sample_data)
  
  cat("\n   Transformation Results:\n")
  cat(glue::glue("   - Original measurements: {nrow(sample_data)}\n"))
  cat(glue::glue("   - Generated events: {nrow(event_log)}\n"))
  cat(glue::glue("   - Unique activities: {n_distinct(event_log$activity)}\n"))
  
  # Show activity distribution
  cat("\n3. Activity Distribution:\n")
  activity_dist <- event_log %>%
    count(activity, sort = TRUE) %>%
    head(10)
  
  for (i in 1:nrow(activity_dist)) {
    cat(glue::glue("   - {activity_dist$activity[i]}: {activity_dist$n[i]} events\n"))
  }
  
  # Analyze patterns
  cat("\n4. Analyzing infection patterns...\n")
  patterns <- transformer$analyze_infection_patterns(event_log)
  
  cat("\n   Pattern Analysis:\n")
  cat(glue::glue("   - Total cases: {patterns$total_cases}\n"))
  cat(glue::glue("   - Sepsis cases: {patterns$sepsis_cases}\n"))
  cat(glue::glue("   - Infection events: {patterns$infection_events}\n"))
  cat(glue::glue("   - High temperature events: {patterns$temperature_patterns$high_temp_events}\n"))
  cat(glue::glue("   - Normal temperature events: {patterns$temperature_patterns$normal_temp_events}\n"))
  
  # Save the transformed event log
  cat("\n5. Saving transformed event log...\n")
  output_file <- "infection_progression_events.csv"
  write_csv(event_log, output_file)
  cat(glue::glue("   Saved to: {output_file}\n"))
  
  # Show sample of final format
  cat("\n6. Sample of transformed data (matching sepsisAgregated_Infection.csv format):\n\n")
  print(event_log %>% 
          select(case, timestamp, activity, SepsisLabel) %>% 
          head(10))
  
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("TRANSFORMATION COMPLETE\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat("The output format matches sepsisAgregated_Infection.csv with activities like:\n")
  cat("- 'High Temperature'\n")
  cat("- 'Normal Temperature'\n")
  cat("- 'Infection + High Temperature'\n")
  cat("- 'Infection + Normal Temperature'\n")
  cat("\nThis event log is ready for process mining analysis to discover\n")
  cat("infection/inflammation progression patterns in sepsis patients.\n")
  
  return(list(transformer = transformer, event_log = event_log))
}

# Example usage
if (interactive()) {
  result <- run_physionet_to_infection_transformation()
  
  # Additional analysis examples
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("ADDITIONAL ANALYSIS OPTIONS\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  
  event_log <- result$event_log
  
  # Transition analysis
  cat("Transition Analysis:\n")
  transitions <- event_log %>%
    group_by(case) %>%
    mutate(next_activity = lead(activity)) %>%
    filter(!is.na(next_activity)) %>%
    count(activity, next_activity, sort = TRUE) %>%
    head(5)
  
  for (i in 1:nrow(transitions)) {
    cat(glue::glue("  {transitions$activity[i]} -> {transitions$next_activity[i]}: {transitions$n[i]} times\n"))
  }
  
  # Time to sepsis analysis
  cat("\nTime to Sepsis Analysis:\n")
  sepsis_times <- event_log %>%
    group_by(case) %>%
    filter(SepsisLabel == 1) %>%
    summarise(
      first_sepsis_hour = min(ICULOS),
      last_normal_temp = max(ICULOS[!str_detect(activity, "High|Low")], na.rm = TRUE)
    ) %>%
    mutate(hours_from_normal_to_sepsis = first_sepsis_hour - last_normal_temp)
  
  if (nrow(sepsis_times) > 0) {
    cat(glue::glue("  Average time from last normal temp to sepsis: {round(mean(sepsis_times$hours_from_normal_to_sepsis, na.rm = TRUE), 1)} hours\n"))
  }
}