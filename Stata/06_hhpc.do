/*-------------------------------------------------------------------------------
# Name:		06_hhpc
# Purpose:	Create preliminary analysis Uganda  
# Author:	Tim Essam, Ph.D.
# Created:	01/12/2015
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/05_hhpc", replace

* Load the assets module
use "$pathraw/GSEC14.dta"

* Merge in geographic information to use when taking median values for assets
merge m:1 HHID using "$pathout/Geovars.dta"

* Check ownership distribution (obviously some outliers)
sum h14q4, d

* Cap owernship number to 20 (may even be too high)
recode h14q4 (21/157 = 20)

* Create a loop to create binaries and counts of the assets in their order
# delimit ;
local assets house building land furniture appliances tv radio generator
	solar bicycle moto vehicle boat othTrans jewelry mobile computer internet
	otherElect;
#delimit cr

* Loop over each asset in order, verifying code using output (p. 24, Section 14)
local count = 1
foreach x of local assets {
	qui g byte `x' = (h14q2 == `count' & h14q3 == 1)
	
	* Check that asset matches order
	display in yellow "`x': `count' asset code"
	local count = `count'+1
	}
*end

foreach name of varlist house-otherElect {
	la var `name' "HH owns at least one `name's"
	bys HHID: g n`name' = (`name' * h14q4)
	replace n`name'=0 if n`name'==. 
	la var n`name' "Total `name's owned by hh"
}
*end

* Check total value of assets for potential outliers
sum h14q5, d
tab h14q5

* Estimate a unit value for items
g unit_price = (h14q5 / h14q4)
