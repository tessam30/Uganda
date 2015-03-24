/*-------------------------------------------------------------------------------
# Name:		101_dataExport
# Purpose:	Create preliminary cut of data for base maps  
# Author:	Tim Essam, Ph.D.
# Created:	03/24/2015
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
u "$pathout/hhchar.dta"

local mlist health shocks health foodSecurityGeo  hhinfra hhpc   
local i = 1
foreach x of local mlist {
	merge 1:1 HHID using "$pathout/`x'.dta", gen(merge_`i')
	local i = `i' + 1
	display "`x'"
}
*end

