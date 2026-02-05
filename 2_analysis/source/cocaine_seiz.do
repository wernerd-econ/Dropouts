* =============================================================================
* Description:
*   This script makes the descriptive stats for cocaine seizures that
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
use "/Users/wernerd/Desktop/Daniel Werner/seizure_data.dta", clear

* Create date variable
destring Year Month, replace
gen year_month = ym(Year, Month)
format year_month %tm

* Keep big coastal seizure in tonns and events
keep Year Month year_month cs_big cs_big_n

* Create period variable
gen Period = ""
replace Period = "Calderón's War on Drugs" if year_month >= ym(2007,1) & year_month <= ym(2012,12)
replace Period = "Intermediate Period" if year_month >= ym(2013,1) & year_month <= ym(2016,12)
replace Period = "Respike" if year_month >= ym(2017,1) & year_month <= ym(2024,12)

preserve

collapse (mean) mean_cs_big=cs_big mean_cs_big_n=cs_big_n ///
		 (p50) median_cs_big=cs_big median_cs_big_n=cs_big_n ///
         (sd) sd_cs_big=cs_big sd_cs_big_n=cs_big_n, ///
         by(Period)

* Add overall stats
tempfile period_stats
save `period_stats'
restore

* Get overall stats for cs_big
summarize cs_big, detail
local overall_mean_big = r(mean)
local overall_sd_big = r(sd)
local overall_median_big = r(p50)

* Get overall stats for cs_big_n
summarize cs_big_n, detail
local overall_mean_big_n = r(mean)
local overall_sd_big_n = r(sd)
local overall_median_big_n = r(p50)

use `period_stats', clear
set obs `=_N+1'
replace Period = "Overall" in `=_N'
replace mean_cs_big = `overall_mean_big' in `=_N'
replace sd_cs_big = `overall_sd_big' in `=_N'
replace median_cs_big = `overall_median_big' in `=_N'
replace mean_cs_big_n = `overall_mean_big_n' in `=_N'
replace sd_cs_big_n = `overall_sd_big_n' in `=_N'
replace median_cs_big_n = `overall_median_big_n' in `=_N'

* Order the periods
gen order = .
replace order = 1 if Period == "Overall"
replace order = 2 if Period == "Calderón's War on Drugs"
replace order = 3 if Period == "Intermediate Period"
replace order = 4 if Period == "Respike"
sort order

* Save variables with proper formatting
* cs_big variables
local overall_big : display %4.1f mean_cs_big[1]
local overall_big_sd : display %4.1f sd_cs_big[1]
local overall_big_median : display %4.1f median_cs_big[1]
local calderon_big : display %4.1f mean_cs_big[2]
local calderon_big_sd : display %4.1f sd_cs_big[2]
local calderon_big_median : display %4.1f median_cs_big[2]
local inter_big : display %4.1f mean_cs_big[3]
local inter_big_sd : display %4.1f sd_cs_big[3]
local inter_big_median : display %4.1f median_cs_big[3]
local respike_big : display %4.1f mean_cs_big[4]
local respike_big_sd : display %4.1f sd_cs_big[4]
local respike_big_median : display %4.1f median_cs_big[4]

* cs_big_n variables
local overall_n : display %4.0f mean_cs_big_n[1]
local overall_n_sd : display %4.0f sd_cs_big_n[1]
local overall_n_median : display %4.0f median_cs_big_n[1]
local calderon_n : display %4.0f mean_cs_big_n[2]
local calderon_n_sd : display %4.0f sd_cs_big_n[2]
local calderon_n_median : display %4.0f median_cs_big_n[2]
local inter_n : display %4.0f mean_cs_big_n[3]
local inter_n_sd : display %4.0f sd_cs_big_n[3]
local inter_n_median : display %4.0f median_cs_big_n[3]
local respike_n : display %4.0f mean_cs_big_n[4]
local respike_n_sd : display %4.0f sd_cs_big_n[4]
local respike_n_median : display %4.0f median_cs_big_n[4]

* Write table 
file open myfile using "${TABLES}seizure_stats.tex", write replace

* Write table header
file write myfile "\begin{tabular}{l c c c c}" _n
file write myfile "\hline" _n
file write myfile ///
" & \shortstack{Full sample \\ (2007-2024)}" ///
" & \shortstack{War on drugs \\  (2007-2012)}" ///
" & \shortstack{Interim \\  (2013-2016)}" ///
" & \shortstack{Resurgence \\  (2017-2024)} \\"  _n
file write myfile "\hline" _n

* Panel A: cs_big
file write myfile "\multicolumn{5}{l}{\textit{Panel A: Seizures (Metric Tons)}} \\" _n
file write myfile "Mean" _n
file write myfile " & `overall_big' & `calderon_big' & `inter_big' & `respike_big' \\" _n
file write myfile "Median" _n
file write myfile " & `overall_big_median' & `calderon_big_median' & `inter_big_median' & `respike_big_median' \\" _n
file write myfile "Std. dev" _n
file write myfile " & `overall_big_sd' & `calderon_big_sd' & `inter_big_sd' & `respike_big_sd' \\" _n
file write myfile "\hline" _n

* Panel B: cs_big_n
file write myfile "\multicolumn{5}{l}{\textit{Panel B: Seizure Events}} \\" _n
file write myfile "Mean" _n
file write myfile " & `overall_n' & `calderon_n' & `inter_n' & `respike_n' \\" _n
file write myfile "Median" _n
file write myfile " & `overall_n_median' & `calderon_n_median' & `inter_n_median' & `respike_n_median' \\" _n
file write myfile "Std. dev" _n
file write myfile " & `overall_n_sd' & `calderon_n_sd' & `inter_n_sd' & `respike_n_sd' \\" _n

* Close table
file write myfile "\hline" _n
file write myfile "\end{tabular}" _n
file close myfile
* =============================================================================
* II. Create Time Seires Plots Of Ntl HR and Average Municipal HR 
* =============================================================================
use "/Users/wernerd/Desktop/Daniel Werner/seizure_data.dta", clear

* Keep big coastal seizure in tons and events
keep Year Month cs_big

* Create date variable for monthly data
destring Month, replace
gen year_month = ym(Year, Month)
format year_month %tm

* Collapse to monthly level
preserve
collapse (sum) cs_big_monthly=cs_big, by(year_month)
tempfile monthly_data
save `monthly_data'
restore

* Collapse to yearly level
collapse (sum) cs_big_yearly=cs_big, by(Year)

* Create yearly date variable (use middle of year for plotting)
gen year_month = ym(Year, 7)  // July of each year
format year_month %tm

* Merge with monthly data
merge 1:m year_month using `monthly_data'

sort year_month

* Create the plot
twoway ///
    (line cs_big_monthly year_month, lwidth(thin) lcolor(navy)) ///
    (line cs_big_yearly year_month, lwidth(thin) lcolor(red) lpattern(solid)) ///
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
    ytitle("Metric tonnes") ///
    title("") ///
    legend( ///
        order(1 "Monthly seizures" 2 "Yearly seizures") ///
        position(6) ring(1) cols(2))
		
* Save the graph
graph export "${FIGURES}Seizure_TS.pdf", replace
