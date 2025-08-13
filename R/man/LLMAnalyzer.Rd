\name{LLMAnalyzer}
\alias{LLMAnalyzer}
\title{Large Language Model Integration for Clinical Analysis}
\description{
R6 class for integrating Large Language Models (LLMs) into healthcare process mining workflows.
Provides seamless API integration with OpenRouter for accessing multiple AI models
and generating clinical insights from process mining results.
}
\usage{
LLMAnalyzer$new(api_key, base_url = "https://openrouter.ai/api/v1")
}
\arguments{
\item{api_key}{Character string. OpenRouter API key for authentication.}
\item{base_url}{Character string. Base URL for the OpenRouter API.}
}
\details{
The LLMAnalyzer class enables healthcare professionals and researchers to leverage
state-of-the-art language models for generating clinical insights, recommendations,
and interpretations from process mining analyses.

\subsection{Supported Models}{
\itemize{
\item \strong{Anthropic Claude} - anthropic/claude-3.5-sonnet, anthropic/claude-3-haiku
\item \strong{OpenAI GPT} - openai/gpt-4o, openai/gpt-4o-mini
\item \strong{Google Gemini} - google/gemini-pro-1.5, google/gemini-flash-1.5
\item \strong{DeepSeek} - deepseek/deepseek-r1
\item \strong{xAI Grok} - x-ai/grok-2-1212
}
}

\subsection{Clinical Applications}{
\itemize{
\item Sepsis progression pattern interpretation
\item Clinical pathway optimization recommendations
\item Risk factor identification and analysis
\item Treatment protocol evaluation
\item Quality improvement insights
\item Patient outcome prediction explanations
}
}

\subsection{Key Features}{
\itemize{
\item Multi-model analysis with consensus building
\item Clinical context-aware prompt engineering
\item Automatic retry logic and rate limiting
\item Token usage tracking and cost estimation
\item Response quality assessment
\item Error handling and graceful degradation
}
}
}
\section{Methods}{
\describe{
\item{\code{query_model(model, prompt, max_tokens = 1000, temperature = 0.7)}}{
Query a single LLM model with a clinical prompt.
}

\item{\code{analyze_with_multiple_models(process_results, models = NULL, 
                                        clinical_context = "general")}}{
Analyze process mining results using multiple LLM models for consensus.
}

\item{\code{generate_clinical_report(process_data, model = "anthropic/claude-3.5-sonnet")}}{
Generate a comprehensive clinical report from process mining data.
}

\item{\code{format_clinical_prompt(process_data, clinical_context)}}{
Format process mining data into clinical analysis prompts.
}

\item{\code{validate_model(model_name)}}{
Validate if a model name is supported by OpenRouter.
}

\item{\code{estimate_tokens(text)}}{
Estimate token count for text input.
}

\item{\code{parse_api_response(response)}}{
Parse API response and extract relevant information.
}

\item{\code{get_supported_models()}}{
Get list of currently supported LLM models.
}

\item{\code{calculate_cost_estimate(tokens, model)}}{
Calculate estimated cost for API usage.
}
}}
\examples{
\dontrun{
# Initialize LLM analyzer (requires OpenRouter API key)
api_key <- Sys.getenv("OPENROUTER_API_KEY")
llm <- LLMAnalyzer$new(api_key = api_key)

# Single model query
response <- llm$query_model(
  model = "anthropic/claude-3.5-sonnet",
  prompt = "Analyze this sepsis progression pattern: ...",
  max_tokens = 500
)
cat(response$content)

# Multi-model analysis
process_results <- list(
  n_cases = 150,
  avg_duration = 4.2,
  sepsis_rate = 0.28,
  key_findings = "Three distinct progression patterns identified"
)

multi_analysis <- llm$analyze_with_multiple_models(
  process_results = process_results,
  models = c("anthropic/claude-3.5-sonnet", "openai/gpt-4o", "google/gemini-pro-1.5"),
  clinical_context = "sepsis"
)

# Generate comprehensive clinical report
clinical_report <- llm$generate_clinical_report(
  process_data = process_results,
  model = "anthropic/claude-3.5-sonnet"
)

# Check supported models
supported_models <- llm$get_supported_models()
print(supported_models)

# Estimate costs
prompt <- "Analyze sepsis progression patterns in ICU patients..."
tokens <- llm$estimate_tokens(prompt)
cost <- llm$calculate_cost_estimate(tokens, "anthropic/claude-3.5-sonnet")

# Validate model availability
is_valid <- llm$validate_model("anthropic/claude-3.5-sonnet")
}

# Clinical context examples
\dontrun{
# Sepsis analysis
sepsis_analysis <- llm$analyze_with_multiple_models(
  process_results = sepsis_data,
  clinical_context = "sepsis"
)

# Organ failure analysis  
organ_analysis <- llm$analyze_with_multiple_models(
  process_results = organ_data,
  clinical_context = "organ_failure"
)

# General healthcare analysis
general_analysis <- llm$analyze_with_multiple_models(
  process_results = healthcare_data,
  clinical_context = "general"
)
}
}
\note{
\itemize{
\item Requires valid OpenRouter API key: \url{https://openrouter.ai/}
\item API usage incurs costs based on token consumption
\item Some models may have rate limits or availability restrictions
\item Clinical insights should be validated by healthcare professionals
\item Ensure compliance with healthcare data regulations (HIPAA, GDPR, etc.)
}
}
\seealso{
\code{\link{ReportOrchestrator}}, \code{\link{ProcessMiner}}, \code{\link{AdvancedProcessAnalyzer}}
}