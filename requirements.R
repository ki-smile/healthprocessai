# HealthProcessAI - R Requirements
# Process Mining Framework for Healthcare & Life Sciences
# Developed at SMAILE, Karolinska Institutet

# Install all required packages with:
# source("requirements.R")

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    install.packages(new_packages, dependencies = TRUE)
  }
  sapply(packages, require, character.only = TRUE)
}

# Core dependencies
core_packages <- c(
  "tidyverse",      # Data manipulation and visualization
  "dplyr",          # Data manipulation
  "ggplot2",        # Visualization
  "tidyr",          # Data tidying
  "purrr",          # Functional programming
  "readr",          # Data import
  "tibble",         # Modern data frames
  "lubridate",      # Date/time handling
  "glue",           # String interpolation
  "stringr"         # String manipulation
)

# Process mining packages
pm_packages <- c(
  "bupaR",          # Business Process Analytics in R
  "edeaR",          # Exploratory and Descriptive Event-based data Analysis in R
  "processmapR",    # Process map visualization
  "processmonitR",  # Process monitoring
  "petrinetR",      # Petri net modeling
  "heuristicsmineR" # Heuristics mining
)

# API and web packages
api_packages <- c(
  "httr",           # HTTP requests
  "jsonlite",       # JSON handling
  "httr2"           # Modern HTTP client
)

# Reporting packages
reporting_packages <- c(
  "rmarkdown",      # Dynamic documents
  "knitr",          # Report generation
  "tinytex",        # LaTeX for PDF generation
  "DT",             # Interactive tables
  "plotly",         # Interactive plots
  "flexdashboard",  # Dashboard creation
  "kableExtra"      # Enhanced table formatting
)

# Statistical packages
stats_packages <- c(
  "survival",       # Survival analysis
  "broom",          # Tidy statistical output
  "modelr",         # Modeling helpers
  "caret",          # Classification and regression
  "cluster"         # Clustering algorithms
)

# Development packages
dev_packages <- c(
  "devtools",       # Package development
  "testthat",       # Unit testing
  "roxygen2",       # Documentation
  "usethis",        # Workflow utilities
  "styler",         # Code formatting
  "lintr",          # Code linting
  "R6",             # Object-oriented programming
  "fs"              # File system operations
)

# Install all packages
cat("Installing HealthProcessAI R dependencies...\n")
cat("==========================================\n\n")

cat("Installing core packages...\n")
install_if_missing(core_packages)

cat("\nInstalling process mining packages...\n")
install_if_missing(pm_packages)

cat("\nInstalling API packages...\n")
install_if_missing(api_packages)

cat("\nInstalling reporting packages...\n")
install_if_missing(reporting_packages)

cat("\nInstalling statistical packages...\n")
install_if_missing(stats_packages)

cat("\nInstalling development packages...\n")
install_if_missing(dev_packages)

# Verify installation
cat("\n==========================================\n")
cat("Package installation complete!\n")
cat("Verifying installations...\n\n")

all_packages <- c(core_packages, pm_packages, api_packages, 
                  reporting_packages, stats_packages, dev_packages)

installed <- all_packages %in% installed.packages()[,"Package"]
names(installed) <- all_packages

if(all(installed)) {
  cat("✅ All packages successfully installed!\n")
} else {
  cat("⚠️ The following packages failed to install:\n")
  print(names(installed)[!installed])
}

# Print versions
cat("\n==========================================\n")
cat("Installed package versions:\n")
cat("==========================================\n")

# Key packages to check versions
key_packages <- c("bupaR", "tidyverse", "httr", "httr2", "rmarkdown", "R6", "glue", "cluster")
for(pkg in key_packages) {
  if(pkg %in% installed.packages()[,"Package"]) {
    version <- packageVersion(pkg)
    cat(sprintf("%-15s: %s\n", pkg, version))
  }
}

# Additional information
cat("\n==========================================\n")
cat("R Version Information:\n")
cat("==========================================\n")
cat(paste("R version:", R.version.string, "\n"))
cat(paste("Platform:", R.version$platform, "\n"))

cat("\n==========================================\n")
cat("HealthProcessAI R Requirements Installation Complete!\n")
cat("You can now run the R examples and modules.\n")
cat("==========================================\n")