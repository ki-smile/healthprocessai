\name{EventLogLoader}
\alias{EventLogLoader}
\title{Event Log Data Loader for Healthcare Process Mining}

\description{
R6 class for loading, validating, and preparing healthcare event log data for process mining analysis. Supports multiple data formats and provides comprehensive data validation capabilities.
}

\format{
\code{\link{R6Class}} object.
}

\section{Usage}{
\preformatted{
loader <- EventLogLoader$new()

# Load from CSV
event_log <- loader$load_from_csv("sepsis_data.csv")

# Load from Excel  
event_log <- loader$load_from_excel("patient_data.xlsx")

# Validate data
validation <- loader$validate_event_log(event_log)

# Convert to bupaR format
bupar_log <- loader$convert_to_bupar(event_log)
}
}

\section{Methods}{

\describe{
\item{\code{new()}}{Initialize a new EventLogLoader instance.}

\item{\code{load_from_csv(file_path, ...)}}{
Load event log data from CSV file.
\tabular{ll}{
  \code{file_path} \tab Character string path to CSV file \cr
  \code{...} \tab Additional arguments passed to \code{readr::read_csv()} \cr
}
Returns: Data frame with event log data
}

\item{\code{load_from_excel(file_path, sheet = 1, ...)}}{
Load event log data from Excel file.
\tabular{ll}{
  \code{file_path} \tab Character string path to Excel file \cr
  \code{sheet} \tab Sheet number or name to read \cr
  \code{...} \tab Additional arguments passed to \code{readxl::read_excel()} \cr
}
Returns: Data frame with event log data
}

\item{\code{validate_event_log(data)}}{
Validate event log data structure and quality.
\tabular{ll}{
  \code{data} \tab Data frame containing event log data \cr
}
Returns: List with validation results including quality score and issues
}

\item{\code{convert_to_event_log(data)}}{
Convert raw data to standardized event log format.
\tabular{ll}{
  \code{data} \tab Data frame with raw event data \cr
}
Returns: Data frame in standardized event log format
}

\item{\code{convert_to_bupar(event_log)}}{
Convert event log to bupaR eventlog object.
\tabular{ll}{
  \code{event_log} \tab Data frame in event log format \cr
}
Returns: bupaR eventlog object for process mining
}

\item{\code{detect_column_types(data)}}{
Automatically detect and suggest column types for event log data.
\tabular{ll}{
  \code{data} \tab Data frame to analyze \cr
}
Returns: List with suggested column mappings
}

\item{\code{clean_activity_names(event_log)}}{
Clean and standardize activity names in the event log.
\tabular{ll}{
  \code{event_log} \tab Event log data frame \cr
}
Returns: Event log with cleaned activity names
}

\item{\code{add_derived_features(event_log)}}{
Add derived features like duration, day of week, etc.
\tabular{ll}{
  \code{event_log} \tab Event log data frame \cr
}
Returns: Event log with additional derived columns
}

\item{\code{export_summary(event_log, file_path = NULL)}}{
Generate and optionally save data summary report.
\tabular{ll}{
  \code{event_log} \tab Event log data frame \cr
  \code{file_path} \tab Optional path to save summary \cr
}
Returns: List with data summary statistics
}
}
}

\section{Required Data Format}{

The event log data should contain the following columns:
\itemize{
  \item \strong{case}: Unique identifier for each case/patient (character)
  \item \strong{activity}: Name of the activity/event (character)
  \item \strong{timestamp}: Date and time of the event (POSIXct or character)
  \item \strong{resource}: Resource that performed the activity (character, optional)
  \item \strong{lifecycle}: Activity lifecycle (e.g., "complete", "start") (character, optional)
}

Additional columns are preserved and can be used for analysis.
}

\section{Data Validation}{

The validation process checks for:
\itemize{
  \item Required columns presence
  \item Data type consistency  
  \item Missing values
  \item Timestamp ordering
  \item Duplicate events
  \item Activity name consistency
  \item Case completeness
}

Quality scores are calculated as: \code{(checks_passed / total_checks) * 100}
}

\examples{
\dontrun{
# Initialize loader
loader <- EventLogLoader$new()

# Create sample data
sample_data <- data.frame(
  case = c("P001", "P001", "P002", "P002"),
  activity = c("Registration", "Treatment", "Registration", "Discharge"),
  timestamp = c("2024-01-01 10:00", "2024-01-01 10:30", 
                "2024-01-01 11:00", "2024-01-01 11:45"),
  resource = c("Clerk", "Nurse", "Clerk", "Physician"),
  stringsAsFactors = FALSE
)

# Convert to event log
event_log <- loader$convert_to_event_log(sample_data)

# Validate the data
validation <- loader$validate_event_log(event_log)
print(validation$quality_score)

# Convert to bupaR format for process mining
if (requireNamespace("bupaR", quietly = TRUE)) {
  bupar_log <- loader$convert_to_bupar(event_log)
  print(summary(bupar_log))
}

# Load from CSV file
# event_log <- loader$load_from_csv("path/to/your/data.csv")
}
}

\seealso{
\code{\link{ProcessMiner}}, \code{\link{AdvancedProcessAnalyzer}}, \code{\link{ReportGenerator}}

bupaR package documentation: \url{https://www.bupar.net/}
}

\author{
SMAILE Lab, Karolinska Institutet

Farhad Abtahi \email{farhad.abtahi@ki.se}

Eduardo Illueca Fernandez \email{eduardo.illueca@ki.se}

Kaile Chen \email{kaile.chen@ki.se}
}

\references{
\itemize{
  \item SMAILE Lab: \url{https://smile.ki.se}
  \item HealthProcessAI Repository: \url{https://github.com/ki-smile/HealthProcessAI}
  \item bupaR: Business Process Analysis in R. \url{https://www.bupar.net/}
}
}

\keyword{classes}
\keyword{data}
\keyword{healthcare}