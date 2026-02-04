# =============================================================================
# Description:
#   This script makes heat maps of Mexico by municipal homicide rates,
#   both in the full sample and in three time periods of interest.
#   All maps share identical violence cutoffs and legends.
#
# Author: Daniel Werner
# Date: Jan. 29, 2026
# =============================================================================

# =============================================================================
# (1) Load libraries and data
# =============================================================================
if (!require(devtools)) install.packages("devtools")
devtools::install_github("diegovalle/mxmaps")

library(mxmaps)
library(tidyverse)
library(haven)

homicides <- read_dta("/Users/wernerd/Desktop/Daniel Werner/homicides.dta")

fig_path <- "../output/Figures/"

# =============================================================================
# (2) Construct GLOBAL breaks and labels (ONCE)
# =============================================================================
all_values <- homicides %>%
  group_by(municipality, year) %>%
  summarise(
    homicides = sum(homicides),
    pop_year  = pop_tot[month == 12],
    value     = (homicides / pop_year) * 10000,
    .groups   = "drop"
  ) %>%
  group_by(municipality) %>%
  summarise(value = mean(value, na.rm = TRUE), .groups = "drop")

my_breaks_raw <- quantile(
  all_values$value,
  probs = c(0, 0.2, 0.4, 0.6, 0.8, 1),
  na.rm = TRUE
)

my_breaks <- unique(my_breaks_raw)

my_labels <- paste0(
  round(head(my_breaks, -1), 2), " – ",
  round(tail(my_breaks, -1), 2)
)

# =============================================================================
# (3) Define mapping function with FIXED bins
# =============================================================================
mapa_mun_crimen <- function(df, years, breaks, labels) {
  
  df_filt <- df %>%
    filter(year %in% years) %>%
    group_by(municipality, year) %>%
    summarise(
      homicides = sum(homicides),
      pop_year  = pop_tot[month == 12],
      municipality = as.numeric(municipality),
      value = (homicides / pop_year) * 10000,
      .groups = "drop"
    ) %>%
    distinct(municipality, year, .keep_all = TRUE) %>%
    group_by(municipality) %>%
    summarise(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
    rename(region = municipality) %>%
    mutate(
      value_cat = cut(
        value,
        breaks = breaks,
        labels = labels,
        include.lowest = TRUE,
        right = TRUE
      ),
      value = factor(value_cat, levels = labels)
    )
  
  p <- df_filt %>%
    mxmunicipio_choropleth(
      num_colors = length(breaks) - 1,
      title = "",
      show_states = TRUE
    ) +
    scale_fill_brewer(
      palette = "Reds",
      name = "",
      limits = labels,
      drop = FALSE
    )
  
  return(p)
}

# =============================================================================
# (4) Generate maps (ALL share identical legend)
# =============================================================================
whole_samp <- mapa_mun_crimen(
  homicides, 2007:2024,
  breaks = my_breaks,
  labels = my_labels
)

ggsave(filename = file.path(fig_path, "total_hom_map.pdf"), plot = whole_samp)

war <- mapa_mun_crimen(
  homicides, 2007:2012,
  breaks = my_breaks,
  labels = my_labels
)

ggsave(filename = file.path(fig_path, "war_hom_map.pdf"), plot = war)

inter <- mapa_mun_crimen(
  homicides, 2013:2016,
  breaks = my_breaks,
  labels = my_labels
)

ggsave(filename = file.path(fig_path, "interim_hom_map.pdf"), plot = inter)


respike <- mapa_mun_crimen(
  homicides, 2017:2024,
  breaks = my_breaks,
  labels = my_labels
)

ggsave(filename = file.path(fig_path, "respike_hom_map.pdf"), plot = respike)


