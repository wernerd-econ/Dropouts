# =============================================================================
# Description:
#   This script makes municipal level panel data set from the ENOE panel data
#   This will make up the core of the analysis outcome variables and controls
#
# Author: Daniel Werner 
# Date: Jan. 29, 2026
# =============================================================================

# =============================================================================
# (1) Load libraries and prepare data
# =============================================================================
library(haven)
library(tidyverse)
library(ggplot2)

## load in panel dataset
base_path <- "/Users/wernerd/Desktop/Daniel Werner"
panel <- read_dta(file.path(base_path,"ENOE_panel.dta"))

panel <- panel %>%
  mutate(across(
    c(dropout, school, sex, n_hh, weekly_hours_worked, years_schooling, 
      employed, unemployed, PEA, age, monthly_salary_real, hrly_salary_real,
      monthly_salary_real_usd, hrly_salary_real_usd),
    ~ as.numeric(.)
  ))

# =============================================================================
# (2) Create household level variables
# =============================================================================
panel <- panel %>%
  mutate(
    is_child = age < 18 & age > 0,
    is_adult = age >= 18 & !age %in% c(99,98,0),
    is_school_age = age > 5 & age < 18
  ) %>%
  group_by(id_hog, month, year) %>%
    mutate(
      hh_income = sum(monthly_salary_real[is_adult & employed == 1],
                             na.rm = TRUE),
      hh_income_usd = sum(monthly_salary_real_usd[is_adult & employed == 1],
                            na.rm = TRUE),
      hh_hincome = sum(hrly_salary_real[is_adult & employed == 1],
                            na.rm = TRUE),
      hh_hincome_usd = sum(hrly_salary_real_usd[is_adult & employed == 1],
                                na.rm = TRUE),
      hh_adult_schooling = mean(years_schooling[is_adult & years_schooling != 99],
                                na.rm = TRUE),
      hh_adult_hours = mean(weekly_hours_worked[is_adult & employed == 1],
                            na.rm = TRUE),
      hh_adult_employment_rate = mean(employed[is_adult], na.rm = TRUE),
      hh_n_employed_adults = sum(employed[is_adult], na.rm = TRUE),
      hh_n_other_children = sum(is_school_age, na.rm = TRUE) - ifelse(is_school_age, 1, 0),
      hh_children = sum(is_child, na.rm = TRUE)
    ) %>%
    ungroup()
  
# =============================================================================
# (3) Make municipal-level panel
# =============================================================================
municipal_panel <- panel %>%
  group_by(municipality, month, year) %>%
  summarise(
    n_kids_in_school = sum(school, na.rm = TRUE),
    dr_total = sum(dropout, na.rm = TRUE) / sum(school, na.rm = TRUE),
    dr_primary = sum(dropout * primary, na.rm = TRUE) / sum(school * primary, na.rm = TRUE),
    dr_secondary = sum(dropout * secondary, na.rm = TRUE) / sum(school * secondary, na.rm = TRUE),
    dr_high = sum(dropout * high, na.rm = TRUE) / sum(school * high, na.rm = TRUE),
    dr_male = sum(dropout * (sex == 1), na.rm = TRUE) / sum(school * (sex == 1), na.rm = TRUE),
    dr_female = sum(dropout * (sex == 2), na.rm = TRUE) / sum(school * (sex == 2), na.rm = TRUE),
    #
    avg_weekly_hours_worked = mean(weekly_hours_worked, na.rm = TRUE),
    avg_weekly_hours_worked_workers = mean(weekly_hours_worked[weekly_hours_worked > 0],na.rm = TRUE),
    unemployment_rate =  sum(unemployed, na.rm = TRUE)/sum(PEA, na.rm = TRUE),
    employment_rate =  sum(employed, na.rm = TRUE)/sum(PEA, na.rm = TRUE),
    avg_age = mean(if_else(age %in% c(99,98,0), NA_real_, age), na.rm = TRUE),
    avg_income = mean(monthly_salary_real, na.rm = TRUE),
    avg_hincome = mean(hrly_salary_real, na.rm = TRUE),
    avg_income_usd = mean(monthly_salary_real_usd, na.rm = TRUE),
    avg_hincome_usd = mean(hrly_salary_real_usd, na.rm = TRUE),
    avg_income_earners = mean(monthly_salary_real[monthly_salary_real > 0],na.rm = TRUE),
    avg_hincome_earners = mean(hrly_salary_real[hrly_salary_real > 0],na.rm = TRUE),
    avg_income_usd_earners = mean(monthly_salary_real_usd[monthly_salary_real_usd > 0],na.rm = TRUE),
    avg_hincome_usd_earners = mean(hrly_salary_real_usd[hrly_salary_real_usd > 0],na.rm = TRUE),
    avg_years_schooling = mean(if_else(years_schooling == 99, NA_real_, years_schooling), na.rm = TRUE),
    #
    avg_hh_size = mean(n_hh, na.rm = TRUE),
    avg_hh_children = mean(hh_children, na.rm = TRUE),
    avg_hh_income = mean(hh_income, na.rm = TRUE),
    avg_hh_income_usd = mean(hh_income_usd, na.rm = TRUE),
    avg_hh_hincome = mean(hh_hincome, na.rm = TRUE),
    avg_hh_hincome_usd = mean(hh_hincome_usd, na.rm = TRUE),
    avg_hh_adult_schooling = mean(hh_adult_schooling, na.rm = TRUE),
    avg_hh_adult_hours = mean(hh_adult_hours, na.rm = TRUE),
    avg_hh_employment_rate = mean(hh_adult_employment_rate, na.rm = TRUE),
    avg_hh_n_employed_adults = mean(hh_n_employed_adults, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(across(everything(), ~ replace(.x, is.nan(.x) | is.infinite(.x), NA_real_)))

# Save Municipal Dataset
write_dta(municipal_panel, file.path(base_path,"Municipal_data.dta"))

# =============================================================================
# (4) Make individual-level panel
# =============================================================================
# Clear municipal panel from memory to free up memoryt space
rm(municipal_panel)
gc()

individual_panel <- panel %>% 
  filter(age > 05 & age <= 18) %>%
  mutate(across(everything(), ~ replace(.x, is.nan(.x) | is.infinite(.x), NA_real_)))

# Save Individual Dataset
write_dta(individual_panel, file.path(base_path,"Individual_data.dta"))

# =============================================================================
# (5) Do it all again at quarterly level
# =============================================================================

panel <- read_dta(file.path(base_path,"ENOE_panel.dta"))

panel <- panel %>%
  mutate(across(
    c(dropout, school, sex, n_hh, weekly_hours_worked, years_schooling, 
      employed, unemployed, PEA, age, monthly_salary_real, hrly_salary_real,
      monthly_salary_real_usd, hrly_salary_real_usd),
    ~ as.numeric(.)
  ))

# =============================================================================
# (2) Create household level variables
# =============================================================================
panel <- panel %>%
  mutate(
    is_child = age < 18 & age > 0,
    is_adult = age >= 18 & !age %in% c(99,98,0),
    is_school_age = age > 5 & age < 18
  ) %>%
  group_by(id_hog, trim) %>%
    mutate(
      hh_income = sum(monthly_salary_real[is_adult & employed == 1],
                             na.rm = TRUE),
      hh_income_usd = sum(monthly_salary_real_usd[is_adult & employed == 1],
                            na.rm = TRUE),
      hh_hincome = sum(hrly_salary_real[is_adult & employed == 1],
                            na.rm = TRUE),
      hh_hincome_usd = sum(hrly_salary_real_usd[is_adult & employed == 1],
                                na.rm = TRUE),
      hh_adult_schooling = mean(years_schooling[is_adult & years_schooling != 99],
                                na.rm = TRUE),
      hh_adult_hours = mean(weekly_hours_worked[is_adult & employed == 1],
                            na.rm = TRUE),
      hh_adult_employment_rate = mean(employed[is_adult], na.rm = TRUE),
      hh_n_employed_adults = sum(employed[is_adult], na.rm = TRUE),
      hh_n_other_children = sum(is_school_age, na.rm = TRUE) - ifelse(is_school_age, 1, 0),
      hh_children = sum(is_child, na.rm = TRUE)
    ) %>%
    ungroup()
  
# =============================================================================
# (3) Make municipal-level panel
# =============================================================================
municipal_panel <- panel %>%
  group_by(municipality, trim) %>%
  summarise(
    n_kids_in_school = sum(school, na.rm = TRUE),
    dr_total = sum(dropout, na.rm = TRUE) / sum(school, na.rm = TRUE),
    dr_primary = sum(dropout * primary, na.rm = TRUE) / sum(school * primary, na.rm = TRUE),
    dr_secondary = sum(dropout * secondary, na.rm = TRUE) / sum(school * secondary, na.rm = TRUE),
    dr_high = sum(dropout * high, na.rm = TRUE) / sum(school * high, na.rm = TRUE),
    dr_male = sum(dropout * (sex == 1), na.rm = TRUE) / sum(school * (sex == 1), na.rm = TRUE),
    dr_female = sum(dropout * (sex == 2), na.rm = TRUE) / sum(school * (sex == 2), na.rm = TRUE),
    #
    avg_weekly_hours_worked = mean(weekly_hours_worked, na.rm = TRUE),
    avg_weekly_hours_worked_workers = mean(weekly_hours_worked[weekly_hours_worked > 0],na.rm = TRUE),
    unemployment_rate =  sum(unemployed, na.rm = TRUE)/sum(PEA, na.rm = TRUE),
    employment_rate =  sum(employed, na.rm = TRUE)/sum(PEA, na.rm = TRUE),
    avg_age = mean(if_else(age %in% c(99,98,0), NA_real_, age), na.rm = TRUE),
    avg_income = mean(monthly_salary_real, na.rm = TRUE),
    avg_hincome = mean(hrly_salary_real, na.rm = TRUE),
    avg_income_usd = mean(monthly_salary_real_usd, na.rm = TRUE),
    avg_hincome_usd = mean(hrly_salary_real_usd, na.rm = TRUE),
    avg_income_earners = mean(monthly_salary_real[monthly_salary_real > 0],na.rm = TRUE),
    avg_hincome_earners = mean(hrly_salary_real[hrly_salary_real > 0],na.rm = TRUE),
    avg_income_usd_earners = mean(monthly_salary_real_usd[monthly_salary_real_usd > 0],na.rm = TRUE),
    avg_hincome_usd_earners = mean(hrly_salary_real_usd[hrly_salary_real_usd > 0],na.rm = TRUE),
    avg_years_schooling = mean(if_else(years_schooling == 99, NA_real_, years_schooling), na.rm = TRUE),
    #
    avg_hh_size = mean(n_hh, na.rm = TRUE),
    avg_hh_children = mean(hh_children, na.rm = TRUE),
    avg_hh_income = mean(hh_income, na.rm = TRUE),
    avg_hh_income_usd = mean(hh_income_usd, na.rm = TRUE),
    avg_hh_hincome = mean(hh_hincome, na.rm = TRUE),
    avg_hh_hincome_usd = mean(hh_hincome_usd, na.rm = TRUE),
    avg_hh_adult_schooling = mean(hh_adult_schooling, na.rm = TRUE),
    avg_hh_adult_hours = mean(hh_adult_hours, na.rm = TRUE),
    avg_hh_employment_rate = mean(hh_adult_employment_rate, na.rm = TRUE),
    avg_hh_n_employed_adults = mean(hh_n_employed_adults, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(across(everything(), ~ replace(.x, is.nan(.x) | is.infinite(.x), NA_real_)))

# Save Municipal Dataset
write_dta(municipal_panel, file.path(base_path,"Municipal_data_quarterly.dta"))

# =============================================================================
# (4) Make individual-level panel
# =============================================================================
# Clear municipal panel from memory to free up memoryt space
rm(municipal_panel)
gc()

individual_panel <- panel %>% 
  filter(age > 05 & age <= 18) %>%
  mutate(across(everything(), ~ replace(.x, is.nan(.x) | is.infinite(.x), NA_real_)))

# Save Individual Dataset
write_dta(individual_panel, file.path(base_path,"Individual_data_quarterly.dta"))