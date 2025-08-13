\name{EventLogLoader}
\alias{EventLogLoader}
\title{Event Log Data Loader}
\description{
R6 class for loading, validating, and preprocessing healthcare event log data.
Provides standardized data ingestion with support for various CSV formats and
automatic conversion to bupaR-compatible event logs.
}
\usage{
EventLogLoader$new()
}
\details{
The EventLogLoader class handles the first step of the healthcare process mining pipeline.
It provides robust data loading capabilities with automatic format detection,
data validation, and preprocessing for downstream analysis.

\subsection{Key Features}{
\itemize{
\item Flexible CSV loading with customizable column mapping
\item Automatic data type detection and conversion
\item Built-in data validation and quality checks
\item bupaR eventlog format conversion
\item Missing data handling and reporting
\item Basic statistical summaries
\item Data filtering and preprocessing utilities
}
}

\subsection{Supported Data Formats}{
\itemize{
\item Standard CSV files with headers
\item Healthcare event logs (case, activity, timestamp, resource)
\item PhysioNet Challenge format
\item Custom clinical data formats with column mapping
}
}
}
\section{Methods}{
\describe{
\item{\code{load_from_csv(file_path, case_col = "case", activity_col = "activity", 
                         timestamp_col = "timestamp", resource_col = "resource")}}{
Load event log data from CSV file with customizable column mapping.
}

\item{\code{load_from_data_frame(df, case_col = "case", activity_col = "activity", 
                                timestamp_col = "timestamp", resource_col = "resource")}}{
Load event log data from existing data frame.
}

\item{\code{validate_event_log(df)}}{
Validate event log data structure and data types.
}

\item{\code{convert_to_bupar(df)}}{
Convert standardized event log to bupaR eventlog format.
}

\item{\code{get_basic_statistics(df)}}{
Calculate basic statistics about the event log.
}

\item{\code{apply_filters(df, case_filter = NULL, activity_filter = NULL, 
                         date_range = NULL)}}{
Apply various filters to the event log data.
}

\item{\code{preprocess_data(df, remove_incomplete_cases = FALSE)}}{
Preprocess the event log data for analysis.
}

\item{\code{export_to_csv(df, file_path)}}{
Export processed event log to CSV format.
}
}}
\examples{
\dontrun{
# Initialize loader
loader <- EventLogLoader$new()

# Load from CSV with standard column names
event_log <- loader$load_from_csv("sepsis_data.csv")

# Load with custom column mapping
event_log <- loader$load_from_csv(
  "patient_data.csv",
  case_col = "patient_id",
  activity_col = "event_name", 
  timestamp_col = "event_time",
  resource_col = "department"
)

# Validate the loaded data
is_valid <- loader$validate_event_log(event_log)

# Get basic statistics
stats <- loader$get_basic_statistics(event_log)
print(stats)

# Apply filters
filtered_log <- loader$apply_filters(
  event_log,
  case_filter = c("Patient_001", "Patient_002"),
  activity_filter = c("Admission", "Discharge"),
  date_range = c(as.POSIXct("2024-01-01"), as.POSIXct("2024-12-31"))
)

# Convert to bupaR format (if bupaR is available)
if (requireNamespace("bupaR", quietly = TRUE)) {
  bupar_log <- loader$convert_to_bupar(event_log)
  print(bupaR::n_cases(bupar_log))
}

# Preprocess data
clean_log <- loader$preprocess_data(event_log, remove_incomplete_cases = TRUE)

# Export processed data
loader$export_to_csv(clean_log, "processed_sepsis_data.csv")
}

# Working with data frames
df <- data.frame(
  case = c("P001", "P001", "P002", "P002"),
  activity = c("Start", "End", "Start", "End"),
  timestamp = as.POSIXct(c("2024-01-01 10:00", "2024-01-01 12:00",
                          "2024-01-02 09:00", "2024-01-02 11:00")),
  resource = c("ER", "Ward", "ER", "Ward")
)

loader <- EventLogLoader$new()
processed_df <- loader$load_from_data_frame(df)
stats <- loader$get_basic_statistics(processed_df)
}
\seealso{
\code{\link{ProcessMiner}}, \code{\link{AdvancedProcessAnalyzer}}
}