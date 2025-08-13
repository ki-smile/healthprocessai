\name{ProcessMiner}
\alias{ProcessMiner}
\title{Process Mining Engine for Healthcare Pathways}

\description{
R6 class for healthcare process mining using the bupaR ecosystem. Discovers clinical pathways, identifies process variants, analyzes performance metrics, and detects bottlenecks in healthcare processes.
}

\format{
\code{\link{R6Class}} object.
}

\section{Usage}{
\preformatted{
miner <- ProcessMiner$new()

# Discover process model
dfg_result <- miner$discover_dfg(event_log)

# Identify pathway variants  
variants <- miner$identify_variants(event_log)

# Calculate performance metrics
performance <- miner$calculate_performance_metrics(event_log)

# Detect bottlenecks
bottlenecks <- miner$identify_bottlenecks(event_log)
}
}

\section{Methods}{

\describe{
\item{\code{new()}}{Initialize a new ProcessMiner instance.}

\item{\code{discover_dfg(event_log, threshold = 0.1)}}{
Discover Directly-Follows Graph (DFG) from event log data.
\tabular{ll}{
  \code{event_log} \tab Event log data frame or bupaR eventlog \cr
  \code{threshold} \tab Minimum frequency threshold for including transitions \cr
}
Returns: List with DFG, activities, start/end activities, and transitions
}

\item{\code{discover_petri_net(event_log, algorithm = "inductive")}}{
Discover Petri net process model.
\tabular{ll}{
  \code{event_log} \tab Event log data frame or bupaR eventlog \cr
  \code{algorithm} \tab Mining algorithm ("inductive", "alpha", "heuristic") \cr
}
Returns: Petri net model object
}

\item{\code{identify_variants(event_log, min_frequency = 0.01)}}{
Identify and analyze process variants (different pathway patterns).
\tabular{ll}{
  \code{event_log} \tab Event log data frame or bupaR eventlog \cr
  \code{min_frequency} \tab Minimum frequency threshold for variants \cr
}
Returns: List with variant information, frequencies, and statistics
}

\item{\code{calculate_performance_metrics(event_log)}}{
Calculate comprehensive process performance metrics.
\tabular{ll}{
  \code{event_log} \tab Event log data frame or bupaR eventlog \cr
}
Returns: List with case duration, activity performance, and throughput metrics
}

\item{\code{identify_bottlenecks(event_log, threshold_quantile = 0.9)}}{
Identify process bottlenecks based on waiting times and queue analysis.
\tabular{ll}{
  \code{event_log} \tab Event log data frame or bupaR eventlog \cr
  \code{threshold_quantile} \tab Quantile threshold for bottleneck identification \cr
}
Returns: List with bottleneck activities, waiting times, and recommendations
}

\item{\code{analyze_resource_utilization(event_log)}}{
Analyze how resources are utilized across the process.
\tabular{ll}{
  \code{event_log} \tab Event log data frame or bupaR eventlog \cr
}
Returns: List with resource workload, efficiency, and allocation metrics
}

\item{\code{conformance_checking(event_log, reference_model)}}{
Check conformance between actual process and reference model.
\tabular{ll}{
  \code{event_log} \tab Event log data frame or bupaR eventlog \cr
  \code{reference_model} \tab Reference process model \cr
}
Returns: Conformance statistics and deviations
}

\item{\code{temporal_analysis(event_log, time_unit = "hours")}}{
Analyze temporal patterns in the process execution.
\tabular{ll}{
  \code{event_log} \tab Event log data frame or bupaR eventlog \cr
  \code{time_unit} \tab Time unit for analysis ("hours", "days", "weeks") \cr
}
Returns: Temporal patterns, seasonality, and trend analysis
}

\item{\code{visualize_process_map(dfg_result, layout = "hierarchical")}}{
Create process map visualization from DFG results.
\tabular{ll}{
  \code{dfg_result} \tab Result from discover_dfg() method \cr
  \code{layout} \tab Layout algorithm for visualization \cr
}
Returns: ggplot2 process map visualization
}

\item{\code{export_model(model, file_path, format = "json")}}{
Export discovered process model to file.
\tabular{ll}{
  \code{model} \tab Process model object \cr
  \code{file_path} \tab Output file path \cr
  \code{format} \tab Export format ("json", "xml", "png") \cr
}
Returns: Success status and file path
}
}
}

\section{Process Mining Algorithms}{

The ProcessMiner supports multiple discovery algorithms:

\describe{
\item{\strong{Directly-Follows Graph (DFG)}}{
Fast and intuitive representation of process flows. Good for initial exploration and pathway visualization.
}

\item{\strong{Inductive Miner}}{
Robust algorithm that guarantees sound process models. Best for formal process analysis and conformance checking.
}

\item{\strong{Alpha Algorithm}}{
Classic process mining algorithm. Suitable for well-structured processes with clear control flow.
}

\item{\strong{Heuristics Miner}}{
Handles noisy data well and can deal with short loops. Good for real-world healthcare processes.
}
}
}

\section{Healthcare Applications}{

Common healthcare process mining use cases:

\itemize{
  \item \strong{Clinical Pathway Analysis}: Discover actual patient care pathways
  \item \strong{Emergency Department Flow}: Analyze patient flow and waiting times
  \item \strong{Sepsis Care Protocol}: Monitor sepsis recognition and treatment pathways
  \item \strong{Surgery Workflow}: Optimize operating room and perioperative processes
  \item \strong{Discharge Planning}: Improve hospital discharge processes
  \item \strong{Medication Administration}: Analyze medication ordering and delivery
}
}

\examples{
\dontrun{
# Initialize process miner
miner <- ProcessMiner$new()

# Create sample healthcare event log
sample_log <- data.frame(
  case = c("P001", "P001", "P001", "P002", "P002"),
  activity = c("Registration", "Triage", "Treatment", "Registration", "Discharge"),
  timestamp = as.POSIXct(c(
    "2024-01-01 10:00", "2024-01-01 10:15", "2024-01-01 10:45",
    "2024-01-01 11:00", "2024-01-01 11:30"
  )),
  resource = c("Clerk", "Nurse", "Physician", "Clerk", "Nurse")
)

# Discover process model
dfg_result <- miner$discover_dfg(sample_log)
print(dfg_result$transitions)

# Identify process variants
variants <- miner$identify_variants(sample_log)
print(variants$variant_summary)

# Calculate performance metrics
performance <- miner$calculate_performance_metrics(sample_log)
print(performance$case_summary)

# Identify bottlenecks
bottlenecks <- miner$identify_bottlenecks(sample_log)
print(bottlenecks$activity_bottlenecks)

# Visualize the process
if (requireNamespace("ggplot2", quietly = TRUE)) {
  process_map <- miner$visualize_process_map(dfg_result)
  print(process_map)
}
}
}

\seealso{
\code{\link{EventLogLoader}}, \code{\link{AdvancedProcessAnalyzer}}, \code{\link{ReportGenerator}}

bupaR package documentation: \url{https://www.bupar.net/}

processmapR visualization: \url{https://www.bupar.net/processmaps.html}
}

\author{
SMAILE Lab, Karolinska Institutet

Farhad Abtahi \email{farhad.abtahi@ki.se}

Eduardo Illueca Fernandez \email{eduardo.illueca@ki.se}

Kaile Chen \email{kaile.chen@ki.se}
}

\references{
\itemize{
  \item van der Aalst, W.M.P. (2016). Process Mining: Data Science in Action. Springer.
  \item Janssenswillen, G., et al. (2019). bupaR: Business Process Analysis in R. R Journal.
  \item SMAILE Lab: \url{https://smile.ki.se}
  \item HealthProcessAI Repository: \url{https://github.com/ki-smile/HealthProcessAI}
}
}

\keyword{classes}
\keyword{process-mining}
\keyword{healthcare}