* =============================================================================
* Description:
*   This script makes the histogram of distances to the pacific. 
*
* Author: Daniel Werner 
* Date: Feb. 04, 2026
* =============================================================================

* -----------------------------
* 0) Set paths and create folders
* -----------------------------
global FIGURES "../output/Figures/"
capture mkdir "${FIGURES}"

use "/Users/wernerd/Desktop/Daniel Werner/final_geo.dta", clear

* Drop duplicates (keep only unique municipality observations)
duplicates drop municipality, force

* Make histogram
histogram d_to_pc, ///
    frequency ///
    fcolor(maroon) ///
    lcolor(black) ///
    xlabel(, angle(0) nogrid) ///
    ylabel(, angle(0) nogrid) ///
    xtitle("Distance to pacific coast (km)") ///
    ytitle("Number of municipalities") ///
    title("") ///
    graphregion(color(white)) plotregion(color(white))
	
* Save the graph
graph export "${FIGURES}d_to_pc_distribution.pdf", replace
