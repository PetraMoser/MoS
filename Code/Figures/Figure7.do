cls
clear all

global path "C:\Users\scottjmk\DropBox\Research\petra_moser\Replication"

gen demog_type = "`demog_type'"
save "$path\Data\PanelData\EventStudies\Temp\\output.dta", replace

foreach demog_type in Mothers Fathers OtherWomen OtherMen {
	use "$path\Data\PanelData\EventStudies\\`demog_type'.dta", clear
	
	keep if age >= 18 & age <= 65
	keep if academic == 1
	drop if yearofmarriage == .
	drop if asstprofyear == .
	gen deltamarr = year - yearofmarriage
	keep if deltamarr >= -5 & deltamarr <= 30
	
	char deltamarr[omit] -1
	xi i.deltamarr
	save "$path\Data\PanelData\EventStudies\Temp\\input.dta", replace
	
	set more off
	display "    " 
	display "`demog_type' `tenureprof_cum'"
	display "    " 

	use "$path\Data\PanelData\EventStudies\Temp\\input.dta", clear	
		
	reg tenureprof_cum _Ideltamarr* i.year i.cluster_vols_13, r

	gen b  = .
	gen bL = .
	gen bH = .
	replace b  = 0                                         if deltamarr == -1
	replace bL = 0                                         if deltamarr == -1
	replace bH = 0                                         if deltamarr == -1

	foreach i of numlist 1(1)36 {
		display "deltamarr " `i'-6
		if `i' ~= 5 {
			replace b  = _b[_Ideltamarr_`i']                             if deltamarr == `i'-6
			replace bL = _b[_Ideltamarr_`i'] - 1.96*_se[_Ideltamarr_`i'] if deltamarr == `i'-6
			replace bH = _b[_Ideltamarr_`i'] + 1.96*_se[_Ideltamarr_`i'] if deltamarr == `i'-6
		}
	}
		
	keep deltamarr b bL bH
	sort deltamarr
	collapse b bL bH, by(deltamarr)

	gen variable = "tenureprof_cum"
	gen demog_type = "`demog_type'"
		
	append using "$path\Data\PanelData\EventStudies\Temp\\output.dta"
				
	save "$path\Data\PanelData\EventStudies\Temp\\output.dta", replace
}

clear all


display "    " 
display "tenureprof_cum"
display "    " 

use "$path\Data\PanelData\EventStudies\Temp\\output.dta", clear

keep b bL bH variable deltamarr demog_type

reshape wide b bL bH, i(variable deltamarr) j(demog_type, string)

global axis1 xlabel(-5(5)30, nogrid) ylabel(-0.2(0.2)1, angle(0) nogrid) xline(-1) ttext(1 2.5 "Marriage − 1")
	
twoway (line bMothers deltamarr, lcolor(black)) (line bOtherWomen deltamarr, lcolor(black) lpattern(shortdash)) (line bFathers deltamarr, lcolor(gs10)) (line bOtherMen deltamarr, lcolor(gs10) lpattern(shortdash)), graphregion(color(white)) xtitle("Years Relative to Marriage") ytitle("Probability Tenured Professor") legend(order(1 "Mothers" 2 "Other Married Women" 3 "Fathers" 4 "Other Married Men") col(2)) $axis1 
graph export "$path\\Output\Figures\Figure7.png", as(png) replace

