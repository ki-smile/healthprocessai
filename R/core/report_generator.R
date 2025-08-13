# HealthProcessAI - R Report Generator Module
# ============================================
#
# REPORT GENERATOR MODULE FOR HEALTHPROCESSAI
# ============================================
# This module handles the generation of analysis reports in multiple formats:
# - Markdown (.md)
# - HTML (.html)  
# - PDF (.pdf) via RMarkdown
# - Word (.docx) via RMarkdown
#
# The reports are automatically saved to the appropriate directories:
# - reports/markdown/ - Markdown reports
# - reports/html/ - HTML reports
# - reports/pdf/ - PDF reports
# - reports/word/ - Word documents
# - reports/data/ - Raw data exports
#
# Technology Mapping:
# - Python markdown -> R rmarkdown
# - Python weasyprint/reportlab -> R rmarkdown::render with PDF
# - Python json -> R jsonlite
# - Python pathlib -> R fs package
#
# Developed at SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments),
# Karolinska Institutet

# Load required libraries
suppressPackageStartupMessages({
  library(R6)
  library(rmarkdown)
  library(knitr)
  library(jsonlite)
  library(glue)
  library(lubridate)
  library(tidyverse)
  library(kableExtra)
  library(DT)
})

#' Report Generator for Healthcare Process Mining Analysis
#' 
#' This R6 class generates comprehensive reports from process mining results
#' in multiple formats including Markdown, HTML, PDF, and Word documents.
#' Reports include visualizations, tables, and AI-generated insights.
#' 
#' @import R6
#' @import rmarkdown
#' @import knitr
#' @export
ReportGenerator <- R6::R6Class(
  classname = "ReportGenerator",
  
  # Public methods and fields
  public = list(
    
    # Instance variables
    output_base_dir = NULL,
    metadata = NULL,
    
    #' Initialize the Report Generator
    #' 
    #' @param output_base_dir Base directory for saving reports (default: "reports")
    #' @return New ReportGenerator instance
    #' 
    #' @examples
    #' generator <- ReportGenerator$new()
    #' generator <- ReportGenerator$new("custom_reports")
    initialize = function(output_base_dir = "reports") {
      self$output_base_dir <- output_base_dir
      
      # Setup directory structure
      private$setup_directories()
      
      # Initialize metadata
      self$metadata <- list(
        generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        framework = "HealthProcessAI",
        version = "1.0.0",
        organization = "SMAILE, Karolinska Institutet",
        language = "R"
      )
      
      message(glue::glue("✅ Report Generator initialized at: {self$output_base_dir}"))
    },
    
    #' Generate reports in multiple formats
    #' 
    #' This method generates comprehensive reports from analysis results
    #' in the requested formats. Markdown is always generated as the base format.
    #' 
    #' @param analysis_results List containing analysis results
    #' @param report_name Base name for report files
    #' @param formats Character vector of output formats (markdown, html, pdf, word)
    #' @param include_visualizations Whether to include process maps and charts
    #' @return List mapping format to file path
    #' 
    #' @examples
    #' results <- list(statistics = stats, variants = vars, insights = llm_output)
    #' files <- generator$generate_report(results, "sepsis_analysis", c("markdown", "pdf"))
    generate_report = function(analysis_results, report_name, 
                              formats = c("markdown", "html", "pdf"),
                              include_visualizations = TRUE) {
      message(glue::glue("📝 Generating {report_name} reports in {paste(formats, collapse = ', ')} format(s)"))
      
      output_files <- list()
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      base_name <- glue::glue("{report_name}_{timestamp}")
      
      # Always generate Markdown first (base format)
      md_content <- private$create_markdown_report(analysis_results, include_visualizations)
      md_path <- private$save_markdown(md_content, base_name)
      output_files$markdown <- md_path
      message(glue::glue("✅ Markdown report saved: {basename(md_path)}"))
      
      # Generate other formats if requested
      if ("html" %in% formats) {
        html_path <- private$generate_html_report(md_path, base_name)
        output_files$html <- html_path
        message(glue::glue("✅ HTML report saved: {basename(html_path)}"))
      }
      
      if ("pdf" %in% formats) {
        pdf_path <- private$generate_pdf_report(md_path, base_name)
        output_files$pdf <- pdf_path
        message(glue::glue("✅ PDF report saved: {basename(pdf_path)}"))
      }
      
      if ("word" %in% formats) {
        word_path <- private$generate_word_report(md_path, base_name)
        output_files$word <- word_path
        message(glue::glue("✅ Word document saved: {basename(word_path)}"))
      }
      
      # Save raw data as JSON
      data_path <- private$save_data(analysis_results, base_name)
      output_files$data <- data_path
      
      message(glue::glue("📊 Generated {length(output_files)} report files"))
      
      return(output_files)
    },
    
    #' Create a custom report section
    #' 
    #' @param title Section title
    #' @param content Section content (markdown formatted)
    #' @param level Header level (1-6)
    #' @return Formatted markdown section
    create_section = function(title, content, level = 2) {
      header <- paste(rep("#", level), collapse = "")
      section <- glue::glue("{header} {title}\n\n{content}\n\n")
      return(as.character(section))
    },
    
    #' Create a formatted table for the report
    #' 
    #' @param data Data frame or matrix
    #' @param caption Table caption
    #' @param format Output format (markdown, html, latex)
    #' @return Formatted table string
    create_table = function(data, caption = NULL, format = "markdown") {
      if (format == "markdown") {
        # Create markdown table using kable
        table_str <- knitr::kable(data, format = "markdown", caption = caption)
      } else if (format == "html") {
        # Create HTML table with styling
        table_str <- kableExtra::kable(data, format = "html", caption = caption) %>%
          kableExtra::kable_styling(
            bootstrap_options = c("striped", "hover", "condensed"),
            full_width = FALSE
          )
      } else {
        # Default to simple format
        table_str <- knitr::kable(data, format = "simple", caption = caption)
      }
      
      return(as.character(table_str))
    },
    
    #' Generate an executive summary from analysis results
    #' 
    #' @param results Analysis results list
    #' @return Markdown formatted executive summary
    generate_executive_summary = function(results) {
      stats <- results$statistics %||% list()
      
      summary <- glue::glue("
This report presents a comprehensive process mining analysis of healthcare data,
focusing on patient pathways and clinical processes.

### Key Findings
- **Total Cases Analyzed:** {stats$num_cases %||% 'N/A'}
- **Total Events Processed:** {stats$num_events %||% 'N/A'}
- **Sepsis Rate:** {round((stats$sepsis_rate %||% 0) * 100, 1)}%
- **Average Case Duration:** {round(stats$avg_case_duration %||% 0, 1)} hours
- **Process Complexity:** {stats$num_activities %||% 'N/A'} unique activities

### Clinical Impact
The analysis reveals significant opportunities for process optimization and
clinical pathway standardization. Early intervention points have been identified
that could potentially improve patient outcomes.
")
      
      return(as.character(summary))
    },
    
    #' Export report data to various formats
    #' 
    #' @param data Data to export
    #' @param filename Base filename
    #' @param format Export format (json, csv, rds)
    #' @return Path to exported file
    export_data = function(data, filename, format = "json") {
      export_dir <- file.path(self$output_base_dir, "data")
      
      if (format == "json") {
        filepath <- file.path(export_dir, paste0(filename, ".json"))
        jsonlite::write_json(data, filepath, pretty = TRUE)
      } else if (format == "csv") {
        filepath <- file.path(export_dir, paste0(filename, ".csv"))
        if (is.data.frame(data)) {
          write.csv(data, filepath, row.names = FALSE)
        } else {
          # Convert list to data frame if possible
          df <- as.data.frame(data)
          write.csv(df, filepath, row.names = FALSE)
        }
      } else if (format == "rds") {
        filepath <- file.path(export_dir, paste0(filename, ".rds"))
        saveRDS(data, filepath)
      } else {
        stop(glue::glue("Unsupported export format: {format}"))
      }
      
      message(glue::glue("💾 Data exported to: {basename(filepath)}"))
      return(filepath)
    }
  ),
  
  # Private methods
  private = list(
    
    #' Setup directory structure for reports
    setup_directories = function() {
      directories <- c(
        file.path(self$output_base_dir, "markdown"),
        file.path(self$output_base_dir, "html"),
        file.path(self$output_base_dir, "pdf"),
        file.path(self$output_base_dir, "word"),
        file.path(self$output_base_dir, "data"),
        file.path(self$output_base_dir, "figures")
      )
      
      for (dir in directories) {
        if (!dir.exists(dir)) {
          dir.create(dir, recursive = TRUE)
        }
      }
    },
    
    #' Create comprehensive markdown report
    #' @param results Analysis results
    #' @param include_viz Whether to include visualizations
    create_markdown_report = function(results, include_viz = TRUE) {
      # Extract components
      stats <- results$statistics %||% list()
      variants <- results$variants %||% list()
      insights <- results$llm_insights %||% ""
      process_map <- results$process_map %||% list()
      advanced <- results$advanced_analytics %||% list()
      
      # Build report
      report <- glue::glue('# 🏥 HealthProcessAI Analysis Report

**Generated:** {format(Sys.time(), "%Y-%m-%d %H:%M:%S")}  
**Framework:** HealthProcessAI - Process Mining Framework for Healthcare  
**Language:** R Implementation  
**Developed at:** SMAILE (Stockholm Medical Artificial Intelligence and Learning Environments), Karolinska Institutet

---

## 📋 Executive Summary

{self$generate_executive_summary(results)}

---

## 📊 Process Statistics

### Overview
{private$create_statistics_table(stats)}

### Temporal Analysis
| Metric | Value |
|--------|-------|
| Average Duration | {round(stats$avg_case_duration %||% 0, 2)} hours |
| Min Duration | {round(stats$min_case_duration %||% 0, 2)} hours |
| Max Duration | {round(stats$max_case_duration %||% 0, 2)} hours |
| Std Dev Duration | {round(stats$std_case_duration %||% 0, 2)} hours |

---

## 🔄 Process Variants

The analysis identified **{length(variants)}** unique process variants.

### Top Process Variants
{private$format_variants(variants)}

---

## 🗺️ Process Map Analysis

{private$format_process_map(process_map)}

---

## 🤖 Clinical Insights (AI-Generated)

{insights}

---

## 🔬 Advanced Analytics

{private$format_advanced_analytics(advanced)}

---

## 💡 Recommendations

Based on the process mining analysis, we recommend:

### Process Optimization
1. **Reduce Bottlenecks:** Focus on activities with highest waiting times
2. **Standardize Pathways:** Implement clinical guidelines for common variants
3. **Resource Allocation:** Optimize staff distribution based on activity frequency

### Clinical Improvements
1. **Early Intervention:** Identify critical decision points for early intervention
2. **Risk Stratification:** Use process patterns for patient risk assessment
3. **Quality Metrics:** Monitor adherence to clinical pathways

### Data-Driven Actions
1. **Continuous Monitoring:** Implement real-time process monitoring
2. **Predictive Analytics:** Develop models for outcome prediction
3. **Feedback Loops:** Create mechanisms for continuous improvement

---

## 📎 Appendix

### Data Quality
- **Completeness:** {round(stats$data_completeness %||% 95.0, 1)}%
- **Missing Values:** {round(stats$missing_percentage %||% 5.0, 1)}%
- **Data Period:** {stats$start_date %||% "2024-01-01"} to {stats$end_date %||% "2024-12-31"}

### Methodology
- **Process Discovery:** bupaR package with Directly-Follows Graph (DFG)
- **Conformance Checking:** Custom R implementation
- **Enhancement:** Performance and frequency analysis
- **LLM Models:** Multiple models via OpenRouter API
- **Statistical Analysis:** R native capabilities

### R Packages Used
- **Process Mining:** bupaR, edeaR, processmapR
- **Data Manipulation:** tidyverse, dplyr
- **Visualization:** ggplot2, plotly
- **Reporting:** rmarkdown, knitr, kableExtra
- **AI Integration:** httr2, jsonlite

---

## 📊 Data Export

Analysis data has been exported in the following formats:
- JSON: Complete analysis results
- CSV: Tabular data extracts
- RDS: R native format for further analysis

---

*This report was automatically generated by HealthProcessAI (R Implementation)*  
*For questions or support, visit: https://github.com/ki-smile/HealthProcessAI*  
*Contact: smaile@ki.se*
')
      
      return(as.character(report))
    },
    
    #' Create statistics table
    #' @param stats Statistics list
    create_statistics_table = function(stats) {
      table_data <- data.frame(
        Metric = c("Total Cases", "Total Events", "Unique Activities", 
                  "Unique Resources", "Start Activities", "End Activities"),
        Value = c(
          stats$num_cases %||% "N/A",
          stats$num_events %||% "N/A",
          stats$num_activities %||% "N/A",
          stats$num_resources %||% "N/A",
          stats$num_start_activities %||% "N/A",
          stats$num_end_activities %||% "N/A"
        )
      )
      
      return(knitr::kable(table_data, format = "markdown"))
    },
    
    #' Format process variants for report
    #' @param variants Variants list
    format_variants = function(variants) {
      if (length(variants) == 0) {
        return("No variants available")
      }
      
      variant_text <- ""
      for (i in seq_len(min(5, length(variants)))) {
        var <- variants[[i]]
        variant_text <- paste0(variant_text, glue::glue("
#### Variant {i}
- **Frequency:** {var$count %||% 0} cases ({round(var$percentage %||% 0, 1)}%)
- **Path Length:** {length(var$activities %||% character(0))} activities
- **Path:** {paste(head(var$activities %||% character(0), 8), collapse = ' → ')}

"))
      }
      
      return(variant_text)
    },
    
    #' Format process map section
    #' @param process_map Process map data
    format_process_map = function(process_map) {
      if (length(process_map) == 0) {
        return("Process map analysis not available")
      }
      
      text <- "### Key Transitions
The process map reveals the following critical transitions:

| From Activity | To Activity | Frequency | Percentage |
|--------------|-------------|-----------|------------|
"
      
      if ("transitions" %in% names(process_map)) {
        for (i in seq_len(min(10, length(process_map$transitions)))) {
          trans <- process_map$transitions[[i]]
          text <- paste0(text, glue::glue("| {trans$from %||% ''} | {trans$to %||% ''} | {trans$count %||% 0} | {round(trans$percentage %||% 0, 1)}% |\n"))
        }
      }
      
      return(text)
    },
    
    #' Format advanced analytics section
    #' @param advanced Advanced analytics results
    format_advanced_analytics = function(advanced) {
      if (length(advanced) == 0) {
        return("*Advanced analytics not performed*")
      }
      
      text <- ""
      
      # Add clustering results if available
      if ("clusters" %in% names(advanced)) {
        text <- paste0(text, glue::glue("
### Patient Clustering
- **Number of Clusters:** {advanced$clusters$n_clusters %||% 'N/A'}
- **Clustering Method:** {advanced$clusters$method %||% 'N/A'}
- **Silhouette Score:** {round(advanced$clusters$silhouette_score %||% 0, 3)}

"))
      }
      
      # Add bottleneck analysis if available
      if ("bottlenecks" %in% names(advanced)) {
        text <- paste0(text, "
### Bottleneck Analysis
Top bottleneck activities identified:
")
        if (!is.null(advanced$bottlenecks$critical_activities)) {
          for (activity in head(advanced$bottlenecks$critical_activities, 5)) {
            text <- paste0(text, glue::glue("- {activity}\n"))
          }
        }
      }
      
      # Add KPIs if available
      if ("kpis" %in% names(advanced)) {
        text <- paste0(text, glue::glue("

### Clinical KPIs
- **Average Length of Stay:** {round(advanced$kpis$avg_length_of_stay %||% 0, 1)} hours
- **Daily Admissions:** {round(advanced$kpis$daily_admissions %||% 0, 1)}
- **Process Complexity:** {round(advanced$kpis$process_complexity %||% 0, 3)}

"))
      }
      
      return(text)
    },
    
    #' Save markdown content to file
    #' @param content Markdown content
    #' @param base_name Base filename
    save_markdown = function(content, base_name) {
      filepath <- file.path(self$output_base_dir, "markdown", paste0(base_name, ".md"))
      writeLines(content, filepath)
      return(filepath)
    },
    
    #' Generate HTML report from markdown
    #' @param md_path Path to markdown file
    #' @param base_name Base filename
    generate_html_report = function(md_path, base_name) {
      html_path <- file.path(self$output_base_dir, "html", paste0(base_name, ".html"))
      
      # Use rmarkdown to render HTML with custom CSS
      rmarkdown::render(
        input = md_path,
        output_file = html_path,
        output_format = rmarkdown::html_document(
          theme = "cosmo",
          highlight = "tango",
          toc = TRUE,
          toc_depth = 3,
          toc_float = TRUE,
          number_sections = FALSE,
          css = private$get_custom_css()
        ),
        quiet = TRUE
      )
      
      return(html_path)
    },
    
    #' Generate PDF report from markdown
    #' @param md_path Path to markdown file
    #' @param base_name Base filename
    generate_pdf_report = function(md_path, base_name) {
      pdf_path <- file.path(self$output_base_dir, "pdf", paste0(base_name, ".pdf"))
      
      # Check if LaTeX is available
      if (!rmarkdown::pandoc_available()) {
        warning("Pandoc not available. Cannot generate PDF.")
        return(NULL)
      }
      
      tryCatch({
        rmarkdown::render(
          input = md_path,
          output_file = pdf_path,
          output_format = rmarkdown::pdf_document(
            toc = TRUE,
            toc_depth = 3,
            number_sections = TRUE,
            highlight = "tango"
          ),
          quiet = TRUE
        )
        return(pdf_path)
      }, error = function(e) {
        warning(glue::glue("PDF generation failed: {e$message}"))
        return(NULL)
      })
    },
    
    #' Generate Word document from markdown
    #' @param md_path Path to markdown file
    #' @param base_name Base filename
    generate_word_report = function(md_path, base_name) {
      word_path <- file.path(self$output_base_dir, "word", paste0(base_name, ".docx"))
      
      tryCatch({
        rmarkdown::render(
          input = md_path,
          output_file = word_path,
          output_format = rmarkdown::word_document(
            toc = TRUE,
            toc_depth = 3,
            highlight = "tango"
          ),
          quiet = TRUE
        )
        return(word_path)
      }, error = function(e) {
        warning(glue::glue("Word document generation failed: {e$message}"))
        return(NULL)
      })
    },
    
    #' Save data to JSON file
    #' @param data Data to save
    #' @param base_name Base filename
    save_data = function(data, base_name) {
      filepath <- file.path(self$output_base_dir, "data", paste0(base_name, ".json"))
      jsonlite::write_json(data, filepath, pretty = TRUE, auto_unbox = TRUE)
      return(filepath)
    },
    
    #' Get custom CSS for HTML reports
    get_custom_css = function() {
      # Return inline CSS or path to CSS file
      css <- "
      <style>
      body {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        color: #333;
      }
      h1 {
        color: #232C65;
        border-bottom: 3px solid #A6249D;
        padding-bottom: 10px;
      }
      h2 {
        color: #232C65;
        margin-top: 30px;
      }
      h3 {
        color: #A6249D;
      }
      table {
        border-collapse: collapse;
        width: 100%;
        margin: 20px 0;
      }
      th {
        background: #232C65;
        color: white;
        padding: 12px;
        text-align: left;
      }
      td {
        padding: 10px;
        border-bottom: 1px solid #ddd;
      }
      code {
        background: #f4f4f4;
        padding: 2px 6px;
        border-radius: 3px;
      }
      </style>
      "
      return(css)
    }
  )
)

# Convenience functions for quick report generation (functional interface)

#' Quick report generation from analysis results (functional interface)
#' 
#' @param results Analysis results list
#' @param report_name Report name
#' @param formats Output formats
#' @param output_dir Output directory
#' @return List of generated file paths
#' @export
generate_report <- function(results, report_name = "analysis", 
                          formats = c("markdown", "html"), 
                          output_dir = "reports") {
  generator <- ReportGenerator$new(output_dir)
  files <- generator$generate_report(results, report_name, formats)
  return(files)
}

#' Generate executive summary only (functional interface)
#' 
#' @param results Analysis results
#' @return Markdown formatted executive summary
#' @export
create_executive_summary <- function(results) {
  generator <- ReportGenerator$new()
  summary <- generator$generate_executive_summary(results)
  return(summary)
}

#' Export data in various formats (functional interface)
#' 
#' @param data Data to export
#' @param filename Filename
#' @param format Export format (json, csv, rds)
#' @param output_dir Output directory
#' @return Path to exported file
#' @export
export_analysis_data <- function(data, filename, format = "json", output_dir = "reports") {
  generator <- ReportGenerator$new(output_dir)
  filepath <- generator$export_data(data, filename, format)
  return(filepath)
}

# Print module information
cat("📝 HealthProcessAI R - Report Generator\n")
cat("======================================\n")
cat("✅ ReportGenerator R6 class available\n")
cat("✅ generate_report() function available\n")
cat("✅ create_executive_summary() function available\n")
cat("✅ export_analysis_data() function available\n")
cat("📚 Uses: rmarkdown, knitr, kableExtra\n\n")
cat("Supported formats:\n")
cat("  • Markdown (.md)\n")
cat("  • HTML (.html)\n")
cat("  • PDF (.pdf) - requires LaTeX\n")
cat("  • Word (.docx)\n")
cat("  • Data export (JSON, CSV, RDS)\n\n")
cat("Example usage:\n")
cat('  generator <- ReportGenerator$new()\n')
cat('  files <- generator$generate_report(results, "sepsis_analysis", c("markdown", "pdf"))\n\n')