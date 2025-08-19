cls
clear all

global path "C:\Users\scottjmk\DropBox\Research\petra_moser\Replication"

gen demog_type = "`demog_type'"
save "$path\Data\PanelData\EventStudies\Temp\\output.dta", replace

foreach demog_type in Mothers Fathers OtherWomen OtherMen {
	use "$path\Data\PanelData\EventStudies\\`demog_type'.dta", clear
	
	keep if age >= 18 & age <= 65
	keep if academic == 1
	drop if tenureprofyear == .
	gen paper_100 = paper_avg*100
	gen deltaten = year - tenureprofyear
	keep if deltaten >= -10 & deltaten <= 20
	
	char deltaten[omit] -1
	xi i.deltaten
	save "$path\Data\PanelData\EventStudies\Temp\\input.dta", replace
	
	set more off
	display "    " 
	display "`demog_type' `paper_100'"
	display "    " 

	use "$path\Data\PanelData\EventStudies\Temp\\input.dta", clear	
		
	reg paper_100 _Ideltaten* i.year i.age i.cluster_vols_13, r

	gen b  = .
	gen bL = .
	gen bH = .
	replace b  = 0                                         if deltaten == -1
	replace bL = 0                                         if deltaten == -1
	replace bH = 0                                         if deltaten == -1

	foreach i of numlist 1(1)31 {
		display "deltaten " `i'-11
		if `i' ~= 10 {
			replace b  = _b[_Ideltaten_`i']                             if deltaten == `i'-11
			replace bL = _b[_Ideltaten_`i'] - 1.96*_se[_Ideltaten_`i'] if deltaten == `i'-11
			replace bH = _b[_Ideltaten_`i'] + 1.96*_se[_Ideltaten_`i'] if deltaten == `i'-11
		}
	}
		
	keep deltaten b bL bH
	sort deltaten
	collapse b bL bH, by(deltaten)

	gen variable = "paper_100"
	gen demog_type = "`demog_type'"
		
	append using "$path\Data\PanelData\EventStudies\Temp\\output.dta"
				
	save "$path\Data\PanelData\EventStudies\Temp\\output.dta", replace
}

clear all


display "    " 
display "paper_100"
display "    " 

use "$path\Data\PanelData\EventStudies\Temp\\output.dta", clear

keep b bL bH variable deltaten demog_type

reshape wide b bL bH, i(variable deltaten) j(demog_type, string)

global axis1 xlabel(-10(5)20, nogrid) ylabel(-10(5)10, angle(0) nogrid) xline(-1) ttext(10 1.5 "Tenure − 1")
	
twoway (line bMothers deltaten, lcolor(black)) (line bOtherWomen deltaten, lcolor(black) lpattern(shortdash)) (line bFathers deltaten, lcolor(gs10)) (line bOtherMen deltaten, lcolor(gs10) lpattern(shortdash)), graphregion(color(white)) xtitle("Years Relative to Tenure") ytitle("Publications") legend(order(1 "Mothers" 2 "Other Women" 3 "Fathers" 4 "Other Men") col(2)) $axis1 
graph export "$path\\Output\Figures\Figure8.png", as(png) replace

