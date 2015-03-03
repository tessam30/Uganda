/*-------------------------------------------------------------------------------
# Name:		05_hhinfra
# Purpose:	Create preliminary analysis Uganda  
# Author:	Tim Essam, Ph.D.
# Created:	01/12/2015
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

capture log close
log using "$pathlog/05_hhchar", replace
use "$pathraw/GSEC9A.dta", clear

* Type of dwelling
g byte hutDwelling = (h9q1 == 7)
la var hutDwelling "Household dwelling is a hut"

* g byte hh owns dwelling
g byte ownDwelling = inlist(h9q2, 1, 2, 3)
la var ownDwelling "hh owns dwelling"

* g dwelling rooms size
clonevar dwellingSize = h9q3
recode dwellingSize (0 = 1)

* metal roof
g byte metalRoof = inlist(h9q4, 4, 7, 8, 10) == 1
la var metalRoof "dwelling has a metal/tin roof"

* mud home/hut?
g byte mudDwelling = inlist(h9q5, 1, 2, 3) == 1
la var mudDwelling "dwelling is made primarily of mud"

* Dirt floor?
g byte dfloor = inlist(h9q6, 1, 2) == 1
la var dfloor "dwelling has mud/dirt/earth floor" 

* HH has protected water source
g byte protWater = inlist(h9q7, 1, 2, 3, 4, 5) == 1
la var protWater "hh has protected water source"

* Time to get drinking water
g waterTime = (h9q9a+ h9q9b)
la var waterTime "Total time required to get drinking water"

* Distance to water source
clonevar waterDist = h9q10

* HH purchase water used
clonevar waterPay = h9q12
recode waterPay (2 = 0)

* What does hh do to make water safe
g byte safeWater = inlist(h9q17, 1, 2, 3) == 1
la var safeWater "hh boil/filters water to make water safe"

*************
* Sanitation*
*************

* HH has private, covered latrine
g byte latrineCovered = inlist(h9q22, 5, 8) != 1

* HH has hand-washing facility at toilet
g byte latrineWash = (h9q23 != 1)

la var latrineCovered "hh has access to covered latrine"
la var latrineWash "hand washing station facility at toilet"

* Save create variables and collapse
ds(h9q*), not
keep `r(varlist)'

* Copy variable labels to reapply after collapse
include "$pathdo2/copylabels.do"

ds(HHID), not
collapse (max) 	`r(varlist)', by(HHID)

* Reapply variable lables & value labels
include "$pathdo2/attachlabels.do"

* Save data
save "$pathout/hhinfra_tmp", replace

* Create energy use variables
use "$pathraw/GSEC10A.dta", clear

* House has electricity
clonevar electricity = h10q1
recode electricity (2 = 0)

* Stove used by hh
g byte openFire = h10q9 == 8
la var openFire "hh uses open fire for stove"

g byte outdoorStove = h10q12 == 3
la var outdoorStove "hh has outdoor stove"

ds(h10q*), not
keep `r(varlist)'

save "$pathout/hhenergy.dta", replace

* Load in asset module 
