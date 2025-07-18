# OpenRouter Free Models Comparison Script
# This script compares responses from free models using OpenRouter API

# Load required libraries
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(tibble)
library(glue)
library(bupaR)

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
query_model_safe <- function(model_name, prompt, use_case) {
  tryCatch({
    cat("Querying model:", model_name, "\n")
    
    if (use_case == "Infection") {
      
      processMatrix <- 'process_matrix.csv'

      # Read file contents
      matrix_content <- read_file_content(processMatrix)

      # Prepare messages
      messages <- list(
        list(role = "user", content = prompt),
        list(role = "user", content = paste("Process Matrix (Hours) CSV:\n", matrix_content))
      )
      
    }
    
    else {
      
      processMatrix_1 <- 'process_matrix_1.csv'
      processMatrix_2 <- 'process_matrix_2.csv'

      # Read file contents
      matrix_content_1 <- read_file_content(processMatrix_1)
      matrix_content_2 <- read_file_content(processMatrix_2)
      
      # Prepare messages
      messages <- list(
        list(role = "user", content = prompt),
        list(role = "user", content = paste("Process Matrix with Sepsis (Hours) CSV:\n", matrix_content_1)),
        list(role = "user", content = paste("Process Matrix without Sepsis (Hours) CSV:\n", matrix_content_2))
      )
      
    }
    
   
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

workflow <- function(event_log, models, prompt, use_case) {
  
  processMatrix <- 'process_matrix.csv'
  processMap <- 'processMap.json'
  
  # Main execution
  cat("Starting model comparison...\n")
  cat("Testing", length(models), "models\n\n")
  
  #Process Discovery
  

  if (use_case == "Infection"){
    
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
    
    mydata = mydata %>%
      filter_case_condition(SepsisLabel == 1)
    
    #Process Discovery
    
    case_data=cases(mydata)
    trace_data=traces(mydata)
    activity_data=activities(mydata)
    
    
    
    graph = mydata %>%
      process_map(type_nodes = frequency("relative_case"), render = FALSE)
    
    export_map(graph, "processMap.png", "png")
    
    #write_json(as.character(graph), "processMap.json", pretty = FALSE)
    
    matrix = mydata %>% process_matrix(performance(FUN = mean, units = "hours")) 
    
    write.csv(matrix, file="./process_matrix.csv", row.names = FALSE)
    
    # Query all models
    results <- map(models, ~query_model_safe(.x, prompt, use_case = use_case))
    
    # Convert results to a clean data frame
    results_df <- map_dfr(results, ~tibble(
      model = .x$model,
      status = .x$status,
      response = .x$response,
      tokens_used = .x$tokens_used
    ))
    
  }
  
  else if (use_case == "Organ") {
    
    #Process Discovery With Sepsis
    
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
    
    mydata = mydata %>%
      filter_case_condition(SepsisLabel == 1)
    
    case_data=cases(mydata)
    trace_data=traces(mydata)
    activity_data=activities(mydata)
    
    
    
    graph = mydata %>%
      process_map(type_nodes = frequency("relative_case"), render = FALSE)
    
    export_map(graph, "processMap_1.png", "png")
    
    matrix = mydata %>% process_matrix(performance(FUN = mean, units = "hours")) 
    
    write.csv(matrix, file="./process_matrix_1.csv", row.names = FALSE)
    
    #Process Discovery Without Sepsis
    
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
    
    selection = (mydata %>% filter_case_condition(SepsisLabel == 1))$case %>% unique()
    
    mydata = mydata[!(mydata$case %in% selection),]
    
  
    case_data=cases(mydata)
    trace_data=traces(mydata)
    activity_data=activities(mydata)
    
    graph = mydata %>%
      process_map(type_nodes = frequency("relative_case"), render = FALSE)
    
    export_map(graph, "processMap_2.png", "png")
    
    matrix = mydata %>% process_matrix(performance(FUN = mean, units = "hours")) 
    
    write.csv(matrix, file="./process_matrix_2.csv", row.names = FALSE)
    
    # Query all models
    results <- map(models, ~query_model_safe(.x, prompt, use_case = use_case))
    
    # Convert results to a clean data frame
    results_df <- map_dfr(results, ~tibble(
      model = .x$model,
      status = .x$status,
      response = .x$response,
      tokens_used = .x$tokens_used
    ))
    
  }
  
  else {
    print("Error: Case not recognized")
  }
  
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

use_case = "Infection"

OPENROUTER_API_KEY <- "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" #REPLACE BY YOUR OPEN ROUTER API KEY
OPENROUTER_BASE_URL <- "https://openrouter.ai/api/v1"
fileName <- "prompt_infection.txt"

# Define the prompt to test
test_prompt <- readChar(fileName, file.info(fileName)$size)

# Define free models to test (popular free models on OpenRouter)
models <- c(
  "deepseek/deepseek-r1:free"
)

event_log <- "sepsisAgregated_Infection.csv"

workflow(event_log, models, test_prompt, use_case)

cat("\nScript completed!\n")