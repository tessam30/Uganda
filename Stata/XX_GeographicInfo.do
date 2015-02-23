/*-------------------------------------------------------------------------------
# Name:		XX_GeographicInfo
# Purpose:	Tidy up geographic information, export to R and jitter GPS for mapping
# Author:	Tim Essam, Ph.D.
# Created:	10/31/2014; 02/19/2015.
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/


* Bring in geographic data

use "$pathraw/GSEC1.dta", clear

* Tidy up some of the string variables
replace h1aq1 = upper(h1aq1) 
replace h1aq2 = upper(h1aq2)

label drop sregion
label def sregion 1 "Kampala" 2 "Central-1" 3 "Central-3" 4 "East-Central" /*
*/ 5 "Eastern" 6 "Mid-North" 7 "North East" 8 "West Nile" 9 "Mid-West" 10 "South-Western"
label values sregion sregion

decode sregion, gen(subRegion)

* Merge in the geovariable information for exportin to R


