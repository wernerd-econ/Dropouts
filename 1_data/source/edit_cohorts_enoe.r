# =============================================================================
# This script deletes unecessary columns from the ENOE cohort data, creates new
# variables that will be used in the analysis, and saves the final dataset for 
# each cohort to then be merged into a single panel dataset.
# =============================================================================

# Load necessary libraries
library(tidyverse)
library(haven)

delete_unnecessary_columns <- function(df, columns_to_keep) {
  df <- df[, columns_to_keep]
}

create_new_variables <- function(df){
  return()
  # dropout variable creation
  # age cohort variable creation
  # other variable creation as needed

  # delete intermediary columns created
}

main <- function(){
  download_path <- "/Users/wernerd/Desktop/Daniel Werner/Cohorts/"
  #real download path is "../output/" but storing locally for testing
  args <- commandArgs(trailingOnly = TRUE)
  cohort_number <- as.integer(args[1])
  cohort_file <- sprintf("Cohort_%d.dta", cohort_number)
  cohort <- read_dta(file.path(download_path, cohort_file))
  columns_to_keep <- c() # specify the columns you want to keep
  cohort <- delete_unnecessary_columns(cohort, columns_to_keep)
  cohort <- create_new_variables(cohort)
  write_dta(cohort, paste0("../output/", sprintf("CleanCohort_%d.dta", cohort_number)))

}
# Execute
main()