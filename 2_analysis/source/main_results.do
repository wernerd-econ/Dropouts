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


use "/Users/wernerd/Desktop/Daniel Werner/final_indiv.dta", clear 

* -----------------------------
* GRAB THE MUNICIPAL DATA AND BRING IN THE MUNICIPAL LEVEL CONTROLS TO SOAK UP SOME OF THE NOISE
* -----------------------------

tempfile indiv_temp
save `indiv_temp', replace

* Load the municipal-level dataset
use "/Users/wernerd/Desktop/Daniel Werner/final_mun.dta", clear
 
* Keep only the variables you need from municipal data

keep municipality year month avg_* employment_rate

* Save as temporary file
tempfile muni_temp
save `muni_temp', replace

* Reload individual data
use `indiv_temp', clear

* Merge with municipal data
merge m:1 municipality year month using `muni_temp'


* Drop remaining unmerged and low population municipalities
drop if pop_tot < 50000
drop if _merge != 3
cap drop _merge
* -----------------------------
* 2) Generate necessary variables
* -----------------------------
* Instrument 
gen iv = cs_big * d_to_pc


* Treatment
gen ln_homicide = log(1+hr)
gen ln_hom_lag1 = log(1+hr_lag1)
gen ln_hom_lag2 = log(1+hr_lag2)
gen ln_hom_lag3 = log(1+hr_lag3)

* Controls
destring municipality, replace 
gen month_year_date = date(year_month, "YM")
format month_year_date %tm

* -----------------------------
* 3) OLS and IV on Pooled Sample
* -----------------------------
	
ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
local kp_1 = e(rkf)
quietly sum school if e(sample)
local mean_1 : display %6.3f r(mean)


destring year, replace
// ============================================
// TIME PERIOD HETEROGENEITY
// ============================================

// Period 1: 2007-2012
preserve
keep if year >= 2007 & year <= 2012

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_2 = _b[ln_homicide]
local se_2 = _se[ln_homicide]
local N_2 = e(N)
local kp_2 = e(rkf)
quietly sum school if e(sample)
local mean_2 : display %6.3f r(mean)

restore

// Period 2: 2012-2017
preserve
keep if year >= 2013 & year <= 2016

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_3 = _b[ln_homicide]
local se_3 = _se[ln_homicide]
local N_3 = e(N)
local kp_3 = e(rkf)
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)

restore

// Period 3: 2017-2024
preserve
keep if year >= 2017 & year <= 2024

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_4 = _b[ln_homicide]
local se_4 = _se[ln_homicide]
local N_4 = e(N)
local kp_4 = e(rkf)
quietly sum school if e(sample)
local mean_4 : display %6.3f r(mean)

restore

// ============================================
// GENDER HETEROGENEITY
// ============================================

// Males only
preserve
keep if sex == 1

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_5 = _b[ln_homicide]
local se_5 = _se[ln_homicide]
local N_5 = e(N)
local kp_5 = e(rkf)
quietly sum school if e(sample)
local mean_5 : display %6.3f r(mean)

restore

// Females only
preserve
keep if sex == 2

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_6 = _b[ln_homicide]
local se_6 = _se[ln_homicide]
local N_6 = e(N)
local kp_6 = e(rkf)
quietly sum school if e(sample)
local mean_6 : display %6.3f r(mean)
restore


	

// ============================================
// BUILD TABLE
// ============================================
forvalues j = 1/6 {
    local b  = `b_`j''  
    local se = `se_`j''  
    
    * t/z statistic
    local t = abs(`b' / `se')  
    local p = 2 * normal(-`t')
    
    * stars
    local stars ""
    if (`p' < 0.10) local stars "*"
    if (`p' < 0.05) local stars "**"
    if (`p' < 0.01) local stars "***"

    * formatted numbers
    local b_tex  : display %6.3f `b'
    local se_tex : display %6.3f `se'
    local kp_tex : display %6.2f `kp_`j''
    
    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
    local kpout`j' "`kp_tex'"
    
    local N = `N_`j'' 
    * Add comma if N > 10,000
    if `N' >= 10000 {
        local Nout`j' : display %9.0fc `N'
    }
    else {
        local Nout`j' : display %9.0f `N'  
    }
}

// ============================================
// WRITE LATEX TABLE
// ============================================

file open myfile using "${TABLES}main_iv.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
" & \shortstack{Total \\ (1)}" ///
" & \shortstack{2007-2012 \\ (2)}" ///
" & \shortstack{2013-2018 \\ (3)}" ///
" & \shortstack{2019-2024 \\ (4)}" ///
" & \shortstack{Males \\ (5)}" ///
" & \shortstack{Females \\ (6)} \\" _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Effect of ln(homicides)" _n
file write myfile " & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6' \\" _n
file write myfile " & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6' \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ & \$`mean_4'\$ & \$`mean_5'\$ & \$`mean_6'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & `kpout1' & `kpout2' & `kpout3' & `kpout4' & `kpout5' & `kpout6' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile


// ============================================
// Do it again but for high violence municipalities only
// ============================================
destring month, replace
* Save as temporary file
tempfile sample_reg
save `sample_reg', replace

use "/Users/wernerd/Desktop/Daniel Werner/final_mun.dta", clear
destring year month municipality, replace
local top_percent = 15

* Calculate AVERAGE violence across baseline
collapse (mean) avg_hr = hr, by(municipality)

* Identify top X% based on baseline average
_pctile avg_hr, p(`=100-`top_percent'')
local violence_threshold = r(r1)

keep if avg_hr >= `violence_threshold'

keep municipality
gen high_violence_baseline = 1

tempfile baseline_list
save `baseline_list', replace

* ========================================
* APPROACH 2: TIME-VARYING (for each period)
* ========================================
use "/Users/wernerd/Desktop/Daniel Werner/final_mun.dta", clear

destring year month municipality, replace
local top_percent = 15
* Calculate average violence for Period 1: 2007-2012
preserve
keep if year >= 2007 & year <= 2012
collapse (mean) avg_violence_p1 = hr, by(municipality)

_pctile avg_violence_p1, p(`=100-`top_percent'')
local threshold_p1 = r(r1)

gen high_violence_p1 = (avg_violence_p1 >= `threshold_p1')
keep municipality high_violence_p1

tempfile period1_list
save `period1_list', replace
restore

* Calculate average violence for Period 2: 2013-2016
preserve
keep if year >= 2013 & year <= 2016
collapse (mean) avg_violence_p2 = hr, by(municipality)

_pctile avg_violence_p2, p(`=100-`top_percent'')
local threshold_p2 = r(r1)

gen high_violence_p2 = (avg_violence_p2 >= `threshold_p2')
keep municipality high_violence_p2

tempfile period2_list
save `period2_list', replace
restore

* Calculate average violence for Period 3: 2017-2024
preserve
keep if year >= 2017 & year <= 2024
collapse (mean) avg_violence_p3 = hr, by(municipality)

_pctile avg_violence_p3, p(`=100-`top_percent'')
local threshold_p3 = r(r1)

gen high_violence_p3 = (avg_violence_p3 >= `threshold_p3')
keep municipality high_violence_p3

tempfile period3_list
save `period3_list', replace
restore

* ========================================
* MERGE BOTH BACK TO INDIVIDUAL DATA
* ========================================

use `sample_reg', clear

* Merge baseline identification
merge m:1 municipality using `baseline_list'
rename _merge _merge_baseline
replace high_violence_baseline = 0 if missing(high_violence_baseline)
drop _merge_baseline

* Merge period 1 identification
merge m:1 municipality using `period1_list'
drop if _merge == 2
replace high_violence_p1 = 0 if missing(high_violence_p1)
drop _merge

* Merge period 2 identification
merge m:1 municipality using `period2_list'
drop if _merge == 2
replace high_violence_p2 = 0 if missing(high_violence_p2)
drop _merge

* Merge period 3 identification
merge m:1 municipality using `period3_list'
drop if _merge == 2
replace high_violence_p3 = 0 if missing(high_violence_p3)
drop _merge

destring year, replace
// ============================================
// BASELINE SPEC
// ============================================
preserve 
keep if high_violence_baseline == 1

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
local kp_1 = e(rkf)
quietly sum school if e(sample)
local mean_1 : display %6.3f r(mean)
restore


// ============================================
// TIME PERIOD HETEROGENEITY
// ============================================

// Period 1: 2007-2012
preserve
keep if year >= 2007 & year <= 2012 & high_violence_p1 == 1

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_2 = _b[ln_homicide]
local se_2 = _se[ln_homicide]
local N_2 = e(N)
local kp_2 = e(rkf)
quietly sum school if e(sample)
local mean_2 : display %6.3f r(mean)

restore

// Period 2: 2012-2017
preserve
keep if year >= 2013 & year <= 2016 & high_violence_p2 == 1

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_3 = _b[ln_homicide]
local se_3 = _se[ln_homicide]
local N_3 = e(N)
local kp_3 = e(rkf)
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)

restore

// Period 3: 2017-2024
preserve
keep if year >= 2017 & year <= 2024 & high_violence_p3 == 1

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_4 = _b[ln_homicide]
local se_4 = _se[ln_homicide]
local N_4 = e(N)
local kp_4 = e(rkf)
quietly sum school if e(sample)
local mean_4 : display %6.3f r(mean)

restore

// ============================================
// GENDER HETEROGENEITY
// ============================================

// Males only
preserve
keep if sex == 1 & high_violence_baseline == 1

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_5 = _b[ln_homicide]
local se_5 = _se[ln_homicide]
local N_5 = e(N)
local kp_5 = e(rkf)
quietly sum school if e(sample)
local mean_5 : display %6.3f r(mean)

restore

// Females only
preserve
keep if sex == 2 & high_violence_baseline == 1

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_6 = _b[ln_homicide]
local se_6 = _se[ln_homicide]
local N_6 = e(N)
local kp_6 = e(rkf)
quietly sum school if e(sample)
local mean_6 : display %6.3f r(mean)
restore


	

// ============================================
// BUILD TABLE
// ============================================
forvalues j = 1/6 {
    local b  = `b_`j''  
    local se = `se_`j''  
    
    * t/z statistic
    local t = abs(`b' / `se')  
    local p = 2 * normal(-`t')
    
    * stars
    local stars ""
    if (`p' < 0.10) local stars "*"
    if (`p' < 0.05) local stars "**"
    if (`p' < 0.01) local stars "***"

    * formatted numbers
    local b_tex  : display %6.3f `b'
    local se_tex : display %6.3f `se'
    local kp_tex : display %6.2f `kp_`j''
    
    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
    local kpout`j' "`kp_tex'"
    
    local N = `N_`j'' 
    * Add comma if N > 10,000
    if `N' >= 10000 {
        local Nout`j' : display %9.0fc `N'
    }
    else {
        local Nout`j' : display %9.0f `N'  
    }
}

// ============================================
// WRITE LATEX TABLE
// ============================================

file open myfile using "${TABLES}high_violence_iv.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
" & \shortstack{Total \\ (1)}" ///
" & \shortstack{2007-2012 \\ (2)}" ///
" & \shortstack{2013-2018 \\ (3)}" ///
" & \shortstack{2019-2024 \\ (4)}" ///
" & \shortstack{Males \\ (5)}" ///
" & \shortstack{Females \\ (6)} \\" _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Effect of ln(homicides)" _n
file write myfile " & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6' \\" _n
file write myfile " & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6' \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ & \$`mean_4'\$ & \$`mean_5'\$ & \$`mean_6'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & `kpout1' & `kpout2' & `kpout3' & `kpout4' & `kpout5' & `kpout6' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile



