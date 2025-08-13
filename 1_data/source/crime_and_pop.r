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
    mutate(ent = sub("^0+", "", as.character(ent_ocurr)),
           mun = sub("^0+", "", as.character(mun_ocurr)),
           municipality = paste0(ent, "0", sprintf("%02s", mun)),
           year = as.character(anio_ocur),
           month = as.character(mes_ocurr),
           causa_def = as.character(causa_def)) %>%
    select(ent, mun, causa_def, year, month, municipality)
  
  return(deaths)
}

years <- 2007:2023
death_reports <- glue("/Users/wernerd/Desktop/Daniel Werner/Deaths/DEFUN{years}.dbf")

# read in and concatenate records from all files
deaths <- map_dfr(death_reports, read_death_reports)


homicide_codes <- read_delim("cod-mapping.csv", delim = "|", guess_max = 5000)
homicide_codes <- homicide_codes %>% filter(cod_group == "Homicides")



homicide_deaths <- deaths %>% #FILTER OUT DEATHS...
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

## Add population data
pop <- read_excel(file.path("/Users/wernerd/Desktop/Daniel Werner/Population", "pop.xlsx"))
pop <- pop %>% filter(AÑO %in% c(2007:2024)) %>%
  group_by(CLAVE,AÑO) %>%
  summarize(pop_tot = sum(POB_TOTAL), .groups = "drop") %>%
  rename(municipality = CLAVE, year = AÑO)

fake_population <- fake_population %>% arrange(municipality, year) %>%
  group_by(municipality) %>%
  mutate(
    pop_next = lead(population),
    year_next = lead(year),
    monthly_growth = (pop_next / population)^(1/12) - 1
  ) %>%
  filter(!is.na(monthly_growth)) %>%
  rowwise() %>%
  do({
    tibble(
      municipality = .$municipality,
      year = .$year,
      month = 1:12,
      pop_month = .$population * (1 + .$monthly_growth)^(0:11)
    )
  }) %>%
  rename(pop_tot = pop_month) %>%
  ungroup()

pop <- pop %>% mutate(year = as.character(year),
                      month = as.character(month),
                      municipality = as.character(municipality))
                      
homicide_deaths <- homicide_deaths %>%
  left_join(pop, by = c("municipality", "year", "month")) %>%
  mutate(hr_per_ten_thousand = (homicides / pop_tot) * 10000) %>%
  drop_na()


#  keep the total population of school aged children as well


# save the final data set 

