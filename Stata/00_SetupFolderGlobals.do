/*-------------------------------------------------------------------------------
# Name:		00_SetupFolderGlobals
# Purpose:	Create series of folders Food for Uganda Vulnerability Analysis
# Author:	Tim Essam, Ph.D.
# Created:	01/12/2014
# Owner:	USAID GeoCenter | OakStream Systems, LLC
# License:	MIT License
# Ado(s):	see below
#-------------------------------------------------------------------------------
*/

/* RUN/READ ME FIRST -- Make directories for the study.
 1. Requires root name for file folder structure
 2. Requires branch names for sub-folders
 3. Sets global macros for the study; These are used through the do files.
 4. TODO -- Script DOES NOT copy in raw data at this point.
 5. TODO -- Create program folder for calling custom programs.
 6. TODO -- Convert setup .do file into a program (inputs are project path & folder name)
*/
	
* install the confirm directory ado if not already installed
* list all known user-written .ados needed for project
local required_ados confirmdir mvfiles fs spatgsa  adolist labellist winsor2   
foreach x of local required_ados { 
	capture findfile `x'.ado
		if _rc==601 {
			cap ssc install `x'
		}
		else disp in yellow "`x' currently installed."
	}
*end

* Determine path for the study 
global projectpath "U:\"
*global projectpath "C:\Users\t\Box Sync\"
cd "$projectpath"

* Run a macro to set up study folder (needs to be modified)
* Name the file path below -- replace "nigerlsms" with your folder name
local pFolder UgandaLVAM
foreach dir in `pFolder' {
	confirmdir "`dir'"
	if `r(confirmdir)'==170 {
		mkdir "`dir'"
		display in yellow "Project directory named: `dir' created"
		}
	else disp as error "`dir' already exists, not created."
	cd "$projectpath\`dir'"
	}
* end

* Run initially to set up folder structure
* Choose your folders to set up as the local macro `folders'
local folders Rawdata Stata Datain Log Output Dataout Excel PDF Word Graph GIS Export R Python Programs
foreach dir in `folders' {
	confirmdir "`dir'"
	if `r(confirmdir)'==170 {
			mkdir "`dir'"
			disp in yellow "`dir' successfully created."
		}
	else disp as error "`dir' already exists. Skipped to next folder."
}
*end

/*---------------------------------
# Set Globals based on path above #
-----------------------------------*/
global date $S_DATE
local dir `c(pwd)'
global path "`dir'"
global pathdo "`dir'\Stata"
global pathlog  "`dir'\Log"
global pathin "`dir'\Datain"
global pathout "`dir'\Dataout"
global pathgraph "`dir'\Graph"
global pathxls "`dir'\Excel"
global pathreg "`dir'\Output"
global pathgis "`dir'\GIS"
global pathraw "`dir'\Rawdata"
global pathexport "`dir'\Export"
global pathR "`dir'\R"
global pathPython "`dir'\Python"
global pathProgram "`dir'\Program"
global pathPdrive "P:\GeoCenter\GIS\Projects\Ethiopia"

* Project macros are defined as:
macro list 

/*------------------------------------------------------------
# Manually copy raw data  into Datain Folder #

