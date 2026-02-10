* =============================================================================
* Description:
*   This script makes regression specs for validating the instrument used 
*   in the paper 
*
* Author: Daniel Werner 
* Date: Feb. 08, 2026
* =============================================================================

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
* PART 1: Correlation with mexican drug seizures  
********************************************************************************
* Load in Colombia data (2007-2024)
use "/Users/wernerd/Desktop/Daniel Werner/seizure_data.dta", clear

keep Year cs_big

rename Year year

collapse (sum) cs_big, by(year)

* Save as temporary file
tempfile colombia_temp
save `colombia_temp', replace

* Load in Mexico data (2012-2018)
import excel "/Users/wernerd/Desktop/Daniel Werner/DRUGS_MEX.xlsx", firstrow clear
drop if Años == .
rename Años year
rename MariguanaKg marijuana
rename CocaínaKg cocaine
rename HeroínaKg heroin
rename GomadeopioKg opium
rename MetanfetaminaKg meth

replace marijuana = marijuana / 1000
replace cocaine = cocaine /1000
replace heroin = heroin / 1000
replace opium = opium / 1000
replace meth = meth / 1000 

keep if year == 2015 | year == 2016 | year == 2017 | year == 2018

* Save as temporary file
tempfile mex_temp
save `mex_temp', replace

* Load in Mexico data (2000-2014)
import delimited "/Users/wernerd/Desktop/Daniel Werner/SEDENA.csv", varnames(1) clear

drop state

collapse (sum) marijuana cocaine heroin meth opium, by(year)

replace marijuana = marijuana / 1000
replace cocaine = cocaine /1000
replace heroin = heroin / 1000
replace opium = opium / 1000
replace meth = meth / 1000 

* Stack the two Mexico datasets (append rows)
append using `mex_temp'

* Sort by year
sort year

* Merge with Colombia data
merge 1:1 year using `colombia_temp'

keep if _merge == 3

* Calculate total Mexican interdiction
egen total_mex = rowtotal(marijuana cocaine heroin meth opium)

* Regression 1: cs_big on marijuana
regress marijuana cs_big 
local b_1 = _b[cs_big]
local se_1 = _se[cs_big]
local N_1 = e(N)

* Regression 2: cs_big on cocaine
regress cocaine cs_big
local b_2 = _b[cs_big]
local se_2 = _se[cs_big]
local N_2 = e(N)

* Regression 3: cs_big on heroin
regress heroin cs_big
local b_3 = _b[cs_big]
local se_3 = _se[cs_big]
local N_3 = e(N)

* Regression 4: cs_big on meth
regress meth cs_big
local b_4 = _b[cs_big]
local se_4 = _se[cs_big]
local N_4 = e(N)

* Regression 5: cs_big on opium
regress opium cs_big
local b_5 = _b[cs_big]
local se_5 = _se[cs_big]
local N_5 = e(N)

* Regression 6: cs_big on total Mexican seizures
regress total_mex cs_big 
local b_6 = _b[cs_big]
local se_6 = _se[cs_big]
local N_6 = e(N)

* Calculate significance stars for each
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

    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
	
    
    local N = `N_`j'' 
    local Nout`j' : display %2.0f `N'  
}
* Write LaTeX table
file open mytable using "${TABLES}drug_correlations.tex", write replace

file write mytable "\begin{tabular}{l c c c c c c}" _n
file write mytable "\hline\hline" _n
file write mytable " & Marijuana & Cocaine & Heroin & Meth & Opium & Total \\" _n
file write mytable " & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write mytable "\hline" _n

* Coefficient row
file write mytable "Colombian cocaine seizures (metric tonnes)" _n
file write mytable " & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6'  \\" _n
file write mytable " & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6'  \\" _n

file write mytable "\hline" _n

* Observations
file write mytable "\hline" _n
file write mytable "Observations" _n
file write mytable " & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' \\" _n
file write mytable "\hline\hline" _n
file write mytable "\end{tabular}" _n

file close mytable



********************************************************************************
* PART 2: Correlation with mexican economic variables 
********************************************************************************

* 1) Municipal-level regressions
use "/Users/wernerd/Desktop/Daniel Werner/final_mun.dta", clear

destring municipality, replace
gen month_year_date = date(year_month, "YM")
format month_year_date %tm
drop if pop_tot < 15000

* Municipal outcome 1: Employment rate
reghdfe employment_rate cs_big, absorb(i.municipality i.month_year_date) cluster(municipality)
local b_1 = _b[cs_big]
local se_1 = _se[cs_big]
local N_1 = e(N)

* Municipal outcome 2: Average income
reghdfe avg_income cs_big, absorb(i.municipality i.month_year_date) cluster(municipality)
local b_2 = _b[cs_big]
local se_2 = _se[cs_big]
local N_2 = e(N)


* Municipal outcome 3: Average weekly hours worked
reghdfe avg_weekly_hours_worked cs_big, absorb(i.municipality i.month_year_date) cluster(municipality)
local b_3 = _b[cs_big]
local se_3 = _se[cs_big]
local N_3 = e(N)


* 2) Individual-level regressions
use "/Users/wernerd/Desktop/Daniel Werner/final_indiv.dta", clear

gen month_year_date = date(year_month, "YM")
format month_year_date %tm
drop if age >= 6 & age <= 11
drop if pop_tot < 15000

* Individual outcome 1: Houehold adult employment rate
reghdfe hh_adult_employment_rate cs_big, absorb(i.id i.month_year_date) cluster(id)
local b_4 = _b[cs_big]
local se_4 = _se[cs_big]
local N_4 = e(N)

* Individual outcome 2: Household income
reghdfe hh_income cs_big, absorb(i.id i.month_year_date) cluster(id)
local b_5 = _b[cs_big]
local se_5 = _se[cs_big]
local N_5 = e(N)


* Individual outcome 4: Household adult hours worked
reghdfe hh_adult_hours cs_big, absorb(i.id i.month_year_date) cluster(id)
local b_6 = _b[cs_big]
local se_6 = _se[cs_big]
local N_6 = e(N)

* 3) Real GDP numbers (millions of real pesos, seasonally adjusted)
import delimited "/Users/wernerd/Desktop/Daniel Werner/gdp.csv", varnames(1) clear
* Parse the date (assuming it's a string like "1/1/07")
* Split by "/"
split observation_date, parse("/") gen(date_part)

* date_part1 = month, date_part2 = day, date_part3 = year
rename date_part1 month
rename date_part3 year

* Convert to numeric
destring month year, replace

* Handle 2-digit year (07 -> 2007)
replace year = year + 2000 if year < 100

* Drop the day variable (not needed)
drop date_part2 observation_date

* Save as temporary file
tempfile gdp_temp
save `gdp_temp', replace

use "/Users/wernerd/Desktop/Daniel Werner/seizure_data.dta", clear

keep Year Month cs_big
rename Year year 
rename Month month 
destring month, replace

* Merge with GDP data 
merge 1:1 year month using `gdp_temp'
keep if _merge == 3


regress gdp cs_big i.year
local b_7 = _b[cs_big]
local se_7 = _se[cs_big]
local N_7 = e(N)


* Calculate significance stars for each
forvalues j = 1/7 {
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

    * store LaTeX-ready output
    local coef`j' "\$`b_tex'^{`stars'}\$"
    local seout`j' "(`se_tex')"
	
    
    local N = `N_`j'' 
    local Nout`j' : display %9.0fc `N'  
}

* ============================================================================
* Write LaTeX table
* ============================================================================
file open mytable using "${TABLES}placebo_seizures.tex", write replace
file write mytable "\begin{tabular}{l c c c c c c c}" _n
file write mytable "\hline\hline" _n
* Panel headers
file write mytable ///
" & \multicolumn{3}{c}{Municipal Outcomes} & \multicolumn{3}{c}{Individual Outcomes} & National Outcome \\" _n
file write mytable ///
"\cmidrule(lr){2-4} \cmidrule(lr){5-7} \cmidrule(lr){8-8}" _n
* Column labels with shortstack
file write mytable ///
" & \shortstack{Employment \\ Rate} & \shortstack{Avg \\ Income} & \shortstack{Avg Weekly \\ Hours} & \shortstack{HH Adult \\ Employment} & \shortstack{HH \\ Income} & \shortstack{HH Adult \\ Hours} & \shortstack{Real \\ GDP} \\" _n
file write mytable ///
" & (1) & (2) & (3) & (4) & (5) & (6) & (7) \\" _n
file write mytable "\hline" _n
* Coefficient row with shortstack
file write mytable "\shortstack{Colombian seizures \\ (metric tonnes)}" _n
file write mytable ///
" & `coef1' & `coef2' & `coef3' & `coef4' & `coef5' & `coef6' & `coef7' \\" _n
file write mytable ///
" & `seout1' & `seout2' & `seout3' & `seout4' & `seout5' & `seout6' & `seout7' \\" _n
file write mytable "\hline" _n
* Observations
file write mytable ///
"Observations & `Nout1' & `Nout2' & `Nout3' & `Nout4' & `Nout5' & `Nout6' & `Nout7' \\" _n
file write mytable "\hline\hline" _n
file write mytable "\end{tabular}" _n
file close mytable


