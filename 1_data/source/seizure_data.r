# =============================================================================
# Description:
#   This script takes in the raw cocaine seizure data and processes it
#   to create a clean dataset of metric tons  seized by year and month
#
# Author: Daniel Werner 
# Date: Jan. 29, 2026
# =============================================================================

# =============================================================================
# (1) Load libraries and data
# =============================================================================
library(haven)
library(tidyverse)
library(readxl)

base_path <- "/Users/wernerd/Desktop/Daniel Werner/Cocaine"
coca <- read_excel(file.path(base_path,"Cocaina.xlsx"))
base_coca <- read_excel(file.path(base_path, "base.cocaina.xlsx"))

# =============================================================================
# (2) Clean data (2010-2024)
# =============================================================================
coca <- coca %>% mutate(`Type of Seizure` = "coca")
base_coca <- base_coca %>% mutate(`Type of Seizure` = "base coca") %>%
  rename(`UNIDAD DE MEDIDA`=`UNIDADES DE MEDIDA`)

# Combine the two types of seizures
total_seizures <- rbind(coca,base_coca)

# Remove Seizures With Quantity of 0 KG
total_seizures <- total_seizures %>% filter(`CANTIDAD` != 0)

# Extract Year and Month
total_seizures <- total_seizures %>%
  mutate(
    Year = format(`FECHA HECHO`, "%Y"),
    Month = format(`FECHA HECHO`, "%m") 
  ) %>% 
  mutate(Year=as.numeric(Year))

# List of Departments On Atlantic/Pacific Coast (Manually created)

ap <- c("LA GUAJIRA", "MAGDALENA", "ATLANTICO", "BOLIVAR", "SUCRE",
        "CORDOBA", "ANTIOQUIA", "CHOCO", "VALLE DEL CAUCA", "CAUCA",
        "NARIÑO", "SAN ANDRES ISLAS")

# Make Relevant Monthly Seizure Statistics (Metric Tons)
# ts - Total Seizures 
# cs - Coastal Seizures
total_seizures <- total_seizures %>% group_by(Year, Month) %>%
  mutate(ts = sum(`CANTIDAD`)/1000,
         ts_n = n(),
         ts_big = sum(`CANTIDAD`[`CANTIDAD` >= 500])/1000,
         ts_big_n = sum(`CANTIDAD` >= 500),
         cs = sum(`CANTIDAD`[`DEPARTAMENTO` %in% ap])/1000,
         cs_n = sum(`DEPARTAMENTO` %in% ap),
         cs_big = sum(`CANTIDAD`[`CANTIDAD` >= 500 & `DEPARTAMENTO` %in% ap])/1000,
         cs_big_n = sum(`CANTIDAD` >= 500 & `DEPARTAMENTO` %in% ap)
  ) %>%
  ungroup() %>% 
  distinct(Year, Month, .keep_all = TRUE)

# =============================================================================
# (3) Clean data (2007-2009)
# =============================================================================
inc <- read_excel(file.path(base_path, "Incautaciones.xlsx"))

# Keep only relevant cells
inc <- inc %>% filter(`CLASE ELEMENTO` == "COCAINA Y DERIVADOS") %>% 
  filter(`ELEMENTO` %in% c("BASE DE COCA", "CLORHIDRATO DE COCAINA")) %>%
  filter(`CANTIDAD` != 0)

#Extract Year and Month
inc <- inc %>%
  mutate(
    Year = format(`FECHA`, "%Y"),
    Month = format(`FECHA`, "%m") 
  ) %>% 
  mutate(Year=as.numeric(Year)) %>%
  filter(Year %in% c(2007:2009))

# Make Relevant Monthly Seizure Statistics (Metric Tons)
# ts - Total Seizures 
# cs - Coastal Seizures
inc <- inc %>% group_by(Year, Month) %>%
  mutate(ts = sum(`CANTIDAD`)/1000,
         ts_n = n(),
         ts_big = sum(`CANTIDAD`[`CANTIDAD` >= 500])/1000,
         ts_big_n = sum(`CANTIDAD` >= 500),
         cs = sum(`CANTIDAD`[`DEPARTAMENTO` %in% ap])/1000,
         cs_n = sum(`DEPARTAMENTO` %in% ap),
         cs_big = sum(`CANTIDAD`[`CANTIDAD` >= 500 & `DEPARTAMENTO` %in% ap])/1000,
         cs_big_n = sum(`CANTIDAD` >= 500 & `DEPARTAMENTO` %in% ap)
  ) %>%
  ungroup() %>% distinct(Year, Month, .keep_all = TRUE)

# =============================================================================
# (4) Merge the two datatsets
# =============================================================================
inc <- inc %>% select(Year, Month, ts, ts_n, ts_big, ts_big_n,
                      cs, cs_n, cs_big, cs_big_n)

total_seizures <- total_seizures %>% select(Year, Month, ts, ts_n, ts_big,
                                            ts_big_n, cs, cs_n, cs_big, cs_big_n) %>% 
  mutate(Year = as.numeric(Year), Month=as.character(Month))

seizure_data <- bind_rows(inc, total_seizures)

write_dta(seizure_data, "/Users/wernerd/Desktop/Daniel Werner/seizure_data.dta")

# =============================================================================
# (5) Create QUARTERLY version
# =============================================================================

# Add quarter variable to monthly data
seizure_data_quarterly <- seizure_data %>%
  mutate(
    Month = as.numeric(Month),
    quarter = case_when(
      Month %in% 1:3 ~ "T1",
      Month %in% 4:6 ~ "T2",
      Month %in% 7:9 ~ "T3",
      Month %in% 10:12 ~ "T4"
    )
  ) %>%
  group_by(Year, quarter) %>%
  summarise(
    ts = sum(ts, na.rm = TRUE),
    ts_n = sum(ts_n, na.rm = TRUE),
    ts_big = sum(ts_big, na.rm = TRUE),
    ts_big_n = sum(ts_big_n, na.rm = TRUE),
    cs = sum(cs, na.rm = TRUE),
    cs_n = sum(cs_n, na.rm = TRUE),
    cs_big = sum(cs_big, na.rm = TRUE),
    cs_big_n = sum(cs_big_n, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(year = Year, trim = quarter)

write_dta(seizure_data_quarterly, "/Users/wernerd/Desktop/Daniel Werner/seizure_data_quarterly.dta")