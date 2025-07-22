### Overview
This directory contains only this README describing the raw data used throughout this project. 
All the raw data can be found in the following dropbox folder: FILL THIS IN WITH LINK TO FOLDER 
### Source
    ### ENOE Data 
        All ENOE data comes from the INEGI. 
    ### Colombian Cocaine Seizures Data
        Data on Colombian cocaine seizures is from the Colombian Department of Defense 
        The data was kindly shared with me by Daniel Mejía 
    ### Geographic Data 
        Geographic data can be found online in the form of shape files. 
    ### Population Data 
        All municipal population data comes from CONAPO. Reported annually and 
        interpolated assuming linear monthly growth between yearly observations
    ### Mexican CPI Data 

    ### Mexican Drug Seizures Data 

    ### Homicide Data (2 sources must be combined)

### When/where obtained & original form of files
    ### ENOE Data 
         Data for each quarter can be downloaded from the following link: https://www.inegi.org.mx/programas/enoe/15ymas/#microdatos
            - For years 2007-2020T1
                - Download DTA, will come in the form of a zip file called "YYYYtrim#_dta.zip" (where # is a number 1-4, indicating the quarter)
                - Open folder and only keep .dta files labeled COE1T#YY, COE2T#YY, HOGT#YY, SDEMT#YY, and VIVT#YY (disregard .txt file)
            - For years 2020T2-2024
                - Download DTA, will come in the form of a zip file called "enoe_n_YYYY_trim#_dta.zip" (where # is a number 1-4, indicating the quarter)
                - Open folder and only keep .dta files labeled ENOE(N)_COE1T#YY, ENOE(N)_COE2T#YY, ENOE(N)_HOGT#YY, ENOE(N)_SDEMT#YY, and ENOE(N)_VIVT#YY 
(disregard .txt file)
                - Note: Becase of COVID, 2020T2 is skipped

    ### Geographical Data 

### Description
Briefly describe the contents of the subdirectories and files. You do not necessarily need to describe each file separately, but a user should be able to look at 
the directory and understand the organization and purpose of the files.

### Terms of Use
All data used in this repo is public and can be used for any research or other purpose 
### Notes
It is important to be very careful with downloading ENOE onto local hard drive.
The raw files for the ENOE spanning from 2007-2024 take up roughly 72.0GB of 
storage. I have chosen to use dropbox to store all the raw data and an external
hard drive for all intermediary files in my code.
