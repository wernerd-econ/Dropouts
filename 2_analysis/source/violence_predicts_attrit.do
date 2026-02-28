*******************************************************************************
* This script runs a robustness check ensuring violence does not predict  
*  survey attrition
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


********************************************************************************
* PART 1: Robustness Table (attrition)
********************************************************************************

use "/Users/wernerd/Desktop/Daniel Werner/final_indiv.dta", clear 

* Bring in municipal controls
tempfile indiv_temp
save `indiv_temp', replace

use "/Users/wernerd/Desktop/Daniel Werner/final_mun.dta", clear
keep municipality year month avg_* employment_rate
tempfile muni_temp
save `muni_temp', replace

use `indiv_temp', clear
merge m:1 municipality year month using `muni_temp'
drop if _merge != 3
cap drop _merge

* Generate necessary variables
destring municipality, replace 
gen month_year_date = date(year_month, "YM")
format month_year_date %tm
gen ln_homicide = log(1+hr)
gen ln_hom_lag1 = log(1+hr_lag1)
gen ln_hom_lag2 = log(1+hr_lag2)
gen ln_hom_lag3 = log(1+hr_lag3)
drop if pop_tot < 15000
drop if age >= 6 & age <=11
gen iv = cs_big * d_to_pc
destring year month, replace

* Define control list
local controls hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
    hh_n_employed_adults hh_n_other_children hh_children /// 
    ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
    avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
    avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
    avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
    pct_pop_male pct_pop_student

destring total_n n_ent, replace
drop if total_n > 5
* Create attrition variable
gen attrition = (n_ent == total_n & total_n < 5)

* ============================================================================
* Column 1: Whole sample
* ============================================================================
ivreghdfe attrition `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id)
    
local b_1 = _b[ln_homicide]
local se_1 = _se[ln_homicide]
local N_1 = e(N)
local kp_1 = e(rkf)
quietly sum attrition if e(sample)
local mean_1 : display %6.3f r(mean)

* ============================================================================
* Column 2: 2007-2012
* ============================================================================
preserve
keep if year >= 2007 & year <= 2012

ivreghdfe attrition `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id)
    
local b_2 = _b[ln_homicide]
local se_2 = _se[ln_homicide]
local N_2 = e(N)
local kp_2 = e(rkf)
quietly sum attrition if e(sample)
local mean_2 : display %6.3f r(mean)

restore

* ============================================================================
* Column 3: 2013-2016
* ============================================================================
preserve
keep if year >= 2013 & year <= 2016

ivreghdfe attrition `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id)
    
local b_3 = _b[ln_homicide]
local se_3 = _se[ln_homicide]
local N_3 = e(N)
local kp_3 = e(rkf)
quietly sum attrition if e(sample)
local mean_3 : display %6.3f r(mean)

restore

* ============================================================================
* Column 4: 2017-2024
* ============================================================================
preserve
keep if year >= 2017 & year <= 2024

ivreghdfe attrition `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id)
    
local b_4 = _b[ln_homicide]
local se_4 = _se[ln_homicide]
local N_4 = e(N)
local kp_4 = e(rkf)
quietly sum attrition if e(sample)
local mean_4 : display %6.3f r(mean)

restore

// ============================================
// Prepare values for table display
// ============================================

forvalues j = 1/4 {
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
// WRITE LATEX TABLE (Main Spec)
// ============================================

file open myfile using "${TABLES}attrition_robustness.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c }" _n
file write myfile "\hline\hline" _n
file write myfile ///
" {\small \textit{Outcome: Attrition}} & \shortstack{Whole sample \\ 2007-2024}" ///
" & \shortstack{War on drugs \\ 2007-2012}" ///
" & \shortstack{Interim \\ 2013-2016}" ///
" & \shortstack{Resurgence \\ 2017-2024} \\"  _n
file write myfile " & (1) & (2) & (3) & (4) \\" _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1' & `coef2' & `coef3' & `coef4'  \\" _n
file write myfile " & `seout1' & `seout2' & `seout3' & `seout4'  \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean attrition rate" _n
file write myfile " & \$`mean_1'\$ & \$`mean_2'\$ & \$`mean_3'\$ & \$`mean_4'\$  \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & `kpout1' & `kpout2' & `kpout3' & `kpout4' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout1' & `Nout2' & `Nout3' & `Nout4' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile