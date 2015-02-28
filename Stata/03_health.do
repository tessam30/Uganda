/*------------------------------------------------------------------------------
# Name:		03_health
# Purpose:	Process household health and child nutrition information
# Author:	Tim Essam
# Created:	2015/2/26
# License:	MIT License
# Ado(s):	labutil, labutil2 (ssc install labutil, labutil2)
# Dependencies: copylables, attachlabels, 00_SetupFoldersGlobals.do
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/03_health", replace
di in yellow "`c(current_date)' `c(current_time)'"

use "$pathraw/GSEC5.dta", replace

* Household illness in past 30 days
g byte illness = (h5q4 == 1)

* Total costs for household due to illness
egen medCosts = total(h5q12), by(HHID)

* Costs per capita
bys HHID: g byte hhtmp = (inlist(h5q12, 0, .)!=1)
egen hhtmptot = total(hhtmp), by(HHID)
g medCostspc = medCosts/hhtmptot

* Total household time lost due to illness
egen medTime = total(h5q6), by(HHID)

* Label variables
la var illness "HH member sick in past 30 days"
la var medCosts "Total hh medical costs"
la var medCostspc "Per capital medical costs"
la var medTime "Total hh time lost due to illness"

* Save data and move to next module
save "$pathout/illness.dta", replace

* Maternal child health issues
use "$pathraw/GSEC6A.dta", clear

* Merge in hh gender information
merge 1:1 HHID PID using "$pathraw/GSEC2.dta"
keep if _merge == 3
drop _merge

* Children breastfed in household?

* Generate child height var assuming 24 month cutoff used correctly
g cheight = h6q28a 
clonevar ageMonths = h6q4
replace cheight = h6q28b if cheight == .


* Calculate z-scores using zscore06 package
zscore06, a(h6q4) s(h2q3) h(cheight) w(h6q27)

* Remove scores that are implausible
replace haz06=. if haz06<-6 | haz06>6
replace waz06=. if waz06<-6 | waz06>5
replace whz06=. if whz06<-5 | whz06>5
replace bmiz06=. if bmiz06<-5 | bmiz06>5

ren haz06 stunting
ren waz06 underweight
ren whz06 wasting
ren bmiz06 BMI

la var stunting "Stunting: Length/height-for-age Z-score"
la var underweight "Underweight: Weight-for-age Z-score"
la var wasting "Wasting: Weight-for-length/height Z-score"

g byte stunted = stunting < -2 if stunting != .
g byte underwgt = underweight < -2 if underweight != . 
g byte wasted = wasting < -2 if wasting != . 
g byte BMIed = BMI <-2 if BMI ~= . 
la var stunted "Child is stunting"
la var underwgt "Child is underweight for age"
la var wasted "Child is wasting"

sum stunted underwgt wasted 

* Look at the outcomes by age category
twoway (lowess stunted ageMonths, mean adjust bwidth(0.5)) /*
*/ (lowess wasted ageMonths, mean adjust bwidth(0.5)) /*
*/ (lowess underwgt ageMonths, mean adjust bwidth(0.5)),  xlabel(0(6)60,  labsize(small))

* child was/is breastfed
g byte breastFed = (h6q6 == 1)

lowess breastFed ageMonths, mean adjust bwidth(0.3)

* child had diarrhea
g byte childDiarrhea = (h6q16 == 1)

* child had fever
g byte childFever = h6q22 == 1

la var breastFed "Child was breastfed"
la var childDiarrhea "Child had diarrhea in last 2 weeks"
la var childFever "Child had fever in last 2 weeks"

