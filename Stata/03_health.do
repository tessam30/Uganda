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

