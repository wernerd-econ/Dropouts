# =============================================================================
# this script makes municipal level panel data set from the ENOE panel dataset.
# this will make up the core of the analysis outcome variables and controls.
# =============================================================================


library(haven)
library(tidyverse)
library(ggplot2)

## load in homicide dataset
base_path <- "/Users/wernerd/Desktop/Daniel Werner"
panel <- read_dta(file.path(base_path,"ENOE_panel.dta"))

panel <- panel %>%
  mutate(across(
    c(dropout, school, weights, sex, n_hh, weekly_hours_worked, years_schooling, 
      employed, unemployed, PEA, age, monthly_salary_real, hrly_salary_real,
      monthly_salary_real_usd, hrly_salary_real_usd),
    ~ as.numeric(.)
  ))

municipal_panel <- panel %>%
  group_by(municipality, month, year) %>%
  summarise(
    dropout_rate_total = sum(dropout * weights, na.rm = TRUE) / sum(school * weights, na.rm = TRUE),
    dropout_rate_primary = sum(dropout * weights * primary, na.rm = TRUE) / sum(school * weights * primary, na.rm = TRUE),
    dropout_rate_secondary = sum(dropout * weights * secondary, na.rm = TRUE) / sum(school * weights * secondary, na.rm = TRUE),
    dropout_rate_high = sum(dropout * weights * high, na.rm = TRUE) / sum(school * weights * high, na.rm = TRUE),
    dropout_rate_male = sum(dropout * weights * (sex == 1), na.rm = TRUE) / sum(school * weights * (sex == 1), na.rm = TRUE),
    dropout_rate_female = sum(dropout * weights * (sex == 2), na.rm = TRUE) / sum(school * weights * (sex == 2), na.rm = TRUE),
    avg_hh_size = weighted.mean(n_hh, weights, na.rm = TRUE),
    avg_weekly_hours_worked = weighted.mean(weekly_hours_worked, weights, na.rm = TRUE),
    avg_weekly_hours_worked_workers = weighted.mean(
      weekly_hours_worked[weekly_hours_worked > 0],
      weights[weekly_hours_worked > 0],
      na.rm = TRUE
    ),
    avg_years_schooling = weighted.mean(if_else(years_schooling == 99, NA_real_, years_schooling), weights, na.rm = TRUE),
    employment_rate =  sum(employed * weights, na.rm = TRUE)/sum(PEA * weights, na.rm = TRUE),
    unemployment_rate =  sum(unemployed * weights, na.rm = TRUE)/sum(PEA * weights, na.rm = TRUE),
    avg_age = weighted.mean(if_else(age %in% c(99,98,0), NA_real_, age), weights, na.rm = TRUE),
    avg_monthly_salary_real = weighted.mean(monthly_salary_real, weights, na.rm = TRUE),
    avg_hrly_salary_real = weighted.mean(hrly_salary_real, weights, na.rm = TRUE),
    avg_monthly_salary_real_USD = weighted.mean(monthly_salary_real_usd, weights, na.rm = TRUE),
    avg_hrly_salary_real_USD = weighted.mean(hrly_salary_real_usd, weights, na.rm = TRUE),
    avg_monthly_salary_real_earners = weighted.mean(
      monthly_salary_real[monthly_salary_real > 0],
      weights[monthly_salary_real > 0],
      na.rm = TRUE
    ),
    avg_hrly_salary_real_earners = weighted.mean(
      hrly_salary_real[hrly_salary_real > 0],
      weights[hrly_salary_real > 0],
      na.rm = TRUE
    ),
    avg_monthly_salary_real_USD_earners = weighted.mean(
      monthly_salary_real_usd[monthly_salary_real_usd > 0],
      weights[monthly_salary_real_usd > 0],
      na.rm = TRUE
    ),
    avg_hrly_salary_real_USD_earners = weighted.mean(
      hrly_salary_real_usd[hrly_salary_real_usd > 0],
      weights[hrly_salary_real_usd > 0],
      na.rm = TRUE
    ),
    .groups = "drop_last"
  )

municipal_panel <- municipal_panel %>%
  mutate(across(everything(), ~ replace(.x, is.nan(.x) | is.infinite(.x), NA_real_)))

municipal_panel <- municipal_panel %>%
  rename(
    avg_ms_real_usd_earners = avg_monthly_salary_real_USD_earners,
    avg_hs_real_usd_earners = avg_hrly_salary_real_USD_earners,
    avg_ms_real_earners = avg_monthly_salary_real_earners,
    avg_hs_real_earners = avg_hrly_salary_real_earners
  )

#Save Municipal Dataset
write_dta(municipal_panel, file.path(base_path,"Municipal_data.dta"))