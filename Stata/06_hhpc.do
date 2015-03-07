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
log using "$pathlog/06_hhpc", replace
set more off

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


* Estimate a unit value for items using median and mean values

* Another method for hhdurval
egen munitprice = median(h14q5/h14q4) if inlist(h14q4, ., 0)!=1, by(h14q2 subRegion) 
la var munitprice "Median price of durable asset"

egen mnunitprice = mean(h14q5/h14q4) if inlist(h14q4, ., 0)!=1, by(h14q2 subRegion) 
la var mnunitprice "Mean price of durable asset"

* Calculate total value of all durables
egen hhdurasset_md = total(h14q4 * munitprice) if inlist(h14q4, ., 0)!=1, by(HHID)
egen hhdurasset_mn = total(h14q4 * mnunitprice) if inlist(h14q4, ., 0)!=1, by(HHID)

* Caculate total household value of all durables

la var hhdurasset_md "Total value of all durable assets using sub-region item median"
la var hhdurasset_mn "Total value of all durable assets using sub-region item mean"
replace hhdurasset_md = . if hhdurasset_md == 0
replace hhdurasset_mn = . if hhdurasset_mn == 0

* Create hh tota durables value
*egen hhDurablesValue = sum(h14q5), by(HHID h14q2)
egen hhDurablesTotVal = sum(h14q5) if h14q4!=., by(HHID)
la var hhDurablesTotVal "Total value of durables using hh reported figures"

* Generate hh total durables value minus house and land
egen hhDurVal_sub = sum(h14q5) if h14q4!=. & inlist(h14q2, 2, 3, 4)!= 1, by(HHID)
la var hhDurVal_sub "total value of durables not including house, land or buildings"

*tabstat hhDurablesValue, by(d1_02) stat(mean sd min max)

drop h14* region regurb district county subRegion dist* af_* result_code /*
*/  _merge longitude latitude munit* mnunit*


* Collapse down to HH level
include "$pathdo/copylabels.do"
ds (HHID hid urban), not
collapse (max)`r(varlist)' (mean) hid , by(HHID urban)
include "$pathdo/attachlabels.do"

* Create a durable asset index based on core assets (not including house, land, building)
#delimit ;


global factors "furniture appliances tv radio bicycle 
		moto jewelry mobile";
#delimit cr
sum $factors if urban == 0

factor $factors if urban == 0 , pcf
predict wealth_rural if urban ==0
la var wealth_rural "wealth index"
alpha $factors if urban == 0
scree

* Plot the factor loadings to see what is driving resultst
* Plot loadings for review
loadingplot, mlabs(small) mlabc(maroon) mc(maroon) /*
	*/ xline(0, lwidth(med) lpattern(tight_dot) lcolor(gs10)) /*
	*/ yline(0, lwidth(med) lpattern(tight_dot) lcolor(gs10)) /*
	*/ title(Household infrastructure index loadings)
graph export "$pathgraph\WealthLoadings.png", as(png) replace
scree, title(Scree plot of wealth index)


factor $factors , pcf
predict wealth_all
la var wealth_all "wealth index (all)"
alpha $factors
scree

save "$pathout/hhpc.dta", replace
log2html "$pathlog/06_hhpc", replace
capture log close


