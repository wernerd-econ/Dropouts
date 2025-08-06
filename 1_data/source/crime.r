## ======================================================================== ##
        # This script takes in the raw crime and population data
        # and output a clean data set with intentional homicide
        # rates (per 10,000 inhabitants) by year, month, and municipality.
## ======================================================================== ##

#Quick note: Due to data availability, homicide rates
#must be constructed using two different data sources.
#The first is the Incidencia Delictiva Nacional (IDN)
#data from the Mexican government, which provides monthly
#homicide counts by municipality. This contains data at
#the municipal level from 2011 to 2024.
#For the years 2007 to 2012, I use the ... .

#This script also contains a block of code to compare homicides
#in overlapping time periods between the two data sources,
#to ensure consistency and accuracy in the homicide rates calculated.


#### BEGIN SCRIPT ####

# Load necessary libraries
library(tidyverse)

create_homicide_rate <- function(df, year_start, year_end) {
    #filter the data for the specified years 
    #find the total number of homicides per year and month (Homicidio Doloso)
    #merge with population data. Divide the total number of homicides by the population
    #and multiply by 10,000 to get the homicide rate per 10,000 inhabitants.
}

#rbind the two municipality, month, year, and homicide rate data frames
#and save the final data frame to the output directory.