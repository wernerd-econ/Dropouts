# =============================================================================
# Description:
#   This script uses code from Garguilo Abruto & Flordi (2023) to process
#   death report data from INEGI to create a clean dataset of monthly
#   municipal-level homicides in Mexico from 2007 to 2024. It also loads in 
#   raw population data, interpolates it assuming linear growth,
#   and saves the final dataset with homicide counts, population, homicide rates
#   per 10,000 people for every municipality month year from 2007 to 2023.
#
# Author: Daniel Werner 
# Date: Jan. 29, 2026
# =============================================================================

# =============================================================================
# (1) Load libraries and data
# =============================================================================
if (!require(pacman)) {install.packages("pacman")}

pacman::p_load(argparse, here, readr, dplyr, purrr, glue, janitor, stringr)

library(foreign)
library(tidyverse)
library(haven)

read_death_reports <- function(death_reports) {
  
  deaths <- read.dbf(death_reports) %>%
    janitor::clean_names() %>%
    mutate(ent = sub("^0+", "", as.character(ent_ocurr)),
           mun = sub("^0+", "", as.character(mun_ocurr)),
           municipality = paste0(ent, "0", sprintf("%02s", mun)),
           year = as.character(anio_ocur),
           month = as.character(mes_ocurr),
           causa_def = as.character(causa_def)) %>%
    select(ent, mun, causa_def, year, month, municipality)
  
  return(deaths)
}
years <- 2007:2024
death_reports <- glue("/Users/wernerd/Desktop/Daniel Werner/Deaths/DEFUN{years}.dbf")

# Read in and concatenate records from all files
deaths <- map_dfr(death_reports, read_death_reports)

base_path <- "/Users/wernerd/Desktop/Daniel Werner"
homicide_codes <- read_delim(file.path(base_path, "Deaths/cod-mapping.csv"), 
                             delim = "|", guess_max = 5000)

pop <- readxl::read_xlsx(file.path(base_path, "Population/pop.xlsx"))
# =============================================================================
# (2) Clean data (2007-2024) 
# =============================================================================
homicide_codes <- homicide_codes %>% filter(cod_group == "Homicides")

#FILTER OUT DEATHS...
homicide_deaths <- deaths %>% 
  # that occurred outside of time period or are missing year information
  filter(year %in% as.character(years)) %>%
  # missing month information
  filter(month != "99") %>%
  # that occurred outside of Mexico or are missing state info
  filter(!(ent %in% c("33", "34", "35", "99"))) %>%
  # missing municipality information
  filter(mun != "999") %>%
  # that were not homicides 
  filter(causa_def %in% homicide_codes$causa_def) %>%
  group_by(municipality, year, month) %>%
  summarize(homicides = n()) %>%
  ungroup()

# Add population data
pop <- pop %>%
  filter(AÑO %in% 2007:2024) %>%
  group_by(CLAVE, AÑO) %>%
  summarise(
    pop_tot = sum(POB_TOTAL),
    pop_hom = sum(POB_TOTAL[SEXO == "HOMBRES"]),
    pop_fem = sum(POB_TOTAL[SEXO == "MUJERES"]),
    pop_students = sum(POB_05_09 + POB_10_14 + POB_15_19),
    .groups = "drop"
  ) %>%
  rename(municipality = CLAVE, year = AÑO) %>%
  select(municipality, year, pop_tot, pop_hom, pop_fem, pop_students) %>%
  arrange(municipality, year) %>%
  group_by(municipality) %>%
  mutate(
    pop_tot_next = lead(pop_tot),
    pop_hom_next = lead(pop_hom),
    pop_fem_next = lead(pop_fem),
    pop_students_next = lead(pop_students),
    year_next = lead(year),
    tot_monthly_growth = (pop_tot_next / pop_tot)^(1/12) - 1,
    hom_monthly_growth = (pop_hom_next / pop_hom)^(1/12) - 1,
    fem_monthly_growth = (pop_fem_next / pop_fem)^(1/12) - 1,
    students_monthly_growth = (pop_students_next / pop_students)^(1/12) - 1
  ) %>%
  filter(!is.na(tot_monthly_growth),
         !is.na(hom_monthly_growth),
         !is.na(fem_monthly_growth),
         !is.na(students_monthly_growth)) %>%
  ungroup() %>%
  # Expand each row into 12 months
  rowwise() %>%
  mutate(month_data = list(tibble(
    month = 1:12,
    pop_total = pop_tot * (1 + tot_monthly_growth)^(0:11),
    pop_hombre = pop_hom * (1 + hom_monthly_growth)^(0:11),
    pop_mujer = pop_fem * (1 + fem_monthly_growth)^(0:11),
    pop_student = pop_students * (1 + students_monthly_growth)^(0:11)
  ))) %>%
  unnest(month_data) %>%
  ungroup()

pop <- pop %>% select(municipality, year, month, pop_total,
                      pop_hombre, pop_mujer, pop_student) %>%
  rename(pop_male = pop_hombre, pop_fem = pop_mujer, pop_tot = pop_total)

pop <- pop %>% mutate(year = as.character(year),
                      month = as.character(month),
                      municipality = as.character(municipality),
                      pct_pop_student = pop_student/pop_tot,
                      pct_pop_male = pop_male/pop_tot,
                      pct_pop_fem = pop_fem/pop_tot)

# Join and make homicide rates per 10k people
hom_rate <- pop %>%
  left_join(homicide_deaths, by = c("municipality", "year", "month")) %>%
  mutate(
    homicides = if_else(is.na(homicides), 0, homicides),
    hr = (homicides / pop_tot) * 10000
  ) %>%
  arrange(municipality, year, month) %>%
  group_by(municipality) %>%
  mutate(
    hr_lag1 = lag(hr, 1),
    hr_lag2 = lag(hr, 2),
    hr_lag3 = lag(hr, 3)
  ) %>%
  ungroup()


# Save the final data set 
write_dta(hom_rate, "/Users/wernerd/Desktop/Daniel Werner/homicides.dta")

# =============================================================================
# (3) Create QUARTERLY version
# =============================================================================

# Start fresh with raw population data
pop_quarterly <- readxl::read_xlsx(file.path(base_path, "Population/pop.xlsx"))

pop_quarterly <- pop_quarterly %>%
  filter(AÑO %in% 2007:2024) %>%
  group_by(CLAVE, AÑO) %>%
  summarise(
    pop_tot = sum(POB_TOTAL),
    pop_hom = sum(POB_TOTAL[SEXO == "HOMBRES"]),
    pop_fem = sum(POB_TOTAL[SEXO == "MUJERES"]),
    pop_students = sum(POB_05_09 + POB_10_14 + POB_15_19),
    .groups = "drop"
  ) %>%
  rename(municipality = CLAVE, year = AÑO) %>%
  select(municipality, year, pop_tot, pop_hom, pop_fem, pop_students) %>%
  arrange(municipality, year) %>%
  group_by(municipality) %>%
  mutate(
    pop_tot_next = lead(pop_tot),
    pop_hom_next = lead(pop_hom),
    pop_fem_next = lead(pop_fem),
    pop_students_next = lead(pop_students),
    year_next = lead(year),
    # Quarterly growth: (P_t+1/P_t)^(1/4) - 1
    tot_quarterly_growth = (pop_tot_next / pop_tot)^(1/4) - 1,
    hom_quarterly_growth = (pop_hom_next / pop_hom)^(1/4) - 1,
    fem_quarterly_growth = (pop_fem_next / pop_fem)^(1/4) - 1,
    students_quarterly_growth = (pop_students_next / pop_students)^(1/4) - 1
  ) %>%
  filter(!is.na(tot_quarterly_growth),
         !is.na(hom_quarterly_growth),
         !is.na(fem_quarterly_growth),
         !is.na(students_quarterly_growth)) %>%
  ungroup() %>%
  # Expand each row into 4 quarters
  rowwise() %>%
  mutate(quarter_data = list(tibble(
    trim = c("T1", "T2", "T3", "T4"),
    pop_total = pop_tot * (1 + tot_quarterly_growth)^(0:3),
    pop_hombre = pop_hom * (1 + hom_quarterly_growth)^(0:3),
    pop_mujer = pop_fem * (1 + fem_quarterly_growth)^(0:3),
    pop_student = pop_students * (1 + students_quarterly_growth)^(0:3)
  ))) %>%
  unnest(quarter_data) %>%
  ungroup()

pop_quarterly <- pop_quarterly %>% 
  select(municipality, year, trim, pop_total, pop_hombre, pop_mujer, pop_student) %>%
  rename(pop_male = pop_hombre, pop_fem = pop_mujer, pop_tot = pop_total) %>%
  mutate(
    year = as.character(year),
    municipality = as.character(municipality),
    pct_pop_student = pop_student/pop_tot,
    pct_pop_male = pop_male/pop_tot,
    pct_pop_fem = pop_fem/pop_tot
  )

# Aggregate homicides to quarterly
homicide_deaths_quarterly <- deaths %>%
  filter(year %in% as.character(years)) %>%
  filter(month != "99") %>%
  filter(!(ent %in% c("33", "34", "35", "99"))) %>%
  filter(mun != "999") %>%
  filter(causa_def %in% homicide_codes$causa_def) %>%
  mutate(
    month = as.numeric(month),
    trim = case_when(
      month %in% 1:3 ~ "T1",
      month %in% 4:6 ~ "T2",
      month %in% 7:9 ~ "T3",
      month %in% 10:12 ~ "T4"
    )
  ) %>%
  group_by(municipality, year, trim) %>%
  summarize(homicides = n(), .groups = "drop")

# Join and calculate quarterly homicide rates
hom_rate_quarterly <- pop_quarterly %>%
  left_join(homicide_deaths_quarterly, by = c("municipality", "year", "trim")) %>%
  mutate(
    homicides = if_else(is.na(homicides), 0, homicides),
    hr = (homicides / pop_tot) * 10000
  ) %>%
  arrange(municipality, year, trim) %>%
  group_by(municipality) %>%
  mutate(
    hr_lag1 = lag(hr, 1)
  ) %>%
  ungroup()

# Save quarterly data
write_dta(hom_rate_quarterly, "/Users/wernerd/Desktop/Daniel Werner/homicides_quarterly.dta")