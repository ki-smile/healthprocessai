# OpenRouter Free Models Comparison Script
# This script compares responses from free models using OpenRouter API

# Load required libraries
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(tibble)
library(glue)

# Function to save string to markdown file
save_string_to_md <- function(text_string, filename = "output.md", directory = getwd()) {
  # Create full file path
  filepath <- file.path(directory, filename)
  
  # Ensure the filename has .md extension
  if (!grepl("\\.md$", filepath)) {
    filepath <- paste0(filepath, ".md")
  }
  
  # Write the string to file
  writeLines(text_string, con = filepath, useBytes = TRUE)
  
  # Print confirmation message
  cat("Markdown file saved to:", filepath, "\n")
  
  # Return the filepath invisibly
  invisible(filepath)
}

# Function to read file content safely
read_file_content <- function(filepath) {
  if (file.exists(filepath)) {
    content <- readChar(filepath, file.info(filepath)$size)
    return(content)
  } else {
    cat("Warning: File", filepath, "not found.\n")
    return("")
  }
}

# Function to query OpenRouter API
query_openrouter <- function(model_name, messages, temperature = 0.7) {
  
  # Prepare the request body
  body <- list(
    model = model_name,
    messages = messages,
    temperature = temperature
  )
  
  # Make the API request
  response <- POST(
    url = paste0(OPENROUTER_BASE_URL, "/chat/completions"),
    add_headers(
      "Authorization" = paste("Bearer", OPENROUTER_API_KEY),
      "Content-Type" = "application/json",
      "HTTP-Referer" = "http://localhost:8080", # Optional: your app URL
      "X-Title" = "Process Mining Analysis" # Optional: your app name
    ),
    body = toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  
  # Check if request was successful
  if (status_code(response) == 200) {
    content <- content(response, "text", encoding = "UTF-8")
    parsed_response <- fromJSON(content)
    return(parsed_response)
  } else {
    stop(paste("API request failed with status:", status_code(response), 
               "\nResponse:", content(response, "text")))
  }
}

# Function to safely query a model with error handling
query_model_safe <- function(model_name, prompt) {
  tryCatch({
    cat("Querying model:", model_name, "\n")
    
    processMatrix <- 'process_matrix.csv'
    processMap <- 'processMap.json'
    
    # Read file contents
    matrix_content <- read_file_content(processMatrix)
    map_content <- read_file_content(processMap)
    
    # Prepare messages
    messages <- list(
      list(role = "user", content = prompt),
      list(role = "user", content = paste("Process Matrix CSV:\n", matrix_content)),
      list(role = "user", content = paste("Process Map JSON:\n", map_content))
    )
    
    # Query the model
    response <- query_openrouter(model_name, messages)
    
    # Extract the response content
    content <- response$choices[[5]]
    
    return(list(
      model = model_name,
      status = "success",
      response = content,
      tokens_used = ifelse(is.null(response$usage$total_tokens), NA, response$usage$total_tokens)
    ))
    
  }, error = function(e) {
    cat("Error querying model", model_name, ":", e$message, "\n")
    return(list(
      model = model_name,
      status = "error",
      response = paste("Error:", e$message),
      tokens_used = NA
    ))
  })
}

workflow <- function(event_log, models, prompt) {
  
  processMatrix <- 'process_matrix.csv'
  processMap <- 'processMap.json'
  
  # Main execution
  cat("Starting model comparison...\n")
  cat("Testing", length(models), "models\n\n")
  
  #Process Discovery
  
  mydata=read.csv(event_log)
  mydata$timestamp=as.POSIXct(mydata$timestamp)
  mydata=mydata %>%
    eventlog(case_id="case",
             activity_id="activity",
             activity_instance_id="activity_instance_id",
             lifecycle_id="lifecycle",
             timestamp="timestamp",
             resource_id="resource",
             validate = TRUE)
  
  #Filtering
  
  mydata = mydata %>%
    filter_case_condition(SepsisLabel == 1)
  
  #Process Discovery
  
  case_data=cases(mydata)
  trace_data=traces(mydata)
  activity_data=activities(mydata)
  
  process_map = mydata %>%
    process_map(type_nodes = frequency("relative_case"), render = FALSE)
  
  write_json(as.character(process_map), "processMap.json", pretty = FALSE)
  
  matrix = mydata %>% process_matrix(frequency("absolute")) 
  
  write.csv(matrix, file="./process_matrix.csv", row.names = FALSE)
  
  # Query all models
  results <- map(models, ~query_model_safe(.x, prompt))
  
  # Convert results to a clean data frame
  results_df <- map_dfr(results, ~tibble(
    model = .x$model,
    status = .x$status,
    response = .x$response,
    tokens_used = .x$tokens_used
  ))
  
  # Save individual reports
  successful_models <- results_df %>% filter(status == "success")
  
  if(nrow(successful_models) > 0) {
    cat("\n=== SAVING INDIVIDUAL REPORTS ===\n")
    for(i in 1:nrow(successful_models)) {
      model_name_clean <- gsub("[^A-Za-z0-9_-]", "_", successful_models$model[i])
      filename <- glue('Report_{model_name_clean}.md')
      save_string_to_md(successful_models$response$content[i], filename)
    }
  }
  
}

# Set up OpenRouter configuration

OPENROUTER_API_KEY <- "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"
OPENROUTER_BASE_URL <- "https://openrouter.ai/api/v1"

# Define the prompt to test
test_prompt <- "You are an expert on process mining analyst applied to epidemiology with high skills for communicating complex data to a clinical audience in a clear, concise, and actionable manner. 

Your task is to generate a comprehensive report based on the provided process mining analysis. This analysis is composed of a process matrix and a process map, attached. The target audience for this report is a group of clinical and epidemiological stakeholders working on sepsis progression modelling. The report should be written in a professional and collaborative tone, avoiding overly technical jargon where possible. The goal is to provide them with a clear understanding of the current process, identify areas for improvement, and suggest actionable recommendations to enhance patient care and operational efficiency.   The report should be structured as a Markdown (.md) file with the following sections. Remove the ```markdown at the beginning:   

1. Executive Summary: Provide a high-level overview of the key findings and recommendations. This section should be concise and easily digestible for busy clinical leaders. Highlight the most important findings in sepsis progression.   
2. Introduction: State the purpose of the report: to analyze sepsis progression using process mining to identify inefficiencies and opportunities for improvement. Briefly describe the dataset used for the analysis, including the time frame of the data and the number of cases analyzed. Sepsis progression has been modelled according to the following states: i) low risk, ii) infection, iii) cardiac damage, iv) renal damage, v) liver damage, vi) multiorgan damage and vii) sepsis. It is important to note that infection can be combined with organ damage in a specific state (eg. Cardiac damage + Infection). However, the combination of two or more organ damages leads to multiorgan damage. Last, all the transitions are irreversible (except for the low risk state).   
3. Process Map Analysis: Provide a narrative description of the main pathway discovered in the process map, identify the most frequent activities and transitions and highlight any significant variations or loops from the expected sepsis progression. Highlight the top 3-5 most frequent activities (nodes) and explain their role in the process, detailing the most common transitions between activities and their frequencies.   
4. Data Summary Tables: * Generate the following three tables in Markdown format: * Table 1: Case Summary * Total number of cases * Number of unique traces (variants) * Median and average case duration * Duration of the shortest and longest cases * Table 2: Activity Summary * List of all activities discovered. * Frequency of each activity (how many times it appears in the logs). * Median and average time spent in each activity. * Table 3: Trace Summary * List the top 5 most frequent process variants (traces). * For each trace, show the percentage of cases that follow it and its median duration.   
5. Hypothesis for Sepsis Progression: This section should interpret the sepsis progression in the process map, and propose new hypothesis and research questions. In addition, it should propose recommendations and next steps for sepsis prediction in a reasonable time   
6. Conclusion: * Summarize the main findings of the analysis. * Reiterate the key recommendations. * Suggest next steps, such as a workshop with the clinical team to discuss the findings and co-design solutions.   

Please use clear headings, bullet points, and bold text to structure the report for maximum readability. Ensure that all tables are correctly formatted in Markdown.

"

# Define free models to test (popular free models on OpenRouter)
models <- c(
  "deepseek/deepseek-r1:free"
)

event_log <- "sepsisAgregated_Organ.csv"

workflow(event_log, models, test_prompt)

cat("\nScript completed!\n")