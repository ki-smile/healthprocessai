\name{ReportGenerator}
\alias{ReportGenerator}
\title{Multi-Format Report Generation}
\description{
R6 class for generating comprehensive healthcare process mining reports in multiple formats.
Uses RMarkdown for flexible document generation with support for Markdown, HTML, PDF, and Word outputs.
Designed for clinical stakeholders, researchers, and healthcare administrators.
}
\usage{
ReportGenerator$new()
}
\details{
The ReportGenerator class provides the final step in the healthcare process mining pipeline,
creating professional reports that combine process mining results, AI insights, and
clinical recommendations in multiple output formats.

\subsection{Supported Output Formats}{
\itemize{
\item \strong{Markdown} - Universal format for documentation and web publishing
\item \strong{HTML} - Interactive web reports with embedded visualizations
\item \strong{PDF} - Print-ready professional reports (requires LaTeX)
\item \strong{Word} - Microsoft Word documents for clinical documentation
}
}

\subsection{Report Components}{
\itemize{
\item Executive summary with key findings
\item Process analysis with metrics and visualizations
\item Clinical insights and AI-generated recommendations
\item Statistical summaries and performance indicators
\item Model attribution and consensus analysis
\item Appendices with detailed methodology
}
}

\subsection{Target Audiences}{
\itemize{
\item Clinical teams and healthcare providers
\item Hospital administrators and quality improvement staff
\item Healthcare researchers and informaticists
\item Regulatory compliance officers
\item Academic researchers and students
}
}
}
\section{Methods}{
\describe{
\item{\code{generate_markdown_report(data, include_visualizations = TRUE)}}{
Generate a comprehensive Markdown report from analysis results.
}

\item{\code{generate_html_report(data, output_file, include_interactive = TRUE)}}{
Generate an HTML report with interactive elements and visualizations.
}

\item{\code{generate_pdf_report(data, output_file, template = "clinical")}}{
Generate a PDF report suitable for printing and distribution.
}

\item{\code{generate_word_report(data, output_file, template = "clinical")}}{
Generate a Microsoft Word document for clinical documentation.
}

\item{\code{export_all_formats(data, output_dir, filename_base)}}{
Export reports in all available formats to specified directory.
}

\item{\code{create_activity_frequency_chart(activity_data)}}{
Create visualization of activity frequencies.
}

\item{\code{create_bottleneck_chart(bottleneck_data)}}{
Create visualization of process bottlenecks.
}

\item{\code{format_table_for_markdown(df)}}{
Format data frame as Markdown table.
}

\item{\code{get_clinical_report_template()}}{
Get clinical report template for customization.
}

\item{\code{get_research_report_template()}}{
Get research report template for academic use.
}

\item{\code{validate_report_data(data)}}{
Validate report data structure and completeness.
}

\item{\code{generate_report_metadata(data)}}{
Generate metadata about the report and analysis.
}

\item{\code{set_report_theme(theme)}}{
Set report theme (clinical, research, executive).
}

\item{\code{set_custom_css(css)}}{
Set custom CSS styling for HTML reports.
}
}}
\examples{
\dontrun{
# Initialize report generator
generator <- ReportGenerator$new()

# Prepare report data
report_data <- list(
  title = "Sepsis Patient Journey Analysis",
  subtitle = "Process Mining Report with AI Insights", 
  date = Sys.Date(),
  author = "Clinical Analytics Team",
  organization = "Hospital Quality Department",
  
  executive_summary = "Analysis of 250 sepsis cases reveals...",
  
  process_analysis = list(
    n_cases = 250,
    n_activities = 12,
    avg_case_duration = 4.2,
    bottlenecks = data.frame(
      activity = c("Lab_Processing", "Doctor_Consult"),
      avg_duration_hours = c(3.2, 1.8)
    )
  ),
  
  clinical_insights = list(
    key_findings = c(
      "Early vital sign deterioration precedes sepsis",
      "Three distinct patient pathways identified"
    ),
    recommendations = c(
      "Implement automated early warning system",
      "Reduce laboratory processing delays"
    )
  )
)

# Generate Markdown report
markdown_report <- generator$generate_markdown_report(report_data)
writeLines(markdown_report, "sepsis_analysis.md")

# Generate HTML report
html_result <- generator$generate_html_report(
  data = report_data,
  output_file = "sepsis_analysis.html"
)

# Generate PDF report (requires LaTeX)
pdf_result <- generator$generate_pdf_report(
  data = report_data, 
  output_file = "sepsis_analysis.pdf"
)

# Generate Word document
word_result <- generator$generate_word_report(
  data = report_data,
  output_file = "sepsis_analysis.docx"
)

# Export all formats at once
export_results <- generator$export_all_formats(
  data = report_data,
  output_dir = "./reports",
  filename_base = "sepsis_analysis"
)

# Create visualizations
activity_data <- data.frame(
  activity = c("Vital_Signs", "Lab_Test", "Assessment"),
  frequency = c(450, 320, 280)
)
activity_chart <- generator$create_activity_frequency_chart(activity_data)

# Customize report theme
generator$set_report_theme("clinical")
generator$set_custom_css("body { font-family: Arial; }")

# Validate data before generating report
is_valid <- generator$validate_report_data(report_data)
if (is_valid) {
  report <- generator$generate_markdown_report(report_data)
}
}

# Template customization example
\dontrun{
# Get and modify clinical template
clinical_template <- generator$get_clinical_report_template()

# Modify template for specific needs
custom_template <- gsub("## Executive Summary", 
                       "## Clinical Summary", 
                       clinical_template)

# Use custom template (would require additional implementation)
# custom_report <- generator$generate_custom_report(data, custom_template)
}

# Working with large datasets
\dontrun{
# Handle large process mining results
large_data <- list(
  title = "Hospital-wide Process Analysis",
  process_analysis = list(
    n_cases = 10000,
    detailed_activities = data.frame(
      activity = paste0("Activity_", 1:500),
      frequency = sample(1:1000, 500)
    )
  )
)

# Generate efficient report for large data
report <- generator$generate_markdown_report(large_data, 
                                            include_visualizations = FALSE)
}
}
\note{
\itemize{
\item HTML and PDF generation requires \code{rmarkdown} package
\item PDF generation requires LaTeX installation
\item Large datasets may require memory optimization
\item Visualizations require \code{ggplot2} package
\item Interactive features require \code{plotly} or \code{DT} packages
}
}
\seealso{
\code{\link{ReportOrchestrator}}, \code{\link{LLMAnalyzer}}, \code{\link{AdvancedProcessAnalyzer}}
}