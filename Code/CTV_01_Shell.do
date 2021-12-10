
/*******************************************************************************
	
	This master script sequentially calls STATA code that:
	- creates an unbalanced panel of households in years 2009, 2010, 2012.
	- implements sample selection criteria.
	- obtains descriptive statistics and figures.
	- exports final data for test and estimation on the basis of RP (using Matlab).
	- reads data back from Matlab on shadow prices and joint childcare and 
	  summarizes them using figures and tables.
	
	Attention:
	----------
	To run this and all following scripts, access to the raw data LISS is
	needed. Public access to the data is possible after creating an account 
	and signing the appropriate agreement on https://www.dataarchive.lissdata.nl.
	
	Without access to the raw data, comment out 'CTV_02_HouseholdBox' and 
	'CTV_03_YearlyData' below and run the code from 'CTV_04_VarsAndSelection' 
	onward. This requires the assembled data in 'panel_all_AEJ_Accepted.dta', 
	which is already provided in the replication package.
	____________________________________________________________________________

	Filename: 	CTV_01_Shell.do
	Author: 	Alexandros Theloudis (a.theloudis@gmail.com)
	Date: 		Autumn 2021
	Paper: 		Togetherness in the Household 
				Sam Cosaert and Alexandros Theloudis and Bertrand Verheyden

*******************************************************************************/

*	Initial statements:
clear
set more off
cap log close
version 16.1

*	Obtain current date:
local c_date= c(current_date)
global today = "AEJ_Accepted"

*	Set path to replication package folder:
*	Attention to users: please change the path in 'REPdir' to the directory
*	of the replication package in your machines. Those users with access to
*	the raw LISS data should also edit 'RAWDATAdir' (but this is not needed
*	for the code to run as we provide 'panel_all_AEJ_Accepted.dta').
global REPdir    	= "/Users/atheloudis/Dropbox/Projects Finished/Published/Togetherness/Replication_Package"	/* <--- new users, please change this working directory*/
global RAWDATAdir 	= "/Users/atheloudis/Dropbox/Projects Finished/Published/Togetherness in the Household (AEJ-Micro 2022)/my_Togetherness/Data/_Stata/Raw_data"

*	Define global paths and names:
capture : mkdir "$REPdir/Exports", public
global EXPORTSdir 	= "$REPdir/Exports"
global DATAdir 		= "$REPdir/Data"
global CODEdir 		= "$REPdir/Code"

*	Install missing ado files (requires Internet connection):
ssc install estout, replace
ssc install catplot, replace
net install gr0002_3, from(http://www.stata-journal.com/software/sj4-3) replace

*	Execute code:
*do "$CODEdir/CTV_02_HouseholdBox.do"
*do "$CODEdir/CTV_03_YearlyData.do"
do "$CODEdir/CTV_04_VarsAndSelection.do"
do "$CODEdir/CTV_05_Childful.do"
do "$CODEdir/CTV_06_Childless.do"
do "$CODEdir/CTV_07_Export.do"
do "$CODEdir/CTV_08_Childful_AllWorkNonwork.do"
do "$CODEdir/CTV_09_Time_Diary.do"
do "$CODEdir/CTV_10_Descriptives.do"

*** end of do file ***
