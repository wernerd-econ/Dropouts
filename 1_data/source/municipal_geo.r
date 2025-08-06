## =============================================================== ##
        # This script takes in the raw INEGI municipal
        # geostatistic frame and finds the municipal centroids.
        # It also loads the data for the coast and both borders.
        # This can be used to calculate distances from each
        # municipality to the coast and borders.
        # The data and a graph are saved in the output directory.
## =============================================================== ##

# Load necessary libraries
library(tidyverse)
library(ggplot2)
library(sf)
base_path <- "/Users/wernerd/Desktop/Daniel Werner/GeoData/"
municipal <- st_read(file.path(base_path,
                               "areas_geoestadisticas_municipales.shp"))
n_border <- st_read(file.path(base_path,
                              "tl_2023_us_internationalboundary.shp"))
s_border <- st_read(file.path(base_path,
                              "Southern_Border_MX_GUA.shp"))
coast <- st_read(file.path(base_path, "coastline.shp"))

#Make Unique Municipality Code
municipal$CVE_ENT <- sub("^0", "", municipal$CVE_ENT)
municipal <- municipal %>% mutate(Municipio_code = paste0(`CVE_ENT`, `CVE_MUN`))

#Extract the centroid for each municipality (center of the polygon)
municipal <- municipal %>%
  mutate(centroid = st_centroid(geometry))

#Transofrm Border Data to Same Coordinate System as Mexico
#And, just as a double check - transform the Mexican one too

n_border <- st_transform(n_border, crs = 6372)
s_border <- st_transform(s_border, crs = 6372)
municipal <- st_transform(municipal, crs = 6372)
coast <- st_transform(coast, crs = 6372)
geo_data$centroid <- st_transform(geo_data$centroid, crs = 6372)

#Keep only Mexican Border -- Get Rid of Canada and Alaska
n_border <- n_border %>% filter(IBTYPE == "M")

# Visually confirm that everything is in the right place
ggplot() +
  geom_sf(data = municipal, fill = "#fdfdfd", color = "black") +
  geom_sf(data = n_border, color = "red", size = 3) +
  geom_sf(data = municipal, aes(geometry = centroid),
          color = "purple", size = 0.5) +
  geom_sf(data = s_border, color = "red", size = 6) +
  geom_sf(data = coast, color = "red", size = 0.5) +
  theme_minimal() +
  labs(title = "Municipalities and Borders",
       subtitle = "Centroids in Purple, Borders and Coasts in Red") +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))
#Calculate Relevant Distances
municipal <- municipal %>% group_by(Municipio_code) %>% 
  mutate(d_to_n_border = min(st_distance(centroid, n_border$geometry)),
         d_to_s_border = min(st_distance(centroid, s_border$geometry)),
         d_to_coast = min(st_distance(centroid, coast$geometry))) %>%
  ungroup()

#Make units in kilometers instead of meters
municipal$d_to_n_border <- set_units(municipal$d_to_n_border, "km")
municipal$d_to_s_border <- set_units(municipal$d_to_s_border, "km")
municipal$d_to_coast <- set_units(municipal$d_to_coast, "km")

#Keep only relevant columns
municipal <- municipal %>%
  st_set_geometry(NULL) %>%
  select(Municipio_code, d_to_n_border, d_to_s_border, d_to_coast)

#Save the data
write_dta(municipal, file.path(base_path, "final_geo.dta"))