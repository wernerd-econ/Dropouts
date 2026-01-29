# =============================================================================
# Description:
#   This script brings together all data sources to create the final analysis
#   panel. It brings together the ENOE, crime, population, and 
#   geographic data into one dataset at both the municipal and individual level.
#
# Author: Daniel Werner 
# Date: Jan. 29, 2026
# =============================================================================

library(haven)
library(tidyverse)
library(readxl)
library(lubridate)

# =============================================================================
# I. Start with Municipal Panel
# =============================================================================

# =============================================================================
# (I.1) Load  data
# =============================================================================
base_path <-  "/Users/wernerd/Desktop/Daniel Werner/"
municipal_data <- read_dta(file.path(base_path, "Municipal_data.dta"))
homicide_data <- read_dta(file.path(base_path, "homicides.dta"))
geo_data <- read_dta(file.path(base_path, "final_geo.dta"))
total_seizures <- read_dta(file.path(base_path, "seizure_data.dta"))

# =============================================================================
# (I.2) Merge datasets together
# =============================================================================
# Identify municipalities shared across all three datasets -- only valid observations
common_muns <- intersect(intersect(municipal_data$municipality, 
                                             homicide_data$municipality), 
                                   geo_data$municipality)

# Subset datasets to keep only valid municipalities
municipal_data <- municipal_data %>% 
  filter(municipality %in% common_muns)
homicide_data <- homicide_data %>% 
  filter(municipality %in% common_muns)
geo_data <- geo_data %>% 
  filter(municipality %in% common_muns)

# Rename seizure data columns for consistency
total_seizures <- total_seizures %>% rename(year = Year)
total_seizures <- total_seizures %>% rename(month = Month)

# Reformat data for merge
years <- as.character(unique(total_seizures$year))

municipal_data <- municipal_data %>% 
  mutate(year = paste0("20", year)) %>%
  filter(year %in% years) %>%
  mutate(
    year = as.character(year),
    month = sprintf("%02d", as.integer(month)),  # adds leading zero
    year_month = paste0(year, "-", month)        # combine into YYYY-MM
  )

homicide_data <- homicide_data %>% 
  filter(year %in% years) %>%
  mutate(
    year = as.character(year),
    month = sprintf("%02d", as.integer(month)),  # adds leading zero
    year_month = paste0(year, "-", month)        # combine into YYYY-MM
  )

total_seizures <- total_seizures %>%
  mutate(
    year = as.character(year),
    month = sprintf("%02d", as.integer(month)),  # adds leading zero
    year_month = paste0(year, "-", month)        # combine into YYYY-MM
  )

# Identify common year_month combinations across datasets
common_dates <- intersect(intersect(municipal_data$year_month, 
                                    homicide_data$year_month), 
                          total_seizures$year_month)

# Subset datasets to keep only valid dates
municipal_data <- municipal_data %>% 
  filter(year_month %in% common_dates) %>% 
  select(-month, -year) %>%
  mutate(municipality = as.character(municipality))
homicide_data <- homicide_data %>% 
  filter(year_month %in% common_dates) %>%
  mutate(municipality = as.character(municipality))
total_seizures <- total_seizures %>% 
  filter(year_month %in% common_dates) %>%
  select(-month, -year) 

# Merge datasets together
full <- homicide_data %>%
  left_join(total_seizures, by = "year_month") %>%
  left_join(geo_data, by = "municipality") %>%
  left_join(municipal_data, by = c("municipality", "year_month"))

# Save full dataset
write_dta(full, file.path(base_path, "final_mun.dta"))

# =============================================================================
# II. Continue with Individual Panel
# =============================================================================
# Remove old workspace to free up memory
rm(full,municipal_data, total_seizures, geo_data, homicide_data)
rm(common_muns, common_dates, years)
gc()

# =============================================================================
# (II.1) Load  data
# =============================================================================
individual_data <- read_dta(file.path(base_path, "Individual_data.dta"))
homicide_data <- read_dta(file.path(base_path, "homicides.dta"))
geo_data <- read_dta(file.path(base_path, "final_geo.dta"))
total_seizures <- read_dta(file.path(base_path, "seizure_data.dta"))

# =============================================================================
# (II.2) Merge datasets together
# =============================================================================

# Identify municipalities shared across all three datasets -- only valid observations
common_muns <- intersect(intersect(individual_data$municipality, 
                                   homicide_data$municipality), 
                         geo_data$municipality)

# Subset datasets to keep only valid municipalities
individual_data <- individual_data %>% 
  filter(municipality %in% common_muns)
homicide_data <- homicide_data %>% 
  filter(municipality %in% common_muns)
geo_data <- geo_data %>% 
  filter(municipality %in% common_muns)

# Rename seizure data columns for consistency
total_seizures <- total_seizures %>% rename(year = Year)
total_seizures <- total_seizures %>% rename(month = Month)

# Reformat data for merge
years <- as.character(unique(total_seizures$year))

individual_data <- individual_data %>% 
  mutate(year = paste0("20", year)) %>% 
  filter(year %in% years) %>%
  mutate(
    year = as.character(year),
    month = sprintf("%02d", as.integer(month)),  # adds leading zero
    year_month = paste0(year, "-", month)        # combine into YYYY-MM
  )

homicide_data <- homicide_data %>% 
  filter(year %in% years) %>%
  mutate(
    year = as.character(year),
    month = sprintf("%02d", as.integer(month)),  # adds leading zero
    year_month = paste0(year, "-", month)        # combine into YYYY-MM
  )

total_seizures <- total_seizures %>%
  mutate(
    year = as.character(year),
    month = sprintf("%02d", as.integer(month)),  # adds leading zero
    year_month = paste0(year, "-", month)        # combine into YYYY-MM
  )

# Identify common year_month combinations across datasets
common_dates <- intersect(intersect(individual_data$year_month, 
                                    homicide_data$year_month), 
                          total_seizures$year_month)

# Subset datasets to keep only valid dates
individual_data <- individual_data %>% 
  filter(year_month %in% common_dates) %>% 
  select(-month, -year) %>%
  mutate(municipality = as.character(municipality))
homicide_data <- homicide_data %>% 
  filter(year_month %in% common_dates) %>%
  mutate(municipality = as.character(municipality))
total_seizures <- total_seizures %>% 
  filter(year_month %in% common_dates) %>% 
  select(-month, -year)

# Merge datasets together
full <- homicide_data %>%
  left_join(total_seizures, by = "year_month") %>%
  left_join(geo_data, by = "municipality") %>% 
  left_join(individual_data, by = c("municipality", "year_month"))

# Remove month_year x municipality observations with no people in ENOE
full <- full %>%
  filter(!is.na(id))

# Save full dataset
write_dta(full, file.path(base_path, "final_indiv.dta"))
