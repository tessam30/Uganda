/*-------------------------------------------------------------------------------
# Name:		XX_tlus
# Purpose:	Process household data and create tropical livestock assets
# Author:	Tim Essam, Ph.D.
# Created:	2015/03/07
# Modified: 2015/03/07
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	labutil, labutil2 (ssc install labutil, labutil2)
# Dependencies: copylables, attachlabels, 00_SetupFoldersGlobals.do
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/XX_TLUs",  replace
set more off

/* Load module with information on household assets. */
use "$pathraw/












* create vector of assets for which binary variables are created
#delimit ;
local lvstk bullock mcow buffalo goat sheep
		chicken duck othbirds other;
#delimit cr

* Create three livestock variables all related to holdings in time.
local count = 1
foreach x of local lvstk {
	bys a01: g `x' = k1_04 if (livestock == `count')
	bys a01: g `x'2011beg = k1_02a if livestock == `count'
	bys a01: g `x'2011end = k1_03a if livestock == `count'
	
	replace `x' = 0 if `x' ==.
	replace `x'2011beg = 0 if `x'2011beg == .
	replace `x'2011end = 0 if `x'2011end == .	
	la var `x' "Total `x' owned by hh now "
	la var `x'2011beg "Total `x' owned in beg 2011"
	la var `x'2011end "Total `x' owned in end 2011"
	
	bys a01: g `x'diff = `x'2011end - `x'2011beg
	la var `x'diff "Change in `x' during 2011"
	
	* Check that asset matches order
	display in yellow "`x': `count' livestock code"
	local count = `count'+1
	
	* Number seven skipped in survey for whatever reason
	if `count' == 7 {
		local count = `count' + 1
		}
	}
*end

* Determine market unit price by taking total net value of sales / number sold
replace k1_18 =. if k1_18 == 0
g unitprice = round(k1_18/ k1_16, 1)
la var unitprice "Unit price of animal (based on sales)"

* Calculate the median value of each animal in Bangladesh based on unit price
egen medvalanim = median(unitprice), by(livestock)
bys livestock: g valanim = k1_04 * medvalanim
la var valanim "Value of animal"

*Calculate hh-level total
egen tvalanim = total(valanim), by(a01)
la var tvalanim "Total value of animals"

/* Price summary of animals
Livestock	Med. Val	Freq.
bullock		18400	0	2103
milk cow	14500	0	1739
bufallo		15000	0	20
goat		2200	0	1268
sheep		1933.5	0	70
chicken		170		0	4241
duck		200		0	2170
other bir	75		0	192
others		60		0	77
*/

* Collapse data down to household level (keep new vars and hh-id).
ds(k1* livestock), not
keep `r(varlist)'

* Collapse to household level with usual pre/post labels
include "$pathdo/copylabels.do"
collapse (max) bullock-otherdiff tvalanim, by(a01) fast
include "$pathdo/attachlabels.do"

* Merge in ag assets to get horse and mules
merge 1:1 a01 using "$pathout/hhpc.dta", gen(TLU_merge)

/*Create TLU (based on values from http://www.fao.org/wairdocs/ilri/x5443e/x5443e04.htm)
Notes: Sheep includes sheep and goats
Horse includes all draught animals (donkey, horse, bullock)
chxTLU includes all small animals (chicken, fowl, etc).*/
g cattleVal = 0.70
g sheepVal = 0.10
g horsesVal = 0.80
g mulesVal = 0.70
g assesVal = 0.50
g chxVal = 0.01

* Create TLU group values
g TLUcattle = (bullock + mcow + buffalo) * cattleVal
g TLUsheep = (sheep + goat) * sheepVal
g TLUhorses = (nhorse) * horsesVal
g TLUmules = (nmule) * mulesVal
g TLUasses = ndonkey * assesVal
g TLUchx = (chicken + duck + othbirds + other) * chxVal

* Generate overall TLUs
egen TLUtotal = rsum(TLUcattle TLUsheep TLUhorses TLUmules TLUasses TLUchx)
la var TLUtotal "Total tropical livestock units"

* Clean up extra variables
drop cattleVal horsesVal mulesVal assesVal sheepVal chxVal TLUcattle TLUsheep TLUhorses TLUmules TLUasses TLUchx

* Compress & save
save "$pathout/hhTLU_pc.dta", replace
log2html "$pathlog/04_TLUs", replace
log close
