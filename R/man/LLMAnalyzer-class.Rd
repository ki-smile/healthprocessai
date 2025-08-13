\name{LLMAnalyzer}
\alias{LLMAnalyzer}
\title{Large Language Model Integration for Clinical Insights}

\description{
R6 class for integrating Large Language Models (LLMs) into healthcare process mining workflows. Provides access to multiple LLM models via OpenRouter API for generating clinical insights, interpretations, and recommendations from process mining results.
}

\format{
\code{\link{R6Class}} object.
}

\section{Usage}{
\preformatted{
# Initialize with API key
analyzer <- LLMAnalyzer$new(api_key = "your-openrouter-key")

# Query a specific model
insights <- analyzer$query_model(
  model_name = "anthropic/claude-3.5-sonnet",
  prompt = "Analyze this sepsis care pathway..."
)

# Generate comprehensive analysis
analysis <- analyzer$generate_comprehensive_analysis(
  process_data = dfg_result,
  clinical_context = "emergency_department"
)

# Compare multiple models
comparison <- analyzer$multi_model_analysis(
  models = c("anthropic/claude-3.5-sonnet", "google/gemini-pro"),
  prompt = clinical_prompt
)
}
}

\section{Methods}{

\describe{
\item{\code{new(api_key, base_url = "https://openrouter.ai/api/v1")}}{
Initialize a new LLMAnalyzer instance.
\tabular{ll}{
  \code{api_key} \tab OpenRouter API key (required) \cr
  \code{base_url} \tab API base URL (optional) \cr
}
}

\item{\code{query_model(model_name, prompt, temperature = 0.7, max_tokens = 2000, ...)}}{
Query a specific LLM model with a clinical prompt.
\tabular{ll}{
  \code{model_name} \tab Model identifier (e.g., "anthropic/claude-3.5-sonnet") \cr
  \code{prompt} \tab Clinical analysis prompt \cr
  \code{temperature} \tab Sampling temperature (0-1) \cr
  \code{max_tokens} \tab Maximum response tokens \cr
  \code{...} \tab Additional model parameters \cr
}
Returns: List with model response, metadata, and usage statistics
}

\item{\code{generate_comprehensive_analysis(process_data, clinical_context, models = NULL)}}{
Generate comprehensive clinical analysis using multiple LLMs.
\tabular{ll}{
  \code{process_data} \tab Process mining results (DFG, variants, etc.) \cr
  \code{clinical_context} \tab Clinical domain context \cr
  \code{models} \tab Vector of model names (optional) \cr
}
Returns: List with multi-model analysis and consensus insights
}

\item{\code{multi_model_analysis(models, prompt, compare_responses = TRUE)}}{
Query multiple models with the same prompt and compare responses.
\tabular{ll}{
  \code{models} \tab Vector of model names \cr
  \code{prompt} \tab Analysis prompt \cr
  \code{compare_responses} \tab Whether to generate comparison analysis \cr
}
Returns: List with individual responses and comparison metrics
}

\item{\code{create_clinical_prompt(process_summary, context_info, analysis_focus = "general")}}{
Create structured clinical analysis prompts from process mining data.
\tabular{ll}{
  \code{process_summary} \tab Summary of process mining results \cr
  \code{context_info} \tab Clinical context information \cr
  \code{analysis_focus} \tab Focus area ("bottlenecks", "variants", "quality") \cr
}
Returns: Structured prompt text optimized for clinical analysis
}

\item{\code{validate_clinical_response(response, validation_criteria = NULL)}}{
Validate LLM responses for clinical accuracy and relevance.
\tabular{ll}{
  \code{response} \tab LLM response text \cr
  \code{validation_criteria} \tab Validation criteria list \cr
}
Returns: Validation results with quality scores and flags
}

\item{\code{extract_recommendations(analysis_text, priority_filter = TRUE)}}{
Extract actionable recommendations from LLM analysis.
\tabular{ll}{
  \code{analysis_text} \tab LLM analysis response \cr
  \code{priority_filter} \tab Whether to filter by priority level \cr
}
Returns: Structured list of recommendations with priorities
}

\item{\code{get_available_models()}}{
Get list of available models from OpenRouter API.
Returns: Data frame with model information, capabilities, and pricing
}

\item{\code{estimate_token_usage(text)}}{
Estimate token usage for prompt text.
\tabular{ll}{
  \code{text} \tab Input text to analyze \cr
}
Returns: Estimated token count and cost projection
}

\item{\code{cache_response(prompt_hash, response, ttl_hours = 24)}}{
Cache LLM responses to reduce API calls and costs.
\tabular{ll}{
  \code{prompt_hash} \tab Hash of the prompt \cr
  \code{response} \tab LLM response to cache \cr
  \code{ttl_hours} \tab Time-to-live in hours \cr
}
Returns: Cache success status
}

\item{\code{export_analysis(analysis_results, file_path, format = "json")}}{
Export LLM analysis results to file.
\tabular{ll}{
  \code{analysis_results} \tab Analysis results from LLM queries \cr
  \code{file_path} \tab Output file path \cr
  \code{format} \tab Export format ("json", "markdown", "csv") \cr
}
Returns: Success status and exported file path
}
}
}

\section{Supported Models}{

Popular healthcare-optimized models available through OpenRouter:

\describe{
\item{\strong{Anthropic Claude}}{
\code{"anthropic/claude-3.5-sonnet"} - Excellent for clinical reasoning and medical analysis
}

\item{\strong{Google Gemini}}{
\code{"google/gemini-pro"} - Strong analytical capabilities and structured outputs
}

\item{\strong{OpenAI GPT}}{
\code{"openai/gpt-4-turbo"} - Versatile model with good medical knowledge
}

\item{\strong{DeepSeek}}{
\code{"deepseek/deepseek-chat"} - Cost-effective option with competitive performance
}

\item{\strong{Cohere Command}}{
\code{"cohere/command-r-plus"} - Good for structured analysis and recommendations
}
}

See \code{get_available_models()} for complete current list.
}

\section{Clinical Prompt Engineering}{

Best practices for clinical prompts:

\itemize{
  \item \strong{Provide Context}: Include clinical setting, patient population, and care objectives
  \item \strong{Structure Data}: Present process mining results in clear, organized format
  \item \strong{Specify Focus}: Define specific analysis areas (e.g., bottlenecks, quality, safety)
  \item \strong{Request Actionable Outputs}: Ask for specific recommendations with priorities
  \item \strong{Include Constraints}: Mention regulatory requirements, resource limitations
  \item \strong{Validate Results}: Always review LLM outputs with clinical domain experts
}
}

\examples{
\dontrun{
# Initialize with API key (get from https://openrouter.ai)
analyzer <- LLMAnalyzer$new(api_key = Sys.getenv("OPENROUTER_API_KEY"))

# Check available models
models <- analyzer$get_available_models()
print(head(models))

# Create clinical analysis prompt
process_summary <- list(
  total_cases = 150,
  avg_duration = 240, # minutes
  top_activities = c("Registration", "Triage", "Treatment"),
  bottlenecks = c("Lab_Results", "Physician_Assessment")
)

prompt <- analyzer$create_clinical_prompt(
  process_summary = process_summary,
  context_info = list(
    setting = "Emergency Department",
    population = "Adult patients",
    timeframe = "3 months"
  ),
  analysis_focus = "bottlenecks"
)

# Query single model
insights <- analyzer$query_model(
  model_name = "anthropic/claude-3.5-sonnet",
  prompt = prompt,
  temperature = 0.3
)

print(insights$response)

# Multi-model analysis for consensus
comparison <- analyzer$multi_model_analysis(
  models = c("anthropic/claude-3.5-sonnet", "google/gemini-pro"),
  prompt = prompt
)

# Extract actionable recommendations
recommendations <- analyzer$extract_recommendations(
  insights$response,
  priority_filter = TRUE
)

print(recommendations)

# Export results
analyzer$export_analysis(
  analysis_results = insights,
  file_path = "clinical_analysis.json",
  format = "json"
)
}
}

\section{Cost Management}{

Tips for managing OpenRouter API costs:

\itemize{
  \item Use response caching for repeated similar queries
  \item Choose cost-effective models for exploratory analysis
  \item Optimize prompt length while maintaining clarity
  \item Batch similar queries when possible
  \item Monitor token usage with \code{estimate_token_usage()}
}
}

\seealso{
\code{\link{ProcessMiner}}, \code{\link{ReportOrchestrator}}, \code{\link{AdvancedProcessAnalyzer}}

OpenRouter API documentation: \url{https://openrouter.ai/docs}

Clinical AI guidelines: \url{https://www.fda.gov/medical-devices/software-medical-device-samd}
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
  \item OpenRouter Platform: \url{https://openrouter.ai}
  \item Topol, E.J. (2019). High-performance medicine: the convergence of human and artificial intelligence. Nature Medicine.
}
}

\keyword{classes}
\keyword{llm}
\keyword{clinical-ai}
\keyword{healthcare}