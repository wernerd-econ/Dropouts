## ====================================================================== ##
#using code from to generate the homicide count from the death reports and 
#causes of death reported by the INEGI 

# @misc{Gargiulo_Aburto_Floridi_2023,
#   title={Monthly municipal-level homicide rates in Mexico (January 2000–December 2022)},
#   url={osf.io/u8dc3},
#   DOI={10.17605/OSF.IO/U8DC3},
#   publisher={OSF},
#   author={Gargiulo, Maria and Aburto, José Manuel and Floridi, Ginevra},
#   year={2024},
#   month={March}
# }

#also loads in raw population data, interpolates it assuming linear growth,
# and saves the final dataset with homicide counts, population, homicide rates
#per 10,000 people for every municipality month year from 2000 to 2023.
## ====================================================================== ##

if (!require(pacman)) {install.packages("pacman")}

pacman::p_load(argparse, here, readr, dplyr, purrr, glue, janitor, stringr)

library(foreign)
library(tidyverse)

read_death_reports <- function(death_reports) {
  
  deaths <- read.dbf(death_reports) %>%
    janitor::clean_names() %>%
    mutate(ent = ent_ocurr,
           mun = mun_ocurr,
           municipality = paste0(ent, "0", sprintf("%02s", mun)),
           year = anio_ocur,
           month = mes_ocurr,
           causa_def = as.character(causa_def)) %>%
    select(ent, mun, causa_def, year, month, municipality)
  
  return(deaths)
}

years <- 2007:2023
death_reports <- glue("/Users/wernerd/Desktop/Daniel Werner/DEATHS/DEFUN{years}.dbf")

# read in and concatenate records from all files
deaths <- map_dfr(death_reports, read_death_reports)

deaths <- read_death_reports("DEFUN07.dbf")

homicide_codes <- read_delim("cod-mapping.csv", delim = "|", guess_max = 5000)
homicide_codes <- homicide_codes %>% filter(cod_group == "Homicides")



homicide_deaths <- deaths %>% #FILTER OUT DEATHS...
  # that occurred outside of time period or are missing year information
  filter(between(year, 2007, 2023)) %>%
  # missing month information
  filter(month != 99) %>%
  # that occurred outside of Mexico or are missing state info
  filter(!(ent %in% c("33", "34", "35", "99"))) %>%
  # missing municipality information
  filter(mun != "999") %>%
  # that were not homicides 
  filter(causa_def %in% homicide_codes$causa_def) %>%
  group_by(municipality, year, month) %>%
  summarize(homicides = n()) %>%
  ungroup()

## Add population data
