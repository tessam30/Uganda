/*-------------------------------------------------------------------------------
# Name:		XX_FCS
# Purpose:	Create dietary diversity and food consumption scores for Uganda HH
# Author:	Tim Essam, Ph.D.
# Created:	10/31/2014; 02/19/2015.
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/
clear
capture log close
log using "$pathlog/fcs.log", replace
set more off

use "$pathraw/GSEC15B.dta", replace

* Fix observations who are missing ConsCategory information
* Export missing to spreadsheet, use concatenate command to write commands and order
tab itmcd if h15bq2c ==., sort

* Replace consumption category information with info based on type of food
replace h15bq2c = 1 if (inlist(itmcd, 110, 112, 113, 114, 115, 116, 138)==1 & h15bq2c ==.)
replace h15bq2c = 2 if (inlist(itmcd, 101, 102, 105, 107, 108, 109)==1 & h15bq2c ==.)
replace h15bq2c = 3 if itmcd == 147 & h15bq2c ==.
replace h15bq2c = 4 if (inlist(itmcd, 140, 141, 144)==1 & h15bq2c ==.)
replace h15bq2c = 6 if (inlist(itmcd, 135, 136, 137, 139)==1 & h15bq2c ==.)
replace h15bq2c = 7 if (inlist(itmcd, 130, 132, 133)==1 & h15bq2c ==.)
replace h15bq2c = 8 if (inlist(itmcd, 117, 118, 119, 122, 123, 124)==1 & h15bq2c ==.)
replace h15bq2c = 9 if itmcd == 125 & h15bq2c ==.
replace h15bq2c = 10 if (inlist(itmcd, 127, 129, 150)==1 & h15bq2c ==.)
replace h15bq2c = 11 if (inlist(itmcd, 148, 149, 151, 152, 153, 155, 156, 158)==1 & h15bq2c ==.)

* Create variables to calculate Food Consumption Score 
egen cereal_days = max(h15bq3b) if inlist(h15bq2c, 1), by(HHID)
g cerealFCS = cereal_days * 2

egen starches_days = max(h15bq3b) if inlist(h15bq2c, 2), by(HHID)
g starchesFCS = starches_days * 2

* wheat, rice, cereal, starch
egen staples_days = max(h15bq3b) if inlist(h15bq2c, 1, 2), by(HHID)
g staplesFCS = staples_days * 2

* legumes, beans, lentils, nuts, peas & nuts and seeds
egen pulse_days = max(h15bq3b) if inlist(h15bq2c, 4, 5), by(HHID)
g pulseFCS = pulse_days * 3

* Both weighted by 1
egen veg_days = max(h15bq3b) if inlist(h15bq2c, 6), by(HHID)
g vegFCS = veg_days

egen fruit_days = max(h15bq3b) if inlist(h15bq2c, 7), by(HHID)
g fruitFCS = fruit_days

* meat, poultry, fish, eggs
egen meat_days = max(h15bq3b) if inlist(h15bq2c, 8), by(HHID)
g meatFCS = meat_days * 4

egen milk_days = max(h15bq3b) if inlist(h15bq2c, 9), by(HHID)
g milkFCS = milk_days * 4

egen sugar_days = max(h15bq3b) if inlist(h15bq2c, 3), by(HHID)
g sugarFCS = sugar_days * 0.5

egen oil_days = max(h15bq3b) if inlist(h15bq2c, 10), by(HHID)
g oilFCS = oil_days * 0.5

* Check "Outside food and drink" to ensure that you are not missing major consumables
tab itmcd if h15bq2c == 12

* Label the variables, get their averages and plot them on same graph to compare
local ftype cereal starches staples pulse veg fruit meat milk sugar oil 
local n: word count `ftype'
forvalues i = 1/`n' {
	local a: word `i' of `ftype'
	la var `a'_days "Number of days consuming `a'"
	la var `a'FCS "Food consumption score for `x'"
	replace `a'_days = 0 if `a'_days == .
	replace `a'FCS = 0 if `a'FCS == .
}
*end

/* Create dietary diversity variable consisting of following food groups:
  1) Cereals - cereal_days & pulses (x)
  2) White roots and tubers - Starches (x)
  3) Vegetables (x)
  4) Fruits (x)
  5) Meat (x)
  6) Eggs (x) 
  7) Fish and other seafood (x)
  8) Legumes, nuts and seeds (x)
  9) Milk and milk products (x)
  10) Oils an fats 
  11) Sweets*
  12) Apices condiments and beverages	*/
  
local dietDiv cereal starches fruit veg pulse sugar milk
foreach x of local dietDiv {
	g byte `x' = inlist(`x'_days, 0, .) != 1
}
*end  

g byte eggs	= (inlist(h15bq3b, 1, 2, 3, 4, 5, 6, 7) & h15bq2c == 8 & itmcd == 124)
g byte meat	= (inlist(h15bq3b, 1, 2, 3, 4, 5, 6, 7) & h15bq2c == 8 & inlist(itmcd, 122, 123, 124)!=1)
g byte fish	= (inlist(h15bq3b, 1, 2, 3, 4, 5, 6, 7) & h15bq2c == 8 & inlist(itmcd, 122, 123)==1)
g byte oil 	= (inlist(h15bq3b, 1, 2, 3, 4, 5, 6, 7) & h15bq2c == 10 & inlist(itmcd, 150) != 1)
g byte cond = (inlist(h15bq3b, 1, 2, 3, 4, 5, 6, 7) & h15bq2c == 10 & inlist(itmcd, 150) == 1)

local dietLab cereal starches fruit veg pulse sugar milk eggs meat fish oil cond 
foreach x of local dietLab {
	la var `x' "Consumed `x' in last 7 days"
}
*end

* Check  househlolds not reporting any consumption
egen tmp = rsum(cereal starches fruit veg pulse sugar milk eggs meat fish oil cond)
egen tmpsum = total(tmp), by(HHID)
* for checking which HH are missing all consumption information
* br if tmpsum == 0
drop tmp tmpsum

* Keep derived data (FCS & dietary diversity scores) and HHID
ds(h15* itmcd untcd), not
keep `r(varlist)'

* Collapse down to household level using max option, retain labels
qui include "$pathdo2/copylabels.do"
ds(HHID), not
collapse (max) `r(varlist)', by(HHID)
qui include "$pathdo2/attachlabels.do"

* Create food consumption score (FCS) and dietary diversity variables
egen FCS = rsum2(staplesFCS pulseFCS vegFCS fruitFCS meatFCS milkFCS sugarFCS oilFCS)
egen dietDiv = rsum(cereal starches fruit veg pulse sugar milk eggs meat fish oil cond)

* Clone FCS and recode based on Bangladesh thresholds
clonevar FCS_categ = FCS 
recode FCS_categ (0/21 = 0) (21.5/35 = 1) (35.1/53 = 2) (53/112 = 3)
lab def fcscat 0 "Poor" 1 " Borderline" 2 " Acceptable low" 3 "Acceptable high"
lab val FCS_categ fcscat
la var FCS_categ "Food consumption score category"
tab FCS_cat, mi

* Some households have scores of zero which means they didn't eat or values are miscoded
sum *FCS dietDiv
assert FCS <= 112
assert dietDiv <= 12
la var FCS "Food Consumption Score"
la var dietDiv "Dietary diversity (12 food groups)"
g byte foodTag = inlist(dietDiv, 0, 1) == 1

save "$pathout/fstmp.dta", replace

* Load module on fortified food consumption
use "$pathraw/GSEC15BB", replace

g byte foodFtfd = (h15bq14 == 1 & h15bq15 == 1)
la var foodFtfd "HH consumes fortified food"

g byte maizeFtfd = 	(h15bq14 == 1 & h15bq15 == 1 & h15bqid == 113)
g byte oilFtfd 	 = 	(h15bq14 == 1 & h15bq15 == 1 & h15bqid == 127)
g byte sugarFtfd = 	(h15bq14 == 1 & h15bq15 == 1 & h15bqid == 147)
g byte saltFtfd  = 	(h15bq14 == 1 & h15bq15 == 1 & h15bqid == 150)

la var maizeFtfd "HH consumes fortified maize"
la var oilFtfd 	 "HH consumes fortified oil"
la var sugarFtfd "HH consumes fortified oil"
la var saltFtfd  "HH consumes fortified salt"

* keep new variables
ds(h15* result_code), not
keep `r(varlist)'

qui include "$pathdo2/copylabels.do"
ds(HHID), not
collapse (max) `r(varlist)', by(HHID)
qui include "$pathdo2/attachlabels.do"

* Merge with other food consumption data
merge 1:1 HHID using "$pathout/fstmp.dta", gen(food_merge)
drop if food_merge ==1
drop food_merge
compress

save "$pathout/fstmp2.dta", replace

* Bring in food security information (pp 32)
use "$pathraw/GSEC17A.dta", clear

* Create baseic welfare indicators
g byte clothing =  h17q2 == 1
la var clothing "Every hh member owns 2 sets of clothing"

g byte blanket = h17q3 == 1 
la var blanket "Every child in hh has a blanket"

g byte shoes = h17q4 == 1
la var shoes "Every member has at least 1 pair of shoes"

clonevar mealsTaken = h17q5
recode mealsTaken (10 = .) (14 = .)

clonevar saltShortage = h17q6
clonevar bkfst_ychild = h17q7
clonevar bkfst_child = h17q7

clonevar foodLack = h17q9

* Keep new variables and HHID
ds(h17* result_code), not
keep `r(varlist)'

* Merge with other diet information data
merge 1:1 HHID using "$pathout/fstmp2.dta"
compress
save "$pathout/foodSecurity.dta", replace
erase "$pathout/fstmp.dta"
erase "$pathout/fstmp2.dta"

* Merge in Geovars for R graphics
merge 1:1 HHID using "$pathout/Geovars.dta", gen(geo_merge)
drop geo_merge

* Check correlation of FCS and Dietary Diversity
twoway (lpolyci FCS dietDiv if foodTag!=1, /*
*/fitplot(connected)), ytitle(Food Consumption Score) /*
*/xtitle(Dietary Diversity) title(FCS & Dietary Diversity/*
*/ Correlation) legend(order(1 "95% CI" 2 "Local Polynomial Smoothed")) scheme(mrc)
pwcorr FCS dietDiv, sig

* Export a cut of FCS and dietary diversity to R for plotting
preserve
keep if foodTag != 1
keep staples_days pulse_days milk_days meat_days veg_days oil_days sugar_days /*
*/ fruit_days FCS HHID region urban subRegion hid
rename *_days* *
order oil staples veg pulse sugar milk meat fruit FCS 
export delimited using "$pathexport/food.consumption.score.csv", replace
restore

preserve
keep if foodTag != 1



