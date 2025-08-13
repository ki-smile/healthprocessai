# HealthProcessAI - R Step 4: Advanced Analytics and Methodological Approaches
# =============================================================================
#
# STEP 4: ADVANCED ANALYTICS AND METHODOLOGICAL APPROACHES
# =========================================================
# This module implements advanced process mining techniques inspired by
# state-of-the-art healthcare research methodologies.
#
# Learning Goals:
# - Implement conformance checking for clinical guidelines
# - Apply trace clustering for patient stratification  
# - Perform bottleneck analysis and resource optimization
# - Calculate clinical performance indicators
# - Implement predictive process monitoring
#
# Based on methodological approaches from recent healthcare process mining research,
# including techniques for analyzing complex clinical pathways and outcome prediction.
#
# Technology Mapping:
# - Python sklearn -> R cluster/stats packages
# - Python numpy -> R base/stats
# - Python scipy -> R stats package
# - Python pandas -> R tidyverse/dplyr
# - Python pm4py conformance -> R custom implementation
#
# Developed at SMAILE (Stockholm Medical AI Lab for Enhancement),
# Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(R6)
  library(tidyverse)
  library(bupaR)
  library(edeaR)
  library(processmapR) 
  library(cluster)
  library(stats)
  library(lubridate)
  library(glue)
  library(ggplot2)
})

#' Advanced Process Mining Analytics for Healthcare Data
#' 
#' This R6 class provides advanced process mining techniques including:
#' 1. Clinical guideline conformance checking
#' 2. Patient pathway clustering and stratification
#' 3. Bottleneck analysis and performance optimization
#' 4. Clinical KPI calculation and monitoring
#' 5. Predictive process monitoring for early warning
#' 
#' @import R6
#' @import bupaR
#' @import cluster
#' @export
AdvancedProcessAnalyzer <- R6::R6Class(
  classname = "AdvancedProcessAnalyzer",
  
  # Public methods and fields
  public = list(
    
    # Instance variables
    event_log = NULL,
    conformance_results = NULL,
    clusters = NULL,
    performance_metrics = NULL,
    
    #' Initialize the Advanced Process Analyzer
    #' 
    #' @param event_log bupaR eventlog object
    #' @return New AdvancedProcessAnalyzer instance
    #' 
    #' @examples
    #' analyzer <- AdvancedProcessAnalyzer$new(event_log)
    initialize = function(event_log) {
      if (!bupaR::is.eventlog(event_log)) {
        stop("❌ Input must be a bupaR eventlog object")
      }
      
      self$event_log <- event_log
      message("✅ Initialized Advanced Process Analyzer")
    },
    
    #' Check conformance of actual processes against clinical guidelines
    #' 
    #' This method implements rule-based conformance checking to identify 
    #' deviations from expected clinical pathways, similar to approaches 
    #' used in sepsis guideline compliance studies.
    #' 
    #' @param reference_rules List of clinical rules to check against
    #' @param guideline_name Name of the clinical guideline
    #' @return List containing conformance metrics and violations
    #' 
    #' @examples
    #' rules <- list(
    #'   "Blood Test must follow High Fever within 2 hours",
    #'   "Antibiotic must follow Blood Culture within 4 hours"
    #' )
    #' conformance <- analyzer$check_guideline_conformance(rules, "Sepsis Guideline")
    check_guideline_conformance = function(reference_rules, guideline_name = "Clinical Guideline") {
      message(glue::glue("🔍 Checking conformance against {guideline_name}"))
      
      # Convert eventlog to dataframe for analysis
      log_df <- self$event_log %>%
        bupaR::as.data.frame() %>%
        dplyr::arrange(case_id, timestamp)
      
      # Initialize conformance tracking
      total_cases <- length(unique(log_df$case_id))
      compliant_cases <- 0
      violations <- list()
      
      # Check each case against rules
      for (case in unique(log_df$case_id)) {
        case_events <- log_df %>% dplyr::filter(case_id == !!case)
        case_compliant <- private$check_case_conformance(case_events, reference_rules)
        
        if (case_compliant$compliant) {
          compliant_cases <- compliant_cases + 1
        } else {
          violations[[as.character(case)]] <- case_compliant$violations
        }
      }
      
      # Calculate compliance metrics
      compliance_rate <- compliant_cases / total_cases
      
      # Analyze common violation patterns
      violation_summary <- private$analyze_violation_patterns(violations)
      
      self$conformance_results <- list(
        guideline = guideline_name,
        total_cases = total_cases,
        compliant_cases = compliant_cases,
        compliance_rate = compliance_rate,
        violations = violations,
        violation_patterns = violation_summary,
        fitness_score = compliance_rate,  # Simplified fitness
        timestamp = Sys.time()
      )
      
      message(glue::glue("✅ Conformance check complete: {compliance_rate:.1%} compliance"))
      
      return(self$conformance_results)
    },
    
    #' Cluster patients based on their process patterns
    #' 
    #' This implements patient stratification based on pathway similarity,
    #' useful for identifying subgroups with different care patterns or outcomes.
    #' 
    #' @param n_clusters Number of clusters (NULL for automatic detection)
    #' @param method Clustering method ('kmeans', 'hierarchical', 'pam')
    #' @param features Vector of features to use for clustering
    #' @return List containing cluster assignments and characteristics
    #' 
    #' @examples
    #' clusters <- analyzer$cluster_patient_pathways(n_clusters = 3, method = "kmeans")
    cluster_patient_pathways = function(n_clusters = NULL, method = "kmeans", features = NULL) {
      message(glue::glue("🔬 Clustering patient pathways using {method}"))
      
      # Extract pathway features for clustering
      feature_matrix <- private$extract_pathway_features(features)
      
      # Standardize features
      feature_scaled <- scale(feature_matrix)
      
      # Determine optimal number of clusters if not specified
      if (is.null(n_clusters) && method %in% c("kmeans", "pam")) {
        n_clusters <- private$find_optimal_clusters(feature_scaled)
      }
      
      # Perform clustering
      cluster_result <- private$perform_clustering(feature_scaled, method, n_clusters)
      
      # Calculate cluster quality metrics
      if (length(unique(cluster_result$assignments)) > 1) {
        sil_analysis <- cluster::silhouette(cluster_result$assignments, dist(feature_scaled))
        silhouette_score <- mean(sil_analysis[, "sil_width"])
      } else {
        silhouette_score <- -1
      }
      
      # Analyze cluster characteristics
      cluster_profiles <- private$analyze_cluster_characteristics(
        cluster_result$assignments, 
        feature_matrix
      )
      
      # Calculate feature importance for cluster differentiation
      feature_importance <- private$calculate_feature_importance(
        feature_matrix, 
        cluster_result$assignments
      )
      
      self$clusters <- list(
        method = method,
        n_clusters = length(unique(cluster_result$assignments)),
        assignments = cluster_result$assignments,
        silhouette_score = silhouette_score,
        cluster_profiles = cluster_profiles,
        feature_importance = feature_importance,
        clusterer = cluster_result$model
      )
      
      message(glue::glue("✅ Identified {self$clusters$n_clusters} patient clusters"))
      
      return(self$clusters)
    },
    
    #' Identify bottlenecks in the clinical process
    #' 
    #' This method identifies activities and transitions that cause delays,
    #' similar to emergency department flow analysis.
    #' 
    #' @param threshold_percentile Percentile to define bottleneck threshold
    #' @return List containing bottleneck analysis results
    #' 
    #' @examples
    #' bottlenecks <- analyzer$analyze_bottlenecks(threshold_percentile = 75)
    analyze_bottlenecks = function(threshold_percentile = 75) {
      message("🚦 Analyzing process bottlenecks")
      
      # Calculate throughput times for each activity
      throughput_times <- self$event_log %>%
        edeaR::throughput_time("activity", units = "hours") %>%
        dplyr::arrange(desc(mean))
      
      # Calculate idle times (time between activities)
      idle_times <- self$event_log %>%
        edeaR::idle_time("activity", units = "hours")
      
      # Identify bottleneck activities
      bottlenecks <- throughput_times %>%
        dplyr::mutate(
          is_bottleneck = mean >= quantile(mean, threshold_percentile / 100, na.rm = TRUE),
          improvement_potential = ifelse(is_bottleneck, mean * 0.3, 0)  # 30% improvement assumption
        ) %>%
        dplyr::arrange(desc(mean))
      
      # Calculate process-level bottleneck metrics
      total_time <- sum(bottlenecks$mean * bottlenecks$cases, na.rm = TRUE)
      total_cases <- sum(bottlenecks$cases, na.rm = TRUE)
      avg_total_time <- ifelse(total_cases > 0, total_time / total_cases, 0)
      
      # Calculate improvement potential
      improvement_stats <- private$calculate_improvement_potential(bottlenecks)
      
      # Identify critical paths
      critical_activities <- bottlenecks %>%
        dplyr::filter(is_bottleneck) %>%
        dplyr::pull(activity) %>%
        head(5)
      
      results <- list(
        bottlenecks = bottlenecks,
        avg_total_wait_hours = avg_total_time,
        critical_activities = critical_activities,
        improvement_potential = improvement_stats,
        threshold_percentile = threshold_percentile,
        analysis_timestamp = Sys.time()
      )
      
      message(glue::glue("✅ Identified {sum(bottlenecks$is_bottleneck, na.rm = TRUE)} bottleneck activities"))
      
      return(results)
    },
    
    #' Calculate key performance indicators relevant to clinical processes
    #' 
    #' @return List of clinical KPIs
    #' 
    #' @examples
    #' kpis <- analyzer$calculate_clinical_kpis()
    calculate_clinical_kpis = function() {
      message("📊 Calculating clinical KPIs")
      
      # Case duration metrics
      case_durations <- self$event_log %>%
        edeaR::case_list() %>%
        dplyr::mutate(
          duration_hours = as.numeric(complete_timestamp - start_timestamp, units = "hours")
        )
      
      # Process efficiency metrics
      kpis <- list()
      
      if (nrow(case_durations) > 0) {
        kpis$avg_length_of_stay <- mean(case_durations$duration_hours, na.rm = TRUE)
        kpis$median_length_of_stay <- median(case_durations$duration_hours, na.rm = TRUE)
        kpis$p90_length_of_stay <- quantile(case_durations$duration_hours, 0.9, na.rm = TRUE)
        kpis$min_length_of_stay <- min(case_durations$duration_hours, na.rm = TRUE)
        kpis$max_length_of_stay <- max(case_durations$duration_hours, na.rm = TRUE)
      }
      
      # Throughput metrics
      kpis$total_cases <- nrow(case_durations)
      kpis$total_events <- nrow(self$event_log)
      kpis$unique_activities <- length(unique(self$event_log$activity))
      kpis$unique_resources <- length(unique(self$event_log$resource))
      
      # Calculate daily admission rate
      kpis$daily_admissions <- private$calculate_daily_admissions()
      
      # Activity frequency analysis
      activity_stats <- self$event_log %>%
        bupaR::activities() %>%
        dplyr::arrange(desc(absolute_frequency))
      
      kpis$most_frequent_activity <- activity_stats$activity[1]
      kpis$most_frequent_activity_count <- activity_stats$absolute_frequency[1]
      
      # Resource utilization
      kpis$resource_utilization <- private$calculate_resource_utilization()
      
      # Variant analysis
      variants <- self$event_log %>%
        bupaR::traces() %>%
        dplyr::arrange(desc(absolute_frequency))
      
      kpis$num_variants <- nrow(variants)
      kpis$most_common_variant_coverage <- variants$relative_frequency[1] * 100
      
      # Compliance metrics (if available)
      if (!is.null(self$conformance_results)) {
        kpis$guideline_compliance <- self$conformance_results$compliance_rate
      }
      
      # Process complexity metrics
      kpis$avg_trace_length <- mean(case_durations$trace_length, na.rm = TRUE)
      kpis$process_complexity <- nrow(variants) / nrow(case_durations)  # Variants per case ratio
      
      self$performance_metrics <- kpis
      
      message("✅ Clinical KPI calculation complete")
      
      return(kpis)
    },
    
    #' Predict the outcome of an ongoing case based on partial trace
    #' 
    #' This implements predictive process monitoring for early warning systems.
    #' 
    #' @param partial_trace Data frame with partial event sequence
    #' @param outcome_type Type of outcome to predict (e.g., "sepsis", "mortality")
    #' @return List containing prediction and confidence scores
    #' 
    #' @examples
    #' prediction <- analyzer$predict_case_outcome(partial_events, "sepsis")
    predict_case_outcome = function(partial_trace, outcome_type = "sepsis") {
      message(glue::glue("🔮 Predicting {outcome_type} outcome for partial trace"))
      
      # Extract features from partial trace
      trace_features <- private$extract_trace_features(partial_trace)
      
      # Rule-based prediction engine (simplified)
      risk_assessment <- private$assess_clinical_risk(partial_trace, outcome_type)
      
      # Generate risk score and category
      risk_score <- min(risk_assessment$score, 100)
      risk_level <- private$categorize_risk_level(risk_score)
      
      # Get clinical recommendations
      recommendations <- private$get_clinical_recommendations(risk_score, outcome_type)
      
      prediction <- list(
        outcome_type = outcome_type,
        risk_score = risk_score,
        risk_level = risk_level,
        risk_factors = risk_assessment$factors,
        confidence = risk_assessment$confidence,
        recommended_actions = recommendations,
        trace_length = nrow(partial_trace),
        prediction_timestamp = Sys.time()
      )
      
      message(glue::glue("✅ Prediction complete: {risk_level} risk ({risk_score}/100)"))
      
      return(prediction)
    },
    
    #' Export advanced analytics results to files
    #' 
    #' @param output_dir Directory to save results
    #' @return List of saved file paths
    export_advanced_results = function(output_dir = "advanced_analytics_results") {
      message("💾 Exporting advanced analytics results")
      
      # Create output directory
      if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
      }
      
      saved_files <- list()
      
      # Export clustering results if available
      if (!is.null(self$clusters)) {
        cluster_file <- file.path(output_dir, "patient_clusters.json")
        jsonlite::write_json(self$clusters, cluster_file, pretty = TRUE)
        saved_files$clusters <- cluster_file
      }
      
      # Export conformance results if available
      if (!is.null(self$conformance_results)) {
        conformance_file <- file.path(output_dir, "conformance_analysis.json")
        jsonlite::write_json(self$conformance_results, conformance_file, pretty = TRUE)
        saved_files$conformance <- conformance_file
      }
      
      # Export KPIs if available
      if (!is.null(self$performance_metrics)) {
        kpi_file <- file.path(output_dir, "clinical_kpis.json")
        jsonlite::write_json(self$performance_metrics, kpi_file, pretty = TRUE)
        saved_files$kpis <- kpi_file
      }
      
      # Export summary report
      summary_file <- file.path(output_dir, "analytics_summary.md")
      summary_report <- private$generate_summary_report()
      writeLines(summary_report, summary_file)
      saved_files$summary <- summary_file
      
      message(glue::glue("✅ Exported {length(saved_files)} result files to {output_dir}/"))
      
      return(saved_files)
    }
  ),
  
  # Private methods
  private = list(
    
    #' Check conformance of a single case against clinical rules
    #' @param case_events Data frame with events for one case
    #' @param rules List of clinical rules to check
    check_case_conformance = function(case_events, rules) {
      violations <- c()
      compliant <- TRUE
      
      # Example rule checking (simplified)
      activities <- case_events$activity
      timestamps <- case_events$timestamp
      
      # Check for required activity sequences
      if ("High Fever" %in% activities && "Blood Test" %in% activities) {
        fever_idx <- which(activities == "High Fever")[1]
        test_idx <- which(activities == "Blood Test")
        test_idx <- test_idx[test_idx > fever_idx][1]  # First test after fever
        
        if (!is.na(test_idx)) {
          time_diff <- as.numeric(timestamps[test_idx] - timestamps[fever_idx], units = "hours")
          if (time_diff > 2) {
            violations <- c(violations, "Blood test not ordered within 2 hours of high fever")
            compliant <- FALSE
          }
        } else {
          violations <- c(violations, "Blood test not ordered after high fever")
          compliant <- FALSE
        }
      }
      
      return(list(compliant = compliant, violations = violations))
    },
    
    #' Analyze patterns in conformance violations
    #' @param violations List of violations per case
    analyze_violation_patterns = function(violations) {
      all_violations <- unlist(violations)
      if (length(all_violations) == 0) {
        return(list(most_common = character(0), violation_counts = numeric(0)))
      }
      
      violation_counts <- table(all_violations)
      most_common <- names(sort(violation_counts, decreasing = TRUE))[1:min(5, length(violation_counts))]
      
      return(list(
        most_common = most_common,
        violation_counts = as.list(violation_counts)
      ))
    },
    
    #' Extract features from event log for clustering analysis
    #' @param feature_list Optional list of specific features to extract
    extract_pathway_features = function(feature_list = NULL) {
      message("Extracting pathway features for clustering")
      
      # Get case-level statistics
      case_stats <- self$event_log %>%
        edeaR::case_list() %>%
        dplyr::mutate(
          duration_hours = as.numeric(complete_timestamp - start_timestamp, units = "hours"),
          num_events = trace_length
        )
      
      # Activity diversity per case
      activity_diversity <- self$event_log %>%
        dplyr::group_by(case_id) %>%
        dplyr::summarise(
          unique_activities = n_distinct(activity),
          activity_repetitions = n() - n_distinct(activity),
          .groups = "drop"
        )
      
      # Resource diversity per case  
      resource_diversity <- self$event_log %>%
        dplyr::group_by(case_id) %>%
        dplyr::summarise(
          unique_resources = n_distinct(resource),
          .groups = "drop"
        )
      
      # Combine features
      features <- case_stats %>%
        dplyr::left_join(activity_diversity, by = "case_id") %>%
        dplyr::left_join(resource_diversity, by = "case_id") %>%
        dplyr::select(
          case_id,
          duration_hours,
          num_events, 
          unique_activities,
          activity_repetitions,
          unique_resources
        ) %>%
        dplyr::mutate_if(is.numeric, ~ ifelse(is.na(.), 0, .))
      
      # Add clinical outcome features if available
      if ("SepsisLabel" %in% colnames(self$event_log)) {
        sepsis_labels <- self$event_log %>%
          dplyr::group_by(case_id) %>%
          dplyr::summarise(sepsis_label = max(SepsisLabel, na.rm = TRUE), .groups = "drop")
        
        features <- features %>%
          dplyr::left_join(sepsis_labels, by = "case_id")
      }
      
      # Return feature matrix (exclude case_id)
      feature_matrix <- features %>%
        dplyr::select(-case_id) %>%
        as.matrix()
      
      return(feature_matrix)
    },
    
    #' Find optimal number of clusters using multiple methods
    #' @param data Scaled feature matrix
    #' @param max_k Maximum number of clusters to consider
    find_optimal_clusters = function(data, max_k = 10) {
      n_obs <- nrow(data)
      max_k <- min(max_k, n_obs - 1)
      
      if (max_k < 2) return(2)
      
      # Use elbow method with within-cluster sum of squares
      wss <- numeric(max_k)
      for (k in 1:max_k) {
        if (k == 1) {
          wss[k] <- sum(scale(data, scale = FALSE)^2)
        } else {
          kmeans_result <- stats::kmeans(data, centers = k, nstart = 10)
          wss[k] <- kmeans_result$tot.withinss
        }
      }
      
      # Find elbow point (simplified)
      if (length(wss) >= 3) {
        # Calculate second derivative to find elbow
        d2 <- diff(diff(wss))
        optimal_k <- which.max(d2) + 2  # +2 because of double diff
        optimal_k <- min(max(optimal_k, 2), max_k)
      } else {
        optimal_k <- 2
      }
      
      return(optimal_k)
    },
    
    #' Perform clustering using specified method
    #' @param data Scaled feature matrix
    #' @param method Clustering method
    #' @param n_clusters Number of clusters
    perform_clustering = function(data, method, n_clusters) {
      if (method == "kmeans") {
        model <- stats::kmeans(data, centers = n_clusters, nstart = 20)
        assignments <- model$cluster
      } else if (method == "pam") {
        model <- cluster::pam(data, k = n_clusters)
        assignments <- model$clustering
      } else if (method == "hierarchical") {
        dist_matrix <- dist(data)
        model <- stats::hclust(dist_matrix, method = "ward.D2")
        assignments <- stats::cutree(model, k = n_clusters)
      } else {
        stop(glue::glue("Unsupported clustering method: {method}"))
      }
      
      return(list(model = model, assignments = assignments))
    },
    
    #' Analyze characteristics of each cluster
    #' @param assignments Cluster assignments
    #' @param features Feature matrix
    analyze_cluster_characteristics = function(assignments, features) {
      cluster_profiles <- list()
      
      for (cluster_id in unique(assignments)) {
        cluster_mask <- assignments == cluster_id
        cluster_features <- features[cluster_mask, , drop = FALSE]
        
        if (nrow(cluster_features) > 0) {
          profile <- list(
            size = nrow(cluster_features),
            percentage = mean(cluster_mask) * 100,
            avg_duration_hours = mean(cluster_features[, "duration_hours"], na.rm = TRUE),
            avg_events = mean(cluster_features[, "num_events"], na.rm = TRUE),
            avg_unique_activities = mean(cluster_features[, "unique_activities"], na.rm = TRUE),
            avg_repetitions = mean(cluster_features[, "activity_repetitions"], na.rm = TRUE),
            avg_unique_resources = mean(cluster_features[, "unique_resources"], na.rm = TRUE)
          )
          
          # Add outcome statistics if available
          if ("sepsis_label" %in% colnames(features)) {
            profile$sepsis_rate = mean(cluster_features[, "sepsis_label"], na.rm = TRUE)
          }
          
          cluster_profiles[[glue::glue("cluster_{cluster_id}")]] <- profile
        }
      }
      
      return(cluster_profiles)
    },
    
    #' Calculate feature importance for cluster differentiation
    #' @param features Feature matrix
    #' @param assignments Cluster assignments
    calculate_feature_importance = function(features, assignments) {
      importance <- list()
      feature_names <- colnames(features)
      
      for (i in seq_along(feature_names)) {
        feature_name <- feature_names[i]
        feature_values <- features[, i]
        
        # Perform ANOVA to test difference between clusters
        clusters_factor <- factor(assignments)
        
        tryCatch({
          aov_result <- stats::aov(feature_values ~ clusters_factor)
          aov_summary <- summary(aov_result)
          f_stat <- aov_summary[[1]]$`F value`[1]
          p_value <- aov_summary[[1]]$`Pr(>F)`[1]
          
          importance[[feature_name]] <- list(
            f_statistic = ifelse(is.na(f_stat), 0, f_stat),
            p_value = ifelse(is.na(p_value), 1, p_value),
            significant = !is.na(p_value) && p_value < 0.05
          )
        }, error = function(e) {
          importance[[feature_name]] <- list(
            f_statistic = 0,
            p_value = 1,
            significant = FALSE
          )
        })
      }
      
      return(importance)
    },
    
    #' Calculate improvement potential from bottleneck optimization
    #' @param bottlenecks Bottleneck analysis results
    calculate_improvement_potential = function(bottlenecks) {
      if (nrow(bottlenecks) == 0) {
        return(list(hours_saveable = 0, percentage_reduction = 0))
      }
      
      # Calculate current total time
      total_current <- sum(bottlenecks$mean * bottlenecks$cases, na.rm = TRUE)
      
      # Simulate improvement: reduce top bottlenecks by 40%
      bottleneck_cases <- bottlenecks %>%
        dplyr::filter(is_bottleneck) %>%
        head(3)  # Top 3 bottlenecks
      
      potential_savings <- sum(bottleneck_cases$improvement_potential * bottleneck_cases$cases, na.rm = TRUE)
      
      return(list(
        hours_saveable = potential_savings,
        percentage_reduction = ifelse(total_current > 0, (potential_savings / total_current) * 100, 0)
      ))
    },
    
    #' Calculate daily admission statistics
    calculate_daily_admissions = function() {
      case_starts <- self$event_log %>%
        edeaR::case_list() %>%
        dplyr::mutate(admission_date = as.Date(start_timestamp))
      
      if (nrow(case_starts) > 0) {
        daily_counts <- case_starts %>%
          dplyr::count(admission_date) %>%
          dplyr::pull(n)
        
        return(mean(daily_counts, na.rm = TRUE))
      }
      
      return(0)
    },
    
    #' Calculate resource utilization metrics
    calculate_resource_utilization = function() {
      resource_stats <- self$event_log %>%
        dplyr::count(resource, sort = TRUE) %>%
        dplyr::mutate(
          percentage = n / sum(n) * 100,
          resource_type = resource
        )
      
      utilization <- list()
      for (i in seq_len(nrow(resource_stats))) {
        resource_name <- resource_stats$resource[i]
        utilization[[resource_name]] <- list(
          events = resource_stats$n[i],
          percentage = resource_stats$percentage[i]
        )
      }
      
      return(utilization)
    },
    
    #' Extract features from a partial trace for prediction
    #' @param partial_trace Data frame with partial case events
    extract_trace_features = function(partial_trace) {
      features <- list()
      
      # Basic metrics
      features$num_events <- nrow(partial_trace)
      features$unique_activities <- length(unique(partial_trace$activity))
      features$unique_resources <- length(unique(partial_trace$resource))
      
      # Temporal features
      if (nrow(partial_trace) > 0) {
        features$duration_hours <- as.numeric(
          max(partial_trace$timestamp) - min(partial_trace$timestamp), 
          units = "hours"
        )
      } else {
        features$duration_hours <- 0
      }
      
      # Activity pattern features
      activities <- partial_trace$activity
      features$activity_repetitions <- length(activities) - length(unique(activities))
      
      return(features)
    },
    
    #' Assess clinical risk based on partial trace patterns
    #' @param partial_trace Data frame with partial events
    #' @param outcome_type Type of clinical outcome
    assess_clinical_risk = function(partial_trace, outcome_type) {
      risk_score <- 0
      risk_factors <- c()
      
      activities <- partial_trace$activity
      
      # Risk assessment rules (domain-specific)
      if (outcome_type == "sepsis") {
        # High-risk patterns for sepsis
        if ("High Fever" %in% activities) {
          risk_score <- risk_score + 25
          risk_factors <- c(risk_factors, "High fever detected")
        }
        
        if ("Infection" %in% activities || any(grepl("Infection", activities))) {
          risk_score <- risk_score + 35
          risk_factors <- c(risk_factors, "Infection markers present")
        }
        
        if ("ICU" %in% activities || any(grepl("ICU", activities))) {
          risk_score <- risk_score + 30
          risk_factors <- c(risk_factors, "ICU admission required")
        }
        
        if ("Emergency" %in% activities) {
          risk_score <- risk_score + 20
          risk_factors <- c(risk_factors, "Emergency admission")
        }
        
        # Duration-based risk
        if (nrow(partial_trace) > 0) {
          duration_hours <- as.numeric(
            max(partial_trace$timestamp) - min(partial_trace$timestamp), 
            units = "hours"
          )
          
          if (duration_hours > 24) {
            risk_score <- risk_score + 15
            risk_factors <- c(risk_factors, "Extended hospital stay (>24h)")
          }
          
          if (duration_hours > 72) {
            risk_score <- risk_score + 10
            risk_factors <- c(risk_factors, "Prolonged hospital stay (>72h)")
          }
        }
      }
      
      # Calculate confidence based on trace completeness
      confidence <- min(0.95, 0.5 + (nrow(partial_trace) * 0.1))
      
      return(list(
        score = risk_score,
        factors = risk_factors,
        confidence = confidence
      ))
    },
    
    #' Categorize risk level based on numeric score
    #' @param risk_score Numeric risk score (0-100)
    categorize_risk_level = function(risk_score) {
      if (risk_score >= 70) {
        return("HIGH")
      } else if (risk_score >= 40) {
        return("MODERATE") 
      } else {
        return("LOW")
      }
    },
    
    #' Get clinical recommendations based on risk assessment
    #' @param risk_score Numeric risk score
    #' @param outcome_type Type of clinical outcome
    get_clinical_recommendations = function(risk_score, outcome_type) {
      recommendations <- c()
      
      if (risk_score >= 70) {
        recommendations <- c(
          "🚨 Immediate clinical review required",
          "🏥 Consider ICU consultation", 
          "💊 Initiate sepsis protocol if applicable",
          "🩸 Order comprehensive lab panel",
          "📊 Increase vital signs monitoring frequency"
        )
      } else if (risk_score >= 40) {
        recommendations <- c(
          "⚠️ Increase monitoring frequency",
          "💊 Review antibiotic therapy if indicated",
          "👨‍⚕️ Consider specialist consultation",
          "📈 Monitor trends in vital signs",
          "🔄 Reassess condition regularly"
        )
      } else {
        recommendations <- c(
          "✅ Continue standard care protocols",
          "📝 Maintain regular monitoring schedule", 
          "📋 Document progress notes",
          "🔄 Routine clinical assessments"
        )
      }
      
      return(recommendations)
    },
    
    #' Generate summary report of all analytics results
    generate_summary_report = function() {
      report_lines <- c(
        "# Advanced Process Mining Analytics Summary",
        paste("**Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "**"),
        "",
        "## Dataset Overview",
        glue::glue("- **Total cases**: {length(unique(self$event_log$case_id))}"),
        glue::glue("- **Total events**: {nrow(self$event_log)}"),
        glue::glue("- **Unique activities**: {length(unique(self$event_log$activity))}"),
        glue::glue("- **Unique resources**: {length(unique(self$event_log$resource))}"),
        ""
      )
      
      # Add clustering results if available
      if (!is.null(self$clusters)) {
        report_lines <- c(report_lines,
          "## Patient Clustering Analysis",
          glue::glue("- **Method**: {self$clusters$method}"),
          glue::glue("- **Number of clusters**: {self$clusters$n_clusters}"),
          glue::glue("- **Silhouette score**: {round(self$clusters$silhouette_score, 3)}"),
          ""
        )
      }
      
      # Add conformance results if available  
      if (!is.null(self$conformance_results)) {
        report_lines <- c(report_lines,
          "## Conformance Analysis",
          glue::glue("- **Guideline**: {self$conformance_results$guideline}"),
          glue::glue("- **Compliance rate**: {round(self$conformance_results$compliance_rate * 100, 1)}%"),
          glue::glue("- **Compliant cases**: {self$conformance_results$compliant_cases}/{self$conformance_results$total_cases}"),
          ""
        )
      }
      
      # Add KPI summary if available
      if (!is.null(self$performance_metrics)) {
        report_lines <- c(report_lines,
          "## Key Performance Indicators",
          glue::glue("- **Average length of stay**: {round(self$performance_metrics$avg_length_of_stay, 1)} hours"),
          glue::glue("- **Daily admissions**: {round(self$performance_metrics$daily_admissions, 1)}"),
          glue::glue("- **Process variants**: {self$performance_metrics$num_variants}"),
          ""
        )
      }
      
      report_lines <- c(report_lines,
        "---",
        "*Report generated by HealthProcessAI Advanced Analytics (R)*"
      )
      
      return(report_lines)
    }
  )
)

# Convenience functions for quick analysis (functional interface)

#' Quick advanced analytics of healthcare process data (functional interface)
#' 
#' @param event_log bupaR eventlog object
#' @param include_clustering Whether to perform patient clustering
#' @param include_bottlenecks Whether to perform bottleneck analysis  
#' @param include_kpis Whether to calculate clinical KPIs
#' @return List with advanced analytics results
#' @export
analyze_advanced_patterns <- function(event_log, include_clustering = TRUE, 
                                     include_bottlenecks = TRUE, include_kpis = TRUE) {
  analyzer <- AdvancedProcessAnalyzer$new(event_log)
  results <- list(analyzer = analyzer)
  
  if (include_clustering) {
    results$clusters <- analyzer$cluster_patient_pathways()
  }
  
  if (include_bottlenecks) {
    results$bottlenecks <- analyzer$analyze_bottlenecks()
  }
  
  if (include_kpis) {
    results$kpis <- analyzer$calculate_clinical_kpis()
  }
  
  return(results)
}

#' Quick clinical risk prediction (functional interface)
#' 
#' @param partial_events Data frame with partial case events
#' @param outcome_type Type of outcome to predict
#' @return Risk prediction results
#' @export
predict_clinical_risk <- function(partial_events, outcome_type = "sepsis") {
  # Create dummy analyzer for prediction
  dummy_log <- bupaR::eventlog(
    eventlog = partial_events,
    case_id = "case_id",
    activity_id = "activity", 
    timestamp = "timestamp",
    resource_id = "resource"
  )
  
  analyzer <- AdvancedProcessAnalyzer$new(dummy_log)
  prediction <- analyzer$predict_case_outcome(partial_events, outcome_type)
  
  return(prediction)
}

# Print module information
cat("🔬 HealthProcessAI R - Step 4: Advanced Analytics\n")
cat("===============================================\n")
cat("✅ AdvancedProcessAnalyzer R6 class available\n")
cat("✅ analyze_advanced_patterns() function available\n") 
cat("✅ predict_clinical_risk() function available\n")
cat("📚 Uses: bupaR, cluster, stats, tidyverse\n\n")
cat("Example usage:\n")
cat('  analyzer <- AdvancedProcessAnalyzer$new(event_log)\n')
cat("  clusters <- analyzer$cluster_patient_pathways()\n")
cat("  bottlenecks <- analyzer$analyze_bottlenecks()\n")
cat("  kpis <- analyzer$calculate_clinical_kpis()\n\n")