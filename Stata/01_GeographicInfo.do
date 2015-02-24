/*-------------------------------------------------------------------------------
# Name:		01_GeographicInfo
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

* Create additional ID variable to merge back in on (string gives problems)
sort HHID
egen hid = group(HHID)
la var hid "Unique ID numeric"

label drop sregion
label def sregion 1 "Kampala" 2 "Central-1" 3 "Central-3" 4 "East-Central" /*
*/ 5 "Eastern" 6 "Mid-North" 7 "North East" 8 "West Nile" 9 "Mid-West" 10 "South-Western"
label values sregion sregion

decode sregion, gen(subRegion)

ren h1aq2 county
ren h1aq1 district

* Merge in the geovariable information for exportin to R
merge 1:1 HHID using "$pathraw/UNPS_Geovars_1112.dta", gen(_merge)
ren lat_mod latitude
ren lon_mod longitude

keep HHID hid region urban regurb subRegion dist_road dist_popcenter /*
*/ latitude longitude dist_market dist_borderpost dist_admctr af_bio_12 district county

replace county = "SAMIA BUGWE" if county =="SAMIA-BUGWE"

*Export a cut to R for jittering lat/lon then merge back in results
order latitude longitude HHID
export delimited using "$pathexport/UgandaGeo.csv", replace
save "$pathout/Geovars_tmp.dta", replace

/* NOTE: ENSURE THE R FILE GPSjitter.R has been executed and merge file exists.
Use the windows shell to execute the R file (may only work on laptops). */
cd $pathR2
qui: shell "C:\Program Files\R\R-3.1.1\bin\x64\R.exe" CMD BATCH GPSjitter.R

* Verify shell command generated correct file
qui local required_file GPSjitter
foreach x of local required_file { 
	 capture findfile `x'.csv, path($pathexport)
		if _rc==601 {
			noi disp in red "Please verify `x'.csv file exists. Execute GPSjitter.R script."
			* Create an exit conditions based on whether or not file is found.
			if _rc==601 exit = 1
		}
		else display in yellow "File exists, continue with merge."
	}
*end

* Load the .csv and merge with other geographic variables
import delimited "$pathexport/GPSjitter.csv", clear 
la var longitude "HH longitude"
la var latitude  "HH latitude"
drop v1

* Make unique ID upper for merging
merge 1:1 hid using "$pathout/Geovars_tmp.dta", gen(geo_merge)

* 89 that were missing Lat/Lon info do not merge in as expected.
drop geo_merge
compress

save "$pathout/Geovars.dta", replace
erase "$pathout/Geovars_tmp.dta"


