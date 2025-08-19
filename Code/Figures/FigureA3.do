cls
clear all

global path "C:\Users\scottjmk\DropBox\Research\petra_moser\Replication"

gen demog_type = "`demog_type'"
save "$path\Data\PanelData\EventStudies\Temp\\output.dta", replace

foreach demog_type in Mothers Fathers OtherWomen OtherMen {
	use "$path\Data\PanelData\EventStudies\\`demog_type'.dta", clear
	
	gen patent_1000 = patent_avg*1000
	keep if age >= 18 & age <= 65
	
	char age[omit] 20
	xi i.age
	save "$path\Data\PanelData\EventStudies\Temp\\input.dta", replace
	
	set more off
	display "    " 
	display "`demog_type' `patent_1000'"
	display "    " 

	use "$path\Data\PanelData\EventStudies\Temp\\input.dta", clear	
	
	reg patent_1000 _Iage* i.year i.cluster, r

	gen b  = .
	gen bL = .
	gen bH = .
	replace b  = 0                                         if age == 20
	replace bL = 0                                         if age == 20
	replace bH = 0                                         if age == 20

	foreach i of numlist 18(1)65 {
		display "age " `i'
		if `i' ~= 20 {
			replace b  = _b[_Iage_`i']                             if age == `i'
			replace bL = _b[_Iage_`i'] - 1.96*_se[_Iage_`i'] if age == `i'
			replace bH = _b[_Iage_`i'] + 1.96*_se[_Iage_`i'] if age == `i'
		}
	}
		
	keep age b bL bH
	sort age
	collapse b bL bH, by(age)

	gen variable = "patent_1000"
	gen demog_type = "`demog_type'"
		
	append using "$path\Data\PanelData\EventStudies\Temp\\output.dta"
				
	save "$path\Data\PanelData\EventStudies\Temp\\output.dta", replace
}

clear all


display "    " 
display "patent_1000"
display "    " 

use "$path\Data\PanelData\EventStudies\Temp\\output.dta", clear

keep b bL bH variable age demog_type

reshape wide b bL bH, i(variable age) j(demog_type, string)

global axis1 xlabel(20(5)65, nogrid) ylabel(-50(50)200, angle(0) nogrid) xline(27)
	
twoway (line bMothers age, lcolor(black)) (line bOtherWomen age, lcolor(black) lpattern(shortdash)) (line bFathers age, lcolor(gs10)) (line bOtherMen age, lcolor(gs10) lpattern(shortdash)), graphregion(color(white)) xtitle("") ytitle("Patents") legend(order(1 "Mothers" 2 "Other Women" 3 "Fathers" 4 "Other Men") col(2)) $axis1 
graph export "$path\\Output\Figures\FigureA3.png", as(png) replace
