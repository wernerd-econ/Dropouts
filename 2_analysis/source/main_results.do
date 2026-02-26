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
global FIGURES "../output/Figures/"
capture mkdir "${TABLES}"
capture mkdir "${FIGURES}"



use "/Users/wernerd/Desktop/Daniel Werner/final_indiv.dta", clear 

* -----------------------------------------------------------------------------
* GRAB THE MUNICIPAL DATA AND BRING IN THE MUNICIPAL LEVEL CONTROLS 
* -----------------------------------------------------------------------------

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
drop if pop_tot < 15000
drop if _merge != 3
cap drop _merge

* Drop primary school children
drop if age >= 6 & age <=11

* -----------------------------------------------------------------------------
* Generate necessary variables
* -----------------------------------------------------------------------------

* Instrument 
gen iv = cs_big * d_to_pc

* Treatment
gen ln_homicide = log(1+hr)


* Controls
destring municipality, replace 
gen month_year_date = date(year_month, "YM")
format month_year_date %tm
gen ln_hom_lag1 = log(1+hr_lag1)
gen ln_hom_lag2 = log(1+hr_lag2)
gen ln_hom_lag3 = log(1+hr_lag3)

********************************************************************************
* PART 1: First stage scalars 
********************************************************************************

* Run first stage separately to get coefficients
reghdfe ln_homicide iv hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, ///
        absorb(i.month_year_date i.id) cluster(id)

local fs_coef_whole = _b[iv]
local fs_se_whole = _se[iv]

********************************************************************************
* PART 2: Main specification 
********************************************************************************

* OLS
reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
quietly sum school if e(sample)
local mean_1 : display %6.3f r(mean)

* IV minimal controls 
ivreghdfe dropout ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot ///
		  (ln_homicide = iv), /// 
          absorb(i.month_year_date i.id) cluster(id) first
		  
local b_2 = _b[ln_homicide]
local se_2 = _se[ln_homicide]
local N_2 = e(N)
local kp_2 = e(rkf)
quietly sum school if e(sample)
local mean_2 : display %6.3f r(mean)

* IV main specification	
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
local k_stat_whole = e(rkf)
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)

// ============================================
// Prepare values for table display
// ============================================

forvalues j = 1/3 {
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
	if (`j' != 1){
		local kp_tex : display %6.2f `kp_`j''
    }
    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
	if (`j' != 1){
		local kpout`j' "`kp_tex'"
	}
    
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
// WRITE LATEX TABLE (Main Spec)
// ============================================

file open myfile using "${TABLES}main_iv.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c }" _n
file write myfile "\hline\hline" _n
file write myfile ///
" {\small \textit{Outcome: Dropout}} & \shortstack{OLS \\ (1)}" ///
" & \shortstack{Minimal \\ controls \\ (2)}" ///
" & \shortstack{Primary \\ Specification \\  (3)} \\"  _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1' & `coef2' & `coef3'  \\" _n
file write myfile " & `seout1' & `seout2' & `seout3'  \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & – & `kpout2' & `kpout3' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile


********************************************************************************
* PART 3: Time period analysis
********************************************************************************

destring year, replace

* Period 1: 2007-2012
preserve
keep if year >= 2007 & year <= 2012

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
quietly sum school if e(sample)
local mean_1 : display %6.3f r(mean)

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

* Period 2: 2013-2016
preserve
keep if year >= 2013 & year <= 2016

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_3 = _b[ln_homicide]
local se_3 = _se[ln_homicide]
local N_3 = e(N)
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)

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

* Period 3: 2017-2024
preserve
keep if year >= 2017 & year <= 2024

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_5 = _b[ln_homicide]
local se_5 = _se[ln_homicide]
local N_5 = e(N)
quietly sum school if e(sample)
local mean_5 : display %6.3f r(mean)

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_6 = _b[ln_homicide]
local coef_respike = _b[ln_homicide]
local se_6 = _se[ln_homicide]
local N_6 = e(N)
local kp_6 = e(rkf)
quietly sum school if e(sample)
local mean_6 : display %6.3f r(mean)

restore

// ============================================
// Prepare values for table display
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
	if (`j' != 1){
		local kp_tex : display %6.2f `kp_`j''
    }
    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
	if (`j' == 2 | `j' == 4 | `j' == 6){
		local kpout`j' "`kp_tex'"
	}
    
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
// WRITE LATEX TABLE (Time Period Specifications)
// ============================================

file open myfile using "${TABLES}period_iv.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile " {\small \textit{Outcome: Dropout}} & \multicolumn{2}{c}{2007-2012} & \multicolumn{2}{c}{2013-2016} & \multicolumn{2}{c}{2017-2024} \\" _n
file write myfile "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7}" _n
file write myfile " & OLS & IV & OLS & IV & OLS & IV \\" _n
file write myfile " & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6' \\" _n
file write myfile " & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6' \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ & \$`mean_4'\$ & \$`mean_5'\$ & \$`mean_6'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & -- & `kpout2' & -- & `kpout4' & -- & `kpout6' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile

********************************************************************************
* PART 5: Subgroup analysis
********************************************************************************

* Middle School
preserve
keep if age >= 12 & age <=14 & year >= 2017 & year <= 2024

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
quietly sum school if e(sample)
local mean_1 : display %6.3f r(mean)

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

* High School
preserve
keep if age >= 15 & age <=18 & year >= 2017 & year <= 2024

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_3 = _b[ln_homicide]
local se_3 = _se[ln_homicide]
local N_3 = e(N)
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first
		
local b_4 = _b[ln_homicide]
local coef_high = _b[ln_homicide]
local se_4 = _se[ln_homicide]
local N_4 = e(N)
local kp_4 = e(rkf)
quietly sum school if e(sample)
local mean_4 : display %6.3f r(mean)
restore


* Males only
preserve
keep if sex == 1 & year >= 2017 & year <= 2024

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_5 = _b[ln_homicide]
local se_5 = _se[ln_homicide]
local N_5 = e(N)
quietly sum school if e(sample)
local mean_5 : display %6.3f r(mean)

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_6 = _b[ln_homicide]
local coef_male = _b[ln_homicide]
local se_6 = _se[ln_homicide]
local N_6 = e(N)
local kp_6 = e(rkf)
quietly sum school if e(sample)
local mean_6 : display %6.3f r(mean)
restore

* Females only
preserve
keep if sex == 2 & year >= 2017 & year <= 2024

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_7 = _b[ln_homicide]
local se_7 = _se[ln_homicide]
local N_7 = e(N)
quietly sum school if e(sample)
local mean_7 : display %6.3f r(mean)

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_8 = _b[ln_homicide]
local se_8 = _se[ln_homicide]
local N_8 = e(N)
local kp_8 = e(rkf)
quietly sum school if e(sample)
local mean_8 : display %6.3f r(mean)
restore


// ============================================
// Prepare values for table display
// ============================================

forvalues j = 1/8 {
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
	if (`j' != 1){
		local kp_tex : display %6.2f `kp_`j''
    }
    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
	if (`j' == 2 | `j' == 4 | `j' == 6 | `j' == 8){
		local kpout`j' "`kp_tex'"
	}
    
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
// WRITE LATEX TABLE (Time Period Specifications)
// ============================================

file open myfile using "${TABLES}subgroup_iv_respike.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile "{\small \textit{Outcome: Dropout}}  & \multicolumn{2}{c}{Secondary school} & \multicolumn{2}{c}{High school} & \multicolumn{2}{c}{Male} & \multicolumn{2}{c}{Female} \\" _n
file write myfile "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}" _n
file write myfile " & OLS & IV & OLS & IV & OLS & IV & OLS & IV\\" _n
file write myfile " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6' & `coef7' & `coef8' \\" _n
file write myfile " & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6' & `seout7' & `seout8' \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ & \$`mean_4'\$ & \$`mean_5'\$ & \$`mean_6'\$ & \$`mean_7'\$ & \$`mean_8'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & -- & `kpout2' & -- & `kpout4' & -- & `kpout6' & -- & `kpout8' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' & `Nout7' & `Nout8' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile


********************************************************************************
* PART 6: Appendix tables
********************************************************************************

********************************************************************************
* PART 6 (a): Subgroup analysis on whole sample
********************************************************************************
* Middle School
preserve
keep if age >= 12 & age <=14 

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
quietly sum school if e(sample)
local mean_1 : display %6.3f r(mean)

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

* High School
preserve
keep if age >= 15 & age <=18 

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_3 = _b[ln_homicide]
local se_3 = _se[ln_homicide]
local N_3 = e(N)
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)

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


* Males only
preserve
keep if sex == 1 

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_5 = _b[ln_homicide]
local se_5 = _se[ln_homicide]
local N_5 = e(N)
quietly sum school if e(sample)
local mean_5 : display %6.3f r(mean)

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

* Females only
preserve
keep if sex == 2 

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_7 = _b[ln_homicide]
local se_7 = _se[ln_homicide]
local N_7 = e(N)
quietly sum school if e(sample)
local mean_7 : display %6.3f r(mean)

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_8 = _b[ln_homicide]
local se_8 = _se[ln_homicide]
local N_8 = e(N)
local kp_8 = e(rkf)
quietly sum school if e(sample)
local mean_8 : display %6.3f r(mean)
restore


// ============================================
// Prepare values for table display
// ============================================

forvalues j = 1/8 {
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
	if (`j' != 1){
		local kp_tex : display %6.2f `kp_`j''
    }
    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
	if (`j' == 2 | `j' == 4 | `j' == 6 | `j' == 8){
		local kpout`j' "`kp_tex'"
	}
    
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
// WRITE LATEX TABLE (Time Period Specifications)
// ============================================

file open myfile using "${TABLES}subgroup_iv_whole_samp.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile "{\small \textit{Outcome: Dropout}}  & \multicolumn{2}{c}{Secondary school} & \multicolumn{2}{c}{High school} & \multicolumn{2}{c}{Male} & \multicolumn{2}{c}{Female} \\" _n
file write myfile "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}" _n
file write myfile " & OLS & IV & OLS & IV & OLS & IV & OLS & IV\\" _n
file write myfile " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6' & `coef7' & `coef8' \\" _n
file write myfile " & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6' & `seout7' & `seout8' \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ & \$`mean_4'\$ & \$`mean_5'\$ & \$`mean_6'\$ & \$`mean_7'\$ & \$`mean_8'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & -- & `kpout2' & -- & `kpout4' & -- & `kpout6' & -- & `kpout8' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' & `Nout7' & `Nout8' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile

********************************************************************************
* PART 6 (b): Subgroup analysis within 2007-2012
********************************************************************************
* Middle School
preserve
keep if age >= 12 & age <=14 & year >= 2007 & year <= 2012

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
quietly sum school if e(sample)
local mean_1 : display %6.3f r(mean)

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

* High School
preserve
keep if age >= 15 & age <=18 & year >= 2007 & year <= 2012

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_3 = _b[ln_homicide]
local se_3 = _se[ln_homicide]
local N_3 = e(N)
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)

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


* Males only
preserve
keep if sex == 1 & year >= 2007 & year <= 2012

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_5 = _b[ln_homicide]
local se_5 = _se[ln_homicide]
local N_5 = e(N)
quietly sum school if e(sample)
local mean_5 : display %6.3f r(mean)

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

* Females only
preserve
keep if sex == 2 & year >= 2007 & year <= 2012

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_7 = _b[ln_homicide]
local se_7 = _se[ln_homicide]
local N_7 = e(N)
quietly sum school if e(sample)
local mean_7 : display %6.3f r(mean)

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_8 = _b[ln_homicide]
local se_8 = _se[ln_homicide]
local N_8 = e(N)
local kp_8 = e(rkf)
quietly sum school if e(sample)
local mean_8 : display %6.3f r(mean)
restore


// ============================================
// Prepare values for table display
// ============================================

forvalues j = 1/8 {
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
	if (`j' != 1){
		local kp_tex : display %6.2f `kp_`j''
    }
    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
	if (`j' == 2 | `j' == 4 | `j' == 6 | `j' == 8){
		local kpout`j' "`kp_tex'"
	}
    
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
// WRITE LATEX TABLE (Time Period Specifications)
// ============================================

file open myfile using "${TABLES}subgroup_iv_war.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile "{\small \textit{Outcome: Dropout}}  & \multicolumn{2}{c}{Secondary school} & \multicolumn{2}{c}{High school} & \multicolumn{2}{c}{Male} & \multicolumn{2}{c}{Female} \\" _n
file write myfile "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}" _n
file write myfile " & OLS & IV & OLS & IV & OLS & IV & OLS & IV\\" _n
file write myfile " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6' & `coef7' & `coef8' \\" _n
file write myfile " & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6' & `seout7' & `seout8' \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ & \$`mean_4'\$ & \$`mean_5'\$ & \$`mean_6'\$ & \$`mean_7'\$ & \$`mean_8'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & -- & `kpout2' & -- & `kpout4' & -- & `kpout6' & -- & `kpout8' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' & `Nout7' & `Nout8' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile

********************************************************************************
* PART 6 (c): Subgroup analysis on 2013-2016
********************************************************************************
* Middle School
preserve
keep if age >= 12 & age <=14 & year >= 2013 & year <= 2016

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
quietly sum school if e(sample)
local mean_1 : display %6.3f r(mean)

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

* High School
preserve
keep if age >= 15 & age <=18 & year >= 2013 & year <= 2016

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_3 = _b[ln_homicide]
local se_3 = _se[ln_homicide]
local N_3 = e(N)
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)

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


* Males only
preserve
keep if sex == 1 & year >= 2013 & year <= 2016

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_5 = _b[ln_homicide]
local se_5 = _se[ln_homicide]
local N_5 = e(N)
quietly sum school if e(sample)
local mean_5 : display %6.3f r(mean)

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

* Females only
preserve
keep if sex == 2 & year >= 2013 & year <= 2016

reghdfe dropout ln_homicide hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student, /// 
        absorb(i.month_year_date i.id) cluster(id) 

local b_7 = _b[ln_homicide]
local se_7 = _se[ln_homicide]
local N_7 = e(N)
quietly sum school if e(sample)
local mean_7 : display %6.3f r(mean)

ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first

local b_8 = _b[ln_homicide]
local se_8 = _se[ln_homicide]
local N_8 = e(N)
local kp_8 = e(rkf)
quietly sum school if e(sample)
local mean_8 : display %6.3f r(mean)
restore


// ============================================
// Prepare values for table display
// ============================================

forvalues j = 1/8 {
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
	if (`j' != 1){
		local kp_tex : display %6.2f `kp_`j''
    }
    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
	if (`j' == 2 | `j' == 4 | `j' == 6 | `j' == 8){
		local kpout`j' "`kp_tex'"
	}
    
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
// WRITE LATEX TABLE (Time Period Specifications)
// ============================================

file open myfile using "${TABLES}subgroup_iv_interim.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile "{\small \textit{Outcome: Dropout}}  & \multicolumn{2}{c}{Secondary school} & \multicolumn{2}{c}{High school} & \multicolumn{2}{c}{Male} & \multicolumn{2}{c}{Female} \\" _n
file write myfile "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}" _n
file write myfile " & OLS & IV & OLS & IV & OLS & IV & OLS & IV\\" _n
file write myfile " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6' & `coef7' & `coef8' \\" _n
file write myfile " & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6' & `seout7' & `seout8' \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ & \$`mean_4'\$ & \$`mean_5'\$ & \$`mean_6'\$ & \$`mean_7'\$ & \$`mean_8'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & -- & `kpout2' & -- & `kpout4' & -- & `kpout6' & -- & `kpout8' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' & `Nout7' & `Nout8' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile


* Calculate a few more scalars

use "/Users/wernerd/Desktop/Daniel Werner/homicides.dta", clear 

* Calculate SD across all municipality-month observations
summarize hr
local hr_sd = r(sd)

destring year, replace 
summarize hr if year >= 2017 & year <= 2024
local hr_mean_17124 = r(mean)

local delta_log = ln(1 + `hr_mean_17124' + `hr_sd') - ln(1 + `hr_mean_17124')

local effect_1sd_resurge = `coef_respike' * `delta_log'
local effect_1sd_resurge_high = `coef_high' * `delta_log'
local effect_1sd_resurge_male = `coef_male' * `delta_log'

use "/Users/wernerd/Desktop/Daniel Werner/seizure_data.dta", clear 
summarize cs_big
local cs_mean = r(mean)

use "/Users/wernerd/Desktop/Daniel Werner/final_geo.dta", clear 
summarize d_to_pc
local sd_d_to_pc = r(sd)

local delta_log_seiz = -1 * `sd_d_to_pc' * `fs_coef_whole' * `cs_mean'
local pct_effect_100km = exp(`delta_log_seiz') - 1

* -----------------------------------------------------------------------------
* 1) Format locals for LaTeX output
* -----------------------------------------------------------------------------
local fs_coef_fmt                : display %12.10f `fs_coef_whole'
local fs_se_fmt                  : display %12.10f `fs_se_whole'
local k_stat_fmt                 : display %6.2f   `k_stat_whole'
local respike_coef_fmt            : display %5.3f   `coef_respike'
local high_coef_fmt          : display %5.3f   `coef_high'
local male_coef_fmt               : display %5.3f   `coef_male'
local hr_sd_fmt                   : display %4.2f   `hr_sd'
local sd_effect_respike_fmt       : display %5.3f   `effect_1sd_resurge'
local sd_effect_respike_high_fmt   : display %5.3f   `effect_1sd_resurge_high'
local sd_effect_respike_male_fmt  : display %5.3f   `effect_1sd_resurge_male'
local dist_first_stage_fmt        : display %12.10f `pct_effect_100km'
local sd_distance_fmt             : display %4.0f `sd_d_to_pc'

* -----------------------------------------------------------------------------
* 2) Write LaTeX scalars
* -----------------------------------------------------------------------------
file open scalars using "${TABLES}main_analysis_scalars.tex", write replace

file write scalars "\newcommand{\FirstStageCoef}{ `fs_coef_fmt' }" _n
file write scalars "\newcommand{\FirstStageSe}{ `fs_se_fmt' }" _n
file write scalars "\newcommand{\Fstat}{ `k_stat_fmt' }" _n
file write scalars "\newcommand{\RespikeCoef}{ `respike_coef_fmt' }" _n
file write scalars "\newcommand{\HighCoef}{ `high_coef_fmt' }" _n
file write scalars "\newcommand{\MaleCoef}{ `male_coef_fmt' }" _n
file write scalars "\newcommand{\MunicipalHRSD}{ `hr_sd_fmt' }" _n
file write scalars "\newcommand{\sdEffectRespike}{ `sd_effect_respike_fmt' }" _n
file write scalars "\newcommand{\sdEffectRespikeHigh}{ `sd_effect_respike_high_fmt' }" _n
file write scalars "\newcommand{\sdEffectRespikeMale}{ `sd_effect_respike_male_fmt' }" _n
file write scalars "\newcommand{\DistanceFirstStageEffect}{ `dist_first_stage_fmt' }" _n
file write scalars "\newcommand{\DistanceSd}{ `sd_distance_fmt' }" _n

file close scalars





