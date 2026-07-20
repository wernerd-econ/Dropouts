*******************************************************************************
* This script decomposes the dropout outcome into persistent and temporary
* dropout events using the 5-interview ENOE rotating panel:
*   - An event at interview k is classifiable at horizon h if k + h <= 5
*   - persistent (perm`h') = drops out and stays out of school for the next h
*     interviews; temporary (temp`h') = returns to school within h interviews
*   - Events without h quarters of follow-up are set to missing (right-
*     censored), never to 0 or 1; non-event rows are known zeros
* Classification is built from ENOE_panel.dta (all ages) so that follow-up
* interviews are not lost to the age <= 18 filter in final_indiv.dta.
*
* Produces: dropout_permanence.tex, permanence_scalars.tex,
*           perm_dropout_iv.tex, perm_dropout_horizons.tex,
*           perm_dropout_iv_quarterly.tex
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
* PART 1: Build permanence classification from the full ENOE panel
********************************************************************************

use id n_ent school dropout total_n using "../input/ENOE_panel.dta", clear
destring total_n, replace
keep if total_n == 5

* Drop ids with duplicate interview numbers (~0.2%, household-split artifacts).
* Save the id list: the same test run on the filtered analysis files flags
* fewer rows (filters can remove one row of a duplicate pair), so the exact
* same ids must be excluded there via this list rather than re-testing.
duplicates tag id n_ent, gen(dup_tag)
bysort id: egen has_dup = max(dup_tag)
preserve
keep if has_dup > 0
keep id
duplicates drop
tempfile dup_ids
save `dup_ids', replace
restore
drop if has_dup > 0
drop dup_tag has_dup

* School status at the next 1-3 interviews
sort id n_ent
by id: gen s1 = school[_n+1]
by id: gen s2 = school[_n+2]
by id: gen s3 = school[_n+3]

gen byte ret1 = (s1 == 1)                     if !missing(s1)
gen byte ret2 = (s1 == 1 | s2 == 1)           if !missing(s1, s2)
gen byte ret3 = (s1 == 1 | s2 == 1 | s3 == 1) if !missing(s1, s2, s3)

* Classify events at each horizon; non-events are known zeros
foreach h in 1 2 3 {
    gen byte perm`h' = .
    replace perm`h' = 0          if dropout == 0
    replace perm`h' = 1 - ret`h' if dropout == 1 & !missing(ret`h')
    gen byte temp`h' = .
    replace temp`h' = 0          if dropout == 0
    replace temp`h' = ret`h'     if dropout == 1 & !missing(ret`h')
}

keep id n_ent perm1 perm2 perm3 temp1 temp2 temp3
tempfile classif
save `classif', replace

********************************************************************************
* PART 2: Monthly analysis
********************************************************************************

use "../input/final_indiv.dta", clear
destring total_n, replace
drop if total_n != 5

* Drop the same duplicate-interview ids as the classification file
merge m:1 id using `dup_ids', keep(master) nogen

* Bring in the permanence classification
merge 1:1 id n_ent using `classif', assert(match using) keep(match) nogen

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

* Persistent and temporary events must partition dropouts exactly
foreach h in 1 2 3 {
    assert perm`h' + temp`h' == dropout if !missing(perm`h')
}

* Distribution of dropout events across interviews (for the log)
tab n_ent if dropout == 1

* -----------------------------------------------------------------------------
* Descriptives: temporary vs persistent dropout events in the analysis sample
* -----------------------------------------------------------------------------
quietly count if dropout == 1
local ev_all = r(N)
local ev_all_fmt : display %9.0fc `ev_all'

foreach h in 1 2 3 {
    quietly count if dropout == 1 & !missing(perm`h')
    local evfmt`h' : display %9.0fc r(N)
    quietly sum temp`h' if dropout == 1 & !missing(perm`h')
    local retpct`h' : display %4.1f 100 * r(mean)
    local outpct`h' : display %4.1f 100 * (1 - r(mean))
}

file open myfile using "${TABLES}dropout_permanence.tex", write replace

file write myfile "\begin{tabular}{l c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
"Follow-up horizon & \shortstack{Dropout events \\ observed}" ///
" & \shortstack{Returned \\ within horizon (\%)}" ///
" & \shortstack{Still out \\ after horizon (\%)} \\" _n
file write myfile "\hline" _n
file write myfile "One quarter & `evfmt1' & `retpct1' & `outpct1' \\" _n
file write myfile "Two quarters & `evfmt2' & `retpct2' & `outpct2' \\" _n
file write myfile "Three quarters & `evfmt3' & `retpct3' & `outpct3' \\" _n
file write myfile "\hline" _n
file write myfile "All dropout events & `ev_all_fmt' & -- & -- \\" _n
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile

* -----------------------------------------------------------------------------
* IV decomposition: persistent vs temporary dropout (2-quarter horizon)
* -----------------------------------------------------------------------------

* Define control list (same as robustness.do)
local controls hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
    hh_n_employed_adults hh_n_other_children hh_children ///
    ln_hom_lag1 ln_hom_lag2 ln_hom_lag3 pop_tot pct_pop_fem ///
    avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children ///
    avg_income avg_hincome employment_rate avg_hh_n_employed_adults ///
    avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers ///
    pct_pop_male pct_pop_student

* Outcomes and time periods (whole sample + the three war periods)
local outcomes perm2 temp2 dropout
local per1 2007 2024
local per2 2007 2012
local per3 2013 2016
local per4 2017 2024

forvalues oi = 1/3 {
    local o : word `oi' of `outcomes'
    forvalues p = 1/4 {
        local y1 : word 1 of `per`p''
        local y2 : word 2 of `per`p''

        ivreghdfe `o' `controls' (ln_homicide = iv) ///
            if year >= `y1' & year <= `y2' & !missing(perm2), ///
            absorb(i.month_year_date i.id) cluster(id) first

        local b_`oi'_`p'  = _b[ln_homicide]
        local se_`oi'_`p' = _se[ln_homicide]
        local N_`oi'_`p'  = e(N)
        local kp_`oi'_`p' = e(rkf)
        quietly sum `o' if e(sample)
        local mean_`oi'_`p' : display %6.3f r(mean)
    }
}

* All three panels share the classifiable sample, and 2SLS is linear in the
* outcome, so the persistent and temporary coefficients must sum to the total
forvalues p = 1/4 {
    assert `N_1_`p'' == `N_2_`p''
    assert `N_1_`p'' == `N_3_`p''
    assert reldif(`b_1_`p'' + `b_2_`p'', `b_3_`p'') < 1e-3
}

* -----------------------------------------------------------------------------
* Horizon robustness (whole sample): 1- and 3-quarter horizons
* -----------------------------------------------------------------------------
foreach h in 1 3 {
    ivreghdfe perm`h' `controls' (ln_homicide = iv) if !missing(perm`h'), ///
        absorb(i.month_year_date i.id) cluster(id) first
    local bh_perm_`h'  = _b[ln_homicide]
    local seh_perm_`h' = _se[ln_homicide]
    local Nh_`h'  = e(N)
    local kph_`h' = e(rkf)

    ivreghdfe temp`h' `controls' (ln_homicide = iv) if !missing(temp`h'), ///
        absorb(i.month_year_date i.id) cluster(id) first
    local bh_temp_`h'  = _b[ln_homicide]
    local seh_temp_`h' = _se[ln_homicide]
    assert `Nh_`h'' == e(N)
}

* The 2-quarter horizon column is the whole-sample decomposition estimated above
local bh_perm_2  = `b_1_1'
local seh_perm_2 = `se_1_1'
local bh_temp_2  = `b_2_1'
local seh_temp_2 = `se_2_1'
local Nh_2  = `N_1_1'
local kph_2 = `kp_1_1'

// ============================================
// Prepare values for table display (main decomposition)
// ============================================

forvalues oi = 1/3 {
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
// WRITE LATEX TABLE (Monthly decomposition)
// ============================================

file open myfile using "${TABLES}perm_dropout_iv.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
" & \shortstack{Whole sample \\ (1)}" ///
" & \shortstack{War on drugs \\ 2007-2012 \\ (2)}" ///
" & \shortstack{Interim \\ 2013-2016 \\ (3)}" ///
" & \shortstack{Resurgence \\ 2017-2024 \\ (4)} \\" _n
file write myfile "\hline" _n

* Panel A: persistent dropouts
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel A. Outcome: Persistent dropout}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1_1' & `coef1_2' & `coef1_3' & `coef1_4' \\" _n
file write myfile " & `seout1_1' & `seout1_2' & `seout1_3' & `seout1_4' \\" _n
file write myfile "Mean of persistent dropout" _n
file write myfile " & \$`mean_1_1'\$ & \$`mean_1_2'\$ & \$`mean_1_3'\$ & \$`mean_1_4'\$ \\" _n
file write myfile "\hline" _n

* Panel B: temporary dropouts
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel B. Outcome: Temporary dropout}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef2_1' & `coef2_2' & `coef2_3' & `coef2_4' \\" _n
file write myfile " & `seout2_1' & `seout2_2' & `seout2_3' & `seout2_4' \\" _n
file write myfile "Mean of temporary dropout" _n
file write myfile " & \$`mean_2_1'\$ & \$`mean_2_2'\$ & \$`mean_2_3'\$ & \$`mean_2_4'\$ \\" _n
file write myfile "\hline" _n

* Panel C: all dropouts on the same classifiable sample
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel C. Outcome: All dropouts}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef3_1' & `coef3_2' & `coef3_3' & `coef3_4' \\" _n
file write myfile " & `seout3_1' & `seout3_2' & `seout3_3' & `seout3_4' \\" _n
file write myfile "Mean of dropout" _n
file write myfile " & \$`mean_3_1'\$ & \$`mean_3_2'\$ & \$`mean_3_3'\$ & \$`mean_3_4'\$ \\" _n

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

// ============================================
// WRITE LATEX TABLE (Horizon robustness, whole sample)
// ============================================

foreach h in 1 2 3 {
    foreach m in perm temp {
        local b  = `bh_`m'_`h''
        local se = `seh_`m'_`h''

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

        * store LaTeX-ready output
        local hcoef_`m'_`h' "\$`b_tex'^{`stars'}\$"
        local hseout_`m'_`h' "(`se_tex')"
    }
    local hkpout`h' : display %6.2f `kph_`h''
    local hNout`h' : display %9.0fc `Nh_`h''
}

file open myfile using "${TABLES}perm_dropout_horizons.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
"Follow-up horizon & \shortstack{One quarter \\ (1)}" ///
" & \shortstack{Two quarters \\ (2)}" ///
" & \shortstack{Three quarters \\ (3)} \\" _n
file write myfile "\hline" _n

* Panel A: persistent dropouts
file write myfile "\multicolumn{4}{l}{{\small \textit{Panel A. Outcome: Persistent dropout}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `hcoef_perm_1' & `hcoef_perm_2' & `hcoef_perm_3' \\" _n
file write myfile " & `hseout_perm_1' & `hseout_perm_2' & `hseout_perm_3' \\" _n
file write myfile "\hline" _n

* Panel B: temporary dropouts
file write myfile "\multicolumn{4}{l}{{\small \textit{Panel B. Outcome: Temporary dropout}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `hcoef_temp_1' & `hcoef_temp_2' & `hcoef_temp_3' \\" _n
file write myfile " & `hseout_temp_1' & `hseout_temp_2' & `hseout_temp_3' \\" _n

* Kleibergen-Paap F-stat row
file write myfile "\hline" _n
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & `hkpout1' & `hkpout2' & `hkpout3' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `hNout1' & `hNout2' & `hNout3' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile

// ============================================
// WRITE LATEX SCALARS
// ============================================

local perm_b_fmt  : display %5.3f `b_1_1'
local perm_se_fmt : display %5.3f `se_1_1'
local temp_b_fmt  : display %5.3f `b_2_1'
local temp_se_fmt : display %5.3f `se_2_1'

file open scalars using "${TABLES}permanence_scalars.tex", write replace

file write scalars "\newcommand{\RetOneQ}{ `retpct1' }" _n
file write scalars "\newcommand{\RetTwoQ}{ `retpct2' }" _n
file write scalars "\newcommand{\RetThreeQ}{ `retpct3' }" _n
file write scalars "\newcommand{\StillOutTwoQ}{ `outpct2' }" _n
file write scalars "\newcommand{\NEventsTwoQ}{ `evfmt2' }" _n
file write scalars "\newcommand{\NEventsAll}{ `ev_all_fmt' }" _n
file write scalars "\newcommand{\PermCoefWhole}{ `perm_b_fmt' }" _n
file write scalars "\newcommand{\PermSeWhole}{ `perm_se_fmt' }" _n
file write scalars "\newcommand{\TempCoefWhole}{ `temp_b_fmt' }" _n
file write scalars "\newcommand{\TempSeWhole}{ `temp_se_fmt' }" _n

file close scalars

********************************************************************************
* PART 2b: Subgroup analysis (monthly, restricted to the post-2017 resurgence
* period, mirroring the main subgroup table subgroup_iv_respike.tex). Repeats
* the persistent/temporary decomposition within each demographic/educational
* subgroup to confirm the decomposition pattern holds for the subgroups as well.
* The monthly analysis dataset built in PART 2 is still in memory (the outcomes
* perm2 / temp2 / dropout and the `outcomes' and `controls' locals remain in
* scope), so no reload is needed.
********************************************************************************

* Subgroup filters, one per output column (match subgroup_iv_respike.tex):
*   (1) secondary school (ages 12-14)  (2) high school (ages 15-18)
*   (3) males                          (4) females
local sg1 age >= 12 & age <= 14
local sg2 age >= 15 & age <= 18
local sg3 sex == 1
local sg4 sex == 2

forvalues g = 1/4 {
    forvalues oi = 1/3 {
        local o : word `oi' of `outcomes'

        ivreghdfe `o' `controls' (ln_homicide = iv) ///
            if (`sg`g'') & year >= 2017 & year <= 2024 & !missing(perm2), ///
            absorb(i.month_year_date i.id) cluster(id) first

        local sb_`oi'_`g'  = _b[ln_homicide]
        local sse_`oi'_`g' = _se[ln_homicide]
        local sN_`oi'_`g'  = e(N)
        local skp_`oi'_`g' = e(rkf)
        quietly sum `o' if e(sample)
        local smean_`oi'_`g' : display %6.3f r(mean)
    }
}

* Within each subgroup all three panels share the classifiable sample, and the
* persistent and temporary coefficients must sum to the total effect
forvalues g = 1/4 {
    assert `sN_1_`g'' == `sN_2_`g''
    assert `sN_1_`g'' == `sN_3_`g''
    assert reldif(`sb_1_`g'' + `sb_2_`g'', `sb_3_`g'') < 1e-3
}

// ============================================
// Prepare values for table display (subgroups)
// ============================================

forvalues oi = 1/3 {
    forvalues g = 1/4 {
        local b  = `sb_`oi'_`g''
        local se = `sse_`oi'_`g''

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
        local kp_tex : display %6.2f `skp_`oi'_`g''

        * store LaTeX-ready output
        local scoef`oi'_`g' "\$`b_tex'^{`stars'}\$"
        local sseout`oi'_`g' "(`se_tex')"
        local skpout`g' "`kp_tex'"

        local N = `sN_`oi'_`g''
        * Add comma if N > 10,000
        if `N' >= 10000 {
            local sNout`g' : display %9.0fc `N'
        }
        else {
            local sNout`g' : display %9.0f `N'
        }
    }
}

// ============================================
// WRITE LATEX TABLE (Subgroups, monthly)
// ============================================

file open myfile using "${TABLES}perm_dropout_subgroups.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile "{\small \textit{Resurgence (2017-2024)}} & Secondary school & High school & Male & Female \\" _n
file write myfile " & (1) & (2) & (3) & (4) \\" _n
file write myfile "\hline" _n

* Panel A: persistent dropouts
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel A. Outcome: Persistent dropout}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `scoef1_1' & `scoef1_2' & `scoef1_3' & `scoef1_4' \\" _n
file write myfile " & `sseout1_1' & `sseout1_2' & `sseout1_3' & `sseout1_4' \\" _n
file write myfile "Mean of persistent dropout" _n
file write myfile " & \$`smean_1_1'\$ & \$`smean_1_2'\$ & \$`smean_1_3'\$ & \$`smean_1_4'\$ \\" _n
file write myfile "\hline" _n

* Panel B: temporary dropouts
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel B. Outcome: Temporary dropout}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `scoef2_1' & `scoef2_2' & `scoef2_3' & `scoef2_4' \\" _n
file write myfile " & `sseout2_1' & `sseout2_2' & `sseout2_3' & `sseout2_4' \\" _n
file write myfile "Mean of temporary dropout" _n
file write myfile " & \$`smean_2_1'\$ & \$`smean_2_2'\$ & \$`smean_2_3'\$ & \$`smean_2_4'\$ \\" _n
file write myfile "\hline" _n

* Panel C: all dropouts on the same classifiable sample
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel C. Outcome: All dropouts}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `scoef3_1' & `scoef3_2' & `scoef3_3' & `scoef3_4' \\" _n
file write myfile " & `sseout3_1' & `sseout3_2' & `sseout3_3' & `sseout3_4' \\" _n
file write myfile "Mean of dropout" _n
file write myfile " & \$`smean_3_1'\$ & \$`smean_3_2'\$ & \$`smean_3_3'\$ & \$`smean_3_4'\$ \\" _n

* Kleibergen-Paap F-stat row (identical across panels within a subgroup)
file write myfile "\hline" _n
file write myfile "Kleibergen-Paap F-stat" _n
file write myfile " & `skpout1' & `skpout2' & `skpout3' & `skpout4' \\" _n

* Observations row
file write myfile "\hline" _n
file write myfile "Observations" _n
file write myfile " & `sNout1' & `sNout2' & `sNout3' & `sNout4' \\" _n

* Close table
file write myfile "\hline\hline" _n
file write myfile "\end{tabular}" _n

file close myfile

********************************************************************************
* PART 3: Quarterly analysis
********************************************************************************

use "../input/final_indiv_quarterly.dta", clear
destring total_n, replace
drop if total_n != 5

* Drop the same duplicate-interview ids as the classification file
merge m:1 id using `dup_ids', keep(master) nogen

* Bring in the permanence classification
merge 1:1 id n_ent using `classif', assert(match using) keep(match) nogen

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

* Persistent and temporary events must partition dropouts exactly
foreach h in 1 2 3 {
    assert perm`h' + temp`h' == dropout if !missing(perm`h')
}

* Define control list (same as quarterly_results.do: only one homicide lag)
local controls_q hh_income hh_adult_schooling hh_adult_hours hh_adult_employment_rate ///
    hh_n_employed_adults hh_n_other_children hh_children ///
    ln_hom_lag1 pop_tot pct_pop_fem ///
    avg_age avg_hh_adult_hours avg_hh_adult_schooling avg_hh_children ///
    avg_income avg_hincome employment_rate avg_hh_n_employed_adults ///
    avg_hh_size avg_weekly_hours_worked avg_weekly_hours_worked_workers ///
    pct_pop_male pct_pop_student

forvalues oi = 1/3 {
    local o : word `oi' of `outcomes'
    forvalues p = 1/4 {
        local y1 : word 1 of `per`p''
        local y2 : word 2 of `per`p''

        ivreghdfe `o' `controls_q' (ln_homicide = iv) ///
            if year >= `y1' & year <= `y2' & !missing(perm2), ///
            absorb(i.trim_f i.id) cluster(id) first

        local b_`oi'_`p'  = _b[ln_homicide]
        local se_`oi'_`p' = _se[ln_homicide]
        local N_`oi'_`p'  = e(N)
        local kp_`oi'_`p' = e(rkf)
        quietly sum `o' if e(sample)
        local mean_`oi'_`p' : display %6.3f r(mean)
    }
}

* All three panels share the classifiable sample, and 2SLS is linear in the
* outcome, so the persistent and temporary coefficients must sum to the total
forvalues p = 1/4 {
    assert `N_1_`p'' == `N_2_`p''
    assert `N_1_`p'' == `N_3_`p''
    assert reldif(`b_1_`p'' + `b_2_`p'', `b_3_`p'') < 1e-3
}

// ============================================
// Prepare values for table display
// ============================================

forvalues oi = 1/3 {
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
// WRITE LATEX TABLE (Quarterly decomposition)
// ============================================

file open myfile using "${TABLES}perm_dropout_iv_quarterly.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c}" _n
file write myfile "\hline\hline" _n
file write myfile ///
" & \shortstack{Whole sample \\ (1)}" ///
" & \shortstack{War on drugs \\ 2007-2012 \\ (2)}" ///
" & \shortstack{Interim \\ 2013-2016 \\ (3)}" ///
" & \shortstack{Resurgence \\ 2017-2024 \\ (4)} \\" _n
file write myfile "\hline" _n

* Panel A: persistent dropouts
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel A. Outcome: Persistent dropout}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef1_1' & `coef1_2' & `coef1_3' & `coef1_4' \\" _n
file write myfile " & `seout1_1' & `seout1_2' & `seout1_3' & `seout1_4' \\" _n
file write myfile "Mean of persistent dropout" _n
file write myfile " & \$`mean_1_1'\$ & \$`mean_1_2'\$ & \$`mean_1_3'\$ & \$`mean_1_4'\$ \\" _n
file write myfile "\hline" _n

* Panel B: temporary dropouts
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel B. Outcome: Temporary dropout}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef2_1' & `coef2_2' & `coef2_3' & `coef2_4' \\" _n
file write myfile " & `seout2_1' & `seout2_2' & `seout2_3' & `seout2_4' \\" _n
file write myfile "Mean of temporary dropout" _n
file write myfile " & \$`mean_2_1'\$ & \$`mean_2_2'\$ & \$`mean_2_3'\$ & \$`mean_2_4'\$ \\" _n
file write myfile "\hline" _n

* Panel C: all dropouts on the same classifiable sample
file write myfile "\multicolumn{5}{l}{{\small \textit{Panel C. Outcome: All dropouts}}} \\" _n
file write myfile "Homicides per 10,000" _n
file write myfile " & `coef3_1' & `coef3_2' & `coef3_3' & `coef3_4' \\" _n
file write myfile " & `seout3_1' & `seout3_2' & `seout3_3' & `seout3_4' \\" _n
file write myfile "Mean of dropout" _n
file write myfile " & \$`mean_3_1'\$ & \$`mean_3_2'\$ & \$`mean_3_3'\$ & \$`mean_3_4'\$ \\" _n

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
