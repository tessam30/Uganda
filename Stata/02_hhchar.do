/*------------------------------------------------------------------------------
# Name:		02_hhchar
# Purpose:	Process household characteristics and education characteristics
# Author:	Tim Essam
# Created:	2015/2/26
# License:	MIT License
# Ado(s):	labutil, labutil2 (ssc install labutil, labutil2)
# Dependencies: copylables, attachlabels, 00_SetupFoldersGlobals.do
#-------------------------------------------------------------------------------
*/

clear
capture log close
log using "$pathlog/01_hhchar.log", replace

use "$pathraw/GSEC2.dta", replace

* Merge education data to household roster using the force command
merge 1:1 HHID PID using "$pathraw/GSEC4.dta", force
ren _merge gsecMerge
merge 1:1 HHID PID using "$pathraw/GSEC3.dta", force

/* Demographic list to calculate
1. Head of Household Sex
2. Relationship Status
*/

* Create head of household variable based on primary respondent and sex
g byte hoh = h2q4 == 1
la var hoh "Head of household"

g byte femhead = h2q3 == 2 & h2q4 == 1
la var femhead "Female head of household"

g agehead = h2q8 if hoh == 1
la var agehead "Age of head of household"

g ageheadsq = agehead^2
la var ageheadsq "Squared age of the head (for non-linear effects)"

* Relationship status variables
g byte marriedHohm = h2q10 == 1 & hoh==1
la var marriedHohm "married HOH monogamous"

g byte marriedHoh = hoh ==1 & inlist(h2q10, 1, 2)
la var marriedHoh "married head of household (any type)"

g byte marriedHohp = h2q10 == 2 & hoh==1
la var marriedHohp "married HOH polygamous"

g byte divorcedHead = (h2q10 == 3 & hoh==1)
la var divorcedHead "divorced HoH"

g byte divorcedFemhead = (h2q10 == 3 & femhead == 1)
la var divorcedFemhead "divorced Female head of household"

g byte widowHead = (h2q10 == 4 & hoh==1)
la var widowHead "widowed HoH"

g byte widowFemhead = (h2q10 == 4 & femhead == 1)
la var widowFemhead "Widowed Female head of household"

g byte singleHead = (h2q10==5 & hoh==1)
la var singleHead "single HoH"

g byte singleFemhead = (h2q10==5 & femhead)
la var singleFemhead "single HoH"

* Calculate household demographics (size, adult equivalent units, dep ratio, etc).

/* Household size - Household size refers to the number of usual members in a 
household. Usual members are defined as those who have lived in the household 
for at least 6 months in the past 12 months. However, it includes persons who 
may have spent less than 6 months during the last 12 months in the household 
but have joined the household with intention to live permanently or for an 
extended period of time.
* http://www.ubos.org/UNHS0910/chapter2_householdcharacteristics.html */

*Create a flag variable for determining who is a usual member from above.
g byte hhmemb = (inlist(h2q7, 1, 2) & h2q5 >= 6)
egen hhsize = total(hhmemb), by(HHID)
la var hhsize "household size"

* Create sex ratio for households
g byte male = h2q3 == 1 & hhmemb == 1
g byte female = h2q3 == 2 & hhmemb == 1
la var male "male hh members"
la var female "female hh members"

egen msize = total(male), by(HHID)
la var msize "number of males in hh"

egen fsize = total(female), by(HHID)
la var fsize "number of females in hh"

* Create a gender ratio variable
g sexRatio = msize/fsize
recode sexRatio (. = 0) if fsize==0
la var sexRatio "Ratio of males to females in HH"

* Calculate age demographics
g byte under15tmp = h2q8 <= 15 & hhmemb ==1 
g byte under24tmp = h2q8 <= 24 &  hhmemb==1

egen under15 = total(under15tmp), by(HHID)
la var under15 "number of hh members under 15 years old"

egen under24 = total(under24tmp), by(HHID)
la var under24 "number of hh members under 24 years old"

egen under15male = total(under15tmp) if male==1, by(HHID)
la var under15male "number of male hh members under 15"

egen under15female = total(under15tmp) if female==1, by(HHID)
la var under15female "number of female hh members under 15"

egen under24male = total(under24tmp) if male==1, by(HHID)
la var under24male "number of male hh members under 24"

egen under24female = total(under24tmp) if female==1, by(HHID)
la var under24female "number of female hh members under 24"

/* Create intl. HH dependency ratio (age ranges appropriate for Bangladesh)
# HH Dependecy Ratio = [(# people 0-14 + those 65+) / # people aged 15-64 ] * 100 # 
The dependency ratio is defined as the ratio of the number of members in the age groups 
of 0–14 years and above 60 years to the number of members of working age (15–60 years). 
The ratio is normally expressed as a percentage (data below are multiplied by 100 for pcts.*/
g byte numDepRatio = (h2q8 < 15 | h2q8 > 64) & hhmemb == 1
g byte demonDepRatio = numDepRatio != 1 & hhmemb == 1
egen totNumDepRatio = total(numDepRatio), by(HHID)
egen totDenomDepRatio = total(demonDepRatio), by(HHID)

* Check that numbers add to hhsize
assert hhsize == totNumDepRatio+totDenomDepRatio if hhmemb==1
g depRatio = (totNumDepRatio/totDenomDepRatio)*100 if totDenomDepRatio!=.
recode depRatio (. = 0) if totDenomDepRatio==0
la var depRatio "Dependency Ratio"


* Calculate household labor shares (ages 12 - 60)
/* Household Labor Shares */
g byte hhLabort = (h2q8>= 12 & h2q8<60) & hhmemb == 1
egen hhlabor = total(hhLabort), by(HHID)
la var hhlabor "hh labor age>11 & < 60"

g byte mlabort = (h2q8>= 12 & h2q8<60 & male == 1)
egen mlabor = total(mlabort), by(HHID)
la var mlabor "hh male labor age>11 & <60"

g byte flabort = (h2q8>= 12 & h2q8<60 & female == 1)
egen flabor = total(flabort), by(HHID)
la var flabor "hh female labor age>11 & <60"
drop hhLabort mlabort flabort

* Male/Female labor share in hh
g mlaborShare = mlabor/hhlabor
recode mlaborShare (. = 0) if hhlabor == 0
la var mlaborShare "share of working age males in hh"

g flaborShare = flabor/hhlabor
recode flaborShare (. = 0) if hhlabor == 0
la var flaborShare "share of working age females in hh"

* Generate adult equivalents in household
g male10 	= 1
g fem10_19 	= 0.84
g fem20		= 0.72
g child10	= 0.60

g ae = .
replace ae = male10 if (h2q8 >=10 ) & male == 1 
replace ae = fem10_19 if (h2q8 >= 10 & h2q8 < 20) & female == 1
replace ae = fem20 if (h2q8 >= 20) & female == 1
replace ae = child10 if (h2q8) < 10 & hhmemb == 1
la var ae "Adult equivalents in household"

egen adultEquiv = total(ae), by(HHID)
la var adultEquiv "Total adult equivalent units"


**********************
* Education outcomes *
**********************
/* Literacy is defined as one’s ability to read with understanding and to 
 write meaningfully in any language. */
g byte literateHoh = h4q4 == 4 & hoh == 1
g byte literateSpouse = h4q4 == 4 & h2q4 == 2 & hhmemb == 1

la var literateHoh "Hoh is literate"
la var literateSpouse "Spouse is literate"

/* Education level values found in h4q7 defined using the following:
http://microdata.worldbank.org/index.php/catalog/565/datafile/F2/V110
http://www.classbase.com/countries/Uganda/Education-System
	No Education (0)
	Pre-Primary (Less than Primary Year 1)
	Primary Level (Years 1 - 7)
	Post-Primary Specialized Training or Certificate
	Junior Vocational/Technical (Years 8 - 10)
	Lower Secondary (Years 8 - 11)
	Upper Secondary (Years 11 - 13)
	Post-Secondary Specialized Training or Certificate
	Tertiary (Above Secondary other than Post-Secondary Specialized Training or Cer
tificate)
*/
g educ = . 
la var educ "Education levels"
* No education (This includes:"Don't Know" and "2" Responses))
replace educ = 0 if inlist(h4q7, 2, 99)
* Pre-primary
replace educ = 1 if inlist(h4q7, 10)
* Primary
replace educ = 2 if inlist(h4q7, 11, 12, 13, 14, 15, 16, 17)
* Post-Primary Specialized Training or Certificate
replace educ = 3 if inlist(h4q7, 41)
* Junior Techincal/Vocational 
replace educ = 4 if inlist(h4q7, 21, 22, 23)
* Lower Secondary 
replace educ = 5 if inlist(h4q7, 31, 32, 33, 34)
* Upper Secondary 
replace educ = 6 if inlist(h4q7, 35, 36)
* Post-Secondary Specialized Training or Certificate
replace educ = 7 if inlist(h4q7, 51)
* Tertiary
replace educ = 8 if inlist(h4q7, 61)

g educHoh = educ if hoh == 1
g educSpouse = educ if h2q4 == 2 & hhmemb == 1

lab def ed 0 "No education" 1 "Pre-primary" 2 "Primary" 3 "Post-Primary" /*
*/ 4 "Junior Techincal/Vocational " 5 "Lower Secondary" 6 "Upper Secondary" /*
*/ 7 "Post-Secondary Specialized" 8 "Tertiary"
la values educ ed
la values educHoh ed
la values educSpouse ed

* Create variable to reflect the maximum level of education in the household for those 25+
egen educAdult = max(educ) if h2q8>24 & hhmemb ==1, by(HHID)
egen educAdultM = max(educ) if h2q8>24 & hhmemb ==1 & male == 1, by(HHID)
egen educAdultF = max(educ) if h2q8>24 & hhmemb ==1 & female == 1, by(HHID)

la var educAdult "Highest adult education in household"
la var educAdultM "Highest male adult education in household"
la var educAdultF "Highest female adult education in household"
la var educHoh "Education of Hoh"
la var educSpouse "Education of spouse"

* Calculate school expenses for all regular household members
egen totSchoolExptmp = rsum2(h4q15a h4q15b h4q15c h4q15d h4q15e h4q15f)
replace totSchoolExptmp = h4q15g if totSchoolExp == 0
egen totSchoolExp = total(totSchoolExptmp), by(HHID)
la var totSchoolExp "Total school expenses for household"

g byte aidSchool = (h4q16 == 1)
la var aidSchool "HH member received school scholarship (all sources)"

* Household member slept under mosquito net
g byte mosqTreatnet = h3q10 == 2 & hhmemb == 1
g byte mosqNet = (inlist(h3q10, 1, 2) & hhmemb == 1)

* Occupation of mother and father (do not know codes yet, need to get them).
g byte occupFath = h3q4 if hhmemb == 1
g byte oocupMoth = h3q7 if hhmemb == 1

drop totNumDepRatio totDenomDepRatio demonDepRatio numDepRatio male10 fem10_19 fem20 child10 /*
*/ under15tmp under24tmp hhmemb totSchoolExptmp

* Retain only derived data for collapsing
ds(h2q* h4* T6* T2* LocID PID gsecMerge h3q* _merge educ), not
keep `r(varlist)'

* Collapse everything down to HH-level using max values for all vars
* Copy variable labels to reapply after collapse
include "$pathdo2/copylabels.do"

ds(HHID), not
collapse (max) `r(varlist)', by(HHID) 

* Reapply variable lables & value labels
include "$pathdo2/attachlabels.do"

* Summarize collapsed data and review for potential coding errors
sum

foreach x of varlist  educHoh educSpouse educAdult educAdultM educAdultF educHoh educSpouse {
	la values `x' ed
	tab `x'
	}
*end


* Save
save "$pathout/hhchar.dta", replace

* Keep a master file of only household id's for missing var checks
use "$pathraw/GSEC2", replace
keep HHID PID
save "$pathout/hhid.dta", replace

* Create an html file of the log for internet sharability
log2html "$pathlog/02_hhchar", replace
log close
