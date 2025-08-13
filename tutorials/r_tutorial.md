# 📊 HealthProcessAI R Tutorial

## Complete Guide to Process Mining in Healthcare with R

This tutorial covers the R implementation of HealthProcessAI using bupaR and the tidyverse ecosystem for healthcare process mining.

**Contributors:**
- **Farhad Abtahi** - Framework Architecture & R Integration Strategy
- **Eduardo Illueca Fernandez** - R Implementation Lead & bupaR Expertise
- **Kaile Chen** - Clinical Applications & Healthcare Use Cases

## 📚 Table of Contents

1. [R Environment Setup](#1-r-environment-setup)
2. [Data Loading with Tidyverse](#2-data-loading-with-tidyverse)
3. [Process Discovery with bupaR](#3-process-discovery-with-bupar)
4. [Interactive Visualizations](#4-interactive-visualizations)
5. [Performance Analysis](#5-performance-analysis)
6. [LLM Integration with httr](#6-llm-integration-with-httr)
7. [Report Generation with RMarkdown](#7-report-generation-with-rmarkdown)
8. [Shiny Dashboards](#8-shiny-dashboards)
9. [Statistical Analysis](#9-statistical-analysis)
10. [Best Practices for R](#10-best-practices-for-r)

---

## 1. R Environment Setup

### 1.1 Installing Required Packages

```r
# Install core process mining packages
install.packages(c(
  "bupaR",           # Process mining framework
  "processmapR",     # Process visualization
  "processmonitR",   # Performance monitoring
  "edeaR",           # Exploratory data analysis
  "eventdataR"       # Event log utilities
))

# Install tidyverse ecosystem
install.packages(c(
  "tidyverse",       # Data manipulation and visualization
  "lubridate",       # Date/time handling
  "readr",           # Fast data reading
  "dplyr",           # Data manipulation
  "ggplot2",         # Visualization
  "plotly"           # Interactive plots
))

# Install additional packages for healthcare analysis
install.packages(c(
  "httr",            # HTTP requests for LLM integration
  "jsonlite",        # JSON handling
  "rmarkdown",       # Report generation
  "knitr",           # Dynamic documents
  "DT",              # Interactive tables
  "shiny",           # Web applications
  "shinydashboard"   # Dashboard framework
))
```

### 1.2 Loading Libraries and Setup

```r
# Core process mining
library(bupaR)
library(processmapR)
library(processmonitR)
library(edeaR)
library(eventdataR)

# Data manipulation and visualization
library(tidyverse)
library(lubridate)
library(plotly)
library(DT)

# LLM integration and reporting
library(httr)
library(jsonlite)
library(rmarkdown)
library(knitr)

# Set options for better output
options(digits = 3)
theme_set(theme_minimal())

# Verify installation
cat("✅ bupaR version:", packageVersion("bupaR"), "\n")
cat("✅ tidyverse version:", packageVersion("tidyverse"), "\n")
cat("✅ All packages loaded successfully!\n")
```

---

## 2. Data Loading with Tidyverse

### 2.1 Healthcare Event Log Structure

```r
# Define the expected structure for healthcare event logs
healthcare_log_structure <- tribble(
  ~Column, ~Description, ~Type, ~Example,
  "case_id", "Patient/Episode identifier", "character", "P001",
  "activity", "Clinical activity/event", "character", "Blood Test",
  "timestamp", "When the event occurred", "POSIXct", "2024-01-15 14:30:00",
  "resource", "Who/what performed activity", "character", "Dr. Smith",
  "attributes", "Additional clinical data", "various", "Temperature: 38.5°C"
)

print(healthcare_log_structure)
```

### 2.2 Loading and Cleaning Healthcare Data

```r
# Function to load and prepare healthcare event data
load_healthcare_data <- function(file_path) {
  
  cat("🔄 Loading healthcare event data from:", file_path, "\n")
  
  # Load data with automatic type detection
  raw_data <- read_csv(file_path, show_col_types = FALSE) %>%
    # Handle common column name variations
    rename_with(~ case_when(
      str_detect(tolower(.x), "case|patient") ~ "case_id",
      str_detect(tolower(.x), "activity|event") ~ "activity", 
      str_detect(tolower(.x), "time|date") ~ "timestamp",
      str_detect(tolower(.x), "resource|staff") ~ "resource",
      TRUE ~ .x
    ))
  
  cat("✅ Loaded", nrow(raw_data), "raw events\n")
  
  # Data cleaning and preparation
  cleaned_data <- raw_data %>%
    # Convert timestamp to proper datetime
    mutate(
      timestamp = case_when(
        is.character(timestamp) ~ as.POSIXct(timestamp, format = "%Y-%m-%d %H:%M:%S"),
        is.POSIXct(timestamp) ~ timestamp,
        TRUE ~ as.POSIXct(timestamp, origin = "1970-01-01")
      )
    ) %>%
    # Remove rows with missing critical data
    filter(
      !is.na(case_id),
      !is.na(activity),
      !is.na(timestamp)
    ) %>%
    # Standardize activity names
    mutate(
      activity = str_to_title(str_trim(activity)),
      # Common healthcare activity mappings
      activity = case_when(
        str_detect(activity, "Emergency|ER") ~ "Emergency Admission",
        str_detect(activity, "Lab|Laboratory") ~ "Lab Test", 
        str_detect(activity, "Blood") ~ "Blood Test",
        str_detect(activity, "IV|Intravenous") ~ "IV Administration",
        str_detect(activity, "Antibiotic") ~ "Antibiotics",
        TRUE ~ activity
      )
    ) %>%
    # Sort by case and time
    arrange(case_id, timestamp) %>%
    # Add derived features
    mutate(
      hour = hour(timestamp),
      day_of_week = wday(timestamp, label = TRUE),
      date = as.Date(timestamp)
    )
  
  # Remove duplicates
  initial_rows <- nrow(cleaned_data)
  cleaned_data <- cleaned_data %>%
    distinct(case_id, activity, timestamp, .keep_all = TRUE)
  removed_dups <- initial_rows - nrow(cleaned_data)
  
  if (removed_dups > 0) {
    cat("✅ Removed", removed_dups, "duplicate events\n")
  }
  
  cat("✅ Data cleaning complete:", nrow(cleaned_data), "events ready\n")
  cat("📊 Summary:", 
      length(unique(cleaned_data$case_id)), "patients,", 
      length(unique(cleaned_data$activity)), "activities\n")
  
  return(cleaned_data)
}

# Usage example
# sepsis_data <- load_healthcare_data("data/sepsisAgregated_Infection.csv")
```

### 2.3 Converting to bupaR Event Log

```r
# Function to create bupaR event log from healthcare data
create_bupar_eventlog <- function(data) {
  
  cat("🔄 Converting to bupaR event log format...\n")
  
  # Create eventlog with proper bupaR structure
  event_log <- data %>%
    eventlog(
      case_id = "case_id",
      activity_id = "activity", 
      activity_instance_id = NULL,  # Let bupaR auto-generate
      lifecycle_id = NULL,          # Single lifecycle for healthcare
      timestamp = "timestamp",
      resource_id = "resource"
    )
  
  cat("✅ Created bupaR event log with", n_cases(event_log), "cases\n")
  cat("📈 Event log summary:\n")
  
  # Print summary statistics
  summary_stats <- list(
    cases = n_cases(event_log),
    events = n_events(event_log),
    activities = n_activities(event_log),
    resources = n_resources(event_log),
    traces = n_traces(event_log)
  )
  
  for (stat in names(summary_stats)) {
    cat("  -", str_to_title(stat), ":", summary_stats[[stat]], "\n")
  }
  
  return(event_log)
}

# Example usage:
# event_log <- create_bupar_eventlog(sepsis_data)
```

---

## 3. Process Discovery with bupaR

### 3.1 Basic Process Discovery

```r
# Function for comprehensive process discovery
discover_healthcare_process <- function(event_log, filter_threshold = 0.8) {
  
  cat("🔍 Discovering healthcare process patterns...\n")
  
  # Basic process map with frequency information
  process_map <- event_log %>%
    # Apply frequency filter to reduce noise
    filter_activity_frequency(percentage = filter_threshold) %>%
    process_map(
      type = frequency("absolute"),
      sec = frequency("absolute")
    )
  
  # Performance-based process map
  performance_map <- event_log %>%
    filter_activity_frequency(percentage = filter_threshold) %>%
    process_map(
      type = performance(median),
      sec = performance(median, "mins")
    )
  
  # Precedence matrix for detailed analysis
  precedence_matrix <- event_log %>%
    precedence_matrix(type = "absolute")
  
  cat("✅ Process discovery complete\n")
  
  return(list(
    frequency_map = process_map,
    performance_map = performance_map,  
    precedence_matrix = precedence_matrix,
    event_log = event_log
  ))
}

# Advanced process analysis
analyze_process_variants <- function(event_log, top_k = 10) {
  
  cat("📊 Analyzing process variants (patient pathways)...\n")
  
  # Get trace statistics
  trace_stats <- event_log %>%
    trace_coverage("trace") %>%
    arrange(desc(absolute)) %>%
    head(top_k) %>%
    mutate(
      percentage = round(relative * 100, 1),
      trace_short = str_trunc(trace, 60)
    )
  
  cat("✅ Found", nrow(trace_stats), "top variants covering", 
      sum(trace_stats$relative) * 100, "% of cases\n")
  
  # Trace length analysis  
  trace_lengths <- event_log %>%
    trace_length("log") %>%
    pull(trace_length)
  
  length_stats <- list(
    mean = mean(trace_lengths),
    median = median(trace_lengths), 
    min = min(trace_lengths),
    max = max(trace_lengths),
    sd = sd(trace_lengths)
  )
  
  cat("📏 Trace lengths - Mean:", round(length_stats$mean, 1), 
      "Median:", length_stats$median, 
      "Range:", length_stats$min, "-", length_stats$max, "\n")
  
  return(list(
    variants = trace_stats,
    length_stats = length_stats,
    raw_lengths = trace_lengths
  ))
}
```

### 3.2 Clinical Pathway Analysis

```r
# Specialized function for clinical pathway analysis
analyze_clinical_pathways <- function(event_log, outcome_column = "SepsisLabel") {
  
  cat("🏥 Analyzing clinical pathways and outcomes...\n")
  
  # If outcome data is available, compare pathways
  if (outcome_column %in% names(event_log)) {
    
    # Separate cases by outcome
    positive_cases <- event_log %>%
      filter(.data[[outcome_column]] == 1) %>%
      cases()
    
    negative_cases <- event_log %>% 
      filter(.data[[outcome_column]] == 0) %>%
      cases()
    
    # Analyze activity patterns by outcome
    positive_activities <- event_log %>%
      filter_case(cases %in% positive_cases) %>%
      activity_frequency("activity") %>%
      mutate(group = "Positive Outcome")
    
    negative_activities <- event_log %>%
      filter_case(cases %in% negative_cases) %>%
      activity_frequency("activity") %>%  
      mutate(group = "Negative Outcome")
    
    # Combine and compare
    activity_comparison <- bind_rows(positive_activities, negative_activities) %>%
      select(activity, relative, group) %>%
      pivot_wider(names_from = group, values_from = relative, values_fill = 0) %>%
      mutate(
        difference = `Positive Outcome` - `Negative Outcome`,
        abs_difference = abs(difference)
      ) %>%
      arrange(desc(abs_difference))
    
    cat("✅ Pathway comparison complete\n")
    cat("🔍 Activities most differentiating outcomes:\n")
    
    activity_comparison %>%
      head(5) %>%
      mutate(
        difference_pct = round(difference * 100, 1),
        interpretation = ifelse(difference > 0, 
                               "More common in positive outcomes",
                               "More common in negative outcomes")
      ) %>%
      select(activity, difference_pct, interpretation) %>%
      print()
    
    return(list(
      positive_cases = positive_cases,
      negative_cases = negative_cases,
      activity_comparison = activity_comparison
    ))
    
  } else {
    cat("ℹ️ No outcome column found, performing general pathway analysis\n")
    
    # General pathway analysis without outcomes
    pathways <- event_log %>%
      traces() %>%
      arrange(desc(absolute)) %>%
      head(10) %>%
      mutate(
        percentage = round(relative * 100, 1),
        pathway_summary = str_extract(trace, "^[^,]+(?:,[^,]+){0,3}")
      )
    
    return(list(pathways = pathways))
  }
}
```

---

## 4. Interactive Visualizations

### 4.1 Interactive Process Maps with plotly

```r
# Function to create interactive process visualizations
create_interactive_visualizations <- function(event_log) {
  
  cat("📊 Creating interactive visualizations...\n")
  
  # Activity frequency plot
  activity_freq_plot <- event_log %>%
    activity_frequency("activity") %>%
    mutate(
      activity = fct_reorder(activity, absolute),
      percentage = round(relative * 100, 1)
    ) %>%
    ggplot(aes(x = absolute, y = activity, fill = absolute)) +
    geom_col() +
    geom_text(aes(label = paste0(percentage, "%")), 
              hjust = -0.1, size = 3) +
    scale_fill_viridis_c(option = "plasma") +
    labs(
      title = "Clinical Activity Frequencies",
      x = "Number of Events",
      y = "Clinical Activity",
      fill = "Count"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  
  interactive_activity_plot <- ggplotly(activity_freq_plot, tooltip = "all")
  
  # Throughput time analysis
  throughput_plot <- event_log %>%
    throughput_time("log", units = "hours") %>%
    ggplot(aes(x = throughput_time)) +
    geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
    geom_vline(aes(xintercept = median(throughput_time)), 
               color = "red", linetype = "dashed", size = 1) +
    labs(
      title = "Patient Case Duration Distribution", 
      x = "Duration (hours)",
      y = "Number of Cases",
      subtitle = paste("Median duration:", 
                       round(median(event_log %>% 
                                   throughput_time("log", units = "hours") %>% 
                                   pull(throughput_time)), 1), "hours")
    ) +
    theme_minimal()
  
  interactive_throughput_plot <- ggplotly(throughput_plot)
  
  # Resource workload analysis
  resource_plot <- event_log %>%
    resource_frequency("resource") %>%
    top_n(10, absolute) %>%
    mutate(resource = fct_reorder(resource, absolute)) %>%
    ggplot(aes(x = absolute, y = resource, fill = relative)) +
    geom_col() +
    scale_fill_gradient(low = "lightblue", high = "darkblue") +
    labs(
      title = "Resource Workload Distribution",
      x = "Number of Activities", 
      y = "Resource",
      fill = "Proportion"
    ) +
    theme_minimal()
  
  interactive_resource_plot <- ggplotly(resource_plot)
  
  cat("✅ Interactive visualizations created\n")
  
  return(list(
    activity_plot = interactive_activity_plot,
    throughput_plot = interactive_throughput_plot,
    resource_plot = interactive_resource_plot
  ))
}
```

### 4.2 Animated Process Analysis

```r
# Function to create animated process analysis
create_animated_analysis <- function(event_log) {
  
  cat("🎬 Creating animated process analysis...\n")
  
  # Activity frequency over time
  time_analysis <- event_log %>%
    mutate(
      date = as.Date(timestamp),
      week = floor_date(date, "week")
    ) %>%
    group_by(week, activity) %>%
    summarise(count = n(), .groups = "drop") %>%
    arrange(week) %>%
    group_by(activity) %>%
    mutate(cumulative = cumsum(count)) %>%
    ungroup()
  
  # Create animated plot
  animated_plot <- time_analysis %>%
    filter(activity %in% (time_analysis %>% 
                         count(activity, wt = count, sort = TRUE) %>% 
                         head(8) %>% 
                         pull(activity))) %>%
    ggplot(aes(x = week, y = cumulative, color = activity)) +
    geom_line(size = 1.2, alpha = 0.8) +
    geom_point(size = 2) +
    scale_color_brewer(type = "qual", palette = "Set2") +
    labs(
      title = "Cumulative Clinical Activities Over Time",
      x = "Week",
      y = "Cumulative Count", 
      color = "Activity"
    ) +
    theme_minimal() +
    theme(legend.position = "right")
  
  interactive_time_plot <- ggplotly(animated_plot)
  
  return(interactive_time_plot)
}
```

---

## 5. Performance Analysis

### 5.1 Bottleneck Identification

```r
# Function to identify process bottlenecks
identify_bottlenecks <- function(event_log, threshold_hours = 2) {
  
  cat("🚫 Identifying process bottlenecks...\n")
  
  # Calculate processing times between activities
  processing_times <- event_log %>%
    processing_time("activity", units = "hours") %>%
    filter(processing_time > 0) %>%
    arrange(desc(processing_time))
  
  # Identify bottlenecks (long processing times)
  bottlenecks <- processing_times %>%
    filter(processing_time >= threshold_hours) %>%
    mutate(
      bottleneck_severity = case_when(
        processing_time >= 24 ~ "Critical (>24h)",
        processing_time >= 8 ~ "High (8-24h)", 
        processing_time >= 4 ~ "Medium (4-8h)",
        TRUE ~ "Low (2-4h)"
      )
    )
  
  cat("⚠️ Found", nrow(bottlenecks), "potential bottlenecks\n")
  
  if (nrow(bottlenecks) > 0) {
    cat("🔍 Top bottlenecks by severity:\n")
    bottlenecks %>%
      count(bottleneck_severity, sort = TRUE) %>%
      print()
  }
  
  # Idle time analysis
  idle_times <- event_log %>%
    idle_time("resource", units = "hours") %>%
    arrange(desc(idle_time))
  
  # Waiting time analysis
  waiting_times <- event_log %>%
    processing_time("case", units = "hours") %>%
    arrange(desc(processing_time)) %>%
    mutate(waiting_category = cut(processing_time, 
                                 breaks = c(0, 4, 12, 24, 48, Inf),
                                 labels = c("0-4h", "4-12h", "12-24h", "24-48h", ">48h")))
  
  return(list(
    processing_times = processing_times,
    bottlenecks = bottlenecks,
    idle_times = idle_times,
    waiting_times = waiting_times
  ))
}
```

### 5.2 Performance Metrics Dashboard

```r
# Function to create performance metrics summary
create_performance_dashboard <- function(event_log) {
  
  cat("📊 Creating performance metrics dashboard...\n")
  
  # Key performance indicators
  kpis <- list(
    # Case metrics
    total_cases = n_cases(event_log),
    total_events = n_events(event_log),
    avg_case_length = mean(event_log %>% trace_length("case") %>% pull(trace_length)),
    
    # Time metrics  
    avg_throughput_hours = mean(event_log %>% throughput_time("log", "hours") %>% pull(throughput_time)),
    median_throughput_hours = median(event_log %>% throughput_time("log", "hours") %>% pull(throughput_time)),
    
    # Resource metrics
    total_resources = n_resources(event_log),
    avg_resource_utilization = mean(event_log %>% resource_frequency("resource") %>% pull(absolute))
  )
  
  # Create summary table
  kpi_table <- tibble(
    Metric = c(
      "Total Patients", "Total Events", "Average Case Length (activities)",
      "Average Case Duration (hours)", "Median Case Duration (hours)", 
      "Total Resources", "Average Resource Load"
    ),
    Value = c(
      kpis$total_cases, kpis$total_events, round(kpis$avg_case_length, 1),
      round(kpis$avg_throughput_hours, 1), round(kpis$median_throughput_hours, 1),
      kpis$total_resources, round(kpis$avg_resource_utilization, 1)
    )
  )
  
  cat("✅ Performance dashboard created\n")
  print(kpi_table)
  
  return(list(
    kpis = kpis,
    kpi_table = kpi_table
  ))
}
```

---

## 6. LLM Integration with httr

### 6.1 OpenRouter API Integration

```r
# Function to integrate with OpenRouter API for LLM analysis
setup_llm_analyzer <- function(api_key, base_url = "https://openrouter.ai/api/v1") {
  
  # Create analyzer object (closure)
  analyzer <- new.env()
  analyzer$api_key <- api_key
  analyzer$base_url <- base_url
  analyzer$headers <- add_headers(
    "Authorization" = paste("Bearer", api_key),
    "Content-Type" = "application/json"
  )
  
  # Function to create clinical prompts
  analyzer$create_clinical_prompt <- function(process_results, domain = "healthcare") {
    prompt <- paste(
      "You are a clinical epidemiologist analyzing healthcare process data.",
      "Please analyze the following process mining results:\n",
      
      "CLINICAL CONTEXT:",
      paste("- Domain:", str_to_title(domain), "care pathways"),
      "- Setting: Hospital with electronic health records", 
      "- Goal: Improve patient outcomes and process efficiency\n",
      
      "PROCESS FINDINGS:",
      paste("- Total Cases:", format(process_results$num_cases, big.mark = ",")),
      paste("- Average Duration:", round(process_results$avg_duration_hours, 1), "hours"),
      paste("- Process Variants:", process_results$num_variants),
      paste("- Top Variant Coverage:", process_results$top_variant_coverage),
      paste("- Activities:", process_results$num_activities, "\n"),
      
      "KEY ACTIVITIES:",
      if (!is.null(process_results$top_activities)) {
        paste(process_results$top_activities, collapse = "\n")
      } else {
        "Data not available"
      }, "\n",
      
      "Please provide analysis covering:",
      "1. Clinical significance of discovered patterns",
      "2. Quality improvement opportunities", 
      "3. Early warning indicators",
      "4. Resource optimization recommendations",
      "5. Specific actionable recommendations",
      
      sep = "\n"
    )
    return(prompt)
  }
  
  # Function to query LLM models
  analyzer$query_model <- function(prompt, model = "deepseek/deepseek-r1", max_tokens = 4000) {
    
    cat("🤖 Querying", model, "for clinical insights...\n")
    
    tryCatch({
      response <- POST(
        url = paste0(analyzer$base_url, "/chat/completions"),
        analyzer$headers,
        body = toJSON(list(
          model = model,
          messages = list(list(role = "user", content = prompt)),
          max_tokens = max_tokens,
          temperature = 0.7
        ), auto_unbox = TRUE)
      )
      
      if (status_code(response) == 200) {
        result <- fromJSON(content(response, "text"))
        cat("✅ Successfully received analysis from", model, "\n")
        return(list(
          status = "success",
          content = result$choices[[1]]$message$content,
          model = model,
          timestamp = Sys.time()
        ))
      } else {
        error_msg <- paste("HTTP", status_code(response), "-", content(response, "text"))
        cat("❌ Error with", model, ":", error_msg, "\n")
        return(list(
          status = "error", 
          error = error_msg,
          model = model,
          timestamp = Sys.time()
        ))
      }
    }, error = function(e) {
      cat("❌ Exception with", model, ":", e$message, "\n")
      return(list(
        status = "error",
        error = e$message, 
        model = model,
        timestamp = Sys.time()
      ))
    })
  }
  
  # Function to analyze with multiple models
  analyzer$analyze_with_multiple_models <- function(prompt, models = NULL) {
    if (is.null(models)) {
      models <- c(
        "anthropic/claude-3.5-sonnet",
        "openai/gpt-4-turbo", 
        "google/gemini-pro-1.5",
        "deepseek/deepseek-r1"
      )
    }
    
    results <- list()
    for (model in models) {
      results[[model]] <- analyzer$query_model(prompt, model)
      Sys.sleep(1) # Rate limiting
    }
    
    return(results)
  }
  
  return(analyzer)
}
```

### 6.2 Clinical Report Generation

```r
# Function to generate clinical reports from LLM analysis
generate_clinical_report_r <- function(process_results, llm_analysis, output_format = "html") {
  
  cat("📄 Generating clinical report...\n")
  
  report_content <- paste(
    "# Healthcare Process Mining Analysis Report",
    "",
    paste("**Generated:", Sys.time(), "**"),  
    paste("**Analysis Framework:** HealthProcessAI with R/bupaR"),
    "", 
    "---",
    "",
    "## Executive Summary", 
    "",
    paste("This report analyzes", format(process_results$num_cases, big.mark = ","), 
          "patient cases using process mining techniques enhanced with AI insights."),
    "",
    "### Key Metrics",
    paste("- **Total Cases:**", format(process_results$num_cases, big.mark = ",")),
    paste("- **Average Duration:**", round(process_results$avg_duration_hours, 1), "hours"),
    paste("- **Process Variants:**", process_results$num_variants),
    paste("- **Main Pathway Coverage:**", process_results$top_variant_coverage),
    "",
    "---",
    "",
    "## Process Mining Findings",
    "",
    "### Most Frequent Activities",
    if (!is.null(process_results$top_activities)) {
      paste(process_results$top_activities, collapse = "\n")
    } else {
      "Activity analysis not available"
    },
    "",
    "---", 
    "",
    "## AI-Enhanced Clinical Analysis",
    "",
    llm_analysis,
    "",
    "---",
    "",
    "## Recommendations",
    "",
    "1. **Immediate Actions (0-30 days)**",
    "   - Implement monitoring for identified patterns",
    "   - Train staff on critical transition timing", 
    "   - Establish alerts for process deviations",
    "",
    "2. **Short-term Improvements (1-3 months)**",
    "   - Optimize resource allocation based on flow patterns",
    "   - Standardize high-variation processes",
    "   - Implement predictive monitoring",
    "",
    "3. **Long-term Optimization (3-12 months)**", 
    "   - Redesign inefficient pathways",
    "   - Integrate findings into clinical guidelines",
    "   - Establish continuous monitoring",
    "",
    "---",
    "",
    "*Report generated by HealthProcessAI using R, bupaR, and AI analysis*",
    "*Developed at SMAILE, Karolinska Institutet*",
    
    sep = "\n"
  )
  
  # Save report
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- paste0("clinical_report_", timestamp, ".", output_format)
  
  if (output_format == "html") {
    writeLines(report_content, "temp_report.md")
    rmarkdown::render("temp_report.md", 
                      output_format = "html_document",
                      output_file = filename)
    file.remove("temp_report.md")
  } else if (output_format == "md") {
    writeLines(report_content, filename)
  }
  
  cat("✅ Clinical report saved as", filename, "\n")
  return(filename)
}
```

---

## 7. Report Generation with RMarkdown

### 7.1 Dynamic Report Template

```r
# Function to create RMarkdown report template
create_rmarkdown_report <- function(event_log, output_dir = "reports") {
  
  cat("📊 Creating RMarkdown report template...\n")
  
  # Ensure output directory exists
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # RMarkdown template
  rmd_template <- '
---
title: "Healthcare Process Mining Analysis"
subtitle: "Generated with HealthProcessAI"
author: "SMAILE Lab, Karolinska Institutet"
date: "`r Sys.Date()`"
output: 
  html_document:
    toc: true
    toc_float: true
    theme: flatly
    highlight: tango
    code_folding: hide
  pdf_document:
    toc: true
    number_sections: true
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(
  echo = TRUE, 
  message = FALSE, 
  warning = FALSE,
  fig.width = 10,
  fig.height = 6
)

# Load required libraries
library(bupaR)
library(processmapR) 
library(tidyverse)
library(plotly)
library(DT)
library(knitr)
```

# Executive Summary

This report presents a comprehensive analysis of healthcare process data using process mining techniques and the bupaR framework in R.

## Key Findings

```{r summary-stats}
# Calculate key statistics
total_cases <- n_cases(event_log)
total_events <- n_events(event_log) 
total_activities <- n_activities(event_log)
avg_case_length <- mean(event_log %>% trace_length("case") %>% pull(trace_length))

# Display summary table
summary_data <- tibble(
  Metric = c("Total Patients", "Total Events", "Unique Activities", "Avg Case Length"),
  Value = c(total_cases, total_events, total_activities, round(avg_case_length, 1))
)

kable(summary_data, caption = "Process Mining Summary Statistics")
```

# Process Discovery

## Activity Frequency Analysis

```{r activity-frequency, fig.cap="Distribution of clinical activities"}
activity_plot <- event_log %>%
  activity_frequency("activity") %>%
  mutate(
    activity = fct_reorder(activity, absolute),
    percentage = round(relative * 100, 1)
  ) %>%
  ggplot(aes(x = absolute, y = activity, fill = absolute)) +
  geom_col() +
  geom_text(aes(label = paste0(percentage, "%")), hjust = -0.1, size = 3) +
  scale_fill_viridis_c(option = "plasma") +
  labs(
    title = "Clinical Activity Frequencies",
    x = "Number of Events", 
    y = "Clinical Activity",
    fill = "Count"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggplotly(activity_plot)
```

## Process Map Visualization

```{r process-map, fig.cap="Healthcare process flow"}
# Generate process map
process_map <- event_log %>%
  filter_activity_frequency(percentage = 0.8) %>%
  process_map(type = frequency("absolute"))

process_map
```

# Performance Analysis

## Case Duration Distribution

```{r throughput-analysis, fig.cap="Patient case duration distribution"}
throughput_data <- event_log %>%
  throughput_time("log", units = "hours")

duration_plot <- throughput_data %>%
  ggplot(aes(x = throughput_time)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  geom_vline(aes(xintercept = median(throughput_time)), 
             color = "red", linetype = "dashed", size = 1) +
  labs(
    title = "Patient Case Duration Distribution",
    x = "Duration (hours)",
    y = "Number of Cases",
    subtitle = paste("Median duration:", round(median(throughput_data$throughput_time), 1), "hours")
  ) +
  theme_minimal()

ggplotly(duration_plot)
```

## Resource Utilization

```{r resource-analysis, fig.cap="Resource workload analysis"}
resource_plot <- event_log %>%
  resource_frequency("resource") %>%
  top_n(10, absolute) %>%
  mutate(resource = fct_reorder(resource, absolute)) %>%
  ggplot(aes(x = absolute, y = resource, fill = relative)) +
  geom_col() +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(
    title = "Resource Workload Distribution",
    x = "Number of Activities",
    y = "Resource", 
    fill = "Proportion"
  ) +
  theme_minimal()

ggplotly(resource_plot)
```

# Trace Analysis

## Most Common Patient Pathways

```{r trace-analysis}
# Get top traces
top_traces <- event_log %>%
  trace_coverage("trace") %>%
  arrange(desc(absolute)) %>%
  head(10) %>%
  mutate(
    percentage = round(relative * 100, 1),
    trace_short = str_trunc(trace, 80)
  ) %>%
  select(trace_short, absolute, percentage)

kable(top_traces, 
      col.names = c("Patient Pathway", "Cases", "Percentage"),
      caption = "Top 10 Most Common Patient Pathways")
```

# Bottleneck Analysis

```{r bottleneck-analysis}
# Identify processing time bottlenecks
processing_times <- event_log %>%
  processing_time("activity", units = "hours") %>%
  filter(processing_time > 0) %>%
  arrange(desc(processing_time)) %>%
  head(10)

kable(processing_times,
      col.names = c("Activity", "Processing Time (hours)"),
      caption = "Activities with Longest Processing Times",
      digits = 2)
```

# Conclusions and Recommendations

Based on the process mining analysis, key recommendations include:

1. **Process Standardization**: Focus on the most variable pathways
2. **Resource Optimization**: Address bottlenecks in high-frequency activities  
3. **Performance Monitoring**: Implement continuous monitoring of key metrics
4. **Staff Training**: Provide targeted training for critical process steps

---

*Report generated using HealthProcessAI with R and bupaR*  
*Developed at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet*
'
  
  # Write template to file
  template_file <- file.path(output_dir, "healthcare_analysis_template.Rmd")
  writeLines(rmd_template, template_file)
  
  cat("✅ RMarkdown template created:", template_file, "\n")
  cat("💡 To generate report, run: rmarkdown::render('", template_file, "')\n")
  
  return(template_file)
}
```

---

## 8. Shiny Dashboards

### 8.1 Interactive Process Mining Dashboard

```r
# Function to create Shiny dashboard for process mining
create_shiny_dashboard <- function() {
  
  cat("🌐 Creating Shiny dashboard for interactive process mining...\n")
  
  # UI definition
  ui <- dashboardPage(
    dashboardHeader(title = "HealthProcessAI Dashboard"),
    
    dashboardSidebar(
      sidebarMenu(
        menuItem("Overview", tabName = "overview", icon = icon("chart-line")),
        menuItem("Process Discovery", tabName = "process", icon = icon("project-diagram")), 
        menuItem("Performance", tabName = "performance", icon = icon("clock")),
        menuItem("Resources", tabName = "resources", icon = icon("users")),
        menuItem("Analysis", tabName = "analysis", icon = icon("search"))
      )
    ),
    
    dashboardBody(
      tabItems(
        # Overview tab
        tabItem(tabName = "overview",
          fluidRow(
            valueBoxOutput("total_cases"),
            valueBoxOutput("total_events"), 
            valueBoxOutput("avg_duration")
          ),
          fluidRow(
            box(
              title = "Activity Frequency", status = "primary", solidHeader = TRUE,
              width = 12,
              plotlyOutput("activity_plot")
            )
          )
        ),
        
        # Process discovery tab
        tabItem(tabName = "process",
          fluidRow(
            box(
              title = "Process Map Controls", status = "primary", solidHeader = TRUE,
              width = 3,
              sliderInput("freq_threshold", "Activity Frequency Threshold:", 
                         min = 0.1, max = 1.0, value = 0.8, step = 0.1),
              radioButtons("map_type", "Map Type:",
                          choices = list("Frequency" = "freq", "Performance" = "perf"),
                          selected = "freq")
            ),
            box(
              title = "Process Visualization", status = "primary", solidHeader = TRUE,
              width = 9,
              plotOutput("process_map", height = "600px")
            )
          )
        ),
        
        # Performance tab
        tabItem(tabName = "performance",
          fluidRow(
            box(
              title = "Case Duration Distribution", status = "primary", solidHeader = TRUE,
              width = 6,
              plotlyOutput("duration_plot")
            ),
            box(
              title = "Bottleneck Analysis", status = "warning", solidHeader = TRUE,
              width = 6, 
              DT::dataTableOutput("bottleneck_table")
            )
          )
        ),
        
        # Resources tab
        tabItem(tabName = "resources",
          fluidRow(
            box(
              title = "Resource Workload", status = "primary", solidHeader = TRUE,
              width = 12,
              plotlyOutput("resource_plot")
            )
          )
        ),
        
        # Analysis tab
        tabItem(tabName = "analysis",
          fluidRow(
            box(
              title = "Trace Coverage Analysis", status = "primary", solidHeader = TRUE,
              width = 12,
              DT::dataTableOutput("trace_table")
            )
          )
        )
      )
    )
  )
  
  return(ui)
}

# Server function for Shiny dashboard  
create_shiny_server <- function(event_log) {
  
  server <- function(input, output) {
    
    # Value boxes for overview
    output$total_cases <- renderValueBox({
      valueBox(
        value = n_cases(event_log),
        subtitle = "Total Patients",
        icon = icon("user-injured"),
        color = "blue"
      )
    })
    
    output$total_events <- renderValueBox({
      valueBox(
        value = n_events(event_log),
        subtitle = "Total Events", 
        icon = icon("list"),
        color = "green"
      )
    })
    
    output$avg_duration <- renderValueBox({
      avg_dur <- round(mean(event_log %>% throughput_time("log", "hours") %>% pull(throughput_time)), 1)
      valueBox(
        value = paste(avg_dur, "hrs"),
        subtitle = "Avg Duration",
        icon = icon("clock"),
        color = "yellow"
      )
    })
    
    # Activity frequency plot
    output$activity_plot <- renderPlotly({
      p <- event_log %>%
        activity_frequency("activity") %>%
        mutate(
          activity = fct_reorder(activity, absolute),
          percentage = round(relative * 100, 1)
        ) %>%
        ggplot(aes(x = absolute, y = activity, fill = absolute)) +
        geom_col() +
        scale_fill_viridis_c() +
        labs(x = "Events", y = "Activity", fill = "Count") +
        theme_minimal()
      
      ggplotly(p)
    })
    
    # Process map (reactive to controls)
    output$process_map <- renderPlot({
      if (input$map_type == "freq") {
        event_log %>%
          filter_activity_frequency(percentage = input$freq_threshold) %>%
          process_map(type = frequency("absolute"))
      } else {
        event_log %>%
          filter_activity_frequency(percentage = input$freq_threshold) %>%  
          process_map(type = performance(median, "hours"))
      }
    })
    
    # Duration distribution
    output$duration_plot <- renderPlotly({
      p <- event_log %>%
        throughput_time("log", "hours") %>%
        ggplot(aes(x = throughput_time)) +
        geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
        labs(x = "Duration (hours)", y = "Cases") +
        theme_minimal()
      
      ggplotly(p)
    })
    
    # Bottleneck analysis table
    output$bottleneck_table <- DT::renderDataTable({
      event_log %>%
        processing_time("activity", "hours") %>%
        arrange(desc(processing_time)) %>%
        head(10) %>%
        mutate(processing_time = round(processing_time, 2))
    }, options = list(pageLength = 10))
    
    # Resource workload plot
    output$resource_plot <- renderPlotly({
      p <- event_log %>%
        resource_frequency("resource") %>%
        top_n(15, absolute) %>%
        mutate(resource = fct_reorder(resource, absolute)) %>%
        ggplot(aes(x = absolute, y = resource)) +
        geom_col(fill = "darkblue", alpha = 0.7) +
        labs(x = "Activities", y = "Resource") +
        theme_minimal()
      
      ggplotly(p)
    })
    
    # Trace analysis table
    output$trace_table <- DT::renderDataTable({
      event_log %>%
        trace_coverage("trace") %>%
        arrange(desc(absolute)) %>%
        head(20) %>%
        mutate(
          percentage = round(relative * 100, 1),
          trace_short = str_trunc(trace, 60)
        ) %>%
        select(trace_short, absolute, percentage)
    }, options = list(pageLength = 15))
  }
  
  return(server)
}

# Function to launch the dashboard
launch_dashboard <- function(event_log, port = 3838) {
  ui <- create_shiny_dashboard()
  server <- create_shiny_server(event_log)
  
  cat("🚀 Launching Shiny dashboard on port", port, "...\n")
  cat("📊 Dashboard will open in your browser\n") 
  
  shinyApp(ui = ui, server = server, options = list(port = port))
}
```

---

## 9. Statistical Analysis

### 9.1 Comparative Analysis

```r
# Function for statistical comparison of patient groups
compare_patient_groups <- function(event_log, group_column = "SepsisLabel") {
  
  cat("📊 Performing statistical comparison of patient groups...\n")
  
  if (!group_column %in% names(event_log)) {
    cat("⚠️ Group column", group_column, "not found in event log\n")
    return(NULL)
  }
  
  # Separate groups
  group_0_cases <- event_log %>% filter(.data[[group_column]] == 0) %>% cases()
  group_1_cases <- event_log %>% filter(.data[[group_column]] == 1) %>% cases()
  
  # Case-level metrics for comparison
  case_metrics <- tibble(
    case_id = c(group_0_cases, group_1_cases),
    group = c(rep("Group_0", length(group_0_cases)), rep("Group_1", length(group_1_cases)))
  )
  
  # Calculate metrics for each case
  case_stats <- map_dfr(case_metrics$case_id, function(case) {
    case_log <- event_log %>% filter_case(cases == case)
    
    tibble(
      case_id = case,
      trace_length = case_log %>% trace_length("case") %>% pull(trace_length),
      throughput_time = case_log %>% throughput_time("log", "hours") %>% pull(throughput_time),
      unique_activities = case_log %>% n_activities(),
      unique_resources = case_log %>% n_resources()
    )
  }) %>%
    left_join(case_metrics, by = "case_id")
  
  # Statistical tests
  results <- list()
  
  # T-tests for continuous variables
  continuous_vars <- c("trace_length", "throughput_time", "unique_activities", "unique_resources")
  
  for (var in continuous_vars) {
    group_0_values <- case_stats %>% filter(group == "Group_0") %>% pull(.data[[var]])
    group_1_values <- case_stats %>% filter(group == "Group_1") %>% pull(.data[[var]])
    
    # Perform t-test
    t_test_result <- t.test(group_1_values, group_0_values)
    
    # Calculate effect size (Cohen's d)
    pooled_sd <- sqrt(((length(group_0_values) - 1) * var(group_0_values) + 
                      (length(group_1_values) - 1) * var(group_1_values)) /
                     (length(group_0_values) + length(group_1_values) - 2))
    cohens_d <- (mean(group_1_values) - mean(group_0_values)) / pooled_sd
    
    results[[var]] <- list(
      variable = var,
      group_0_mean = mean(group_0_values),
      group_1_mean = mean(group_1_values),
      t_statistic = t_test_result$statistic,
      p_value = t_test_result$p.value,
      cohens_d = cohens_d,
      significant = t_test_result$p.value < 0.05,
      interpretation = case_when(
        abs(cohens_d) < 0.2 ~ "negligible effect",
        abs(cohens_d) < 0.5 ~ "small effect", 
        abs(cohens_d) < 0.8 ~ "medium effect",
        TRUE ~ "large effect"
      )
    )
  }
  
  # Create summary table
  comparison_table <- map_dfr(results, function(x) {
    tibble(
      Variable = str_to_title(str_replace_all(x$variable, "_", " ")),
      `Group 0 Mean` = round(x$group_0_mean, 2),
      `Group 1 Mean` = round(x$group_1_mean, 2),
      `Difference` = round(x$group_1_mean - x$group_0_mean, 2),
      `p-value` = ifelse(x$p_value < 0.001, "<0.001", round(x$p_value, 3)),
      `Effect Size` = paste0(round(x$cohens_d, 2), " (", x$interpretation, ")"),
      Significant = ifelse(x$significant, "Yes*", "No")
    )
  })
  
  cat("✅ Statistical comparison complete\n")
  print(comparison_table)
  
  return(list(
    results = results,
    comparison_table = comparison_table,
    case_stats = case_stats
  ))
}
```

### 9.2 Survival Analysis for Process Mining

```r
# Function for survival analysis in process mining context
perform_survival_analysis <- function(event_log, outcome_event = "Discharge") {
  
  cat("📊 Performing survival analysis (time-to-event)...\n")
  
  # Install survival package if needed
  if (!require(survival, quietly = TRUE)) {
    install.packages("survival")
    library(survival)
  }
  
  # Calculate time to outcome event for each case
  survival_data <- event_log %>%
    group_by(case_id) %>%
    arrange(timestamp) %>%
    mutate(
      case_start = min(timestamp),
      time_hours = as.numeric(difftime(timestamp, case_start, units = "hours"))
    ) %>%
    filter(activity == outcome_event) %>%
    summarise(
      time_to_event = min(time_hours),
      event_occurred = 1,
      .groups = "drop"
    )
  
  # Add cases where event never occurred (censored)
  all_cases <- tibble(case_id = unique(event_log$case_id))
  
  survival_complete <- all_cases %>%
    left_join(survival_data, by = "case_id") %>%
    mutate(
      time_to_event = ifelse(is.na(time_to_event), 
                            # Use maximum observed time for censored cases
                            max(survival_data$time_to_event, na.rm = TRUE),
                            time_to_event),
      event_occurred = ifelse(is.na(event_occurred), 0, event_occurred)
    )
  
  # Fit survival model
  surv_object <- Surv(survival_complete$time_to_event, survival_complete$event_occurred)
  km_fit <- survfit(surv_object ~ 1)
  
  # Summary statistics
  surv_summary <- summary(km_fit)
  median_survival <- surv_median(km_fit)$median
  
  cat("✅ Survival analysis complete\n")
  cat("📊 Median time to", outcome_event, ":", round(median_survival, 1), "hours\n")
  
  # Create survival plot
  surv_plot <- ggsurvplot(
    km_fit,
    data = survival_complete,
    title = paste("Time to", outcome_event),
    xlab = "Time (hours)",
    ylab = "Probability of event not occurring",
    conf.int = TRUE,
    risk.table = TRUE
  )
  
  return(list(
    survival_data = survival_complete,
    km_fit = km_fit,
    median_survival = median_survival,
    plot = surv_plot
  ))
}
```

---

## 10. Best Practices for R

### 10.1 Code Organization and Style

```r
# Best practices for R process mining projects

# 1. Project structure
create_project_structure <- function(project_name) {
  
  dirs <- c(
    file.path(project_name, "R"),           # R scripts
    file.path(project_name, "data"),        # Data files  
    file.path(project_name, "reports"),     # Generated reports
    file.path(project_name, "plots"),       # Visualizations
    file.path(project_name, "rmd"),         # RMarkdown files
    file.path(project_name, "shiny"),       # Shiny apps
    file.path(project_name, "tests")        # Test files
  )
  
  walk(dirs, dir.create, recursive = TRUE)
  cat("📁 Created project structure for", project_name, "\n")
}

# 2. Consistent coding style
style_guidelines <- function() {
  cat("
  📝 R Style Guidelines for HealthProcessAI:
  
  ✅ Naming Conventions:
  - Functions: snake_case (e.g., analyze_process_variants)
  - Variables: snake_case (e.g., event_log, patient_data)
  - Constants: SCREAMING_SNAKE_CASE (e.g., DEFAULT_THRESHOLD)
  
  ✅ Function Design:
  - Use verbs for function names (analyze_, create_, calculate_)
  - Include input validation with meaningful error messages
  - Document parameters and return values
  - Use early returns for error conditions
  
  ✅ Data Pipeline:
  - Use pipes (%>%) for sequential operations
  - Keep pipe chains readable (max 5-6 operations)
  - Use intermediate variables for complex transformations
  
  ✅ Error Handling:
  - Use tryCatch() for operations that might fail
  - Provide informative error messages
  - Log progress with cat() statements
  
  Example:
  ")
  
  # Example of well-structured function
  example_function <- function() {
    '
    analyze_sepsis_progression <- function(event_log, threshold = 0.8) {
      # Validate inputs
      if (!is.eventlog(event_log)) {
        stop("Input must be a valid bupaR eventlog object")
      }
      
      if (threshold < 0 || threshold > 1) {
        stop("Threshold must be between 0 and 1")
      }
      
      # Main analysis
      tryCatch({
        cat("🔍 Analyzing sepsis progression patterns...\n")
        
        result <- event_log %>%
          filter_activity_frequency(percentage = threshold) %>%
          process_map(type = frequency("absolute"))
        
        cat("✅ Analysis complete\n")
        return(result)
        
      }, error = function(e) {
        cat("❌ Error in analysis:", e$message, "\n")
        return(NULL)
      })
    }
    '
  }
  
  cat(example_function())
}
```

### 10.2 Performance Optimization

```r
# Performance optimization strategies for R process mining

optimize_r_performance <- function() {
  cat("
  ⚡ Performance Optimization for R Process Mining:
  
  1. Data Loading:
     - Use readr::read_csv() instead of base read.csv()
     - Specify column types to avoid automatic detection
     - Use data.table::fread() for very large files
  
  2. Memory Management:
     - Remove unused objects with rm()
     - Use gc() to force garbage collection
     - Monitor memory usage with pryr::mem_used()
  
  3. Efficient Data Manipulation:
     - Use dplyr for data manipulation (faster than base R)
     - Avoid loops when vectorized operations are available
     - Use data.table for very large datasets
  
  4. bupaR Specific:
     - Filter early and often to reduce data size
     - Use activity/case frequency filters before complex operations
     - Cache intermediate results for repeated analysis
  
  5. Visualization:
     - Use ggplot2 with reasonable data sizes
     - Consider sampling for exploratory plots
     - Use plotly sparingly for large datasets
  ")
  
  # Example optimization functions
  optimized_examples <- list(
    
    # Efficient data loading
    load_large_file = function(file_path) {
      readr::read_csv(
        file_path,
        col_types = cols(
          case_id = col_character(),
          activity = col_character(),
          timestamp = col_datetime(),
          resource = col_character()
        ),
        lazy = FALSE  # Load immediately
      )
    },
    
    # Memory-efficient analysis  
    analyze_large_log = function(event_log) {
      # Filter early to reduce memory footprint
      filtered_log <- event_log %>%
        filter_activity_frequency(percentage = 0.9) %>%
        filter_case_condition(n_events >= 3)
      
      # Perform analysis on filtered data
      result <- filtered_log %>%
        process_map(type = frequency("absolute"))
      
      # Clean up
      rm(filtered_log)
      gc()
      
      return(result)
    },
    
    # Parallel processing example
    parallel_case_analysis = function(event_log) {
      library(parallel)
      
      cases <- unique(event_log$case_id)
      num_cores <- detectCores() - 1
      
      # Function to analyze single case
      analyze_case <- function(case_id) {
        case_log <- event_log %>% filter_case(cases == case_id)
        return(trace_length(case_log, "case"))
      }
      
      # Parallel execution
      results <- mclapply(cases, analyze_case, mc.cores = num_cores)
      
      return(do.call(rbind, results))
    }
  )
  
  return(optimized_examples)
}
```

### 10.3 Testing and Validation

```r
# Testing framework for R process mining functions
create_test_framework <- function() {
  
  # Install testing packages if needed
  required_packages <- c("testthat", "mockery")
  missing_packages <- required_packages[!required_packages %in% installed.packages()]
  
  if (length(missing_packages) > 0) {
    install.packages(missing_packages)
  }
  
  library(testthat)
  
  # Example test structure
  test_examples <- '
  # tests/test_healthcare_functions.R
  
  library(testthat)
  library(bupaR)
  library(dplyr)
  
  # Test data creation
  create_test_eventlog <- function() {
    test_data <- tibble(
      case_id = rep(paste0("P", 1:3), each = 3),
      activity = rep(c("Admission", "Treatment", "Discharge"), 3),
      timestamp = seq.POSIXt(as.POSIXct("2024-01-01"), by = "hour", length.out = 9),
      resource = rep(c("Nurse", "Doctor", "Admin"), 3)
    )
    
    eventlog(test_data,
             case_id = "case_id",
             activity_id = "activity", 
             timestamp = "timestamp",
             resource_id = "resource")
  }
  
  # Tests for data loading
  test_that("Event log creation works correctly", {
    test_log <- create_test_eventlog()
    
    expect_s3_class(test_log, "eventlog")
    expect_equal(n_cases(test_log), 3)
    expect_equal(n_activities(test_log), 3)
    expect_equal(n_events(test_log), 9)
  })
  
  # Tests for process discovery
  test_that("Process discovery produces valid results", {
    test_log <- create_test_eventlog()
    
    # Test activity frequency
    freq_result <- activity_frequency(test_log, "activity")
    expect_s3_class(freq_result, "data.frame")
    expect_equal(nrow(freq_result), 3)
    expect_true(all(freq_result$relative <= 1))
    
    # Test trace coverage
    trace_result <- trace_coverage(test_log, "trace")
    expect_s3_class(trace_result, "data.frame")
    expect_true(sum(trace_result$relative) <= 1.01)  # Allow for rounding
  })
  
  # Tests for performance analysis
  test_that("Performance metrics calculation works", {
    test_log <- create_test_eventlog()
    
    throughput_result <- throughput_time(test_log, "log", "hours")
    expect_s3_class(throughput_result, "data.frame") 
    expect_equal(nrow(throughput_result), 3)
    expect_true(all(throughput_result$throughput_time >= 0))
  })
  
  # Tests for error handling
  test_that("Functions handle invalid inputs gracefully", {
    expect_error(
      activity_frequency(NULL, "activity"),
      "eventlog"
    )
    
    expect_error(
      throughput_time(create_test_eventlog(), "invalid_level"),
      "level"
    )
  })
  '
  
  cat("🧪 Test framework structure:\n")
  cat(test_examples)
  
  # Function to run all tests
  run_project_tests <- function(test_dir = "tests") {
    if (dir.exists(test_dir)) {
      test_results <- test_dir(test_dir)
      print(test_results)
    } else {
      cat("❌ Test directory not found:", test_dir, "\n")
    }
  }
  
  return(list(
    test_examples = test_examples,
    run_tests = run_project_tests
  ))
}
```

---

## 🎓 Summary and Next Steps

### What You've Learned

1. **R Environment Setup**
   - bupaR ecosystem installation and configuration
   - Tidyverse integration for data manipulation
   - Package management best practices

2. **Healthcare Data Processing**
   - Loading and cleaning clinical event logs
   - Converting to bupaR eventlog format  
   - Handling healthcare-specific data challenges

3. **Process Discovery with bupaR**
   - Activity frequency analysis
   - Process map generation
   - Trace and variant analysis
   - Performance metrics calculation

4. **Interactive Visualizations**
   - ggplot2 and plotly integration
   - Dynamic process exploration
   - Animated analysis over time

5. **LLM Integration** 
   - OpenRouter API integration with httr
   - Clinical prompt engineering
   - Automated report generation

6. **Professional Reporting**
   - RMarkdown dynamic reports
   - Interactive Shiny dashboards
   - Statistical analysis integration

7. **Advanced Analytics**
   - Statistical comparisons between groups
   - Survival analysis for healthcare
   - Bottleneck identification

8. **Best Practices**
   - Code organization and style
   - Performance optimization
   - Testing and validation frameworks

### R vs Python Comparison

| Aspect | R Advantages | Python Advantages |
|--------|-------------|-------------------|
| **Learning Curve** | Intuitive pipe syntax | More familiar to programmers |
| **Statistical Analysis** | Built-in statistical tests | Need additional libraries |
| **Visualization** | ggplot2 + interactive plots | More customization options |
| **Reporting** | RMarkdown integration | Multiple format support |
| **Performance** | Good for medium data | Better for large datasets |
| **Deployment** | Shiny apps | More deployment options |

### Next Steps

1. **Practice with Real Data**
   - Load your institution's healthcare data
   - Apply the techniques learned in this tutorial
   - Validate findings with clinical experts

2. **Advanced Techniques** 
   - Conformance checking with pmr
   - Social network analysis with SNA
   - Predictive process monitoring

3. **Integration Projects**
   - Connect with hospital information systems
   - Build production Shiny dashboards
   - Implement continuous monitoring

4. **Collaboration**
   - Work with clinical teams
   - Publish findings in healthcare journals
   - Contribute to open-source process mining

### Additional Resources

- **bupaR Documentation**: [bupar.net](https://bupar.net)
- **Process Mining with R**: Online course materials
- **Healthcare Process Mining Papers**: Academic research repository
- **R Community**: Stack Overflow, R-bloggers, GitHub

### Final Project Ideas

1. **Emergency Department Dashboard**
   - Real-time patient flow monitoring
   - Bottleneck alerts and recommendations
   - Resource optimization suggestions

2. **Clinical Pathway Compliance**
   - Compare actual vs. guideline-recommended care
   - Identify deviations and their outcomes
   - Generate compliance reports

3. **Multi-site Hospital Comparison**
   - Compare processes across hospital sites
   - Identify best practices and inefficiencies  
   - Standardization recommendations

4. **Chronic Disease Management**
   - Long-term patient journey analysis
   - Intervention effectiveness evaluation
   - Predictive risk modeling

---

## 🏥 Congratulations!

You've completed the comprehensive R tutorial for HealthProcessAI. You now have the skills to:

- ✅ Set up robust R environments for process mining
- ✅ Process and analyze healthcare event data
- ✅ Create interactive visualizations and dashboards
- ✅ Integrate AI for clinical insights
- ✅ Generate professional reports and presentations
- ✅ Apply statistical methods to validate findings
- ✅ Follow best practices for R development

**Remember**: Always validate your findings with clinical domain experts and consider the full context of patient care when making recommendations.

### Choose Your Next Learning Path:

- 📚 [Complete Tutorial](complete_tutorial.md) - Deep dive into advanced topics
- 🐍 [Python Tutorial](python_tutorial.md) - Learn the Python implementation  
- 👩‍⚕️ [Clinician Tutorial](clinician_pm_tutorial.md) - Clinical interpretation focus
- ⚡ [Quick Start](quickstart.md) - Rapid prototyping guide

**Happy Process Mining with R! 📊🏥**

---

*This tutorial is part of HealthProcessAI - Developed at SMAILE (Stockholm Medical AI Lab for Enhancement), Karolinska Institutet*

**Contributors:**
- **Farhad Abtahi** - Framework Architecture & Educational Design
- **Eduardo Illueca Fernandez** - R Implementation & bupaR Expertise  
- **Kaile Chen** - Clinical Applications & Healthcare Integration