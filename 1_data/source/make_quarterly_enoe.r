# =============================================================================
# This script puts the five parts of the ENOE together for each quarter
# =============================================================================



# install.packages("devtools")
library(devtools)
# install_github("karthik/rdrop2")
library(curl)
library(rdrop2)
library(haven)
library(tidyverse)

# =============================================================================
# ------ Setting up the Dropbox connection ------- 
token <- readRDS("../../dropbox_token.rds")


# =============================================================================
# ---- Function to fuse components into a single ENOE (YYYY-T#) ----
    # For more information on how to merge these datasets, refer to the document at the following link:
    # https://pueaa.unam.mx/uploads/materials/Escoto-A.-2021.pdf?v=1661541626 

fuse_quarter <- function(sdem, coe1, coe2, hog, viv){
    #Creating IDs for dwelling, home, and person (the three levels along which the merge occurs)
    id_viv <- c("cd_a", "ent", "con", "v_sel") 
    id_hog <- c("cd_a", "ent", "con", "v_sel","n_hog", "h_mud") 
    id_persona <- c("cd_a", "ent", "con", "v_sel","n_hog", "h_mud", "n_ren")
    
    #Fusing Survey of Occupation and Employment 1 and 2
    coe <- merge(coe1,coe2, by=id_persona)
    #Rename a few variables so as to not confuse with socio-demographic variable names later on 
    coe <- coe %>% rename(p1coe=p1, p3coe=p3) 
    #Eliminate repeated variables from merge
    coe <- coe %>%  select(-ends_with(".y")) %>% 
        rename_at(.vars = vars(ends_with(".x")),
            .funs = funs(sub("[.]x$", "", .))) 

    #Fusing Info of Occupaion and Employment Survey (COE) w/ Socio-Demographic Survey (SDEM)
    sdemcoe <- merge(sdem, coe, by=id_persona, all = TRUE)
    #Eliminate repeated variables from merge 
    sdemcoe <- sdemcoe %>% select(-ends_with(".y")) %>% 
        rename_at(.vars = vars(ends_with(".x")),  
            .funs = funs(sub("[.]x$", "", .))) 

    #Fusing Home Survey (HOG) and Dwelling Survey (VIV) 
    vivhog <- merge(viv, hog, by=id_viv)
    #Eliminate repeated variables from merge 
    vivhog <- vivhog %>%  select(-ends_with(".y")) %>% 
        rename_at(.vars = vars(ends_with(".x")),  
            .funs = funs(sub("[.]x$", "", .))) 

    #Fusing to make final database (all together)
    complete <- merge(vivhog, sdemcoe, by=id_hog)
    #Eliminate repeated variables from merge 
    complete <- complete %>%  select(-ends_with(".y")) %>% 
        rename_at(.vars = vars(ends_with(".x")),  
            .funs = funs(sub("[.]x$", "", .))) 

    #Keep only valid survey entries (drop incomplete interviews and those with an absent condition of residence)
    complete <- complete %>% filter(r_def == 0) %>% filter(c_res != 2)

    return(complete)
}

# ---- Function to process a single year/quarter ----
process_quarter <- function(year, quarter) {
  folder_path <- sprintf("%d/%s", year, quarter)

  #Helper function to load files from dropbox
  load_from_dropbox <- function(folder_path, filename) {
    dropbox_file <- sprintf("%s/%s", folder_path, filename)
    temp_file <- tempfile(fileext = ".dta")
    drop_download(dropbox_file, local_path = temp_file, overwrite = TRUE, dtoken = token)
    df <- read_dta(temp_file)
    names(df) <- tolower(names(df))
    file.remove(temp_file) 
    return(df)
  }
  sdem <- load_from_dropbox(folder_path, "sdem.dta")
  coe1 <- load_from_dropbox(folder_path, "coe1.dta")
  coe2 <- load_from_dropbox(folder_path, "coe2.dta")
  hog  <- load_from_dropbox(folder_path, "hog.dta")
  viv  <- load_from_dropbox(folder_path, "viv.dta")
  
  # Fuse datasets
  year_quarter <- fuse_quarter(sdem, coe1, coe2, hog, viv)
  message("Fusing Completed Succesfully")
  rm(sdem, coe1, coe2, hog, viv)
  
  # Save output
  #Maybe since uploading doesnt work, I can have raw data in dropbox, save this into hard drive
  save_path <- paste0("/Users/dannywerner/HARD DRIVE/",
                      sprintf("%d_%s.dta", year, quarter))
  write_dta(year_quarter, save_path)
  cat(paste0(sprintf("%d_%s.dta", year, quarter), "has been saved to external hard drive"))
  rm(year_quarter)
  gc()
}

# ---- Main loop over years and quarters ----

main <- function() {
  years <- 2007:2025
  quarters <- c("T1", "T2", "T3", "T4")
  for (y in years) {
    for (q in quarters) {
      if (y == 2010 && q == "T2") { #missing b/c covid 
        message("Skipping 2010 T2 due to missing data.")
        next  # skips to next iteration
      }
      cat(sprintf("Processing %d %s...\n", y, q))
      tryCatch({
        process_quarter(y, q)
        gc()
      }, error = function(e) {
        message(sprintf("Failed for %d %s: %s", y, q, e$message))
      })
    }
  }
}

# ---- Execute ----
main()