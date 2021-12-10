
/*******************************************************************************
	
	This code uses data from the LISS household box in 2007-2017 and:
	- keeps in demographics and income background variables
	- implements baseline sample selection on the basis of years, family status
	  and consistency of other information
	- collapses data to one record by individual per year
	____________________________________________________________________________

	Filename: 	CTV_02_HouseholdBox.do
	Author: 	Alexandros Theloudis (a.theloudis@gmail.com)
	Date: 		Autumn 2021
	Paper: 		Togetherness in the Household 
				Sam Cosaert and Alexandros Theloudis and Bertrand Verheyden

*******************************************************************************/

*	Initial statements:
clear
set more off
version 16.1

*	Use data:
use "$RAWDATAdir/RawAllYears_HouseholdBox.dta", clear
sort nomem_encr wave

*	Select variables:
#delimit;
keep nomem_encr nohouse_encr geslacht positie gebjaar aantalhh aantalki
	partner burgstat woonvorm woning sted belbezig brutoink brutoink_f 
	nettoink nettoink_f brutohh_f nettohh_f oplmet wave ;
#delimit cr


/*******************************************************************************
Baseline data cleaning and selection of individuals
*******************************************************************************/

* 	Generate month and year variables; these are used for data cleaning, 
*	and data collapse:
gen month = .
label variable month "Month observ record"
gen year = .
label variable year "Year observ record"
forv yy = 2007 2008 to 2017 {
forv mm = 01 02 to 12 {
	qui replace month = `mm' if (wave==`yy'0`mm' & `mm'<10) | (wave==`yy'`mm' & `mm'>=10)
	qui replace year = `yy' if (wave==`yy'0`mm' & `mm'<10) | (wave==`yy'`mm' & `mm'>=10)
}
}
sort nomem_encr year wave

*	[Baseline Selection 1]
*	Keep years from 2009 (incl.) onwards as there are no consumption/time-use 
*	data in earlier years:
keep if year >= 2009

*	[Baseline Selection 2] 
*	Keep those who are household heads or wedded/unwedded partners:
keep if positie==1 | positie==2 | positie==3

*	[Baseline Selection 3]
*	Keep those who do not experience marital status changes in a given year.
*	These are households whose behavior may be constrained by such changes:
foreach var of varlist partner burgstat {
	qby nomem_encr year : egen sd_`var' = sd(`var')
}
drop if (sd_partner!=0 & sd_partner!=.) | (sd_burgstat!=0 & sd_burgstat!=.)
drop sd_*

*	[Baseline Selection 4]
*	Keep those who have a partner:
drop if partner != 1
drop partner

*	[Baseline Selection 5]
*	Keep those who report their gender and year of birth consistently over time:
foreach var of varlist geslacht gebjaar {
	qby nomem_encr : egen sd_`var' = sd(`var')
}	
drop if (sd_geslacht!=0 & sd_geslacht!=.) | (sd_gebjaar!=0 & sd_gebjaar!=.)
drop sd_*

*	[Baseline Selection 6]
*	Drop few individuals who report abnormal household composition (aantalhh>9):
qui gen tag = aantalhh>9
qby nomem_encr : egen stag=sum(tag)
drop if stag!=0
drop tag stag

*	[Baseline Selection 7]
* 	Drop those who appear in the survey less than 3 months (the modal values
*	for incomes or demographics subsequently may be unreliable):
*	Note: we exclude 2017 because of partial data at the time this is written.
by nomem_encr year : egen timespresent = count(month)
drop if timespresent<4 & year<2017
drop if timespresent==1 & year==2017
drop timespresent

*	[Baseline Selection 8]
*	Drop those who are associated with more than one households in a given year:
by nomem_encr year : egen hhjumps = sd(nohouse_encr)
drop if hhjumps!=0
drop hhjumps

*	Replace demographics by modal value per year: 
*	Note: Given that demographics are recorded on a monthly basis while 
*	consumption and time-use are reported in one only month in a given year, 
*	merging the two on the basis of a single month may miss important demographic 
*	changes that happen prior to or after the consumption/time-use data. Using the
*   yearly modal value partly addresses this concern. Demographics involved are:
*		-number of HH members (aantalhh)
*		-number of children (aantalki)
*		-position in the household* (positie)
*		-domestic situation* (woonvorm)
*		-type of dwelling (woning)
*		-urban/rural residence (sted)
*		-primary occupation (belbezig)
*		-highest level of education (oplmet)
*	*position in the household (eg. from head to partner and vice versa) may 
*	change as the result of, say, a change in the renting contract of home
*	*domestic situation may reflect the birth of a child. Compositional changes 
*	eg. partnering or marrying are captured by 'partner' and 'burgstat' above.
foreach var of varlist aantalhh aantalki positie woonvorm woning sted belbezig oplmet {
	qby nomem_encr year : egen mode_`var' = mode(`var'), maxmode
	replace `var' = mode_`var'
	drop mode_`var'
}
*	Drop unneeded variables & order:
drop month wave
#delimit;
order nomem_encr nohouse_encr year geslacht positie gebjaar aantalhh 
	aantalki burgstat woonvorm woning sted belbezig oplmet 
	brutoink brutoink_f nettoink nettoink_f brutohh_f nettohh_f ;
#delimit cr

*	Replace income by modal value per year:
*	Note: the reason we do this is like for demographics above. An informal
*	inspection of income changes over time highlights that such changes are 
*	evenly allocated across months in a year. So the the mode operator is 
*	not going to miss any systematic updating of income. 
sort nomem_encr year
foreach var of varlist brutoink brutoink_f nettoink nettoink_f brutohh_f nettohh_f {
	qby nomem_encr year : egen mode_`var' = mode(`var'), maxmode
	replace `var' = mode_`var'
	drop mode_`var'
}


/*******************************************************************************
Collapse monthly entries to one yearly entry per individual; export 
*******************************************************************************/

*	Retain default value labels:
local list_of_vars_valuelabels
foreach var of varlist * {
   local templocal : value label `var'
   if ("`templocal'" != "") {
      local varlabel_`var' : value label `var'
      local list_of_vars_valuelabels "`list_of_vars_valuelabels' `var'"
   }
}
	
*	Collapse:
#delimit;
collapse (mean) nohouse_encr geslacht positie gebjaar aantalhh aantalki burgstat 
	woonvorm woning sted belbezig oplmet brutoink brutoink_f nettoink nettoink_f 
	brutohh_f nettohh_f, by(nomem_encr year) ;
#delimit cr

*	(Re)apply default value labels:
foreach var of local list_of_vars_valuelabels {
   cap label values `var' `varlabel_`var''
}

*	(Re)name and (re)label variables: 
*	The rule for the first letters of a variable name is as follows:
*		- dm_ : denotes 'demographics' variables
*		- w_  : denotes 'work' and work related variables
*		- y_  : denotes 'income' and income related variables
*	All variable labels contain '(hbox)' to indicate these variables are 
*	obtained from the LISS Household Box (Core study 1).
rename geslacht dm_gender
rename positie dm_position
rename gebjaar dm_yb
rename aantalhh dm_nummems
rename aantalki dm_numkids
rename burgstat dm_mstatus
rename woonvorm dm_fstatus
rename woning dm_dwelling
rename sted dm_urban
rename belbezig w_employm
rename oplmet dm_educ
rename brutoink y_gm
rename brutoink_f y_gmhat
rename nettoink y_nm
rename nettoink_f y_nmhat
rename brutohh_f y_hhgmhat
rename nettohh_f y_hhnmhat
label variable nohouse_encr ""
label variable dm_gender "(hbox) Gender"
label variable dm_position "(hbox) Position within the household"
label variable dm_yb "(hbox) Year of birth"
label variable dm_nummems "(hbox) Number of household members"
label variable dm_numkids "(hbox) Number of living-at-home children in the household"
label variable dm_mstatus "(hbox) Civil status"
label variable dm_fstatus "(hbox) Domestic situation of the household head"
label variable dm_dwelling "(hbox) Type of dwelling that the household inhabits"
label variable dm_urban "(hbox) Urban character of place of residence"
label variable w_employm "(hbox) Primary employment"
label variable dm_educ "(hbox) Highest level of education with diploma"
label variable y_gm "(hbox) Personal gross monthly income in Euros"
label variable y_gmhat "(hbox) Personal gross monthly income in Euros, imputed"
label variable y_nm "(hbox) Personal net monthly income in Euros"
label variable y_nmhat "(hbox) Personal net monthly income in Euros, imputed (available as from July 2008)"
label variable y_hhgmhat "(hbox) Gross household income in Euros"
label variable y_hhnmhat "(hbox) Net household income in Euros"

*	Export:
order nomem_encr nohouse_encr year dm_* w_* y_* 
compress
save "$DATAdir/hbox2009_2017_$today.dta", replace

*** end of do file ***
