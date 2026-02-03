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
drop if pop_tot < 10000
drop if _merge != 3
cap drop _merge

* Drop primary school children
drop if age >= 6 & age <=11

* -----------------------------------------------------------------------------
* 2) Generate necessary variables
* -----------------------------------------------------------------------------

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
gen ln_hom_lag1 = log(1+hr_lag1)
gen ln_hom_lag2 = log(1+hr_lag2)
gen ln_hom_lag3 = log(1+hr_lag3)


* -----------------------------------------------------------------------------
* 3) Main Specification
* -----------------------------------------------------------------------------

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
quietly sum school if e(sample)
local mean_3 : display %6.3f r(mean)


* -----------------------------------------------------------------------------
* 4) Time Periods
* -----------------------------------------------------------------------------

destring year, replace

* Period 1: 2007-2012
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

local b_4 = _b[ln_homicide]
local se_4 = _se[ln_homicide]
local N_4 = e(N)
local kp_4 = e(rkf)
quietly sum school if e(sample)
local mean_4 : display %6.3f r(mean)

restore

* Period 2: 2013-2017
preserve
keep if year >= 2013 & year <= 2018

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

* Period 3: 2019-2024
preserve
keep if year >= 2019 & year <= 2024

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

* -----------------------------------------------------------------------------
* 5) Gender -- Only want coefficients and SE (no table presented)
* -----------------------------------------------------------------------------

* Males only
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

local b_7 = _b[ln_homicide]
local se_7 = _se[ln_homicide]
local N_7 = e(N)
local kp_7 = e(rkf)
restore

* Females only
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

local b_8 = _b[ln_homicide]
local se_8 = _se[ln_homicide]
local N_8 = e(N)
local kp_8 = e(rkf)
restore

* -----------------------------------------------------------------------------
* 6) Schooling cohort heterogeneity
* -----------------------------------------------------------------------------

* Middle School
preserve
keep if age >= 12 & age <=14
ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first
		
local b_9 = _b[ln_homicide]
local se_9 = _se[ln_homicide]
local N_9 = e(N)
local kp_9 = e(rkf)
quietly sum school if e(sample)
local mean_9 : display %6.3f r(mean)
restore

* High School
preserve
keep if age >= 15 & age <=18
ivreghdfe dropout hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
		hh_n_employed_adults hh_n_other_children hh_children /// 
		ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
		avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
		avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
		avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
		pct_pop_male pct_pop_student (ln_homicide = iv), /// 
        absorb(i.month_year_date i.id) cluster(id) first
		
local b_10 = _b[ln_homicide]
local se_10 = _se[ln_homicide]
local N_10 = e(N)
local kp_10 = e(rkf)
quietly sum school if e(sample)
local mean_10 : display %6.3f r(mean)
restore

* -----------------------------------------------------------------------------
* 7) Build Tables
* -----------------------------------------------------------------------------
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
" & \shortstack{OLS \\ (1)}" ///
" & \shortstack{Minimal \\ controls \\ (2)}" ///
" & \shortstack{Primary \\ Specification \\  (3)} \\"  _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "\$ \hat{\beta}_2 \$" _n
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

// ============================================
// WRITE LATEX TABLE (Additional Specifications)
// ============================================

file open myfile using "${TABLES}het_iv.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
" & \shortstack{Full \\ sample \\ (1)}" ///
" & \shortstack{2007 - 2012 \\ (2)}" ///
" & \shortstack{2013 - 2018  \\  (3)} " ///
" & \shortstack{2019 - 2024  \\  (4)} " ///
" & \shortstack{Secondary  \\ school \\  (5)} " ///
" & \shortstack{High  \\ school \\  (6)} \\ " _n
file write myfile "\hline" _n

* Coefficient row
file write myfile "\$ \hat{\beta}_2 \$" _n
file write myfile " & `coef3' & `coef4' & `coef5' & `coef6' & `coef9' & `coef10'  \\" _n
file write myfile " & `seout3' & `seout4' & `seout5' & `seout6' & `seout9' & `seout10'    \\" _n

* Mean of dependent variable row
file write myfile "\hline" _n
file write myfile "Mean of school enrollment" _n
file write myfile " & \$`mean_3'\$ & \$`mean_4'\$ & \$`mean_5'\$  & \$`mean_6'\$ & \$`mean_9'\$ & \$`mean_10'\$ \\" _n

* Kleibergen-Paap F-stat row
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " &`kpout3' &`kpout4' &`kpout5' &`kpout6' &`kpout9' &`kpout10' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `Nout3' & `Nout4' & `Nout5' & `Nout6' & `Nout9' & `Nout10'  \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile

* -----------------------------------------------------------------------------
* 8) Save scalars
* -----------------------------------------------------------------------------
file open scalars using "${TABLES}main_analysis_scalars.tex", write replace

file write scalars "\newcommand{\MaleBeta}{" `coef7' "}" _n
file write scalars "\newcommand{\MaleSE}{" `seout7' "}" _n
file write scalars "\newcommand{\FemaleBeta}{" `coef8' "}" _n
file write scalars "\newcommand{\FemaleSE}{" `seout8' "}" _n
file write scalars "\newcommand{\TotalBeta}{" `coef3' "}" _n
file write scalars "\newcommand{\RecentBeta}{" `coef6' "}" _n
file write scalars "\newcommand{\SecondaryBeta}{" `coef9' "}" _n

file close scalars
