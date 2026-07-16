*******************************************************************************
* This script runs the reviewer-requested robustness check that replaces the
* dropout outcome with adolescent employment outcomes in the IV design:
*   Panel A: employed (clase2 == 1, poblacion ocupada -- extensive margin)
*   Panel B: weekly hours worked (hrsocup; zeros for non-workers, so this
*            captures total labor supply, not just the intensive margin)
* Produces employment_iv.tex (monthly) and employment_iv_quarterly.tex
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
* PART 1: Monthly analysis
********************************************************************************

use "../input/final_indiv.dta", clear
destring total_n, replace
drop if total_n != 5

* Bring in municipal controls
tempfile indiv_temp
save `indiv_temp', replace

use "../input/final_mun.dta", clear
keep municipality year month avg_* employment_rate
tempfile muni_temp
save `muni_temp', replace

use `indiv_temp', clear
merge m:1 municipality year month using `muni_temp', keep(match) nogen

* Same sample restrictions as main_results.do
drop if pop_tot < 15000
drop if age >= 6 & age <= 11

* Generate necessary variables
gen iv = cs_big * d_to_pc
gen ln_homicide = log(1+hr)
destring municipality, replace
gen month_year_date = date(year_month, "YM")
format month_year_date %tm
gen ln_hom_lag1 = log(1+hr_lag1)
gen ln_hom_lag2 = log(1+hr_lag2)
gen ln_hom_lag3 = log(1+hr_lag3)
destring year, replace

* Employment outcome straight from clase2 (poblacion ocupada); ocupados are a
* subset of the PEA, so this must coincide with employed = clase1==1 & clase2==1
gen emp = clase2 == 1
assert emp == employed

* Define control list (same as robustness.do)
local controls hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
    hh_n_employed_adults hh_n_other_children hh_children ///
    ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
    avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children ///
    avg_income avg_hincome employment_rate avg_hh_n_employed_adults ///
    avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers ///
    pct_pop_male pct_pop_student

* Outcomes and time periods (whole sample + the three war periods)
local outcomes emp weekly_hours_worked
local per1 2007 2024
local per2 2007 2012
local per3 2013 2016
local per4 2017 2024

forvalues oi = 1/2 {
    local o : word `oi' of `outcomes'
    forvalues p = 1/4 {
        local y1 : word 1 of `per`p''
        local y2 : word 2 of `per`p''

        ivreghdfe `o' `controls' (ln_homicide = iv) ///
            if year >= `y1' & year <= `y2', ///
            absorb(i.month_year_date i.id) cluster(id) first

        local b_`oi'_`p'  = _b[ln_homicide]
        local se_`oi'_`p' = _se[ln_homicide]
        local N_`oi'_`p'  = e(N)
        local kp_`oi'_`p' = e(rkf)
        quietly sum `o' if e(sample)
        local mean_`oi'_`p' : display %6.3f r(mean)
    }
}

* Both panels run on the same sample, so N (and the first stage) must line up
forvalues p = 1/4 {
    assert `N_1_`p'' == `N_2_`p''
}

// ============================================
// Prepare values for table display
// ============================================

forvalues oi = 1/2 {
    forvalues p = 1/4 {
        local b  = `b_`oi'_`p''
        local se = `se_`oi'_`p''

        * t/z statistic
        local t = abs(`b' / `se')
        local pval = 2 * normal(-`t')

        * stars
        local stars ""
        if (`pval' < 0.10) local stars "*"
        if (`pval' < 0.05) local stars "**"
        if (`pval' < 0.01) local stars "***"

        * formatted numbers
        local b_tex  : display %6.3f `b'
        local se_tex : display %6.3f `se'
        local kp_tex : display %6.2f `kp_`oi'_`p''

        * store LaTeX-ready output
        local coef`oi'_`p' "\$`b_tex'^{`stars'}\$"
        local seout`oi'_`p' "(`se_tex')"
        local kpout`p' "`kp_tex'"

        local N = `N_`oi'_`p''
        * Add comma if N > 10,000
        if `N' >= 10000 {
            local Nout`p' : display %9.0fc `N'
        }
        else {
            local Nout`p' : display %9.0f `N'
        }
    }
}

// ============================================
// WRITE LATEX TABLE (Monthly)
// ============================================

file open myfile using "${TABLES}employment_iv.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
" & \shortstack{Whole sample \\ (1)}" ///
" & \shortstack{War on drugs \\ 2007-2012 \\ (2)}" ///
" & \shortstack{Interim \\ 2013-2016 \\ (3)}" ///
" & \shortstack{Resurgence \\ 2017-2024 \\ (4)} \\" _n
file write myfile "\hline" _n

* Panel A: extensive margin
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel A. Outcome: Employed}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1_1' & `coef1_2' & `coef1_3' & `coef1_4' \\" _n
file write myfile " & `seout1_1' & `seout1_2' & `seout1_3' & `seout1_4' \\" _n
file write myfile "Mean of employed" _n
file write myfile " & \$`mean_1_1'\$ & \$`mean_1_2'\$ & \$`mean_1_3'\$ & \$`mean_1_4'\$ \\" _n
file write myfile "\hline" _n

* Panel B: hours worked
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel B. Outcome: Weekly hours worked}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef2_1' & `coef2_2' & `coef2_3' & `coef2_4' \\" _n
file write myfile " & `seout2_1' & `seout2_2' & `seout2_3' & `seout2_4' \\" _n
file write myfile "Mean of weekly hours worked" _n
file write myfile " & \$`mean_2_1'\$ & \$`mean_2_2'\$ & \$`mean_2_3'\$ & \$`mean_2_4'\$ \\" _n

* Kleibergen-Paap F-stat row (identical across panels: same sample, same first stage)
file write myfile "\hline" _n
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

********************************************************************************
* PART 2: Quarterly analysis
********************************************************************************

use "../input/final_indiv_quarterly.dta", clear
destring total_n, replace
drop if total_n != 5

* Bring in municipal controls
tempfile indiv_temp_q
save `indiv_temp_q', replace

use "../input/final_mun_quarterly.dta", clear
keep municipality trim avg_* employment_rate
tempfile muni_temp_q
save `muni_temp_q', replace

use `indiv_temp_q', clear
merge m:1 municipality trim using `muni_temp_q', keep(match) nogen

drop year month
gen year = real(substr(trim, 1, 4))
encode trim, gen(trim_f)

* Same sample restrictions as quarterly_results.do
drop if pop_tot < 15000
drop if age >= 6 & age <= 11

* Generate necessary variables
gen iv = cs_big * d_to_pc
gen ln_homicide = log(1+hr)
destring municipality, replace
gen ln_hom_lag1 = log(1+hr_lag1)

* Employment outcome straight from clase2 (poblacion ocupada)
gen emp = clase2 == 1
assert emp == employed

* Define control list (same as quarterly_results.do: only one homicide lag)
local controls_q hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
    hh_n_employed_adults hh_n_other_children hh_children ///
    ln_hom_lag1 pop_tot pct_pop_fem ///
    avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children ///
    avg_income avg_hincome employment_rate avg_hh_n_employed_adults ///
    avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers ///
    pct_pop_male pct_pop_student

forvalues oi = 1/2 {
    local o : word `oi' of `outcomes'
    forvalues p = 1/4 {
        local y1 : word 1 of `per`p''
        local y2 : word 2 of `per`p''

        ivreghdfe `o' `controls_q' (ln_homicide = iv) ///
            if year >= `y1' & year <= `y2', ///
            absorb(i.trim_f i.id) cluster(id) first

        local b_`oi'_`p'  = _b[ln_homicide]
        local se_`oi'_`p' = _se[ln_homicide]
        local N_`oi'_`p'  = e(N)
        local kp_`oi'_`p' = e(rkf)
        quietly sum `o' if e(sample)
        local mean_`oi'_`p' : display %6.3f r(mean)
    }
}

* Both panels run on the same sample, so N (and the first stage) must line up
forvalues p = 1/4 {
    assert `N_1_`p'' == `N_2_`p''
}

// ============================================
// Prepare values for table display
// ============================================

forvalues oi = 1/2 {
    forvalues p = 1/4 {
        local b  = `b_`oi'_`p''
        local se = `se_`oi'_`p''

        * t/z statistic
        local t = abs(`b' / `se')
        local pval = 2 * normal(-`t')

        * stars
        local stars ""
        if (`pval' < 0.10) local stars "*"
        if (`pval' < 0.05) local stars "**"
        if (`pval' < 0.01) local stars "***"

        * formatted numbers
        local b_tex  : display %6.3f `b'
        local se_tex : display %6.3f `se'
        local kp_tex : display %6.2f `kp_`oi'_`p''

        * store LaTeX-ready output
        local coef`oi'_`p' "\$`b_tex'^{`stars'}\$"
        local seout`oi'_`p' "(`se_tex')"
        local kpout`p' "`kp_tex'"

        local N = `N_`oi'_`p''
        * Add comma if N > 10,000
        if `N' >= 10000 {
            local Nout`p' : display %9.0fc `N'
        }
        else {
            local Nout`p' : display %9.0f `N'
        }
    }
}

// ============================================
// WRITE LATEX TABLE (Quarterly)
// ============================================

file open myfile using "${TABLES}employment_iv_quarterly.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
" & \shortstack{Whole sample \\ (1)}" ///
" & \shortstack{War on drugs \\ 2007-2012 \\ (2)}" ///
" & \shortstack{Interim \\ 2013-2016 \\ (3)}" ///
" & \shortstack{Resurgence \\ 2017-2024 \\ (4)} \\" _n
file write myfile "\hline" _n

* Panel A: extensive margin
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel A. Outcome: Employed}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1_1' & `coef1_2' & `coef1_3' & `coef1_4' \\" _n
file write myfile " & `seout1_1' & `seout1_2' & `seout1_3' & `seout1_4' \\" _n
file write myfile "Mean of employed" _n
file write myfile " & \$`mean_1_1'\$ & \$`mean_1_2'\$ & \$`mean_1_3'\$ & \$`mean_1_4'\$ \\" _n
file write myfile "\hline" _n

* Panel B: hours worked
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel B. Outcome: Weekly hours worked}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef2_1' & `coef2_2' & `coef2_3' & `coef2_4' \\" _n
file write myfile " & `seout2_1' & `seout2_2' & `seout2_3' & `seout2_4' \\" _n
file write myfile "Mean of weekly hours worked" _n
file write myfile " & \$`mean_2_1'\$ & \$`mean_2_2'\$ & \$`mean_2_3'\$ & \$`mean_2_4'\$ \\" _n

* Kleibergen-Paap F-stat row (identical across panels: same sample, same first stage)
file write myfile "\hline" _n
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
