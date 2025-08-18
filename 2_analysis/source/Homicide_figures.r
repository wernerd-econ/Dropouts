library(haven)
library(tidyverse)
library(ggplot2)

## load in homicide dataset
base_path <- "/Users/wernerd/Desktop/Daniel Werner"
homicide_data <- read_dta(file.path(base_path,"homicides.dta"))

ntl_homicide <- homicide_data %>% 
  group_by(month, year) %>%
  summarise(hom_ntl = sum(homicides),
            pop_ntl = sum(pop_tot),
            ntl_hom_per_tenk = hom_ntl/pop_ntl * 10000,
            avg_mun_hom = mean(homicide_rate_per_tenk),
            year_month = paste0(year, "-", month)) %>%
  distinct(year_month, .keep_all = TRUE)

ntl_homicide$year_month <- as.Date(paste0(ntl_homicide$year_month, "-01"))

ggplot(ntl_homicide, aes(x = year_month)) +
  geom_line(aes(y = ntl_hom_per_tenk, color = "National Homicide Rate")) +
  geom_line(aes(y = avg_mun_hom, color = "Average Municipal Homicide Rate")) +
  annotate("rect",
           xmin = as.Date("2007-01-01"),
           xmax = as.Date("2011-12-31"),
           ymin = -Inf, ymax = Inf,
           fill = "gray30", alpha = 0.2) +
  annotate("rect",
           xmin = as.Date("2015-01-01"),
           xmax = as.Date("2019-12-31"),
           ymin = -Inf, ymax = Inf,
           fill = "gray30", alpha = 0.2) +
  labs(
    x = "Year-Month",
    y = "Homicide Rate per 10k",
    title = "Homicide Rate Over Time",
    color = "Series"
  ) +
  scale_color_manual(values = c(
    "National Homicide Rate" = "firebrick",
    "Average Municipal Homicide Rate" = "steelblue"
  )) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
