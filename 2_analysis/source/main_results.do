*******************************************************************************
* This script runs the main IV analysis for the paper and produces the  
* regression tables found in the body and appendix of the paper 
* 
* Author: Daniel Werner 
*******************************************************************************

clear all
set more off
set seed 2042023

* -----------------------------
* 0) Set paths and create folders
* -----------------------------
global TABLES  "../output/Tables/"
capture mkdir "${TABLES}"


* -----------------------------
* 1) Load the dataset
* -----------------------------
* use "../input/final_mun.dta", clear 
use "/Users/wernerd/Desktop/Daniel Werner/final_mun.dta", clear 

* -----------------------------
* 2) Generate necessary variables
* -----------------------------
* Instrument 
gen iv = cs_big * d_to_ep


* Treatment
gen ln_homicide = log(1+hr)

* Controls
destring municipality, replace 
gen month_year_date = date(year_month, "YM")
format month_year_date %tm

* -----------------------------
* 3) OLS and IV on Pooled Sample
* -----------------------------

reghdfe dropout_rate_total ln_homicide employment_rate avg_hh_size avg_weekly_hours_worked ///
    avg_weekly_hours_worked_workers avg_years_schooling pop_tot percent_pop_student ///
    avg_age avg_ms_real_earners avg_hs_real_earners, /// 
    absorb(i.month_year_date i.municipality) cluster(municipality)

drop if pop_tot < 10000 
	
ivreghdfe dr_total employment_rate avg_hh_size avg_weekly_hours_worked ///
    avg_weekly_hours_worked_workers avg_years_schooling pop_tot pct_pop_student ///
	pct_pop_male avg_age avg_income_earners avg_hincome_earners ///
	n_kids_in_school avg_years_schooling avg_hh_income avg_hh_children ///
	avg_hh_hincome avg_hh_adult_schooling avg_hh_hincome avg_hh_adult_hours /// 
	avg_hh_employment_rate avg_hh_n_employed_adults (ln_homicide = iv), /// 
    absorb(i.month_year_date i.municipality) cluster(municipality) first




// Continuous
cap drop iv
gen iv = cs_big * d_to_pc
ivreghdfe dr_total employment_rate avg_hh_size avg_weekly_hours_worked ///
    avg_weekly_hours_worked_workers avg_years_schooling pct_pop_student ///
    pct_pop_male avg_age avg_income_earners avg_hincome_earners pop_tot ///
    avg_years_schooling avg_hh_income avg_hh_children ///
    avg_hh_hincome avg_hh_adult_schooling avg_hh_hincome avg_hh_adult_hours /// 
    avg_hh_employment_rate avg_hh_n_employed_adults (ln_homicide = iv), /// 
    absorb(i.month_year_date i.municipality) cluster(municipality) first
local kp = e(rkf)
display "Pacific continuous: F = `kp'"

preserve
destring year, replace
keep if year >= 2019 & year <= 2024
gen iv = cs_big * d_to_pc
ivreghdfe dr_total employment_rate avg_hh_size avg_weekly_hours_worked ///
    avg_weekly_hours_worked_workers avg_years_schooling pct_pop_student ///
    pct_pop_male avg_age avg_income_earners avg_hincome_earners pop_tot ///
    avg_years_schooling avg_hh_income avg_hh_children ///
    avg_hh_hincome avg_hh_adult_schooling avg_hh_hincome avg_hh_adult_hours /// 
    avg_hh_employment_rate avg_hh_n_employed_adults (ln_homicide = iv), /// 
    absorb(i.month_year_date i.municipality) cluster(municipality) first
local kp = e(rkf)
display "Pacific continuous: F = `kp'"
restore 



use "/Users/wernerd/Desktop/Daniel Werner/final_indiv.dta", clear 
drop if pop_tot < 10000
* -----------------------------
* 2) Generate necessary variables
* -----------------------------
* Instrument 
gen iv = cs_big * d_to_ep


* Treatment
gen ln_homicide = log(1+hr)

* Controls
destring municipality, replace 
gen month_year_date = date(year_month, "YM")
format month_year_date %tm

* -----------------------------
* 3) OLS and IV on Pooled Sample
* -----------------------------

reghdfe dropout_rate_total ln_homicide employment_rate avg_hh_size avg_weekly_hours_worked ///
    avg_weekly_hours_worked_workers avg_years_schooling pop_tot percent_pop_student ///
    avg_age avg_ms_real_earners avg_hs_real_earners, /// 
    absorb(i.month_year_date i.municipality) cluster(municipality)

drop if pop_tot < 10000 
	
ivreghdfe school  hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children (ln_homicide = iv), /// 
    absorb(i.month_year_date i.id) cluster(id) first




// Continuous
cap drop iv
gen iv = cs_big * d_to_pc
ivreghdfe dr_total employment_rate avg_hh_size avg_weekly_hours_worked ///
    avg_weekly_hours_worked_workers avg_years_schooling pct_pop_student ///
    pct_pop_male avg_age avg_income_earners avg_hincome_earners pop_tot ///
    avg_years_schooling avg_hh_income avg_hh_children ///
    avg_hh_hincome avg_hh_adult_schooling avg_hh_hincome avg_hh_adult_hours /// 
    avg_hh_employment_rate avg_hh_n_employed_adults (ln_homicide = iv), /// 
    absorb(i.month_year_date i.municipality) cluster(municipality) first
local kp = e(rkf)
display "Pacific continuous: F = `kp'"

preserve
destring year, replace
keep if year >= 2019 & year <= 2024
gen iv = cs_big * d_to_pc
ivreghdfe dr_total employment_rate avg_hh_size avg_weekly_hours_worked ///
    avg_weekly_hours_worked_workers avg_years_schooling pct_pop_student ///
    pct_pop_male avg_age avg_income_earners avg_hincome_earners pop_tot ///
    avg_years_schooling avg_hh_income avg_hh_children ///
    avg_hh_hincome avg_hh_adult_schooling avg_hh_hincome avg_hh_adult_hours /// 
    avg_hh_employment_rate avg_hh_n_employed_adults (ln_homicide = iv), /// 
    absorb(i.month_year_date i.municipality) cluster(municipality) first
local kp = e(rkf)
display "Pacific continuous: F = `kp'"
restore 

