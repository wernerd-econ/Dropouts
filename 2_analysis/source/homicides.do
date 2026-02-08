* =============================================================================
* Description:
*   This script makes the descriptive stats and figures for homicide rates that
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
* I. Create Summary Statistics By Period 
* =============================================================================
use "/Users/wernerd/Desktop/Daniel Werner/homicides.dta", clear

* Collapse to month-year level
collapse (sum) hom_ntl=homicides pop_ntl=pop_tot, by(year month)

* Calculate homicide rate per 10,000
gen ntl_hr = (hom_ntl / pop_ntl) * 10000

* Create date variable
destring year month, replace
gen year_month = ym(year, month)
format year_month %tm

* Create period variable
gen Period = ""
replace Period = "Calderón's War on Drugs" if year_month >= ym(2007,1) & year_month <= ym(2012,12)
replace Period = "Intermediate Period" if year_month >= ym(2013,1) & year_month <= ym(2016,12)
replace Period = "Respike" if year_month >= ym(2017,1) & year_month <= ym(2024,12)

preserve

* Calculate stats by period
statsby mean_hr=r(mean) sd_hr=r(sd) median_hr=r(p50), by(Period) clear: summarize ntl_hr, detail

* Add overall stats
tempfile period_stats
save `period_stats'
restore
summarize ntl_hr, detail
local overall_mean = r(mean)
local overall_sd = r(sd)
local overall_median = r(p50)
use `period_stats', clear
set obs `=_N+1'
replace Period = "Overall" in `=_N'
replace mean_hr = `overall_mean' in `=_N'
replace sd_hr = `overall_sd' in `=_N'
replace median_hr = `overall_median' in `=_N'

* Order the periods
gen order = .
replace order = 1 if Period == "Overall"
replace order = 2 if Period == "Calderón's War on Drugs"
replace order = 3 if Period == "Intermediate Period"
replace order = 4 if Period == "Respike"
sort order

* Save variables with proper formatting
local overall_hr : display %6.3f mean_hr[1]
local overall_sd : display %6.3f sd_hr[1]
local overall_median : display %6.3f median_hr[1]
local calderon_hr : display %6.3f mean_hr[2]
local calderon_sd : display %6.3f sd_hr[2]
local calderon_median : display %6.3f median_hr[2]
local inter_hr : display %6.3f mean_hr[3]
local inter_sd : display %6.3f sd_hr[3]
local inter_median : display %6.3f median_hr[3]
local respike_hr : display %6.3f mean_hr[4]
local respike_sd : display %6.3f sd_hr[4]
local respike_median : display %6.3f median_hr[4]

* Write table 
file open myfile using "${TABLES}hom_stats.tex", write replace
* Write table header
file write myfile "\begin{tabular}{l c c c c}" _n
file write myfile "\hline" _n
file write myfile ///
" & \shortstack{Full sample \\ (2007-2024)}" ///
" & \shortstack{War on drugs \\  (2007-2012)}" ///
" & \shortstack{Interim \\  (2013-2016)}" ///
" & \shortstack{Resurgence \\  (2017-2024)} \\"  _n
file write myfile "\hline" _n
* Mean row
file write myfile "Mean" _n
file write myfile " & `overall_hr' & `calderon_hr' & `inter_hr' & `respike_hr' \\" _n
* Median row
file write myfile "Median" _n
file write myfile " & `overall_median' & `calderon_median' & `inter_median' & `respike_median' \\" _n
* SD row
file write myfile "Std. dev" _n
file write myfile " & `overall_sd' & `calderon_sd' & `inter_sd' & `respike_sd' \\" _n
* Close table
file write myfile "\hline" _n
file write myfile "\end{tabular}" _n
file close myfile

* =============================================================================
* II. Create Time Seires Plots Of Ntl HR and Average Municipal HR 
* =============================================================================
use "/Users/wernerd/Desktop/Daniel Werner/homicides.dta", clear

keep homicides pop_tot hr year month

* Collapse to month-year level
collapse (sum) hom_ntl=homicides pop_ntl=pop_tot (mean) avg_mun_hom=hr, by(year month)

* Calculate national homicide rate per 10,000
gen ntl_hr = (hom_ntl / pop_ntl) * 10000

* Create date variable
destring year month, replace
gen year_month = ym(year, month)
format year_month %tm

sort year month

* SAVE NECESSARY SCALARS BEFORE PLOT 
* ============================================================================
* Period 1: 2007-2012 (Min and Max)
* ============================================================================
preserve
keep if year >= 2007 & year <= 2012

* Find minimum
egen min_hr = min(ntl_hr)
gen is_min = (ntl_hr == min_hr)
sum year if is_min == 1
local calderon_min_year = r(mean)
sum month if is_min == 1
local calderon_min_month = r(mean)
sum ntl_hr if is_min == 1
local calderon_min_hr = r(mean)

* Find maximum
egen max_hr = max(ntl_hr)
gen is_max = (ntl_hr == max_hr)
sum year if is_max == 1
local calderon_max_year = r(mean)
sum month if is_max == 1
local calderon_max_month = r(mean)
sum ntl_hr if is_max == 1
local calderon_max_hr = r(mean)

restore

* ============================================================================
* Period 2: 2013-2016 (Min)
* ============================================================================
preserve
keep if year >= 2013 & year <= 2016

* Find minimum
egen min_hr = min(ntl_hr)
gen is_min = (ntl_hr == min_hr)
sum year if is_min == 1
local interim_min_year = r(mean)
sum month if is_min == 1
local interim_min_month = r(mean)
sum ntl_hr if is_min == 1
local interim_min_hr = r(mean)

restore

* ============================================================================
* Period 3: 2017-2024 (Max)
* ============================================================================
preserve
keep if year >= 2017 & year <= 2024

* Find maximum
egen max_hr = max(ntl_hr)
gen is_max = (ntl_hr == max_hr)
sum year if is_max == 1
local respike_max_year = r(mean)
sum month if is_max == 1
local respike_max_month = r(mean)
sum ntl_hr if is_max == 1
local respike_max_hr = r(mean)

restore


* Create the plot
twoway ///
    (line ntl_hr year_month, lwidth(medium)) ///
    (line avg_mun_hom year_month, lwidth(medium) lpattern(dash)) ///
    , ///
	xline(`=ym(2013,1)' `=ym(2017,1)', ///
          lpattern(dash) lcolor(black) lwidth(thin)) ///
    xlabel( ///
        `=ym(2007,1)' "2007" ///
        `=ym(2008,1)' "2008" ///
        `=ym(2009,1)' "2009" ///
        `=ym(2010,1)' "2010" ///
        `=ym(2011,1)' "2011" ///
        `=ym(2012,1)' "2012" ///
        `=ym(2013,1)' "2013" ///
        `=ym(2014,1)' "2014" ///
        `=ym(2015,1)' "2015" ///
        `=ym(2016,1)' "2016" ///
        `=ym(2017,1)' "2017" ///
        `=ym(2018,1)' "2018" ///
        `=ym(2019,1)' "2019" ///
        `=ym(2020,1)' "2020" ///
        `=ym(2021,1)' "2021" ///
        `=ym(2022,1)' "2022" ///
        `=ym(2023,1)' "2023" ///
        `=ym(2024,1)' "2024", ///
        angle(45) nogrid ///
    ) ///
    ylabel(, angle(0) nogrid) ///
    xtitle("") ///
    ytitle("Homicides per ten thousand") ///
    title("") ///
    legend( ///
        order(1 "National homicide rate" 2 "Average municipal homicide rate") ///
        position(6) ring(1) cols(2))


* Save the graph
graph export "${FIGURES}Homicide_TS.pdf", replace

* -----------------------------------------------------------------------------
* Make scalars
* -----------------------------------------------------------------------------
* ============================================================================
* Format and save as LaTeX commands
* ============================================================================

* Format homicide rates
local calderon_min_hr_fmt : display %6.2f `calderon_min_hr'
local calderon_max_hr_fmt : display %6.2f `calderon_max_hr'
local interim_min_hr_fmt : display %6.2f `interim_min_hr'
local respike_max_hr_fmt : display %6.2f `respike_max_hr'

* Create month names (optional)
local months "January February March April May June July August September October November December"
local calderon_min_month_name : word `calderon_min_month' of `months'
local calderon_max_month_name : word `calderon_max_month' of `months'
local interim_min_month_name : word `interim_min_month' of `months'
local respike_max_month_name : word `respike_max_month' of `months'

* Write to LaTeX file
file open scalars using "${TABLES}homicide_extrema.tex", write replace

* Calderón period min
file write scalars "\newcommand{\CalderonMinHR}{" `calderon_min_hr_fmt' "}" _n
file write scalars "\newcommand{\CalderonMinYear}{" `calderon_min_year' "}" _n
file write scalars "\newcommand{\CalderonMinMonthName}{" "`calderon_min_month_name'" "}" _n

* Calderón period max
file write scalars "\newcommand{\CalderonMaxHR}{" `calderon_max_hr_fmt' "}" _n
file write scalars "\newcommand{\CalderonMaxYear}{" `calderon_max_year' "}" _n
file write scalars "\newcommand{\CalderonMaxMonthName}{" "`calderon_max_month_name'" "}" _n

* Interim period min
file write scalars "\newcommand{\InterimMinHR}{" `interim_min_hr_fmt' "}" _n
file write scalars "\newcommand{\InterimMinYear}{" `interim_min_year' "}" _n
file write scalars "\newcommand{\InterimMinMonthName}{" "`interim_min_month_name'" "}" _n

* Respike period max
file write scalars "\newcommand{\RespikeMaxHR}{" `respike_max_hr_fmt' "}" _n
file write scalars "\newcommand{\RespikeMaxYear}{" `respike_max_year' "}" _n
file write scalars "\newcommand{\RespikeMaxMonthName}{" "`respike_max_month_name'" "}" _n

file close scalars

