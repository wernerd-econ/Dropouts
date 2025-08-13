## =============================================================== ##
        # This script takes in the raw cocaine seizure data
        # and processes it to create a clean dataset of metric tons
        # seized by year and month.
## =============================================================== ##

# Load necessary libraries
library(tidyverse)

base_path <- "/Users/wernerd/Desktop/Daniel Werner/Cocaine/"
#Cocaine Seizures - Base Cocaine and Cocaine
coca <- read_excel(file.path(base_path, "Cocaina.xlsx"))
base_coca <- read_excel(file.path(base_path, "base.cocaina.xlsx"))

coca <- coca %>% mutate(`Type of Seizure` = "coca")
base_coca <- base_coca %>% mutate(`Type of Seizure` = "base coca") %>% 
  rename(`UNIDAD DE MEDIDA` = `UNIDADES DE MEDIDA`)
total_seizures <- rbind(coca, base_coca)

#Remove Seizures With Quantity of 0 KG
total_seizures <- total_seizures %>% filter(`CANTIDAD` != 0)

#Extract Year and Month
total_seizures <- total_seizures %>%
  mutate(
    year = format(`FECHA HECHO`, "%Y"),
    month = format(`FECHA HECHO`, "%m")
  )

#Filter For Relevant Years
total_seizures <- total_seizures %>% mutate(year = as.numeric(year)) %>%
  filter(year %in% c(2007:2024))
 
#List of Departments On Atlantic/Pacific Coast
ap <- c("LA GUAJIRA", "MAGDALENA", "ATLANTICO", "BOLIVAR", "SUCRE",
        "CORDOBA", "ANTIOQUIA", "CHOCO", "VALLE DEL CAUCA", "CAUCA",
        "NARIÑO", "SAN ANDRES ISLAS")
 
#Make Relevant Monthly Seizure Statistics
total_seizures <- total_seizures %>% group_by(year, month) %>%
  mutate(`Total Seizures (Tons)` = sum(`CANTIDAD`) / 1000,
         `Seizure Events (#)` = n(),
         `Seizures Above 0.5 Tons (Tons)` = sum(`CANTIDAD`[`CANTIDAD` >= 500])/1000,
         `Seizure Events Above 0.5 Tons (#)` = sum(`CANTIDAD` >= 500),
         `Coastal Seizures (Tons)` = sum(`CANTIDAD`[`DEPARTAMENTO` %in% ap])/1000,
         `Coastal Seizure Events (#)` = sum(`DEPARTAMENTO` %in% ap),
         `Coastal Seizures Above 0.5 Tons (Tons)` = sum(`CANTIDAD`[`CANTIDAD` >= 500 & `DEPARTAMENTO` %in% ap])/1000,
         `Coastal Seizure Events Above 0.5 Tons (#)` = sum(`CANTIDAD` >= 500 & `DEPARTAMENTO` %in% ap)
         ) %>%
  ungroup()

total_seizures <- total_seizures %>% rename(date = `FECHA HECHO`) %>%
  select(-COD_DEPTO, -COD_MUNI, -DEPARTAMENTO, -MUNICIPIO, -CANTIDAD,
         -`UNIDAD DE MEDIDA`, -`Type of Seizure`) %>%
  group_by(year, month) %>%
  distinct(year, month, .keep_all = TRUE)

# Save the cleaned data