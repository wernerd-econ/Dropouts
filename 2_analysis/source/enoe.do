* =============================================================================
* Description:
*   This script makes the descriptive stats and figures for ENOE that
*   appear in the paper. 
*
* Author: Daniel Werner 
* Date: Feb. 03, 2026
* =============================================================================
* -----------------------------
* 0) Set paths and create folders
* -----------------------------
global TABLES  "../output/Tables/"
global FIGURES "../output/Figures/"
capture mkdir "${TABLES}"
capture mkdir "${FIGURES}"

* =============================================================================
* I. Create summary statistics of dropout rates in the sample
* =============================================================================
use "/Users/wernerd/Desktop/Daniel Werner/final_indiv.dta", clear

keep id year month primary secondary high sex dropout school

destring year month, replace

gsort id year month

* First, identify who started the panel in school and who dropped out

* For each person, get their first observation
bysort id: gen first_obs = (_n == 1)

* Check if they started in school
bysort id: gen started_in_school = (school[1] == 1)

* Check if they ever dropped out (assuming dropout is an indicator)
bysort id: egen ever_dropout = max(dropout)

* Keep only one observation per person
keep if first_obs == 1

* Now calculate statistics by school level and sex
* Create a combined dataset with all the breakdowns

preserve

* Primary School (6-12)
keep if primary == 1

* Total for primary
count
local prim_total = r(N)
count if started_in_school == 1
local prim_started = r(N)
count if ever_dropout == 1
local prim_dropouts = r(N)
local prim_rate = (`prim_dropouts' / `prim_started') * 100

* Men in primary
count if sex == 1
local prim_men_total = r(N)
count if sex == 1 & started_in_school == 1
local prim_men_started = r(N)
count if sex == 1 & ever_dropout == 1
local prim_men_dropouts = r(N)
local prim_men_rate = (`prim_men_dropouts' / `prim_men_started') * 100

* Women in primary
count if sex == 2
local prim_women_total = r(N)
count if sex == 2 & started_in_school == 1
local prim_women_started = r(N)
count if sex == 2 & ever_dropout == 1
local prim_women_dropouts = r(N)
local prim_women_rate = (`prim_women_dropouts' / `prim_women_started') * 100

restore

* Repeat for Secondary and High School
preserve
keep if secondary == 1

count
local sec_total = r(N)
count if started_in_school == 1
local sec_started = r(N)
count if ever_dropout == 1
local sec_dropouts = r(N)
local sec_rate = (`sec_dropouts' / `sec_started') * 100

count if sex == 1
local sec_men_total = r(N)
count if sex == 1 & started_in_school == 1
local sec_men_started = r(N)
count if sex == 1 & ever_dropout == 1
local sec_men_dropouts = r(N)
local sec_men_rate = (`sec_men_dropouts' / `sec_men_started') * 100

count if sex == 2
local sec_women_total = r(N)
count if sex == 2 & started_in_school == 1
local sec_women_started = r(N)
count if sex == 2 & ever_dropout == 1
local sec_women_dropouts = r(N)
local sec_women_rate = (`sec_women_dropouts' / `sec_women_started') * 100

restore

* High School
preserve
keep if high == 1

count
local high_total = r(N)
count if started_in_school == 1
local high_started = r(N)
count if ever_dropout == 1
local high_dropouts = r(N)
local high_rate = (`high_dropouts' / `high_started') * 100

count if sex == 1
local high_men_total = r(N)
count if sex == 1 & started_in_school == 1
local high_men_started = r(N)
count if sex == 1 & ever_dropout == 1
local high_men_dropouts = r(N)
local high_men_rate = (`high_men_dropouts' / `high_men_started') * 100

count if sex == 2
local high_women_total = r(N)
count if sex == 2 & started_in_school == 1
local high_women_started = r(N)
count if sex == 2 & ever_dropout == 1
local high_women_dropouts = r(N)
local high_women_rate = (`high_women_dropouts' / `high_women_started') * 100

restore

* Overall totals
count
local total_total = r(N)
count if started_in_school == 1
local total_started = r(N)
count if ever_dropout == 1
local total_dropouts = r(N)
local total_rate = (`total_dropouts' / `total_started') * 100

count if sex == 1
local total_men_total = r(N)
count if sex == 1 & started_in_school == 1
local total_men_started = r(N)
count if sex == 1 & ever_dropout == 1
local total_men_dropouts = r(N)
local total_men_rate = (`total_men_dropouts' / `total_men_started') * 100

count if sex == 2
local total_women_total = r(N)
count if sex == 2 & started_in_school == 1
local total_women_started = r(N)
count if sex == 2 & ever_dropout == 1
local total_women_dropouts = r(N)
local total_women_rate = (`total_women_dropouts' / `total_women_started') * 100

* Write the LaTeX table
file open mytable using "${TABLES}dropout_stats.tex", write replace

file write mytable "\begin{tabular}{llrrrl}" _n
file write mytable "\toprule" _n
file write mytable "Age Group & Category & Total People & Started Panel In School & Dropouts & Dropout Rate\\" _n
file write mytable "\midrule" _n

* Primary School
file write mytable "Primary School (6-12) & Total & " %12.0fc (`prim_total') " & " %12.0fc (`prim_started') " & " %12.0fc (`prim_dropouts') " & " %5.1f (`prim_rate') "\%\\" _n
file write mytable " & \hspace{1em}\textit{Men} & " %12.0fc (`prim_men_total') " & " %12.0fc (`prim_men_started') " & " %12.0fc (`prim_men_dropouts') " & " %5.1f (`prim_men_rate') "\%\\" _n
file write mytable " & \hspace{1em}\textit{Women} & " %12.0fc (`prim_women_total') " & " %12.0fc (`prim_women_started') " & " %12.0fc (`prim_women_dropouts') " & " %5.3f (`prim_women_rate') "\%\\" _n

* Secondary School
file write mytable "Secondary School (12-15) & Total & " %12.0fc (`sec_total') " & " %12.0fc (`sec_started') " & " %12.0fc (`sec_dropouts') " & " %5.1f (`sec_rate') "\%\\" _n
file write mytable " & \hspace{1em}\textit{Men} & " %12.0fc (`sec_men_total') " & " %12.0fc (`sec_men_started') " & " %12.0fc (`sec_men_dropouts') " & " %5.3f (`sec_men_rate') "\%\\" _n
file write mytable " & \hspace{1em}\textit{Women} & " %12.0fc (`sec_women_total') " & " %12.0fc (`sec_women_started') " & " %12.0fc (`sec_women_dropouts') " & " %5.1f (`sec_women_rate') "\%\\" _n

* High School
file write mytable "High School (15-18) & Total & " %12.0fc (`high_total') " & " %12.0fc (`high_started') " & " %12.0fc (`high_dropouts') " & " %5.1f (`high_rate') "\%\\" _n
file write mytable " & \hspace{1em}\textit{Men} & " %12.0fc (`high_men_total') " & " %12.0fc (`high_men_started') " & " %12.0fc (`high_men_dropouts') " & " %5.1f (`high_men_rate') "\%\\" _n
file write mytable " & \hspace{1em}\textit{Women} & " %12.0fc (`high_women_total') " & " %12.0fc (`high_women_started') " & " %12.0fc (`high_women_dropouts') " & " %5.1f (`high_women_rate') "\%\\" _n

* Total
file write mytable "Total & Total & " %12.0fc (`total_total') " & " %12.0fc (`total_started') " & " %12.0fc (`total_dropouts') " & " %5.1f (`total_rate') "\%\\" _n
file write mytable " & \hspace{1em}\textit{Men} & " %12.0fc (`total_men_total') " & " %12.0fc (`total_men_started') " & " %12.0fc (`total_men_dropouts') " & " %5.1f (`total_men_rate') "\%\\" _n
file write mytable " & \hspace{1em}\textit{Women} & " %12.0fc (`total_women_total') " & " %12.0fc (`total_women_started') " & " %12.0fc (`total_women_dropouts') " & " %5.1f (`total_women_rate') "\%\\" _n

file write mytable "\bottomrule" _n
file write mytable "\end{tabular}" _n

file close mytable


* =============================================================================
* II. Create summary statistics at municipal level
* =============================================================================
use "/Users/wernerd/Desktop/Daniel Werner/final_mun.dta", clear

destring municipality year month, replace 

keep avg_weekly_hours_worked_workers unemployment_rate avg_age avg_income_earners ///
     avg_income_usd_earners avg_years_schooling avg_hh_size avg_hh_income ///
     avg_hh_income_usd avg_hh_employment_rate municipality year month

* Create time period variable
gen year_month = ym(year, month)
format year_month %tm

gen Period = ""
replace Period = "Calderón's War on Drugs" if year_month >= ym(2007,1) & year_month <= ym(2012,12)
replace Period = "Intermediate Period" if year_month >= ym(2013,1) & year_month <= ym(2016,12)
replace Period = "Respike" if year_month >= ym(2017,1) & year_month <= ym(2024,12)

* Shorten variable names first
rename avg_weekly_hours_worked_workers weekly_hrs
rename unemployment_rate unemp_rate
rename avg_income_earners income
rename avg_income_usd_earners income_usd
rename avg_years_schooling years_school
rename avg_hh_size hh_size
rename avg_hh_income hh_income
rename avg_hh_income_usd hh_income_usd
rename avg_hh_employment_rate hh_emp_rate

* Then use the shortened names in your collapse and formatting
preserve
collapse (mean) weekly_hrs unemp_rate avg_age income income_usd ///
         years_school hh_size hh_income hh_income_usd hh_emp_rate, ///
         by(municipality Period)

collapse (mean) weekly_hrs unemp_rate avg_age income income_usd ///
         years_school hh_size hh_income hh_income_usd hh_emp_rate, ///
         by(Period)

tempfile period_stats
save `period_stats'
restore

* Get overall stats
preserve
collapse (mean) weekly_hrs unemp_rate avg_age income income_usd ///
         years_school hh_size hh_income hh_income_usd hh_emp_rate, ///
         by(municipality)

collapse (mean) weekly_hrs unemp_rate avg_age income income_usd ///
         years_school hh_size hh_income hh_income_usd hh_emp_rate

* Store overall means
local overall_hrs = weekly_hrs
local overall_unemp = unemp_rate
local overall_age = avg_age
local overall_income = income
local overall_income_usd = income_usd
local overall_school = years_school
local overall_hhsize = hh_size
local overall_hhinc = hh_income
local overall_hhinc_usd = hh_income_usd
local overall_hhemp = hh_emp_rate

restore

* Load period stats and add overall
use `period_stats', clear
set obs `=_N+1'
replace Period = "Overall" in `=_N'
replace weekly_hrs = `overall_hrs' in `=_N'
replace unemp_rate = `overall_unemp' in `=_N'
replace avg_age = `overall_age' in `=_N'
replace income = `overall_income' in `=_N'
replace income_usd = `overall_income_usd' in `=_N'
replace years_school = `overall_school' in `=_N'
replace hh_size = `overall_hhsize' in `=_N'
replace hh_income = `overall_hhinc' in `=_N'
replace hh_income_usd = `overall_hhinc_usd' in `=_N'
replace hh_emp_rate = `overall_hhemp' in `=_N'

* Order periods
gen order = .
replace order = 1 if Period == "Overall"
replace order = 2 if Period == "Calderón's War on Drugs"
replace order = 3 if Period == "Intermediate Period"
replace order = 4 if Period == "Respike"
sort order

* Format variables for display
local hrs_1 : display %6.2f weekly_hrs[1]
local hrs_2 : display %6.2f weekly_hrs[2]
local hrs_3 : display %6.2f weekly_hrs[3]
local hrs_4 : display %6.2f weekly_hrs[4]

local unemp_1 : display %6.2f unemp_rate[1]
local unemp_2 : display %6.2f unemp_rate[2]
local unemp_3 : display %6.2f unemp_rate[3]
local unemp_4 : display %6.2f unemp_rate[4]

local age_1 : display %6.0f avg_age[1]
local age_2 : display %6.0f avg_age[2]
local age_3 : display %6.0f avg_age[3]
local age_4 : display %6.0f avg_age[4]

local inc_1 : display %6.0fc income[1]
local inc_2 : display %6.0fc income[2]
local inc_3 : display %6.0fc income[3]
local inc_4 : display %6.0fc income[4]

local incusd_1 : display %6.0f income_usd[1]
local incusd_2 : display %6.0f income_usd[2]
local incusd_3 : display %6.0f income_usd[3]
local incusd_4 : display %6.0f income_usd[4]

local school_1 : display %6.0f years_school[1]
local school_2 : display %6.0f years_school[2]
local school_3 : display %6.0f years_school[3]
local school_4 : display %6.0f years_school[4]

local hhsize_1 : display %6.0f hh_size[1]
local hhsize_2 : display %6.0f hh_size[2]
local hhsize_3 : display %6.0f hh_size[3]
local hhsize_4 : display %6.0f hh_size[4]

local hhinc_1 : display %6.0fc hh_income[1]
local hhinc_2 : display %6.0fc hh_income[2]
local hhinc_3 : display %6.0fc hh_income[3]
local hhinc_4 : display %6.0fc hh_income[4]

local hhincusd_1 : display %6.0f hh_income_usd[1]
local hhincusd_2 : display %6.0f hh_income_usd[2]
local hhincusd_3 : display %6.0f hh_income_usd[3]
local hhincusd_4 : display %6.0f hh_income_usd[4]

local hhemp_1 : display %6.2f hh_emp_rate[1]
local hhemp_2 : display %6.2f hh_emp_rate[2]
local hhemp_3 : display %6.2f hh_emp_rate[3]
local hhemp_4 : display %6.2f hh_emp_rate[4]

* Write LaTeX table
file open mytable using "${TABLES}mun_summary_stats.tex", write replace

file write mytable "\begin{tabular}{l c c c c}" _n
file write mytable "\hline" _n
file write mytable " & \shortstack{Full sample \\ (2007-2024)} & \shortstack{War on drugs \\ (2007-2012)} & \shortstack{Interim \\ (2013-2016)} & \shortstack{Resurgence \\ (2017-2024)} \\" _n
file write mytable "\hline" _n

file write mytable "Avg. weekly hours (workers)" _n
file write mytable " & `hrs_1' & `hrs_2' & `hrs_3' & `hrs_4' \\" _n

file write mytable "Unemployment rate" _n
file write mytable " & `unemp_1' & `unemp_2' & `unemp_3' & `unemp_4' \\" _n

file write mytable "Avg. age" _n
file write mytable " & `age_1' & `age_2' & `age_3' & `age_4' \\" _n

file write mytable "Avg. income (earners)" _n
file write mytable " & \\$`inc_1' & \\$`inc_2' & \\$`inc_3' & \\$`inc_4' \\" _n
file write mytable " & (\\$`incusd_1') & (\\$`incusd_2') & (\\$`incusd_3') & (\\$`incusd_4') \\" _n

file write mytable "Avg. years schooling" _n
file write mytable " & `school_1' & `school_2' & `school_3' & `school_4' \\" _n

file write mytable "Avg. household size" _n
file write mytable " & `hhsize_1' & `hhsize_2' & `hhsize_3' & `hhsize_4' \\" _n

file write mytable "Avg. household income" _n
file write mytable " & \\$`hhinc_1' & \\$`hhinc_2' & \\$`hhinc_3' & \\$`hhinc_4' \\" _n
file write mytable " & (\\$`hhincusd_1') & (\\$`hhincusd_2') & (\\$`hhincusd_3') & (\\$`hhincusd_4') \\" _n

file write mytable "Avg. HH employment rate" _n
file write mytable " & `hhemp_1' & `hhemp_2' & `hhemp_3' & `hhemp_4' \\" _n

file write mytable "\hline" _n
file write mytable "\end{tabular}" _n

file close mytable
