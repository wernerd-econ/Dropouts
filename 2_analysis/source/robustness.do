*******************************************************************************
* This script runs the robustness IV analysis for the paper and produces the  
* robustness regression tables found in the appendix of the paper 
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


********************************************************************************
* PART 1: Robustness Table
********************************************************************************

use "/Users/wernerd/Desktop/Daniel Werner/final_indiv.dta", clear 
destring total_n, replace

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
destring year month, replace

* Define control list
local controls hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
    hh_n_employed_adults hh_n_other_children hh_children /// 
    ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
    avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children /// 
    avg_income avg_hincome employment_rate avg_hh_n_employed_adults /// 
    avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers /// 
    pct_pop_male pct_pop_student

* ============================================================================
* ROW 1: Main specification (baseline)
* ============================================================================
preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc

* Whole sample
ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_1_1 = _b[ln_homicide]
local se_1_1 = _se[ln_homicide]

* 2007-2012
keep if year >= 2007 & year <= 2012
ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_1_2 = _b[ln_homicide]
local se_1_2 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc

* 2013-2016
keep if year >= 2013 & year <= 2016
ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_1_3 = _b[ln_homicide]
local se_1_3 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc

* 2017-2024
keep if year >= 2017 & year <= 2024
ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_1_4 = _b[ln_homicide]
local se_1_4 = _se[ln_homicide]
restore

* ============================================================================
* ROW 2: No 5-quarter restriction
* ============================================================================
* Note: Would need to load data without this restriction
* For now, using same data but you'd load ENOE_panel without cohort restriction

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
gen iv = cs_big * d_to_pc

* Whole sample
ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_2_1 = _b[ln_homicide]
local se_2_1 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
gen iv = cs_big * d_to_pc
keep if year >= 2007 & year <= 2012

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_2_2 = _b[ln_homicide]
local se_2_2 =_se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
gen iv = cs_big * d_to_pc
keep if year >= 2013 & year <= 2016

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_2_3 =_b[ln_homicide]
local se_2_3 =_se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
gen iv = cs_big * d_to_pc
keep if year >= 2017 & year <= 2024

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_2_4 = _b[ln_homicide]
local se_2_4 = _se[ln_homicide]
restore

* ============================================================================
* ROW 3: Different population threshold (10,000 instead of 15,000)
* ============================================================================
preserve
drop if pop_tot < 10000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_3_1 = _b[ln_homicide]
local se_3_1 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 10000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc
keep if year >= 2007 & year <= 2012

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_3_2 = _b[ln_homicide]
local se_3_2 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 10000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc
keep if year >= 2013 & year <= 2016

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_3_3 = _b[ln_homicide]
local se_3_3 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 10000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc
keep if year >= 2017 & year <= 2024

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_3_4 = _b[ln_homicide]
local se_3_4 = _se[ln_homicide]
restore

* ============================================================================
* ROW 4: All cocaine seizures (not just large coastal)
* ============================================================================
preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = ts * d_to_pc  // Total seizures instead of cs_big

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_4_1 = _b[ln_homicide]
local se_4_1 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = ts * d_to_pc
keep if year >= 2007 & year <= 2012

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_4_2 = _b[ln_homicide]
local se_4_2 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = ts * d_to_pc
keep if year >= 2013 & year <= 2016

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_4_3 = _b[ln_homicide]
local se_4_3 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = ts * d_to_pc
keep if year >= 2017 & year <= 2024

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_4_4 = _b[ln_homicide]
local se_4_4 = _se[ln_homicide]
restore


* ============================================================================
* ROW 5: Drop COVID period (2020)
* ============================================================================
preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
drop if year == 2020
gen iv = cs_big * d_to_pc

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_5_1 = _b[ln_homicide]
local se_5_1 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
drop if year == 2020
gen iv = cs_big * d_to_pc
keep if year >= 2007 & year <= 2012

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_5_2 = _b[ln_homicide]
local se_5_2 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
drop if year == 2020
gen iv = cs_big * d_to_pc
keep if year >= 2013 & year <= 2016

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_5_3 = _b[ln_homicide]
local se_5_3 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
drop if year == 2020
gen iv = cs_big * d_to_pc
keep if year >= 2017 & year <= 2024

ivreghdfe dropout `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_5_4 = _b[ln_homicide]
local se_5_4 = _se[ln_homicide]
restore

* ============================================================================
* ROW 7: School enrollment as outcome (instead of dropout)
* ============================================================================
preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc

ivreghdfe school `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_6_1 = _b[ln_homicide]
local se_6_1 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc
keep if year >= 2007 & year <= 2012

ivreghdfe school `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_6_2 = _b[ln_homicide]
local se_6_2 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc
keep if year >= 2013 & year <= 2016

ivreghdfe school `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_6_3 = _b[ln_homicide]
local se_6_3 = _se[ln_homicide]
restore

preserve
drop if pop_tot < 15000
drop if age >= 6 & age <=11
drop if total_n != 5
gen iv = cs_big * d_to_pc
keep if year >= 2017 & year <= 2024

ivreghdfe school `controls' (ln_homicide = iv), ///
    absorb(i.month_year_date i.id) cluster(id) first
local b_6_4 = _b[ln_homicide]
local se_6_4 = _se[ln_homicide]
restore

* ============================================================================
* Format coefficients and standard errors
* ============================================================================
forvalues i = 1/6 {
    forvalues j = 1/4 {
        local b  = `b_`i'_`j''  
        local se = `se_`i'_`j''  
        
        * t/z statistic and p-value
        local t = abs(`b' / `se')  
        local p = 2 * normal(-`t')
        
        * Stars
        local stars ""
        if (`p' < 0.10) local stars "*"
        if (`p' < 0.05) local stars "**"
        if (`p' < 0.01) local stars "***"

        * Formatted numbers
        local b_tex  : display %6.3f `b'
        local se_tex : display %6.3f `se'

        * Store LaTeX-ready output
        local coef`i'_`j' "\$`b_tex'^{`stars'}\$"
        local seout`i'_`j' "(`se_tex')"
    }
}

* ============================================================================
* Write LaTeX table
* ============================================================================
file open myfile using "${TABLES}robustness_iv.tex", write replace

* Header
file write myfile "\begin{tabular}{l c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile " & Full Sample & War on drugs & Interim & Resurgence  \\" _n
file write myfile " & (1) & (2) & (3) & (4) \\" _n
file write myfile "\hline" _n

* Row 1: Main specification
file write myfile "Main specification" _n
file write myfile " & `coef1_1' & `coef1_2' & `coef1_3' & `coef1_4' \\" _n
file write myfile " & `seout1_1' & `seout1_2' & `seout1_3' & `seout1_4' \\" _n

* Row 2: No 5-quarter restriction
///file write myfile "No 5 quarter restriction" _n
file write myfile " & `coef2_1' & `coef2_2' & `coef2_3' & `coef2_4' \\" _n
file write myfile " & `seout2_1' & `seout2_2' & `seout2_3' & `seout2_4' \\" _n

* Row 3: Different population threshold
file write myfile "Population threshold: 10,000" _n
file write myfile " & `coef3_1' & `coef3_2' & `coef3_3' & `coef3_4' \\" _n
file write myfile " & `seout3_1' & `seout3_2' & `seout3_3' & `seout3_4' \\" _n

* Row 4: All cocaine seizures
file write myfile "All cocaine seizures" _n
file write myfile " & `coef4_1' & `coef4_2' & `coef4_3' & `coef4_4' \\" _n
file write myfile " & `seout4_1' & `seout4_2' & `seout4_3' & `seout4_4' \\" _n

* Row 6: Drop COVID
file write myfile "Drop COVID (2020)" _n
file write myfile " & `coef5_1' & `coef5_2' & `coef5_3' & `coef5_4' \\" _n
file write myfile " & `seout5_1' & `seout5_2' & `seout5_3' & `seout5_4' \\" _n

* Row 7: School enrollment outcome
file write myfile "Outcome: School enrollment" _n
file write myfile " & `coef6_1' & `coef6_2' & `coef6_3' & `coef6_4' \\" _n
file write myfile " & `seout6_1' & `seout6_2' & `seout6_3' & `seout6_4' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile








