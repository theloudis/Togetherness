
/*******************************************************************************
	
	This code implements the sample selection and constructs new variables.
	Specifically it:
	- selects households on the basis of consistency of supplied information,
	  age of parents and children, usable consumption, market participation
	- constructs hourly wages and market hours
	- operationalizes the time use variables
	- separates data with respect to whether families have children or not.
	____________________________________________________________________________

	Filename: 	CTV_04_VarsAndSelection.do
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
use "$DATAdir/panel_all_$today.dta", clear


/*******************************************************************************
Household composition
*******************************************************************************/

* 	Check spouses' consistency wrt being with same partner since 'last year': 
*	Reason: We want spousal choices to reflect tradeoffs arising from labor 
*	market or childrearing rather than changes in household composition.
by nohouse_encr : egen minyr = min(year)
#delimit;
gen todrop = ((dm_samepartnerH==0 & year!=minyr) | 
	(dm_samepartnerW==0 & year!=minyr) | 
	(dm_samepartnerH!=dm_samepartnerW & dm_samepartnerH!=. & dm_samepartnerW!=.)) ;
#delimit cr
drop if todrop==1
drop todrop minyr dm_samepartner*

*	Check spouses' mutual consistency of marital status via 'dm_marriedwpartner':
*	Note: a cross tabulation of variables 'dm_mstatusH' & 'dm_mstatusW' shows 
*	that some individuals are married while others are divorced, separated, 
*	widowed, or never married. We do not drop those who are separated or 
*	divorced so long as they live with a partner (dm_haspartner in 
*	'CTV_03_YearlyData.do') and both partners agree on their marital status wrt
*	one another ('dm_marriedwpartner'). Those who declare themselves separated 
*	etc are likely referring to separation from previous partners:
gen todrop = (dm_marriedwpartnerH!=dm_marriedwpartnerW)
drop if todrop==1
drop todrop dm_marriedwpartner* 

*	Create compact marital status variable for the household:
gen dm_mstatus = 1 if dm_mstatusH==1 & dm_mstatusW==1		/*married*/
replace dm_mstatus = 2 if dm_mstatusH==5 & dm_mstatusW==5 	/*never married*/
replace dm_mstatus = 3 if dm_mstatus!=1 & dm_mstatus!=2		/*all other, eg. previously separated*/
label variable dm_mstatus "(gen) Marital status"
label define mstatusl 1 "married" 2 "never married" 3 "other, eg.previously separated"
label values dm_mstatus mstatusl
drop dm_mstatusH dm_mstatusW
order nohouse_encr year nomem_encr* dm_mstatus

*	Check consistency of year of birth per spouse:
by nohouse_encr : egen sdybH = sd(dm_ybH)
by nohouse_encr : egen sdybW = sd(dm_ybW)
gen todrop = ((sdybH!=0 & sdybH!=.) | (sdybW!=0 & sdybW!=.))
drop if todrop==1
drop todrop sdyb*

*	Generate spousal age:
gen dm_ageH = year-dm_ybH
gen dm_ageW = year-dm_ybW
foreach v of varlist dm_age* {
	label variable `v' "(gen) Age"
}
drop dm_ybH dm_ybW
order nohouse_encr year nomem_encr* dm_age* dm_mstatus

*	Select on the basis of spouses' age. We want the spouses to be of working 
*	age and not restricted by statutory retirement or schooling (eg. 25-60):
*	Note: We use current earnings from household box. These aren't retrospective,
*	so age in the records accords with age when earnings were generated. 
gen todrop = (dm_ageH<25 | dm_ageH>60 | dm_ageW<25 | dm_ageW>60)
drop if todrop==1
drop todrop

*	Consistency of number of household members and number of kids:
gen todrop = ((dm_nummemsH!=dm_nummemsW) | (dm_numkidsH!=dm_numkidsW))
drop if todrop==1
gen dm_nummems=dm_nummemsH
gen dm_numkids=dm_numkidsH
foreach v of varlist dm_nummems dm_numkids {
	local l`v' : variable label `v'H
	label variable `v' "`l`v''"
}
drop todrop dm_nummemsH dm_nummemsW dm_numkidsH dm_numkidsW

*	Consolidate a few household demographic variables to the response given by
*	the wife (spousal responses do not differ here anyway):
drop dm_fstatusH dm_dwellingH dm_urbanH
rename dm_fstatusW dm_fstatus
rename dm_dwellingW dm_dwelling
rename dm_urbanW dm_urban
order nohouse_encr year nomem_encr* dm_age* dm_nummems dm_numkids dm_mstatus dm_fstatus dm_dwelling dm_urban


/*******************************************************************************
Labor market earnings, hours, wages
*******************************************************************************/

*	Remove income variables that are not needed; use imputed net monthly income
*	(available from hbox) as the relevant earnings variable per spouse. This 
*	variable has slightly larger coverage in the sample compared to non-imputed 
*	ones (thus preferred). There are only very small differences between the
*	moments of this variable and of the non-imputed ones.
drop y_gm* y_nmH y_nmW y_hh*mhat*

*	Export dataset prior to selection into market work:
preserve
keep if dm_numkids>0
save "$DATAdir/panel_childful_workuncond_$today.dta", replace
restore

*	Tag those who report zero monthly (or missing) earnings:
gen todrop = (y_nmhatH==0 | y_nmhatH==. | y_nmhatW==0 | y_nmhatW==.)
drop if todrop==1
drop todrop

*	Market work is reported in two modules: Core Module 6 'Work and Schooling'
*	and Assembled Study 34 'Consumption & Time-Use'. We mainly use information
*	from Module 6 as this has a better coverage. However, when this is not
*	available, we also use information from Module 34. 

*	Note: In all cases we impose a theoretical maximum of 84 weekly market work 
*	hours (=16.8 hours per day x 5 days per week, 7.2 remaining daily hours are  
*	for sleep; or 12 hours per day x 7 days per week). 

*	-male hours Assembled Study 34:
gen w_hrs34H = w_whrsH+w_wminsH/60 if w_wminsH!=. 
replace w_hrs34H = w_whrsH if w_wminsH==.
replace w_hrs34H = . if w_hrs34H>84

*	-female hours Assembled Study 34:
gen w_hrs34W = w_whrsW+w_wminsW/60 if w_wminsW!=.
replace w_hrs34W = w_whrsW if w_wminsW==.
replace w_hrs34W = . if w_hrs34W>84

*	-male hours Core Module 6:
gen hH = w_hrs6H if w_hrs6H<=84
replace hH = hH + w_2ndjobwhrsH if w_2ndjobH!=3
replace hH = . if hH>84
replace hH = w_hrs34H if hH==0 | hH==.

*	-female hours Core Module 6:
gen hW = w_hrs6W if w_hrs6W<=84 
replace hW = hW + w_2ndjobwhrsW if w_2ndjobW!=3
replace hW = . if hW>84
replace hW = w_hrs34W if hW==0 | hW==.

*	-label market work variables:
foreach var of varlist hH hW {
	label variable `var' "(gen) wk hours market work"
}
*
*	Generate hourly wages as annual earnings over annual hours:
gen wH = (y_nmhatH*12)/(hH*52)
label variable wH "(gen) hourly wage"
gen wW = (y_nmhatW*12)/(hW*52)
label variable wW "(gen) hourly wage"

*	Drop unneeded labor market participation variables:
*	Note: 'w_paidwork' is for whether one is in paid work or not. There are
*	persons who report positive hours and earnings but that are out of paid
*	work. These are likely to be self-employed people whom we do not drop.
drop w_paidwork* w_whrs* w_wmins* w_hrs6* w_2ndjob* w_hrs34* w_comumins6*


/*******************************************************************************
Time use variables
*******************************************************************************/

*	Here we clean and construct composite variables for each spouse for the
*	weekly time spent on various activities.

*	Weekly leisure (comprising private + public leisure):
*	- for men:
gen LH = l_lhrsH+l_lminsH/60 if l_lminsH!=. 
replace LH = l_lhrsH if l_lminsH==.
label variable LH "(gen) Total leisure HD"
*	- for women:
gen LW = l_lhrsW+l_lminsW/60 if l_lminsW!=. 
replace LW = l_lhrsW if l_lminsW==.
label variable LW "(gen) Total leisure WF"
drop l_lhrs* l_lmins*

*	Impose a theoretical maximum of 112 weekly hours of leisure (=16 hours per 
*	day x 7 days per week, 8 remaining daily hours are for sleep).
replace LH = . if LH>112
replace LW = . if LW>112

*	Generate public leisure variable:
gen LpH = l_lpubhrsH+l_lpubminsH/60 if l_lpubminsH!=. 
replace LpH = l_lpubhrsH if l_lpubminsH==.
label variable LpH "(gen) Public leisure HD"
gen LpW = l_lpubhrsW+l_lpubminsW/60 if l_lpubminsW!=. 
replace LpW = l_lpubhrsW if l_lpubminsW==.
label variable LpW "(gen) Public leisure WF"
drop l_lpubhrs* l_lpubmins*

*	Impose a theoretical maximum of 112 weekly hours of public leisure (=16 
*	hours per day x 7 days per week, 8 remaining daily hours are for sleep) and
*	treat missing values as zero (approx. 2.5% of the sample):
replace LpH = 0 if LpH==.
replace LpW = 0 if LpW==.
replace LpH = . if LpH>112
replace LpW = . if LpW>112

*	Drop observations with unusable values of leisure:
gen todrop = 1 if LH==. | LW==. | LpH==. | LpW==.
drop if todrop==1
drop todrop

*	Weekly childcare:
*	- for men:
gen TH = h_wkidshrsH+h_wkidsminsH/60 if h_wkidsminsH!=. 
replace TH = h_wkidshrsH if h_wkidsminsH==.
label variable TH "(gen) Total childcare HD"
*	- for women:
gen TW = h_wkidshrsW+h_wkidsminsW/60 if h_wkidsminsW!=. 
replace TW = h_wkidshrsW if h_wkidsminsW==.
label variable TW "(gen) Total childcare WF"
drop h_wkidshrs* h_wkidsmins*

*	Weekly commuting time:
*	- for men:
gen CommutingH = w_comuhrsH+w_comuminsH/60 if w_comuminsH!=. 
replace CommutingH = w_comuhrsH if w_comuminsH==.
label variable CommutingH "(gen) Commuting time HD"
*	- for women:
gen CommutingW = w_comuhrsW+w_comuminsW/60 if w_comuminsW!=. 
replace CommutingW = w_comuhrsW if w_comuminsW==.
label variable CommutingW "(gen) Commuting time WF"
*	- assume zero commuting time if missing value:
replace CommutingH = 0 if CommutingH==.
replace CommutingW = 0 if CommutingW==.
drop w_comuhrs* w_comumins*

*	Weekly chores:
*	- for men:
gen ChoresH = h_chorshrsH+h_chorsminsH/60 if h_chorsminsH!=. 
replace ChoresH = h_chorshrsH if h_chorsminsH==.
label variable ChoresH "(gen) Chores HD"
*	- for women:
gen ChoresW = h_chorshrsW+h_chorsminsW/60 if h_chorsminsW!=. 
replace ChoresW = h_chorshrsW if h_chorsminsW==.
label variable ChoresW "(gen) Chores WF"
*	- assume zero chores if missing value:
replace ChoresH = 0 if ChoresH==.
replace ChoresW = 0 if ChoresW==.
drop h_chorshrs* h_chorsmins*

*	Weekly personal care:
*	- for men:
gen PcareH = h_pcarehrsH+h_pcareminsH/60 if h_pcareminsH!=. 
replace PcareH = h_pcarehrsH if h_pcareminsH==.
label variable PcareH "(gen) Personal care HD"
*	- for women:
gen PcareW = h_pcarehrsW+h_pcareminsW/60 if h_pcareminsW!=. 
replace PcareW = h_pcarehrsW if h_pcareminsW==.
label variable PcareW "(gen) Personal care WF"
*	- assume zero personal care if missing value:
replace PcareH = 0 if PcareH==.
replace PcareW = 0 if PcareW==.
drop h_pcarehrs* h_pcaremins*

*	Weekly care for parents:
*	- for men:
gen ParentcareH = h_wparshrsH+h_wparsminsH/60 if h_wparsminsH!=. 
replace ParentcareH = h_wparshrsH if h_wparsminsH==.
label variable ParentcareH "(gen) Care parents HD"
*	- for women:
gen ParentcareW = h_wparshrsW+h_wparsminsW/60 if h_wparsminsW!=. 
replace ParentcareW = h_wparshrsW if h_wparsminsW==.
label variable ParentcareW "(gen) Care parents WF"
*	- assume zero care for parents if missing value:
replace ParentcareH = 0 if ParentcareH==.
replace ParentcareW = 0 if ParentcareW==.
drop h_wparshrs* h_wparsmins*

*	Weekly care for family members (excl. childcare):
*	- for men:
gen FcareH = h_wfamhrsH+h_wfamminsH/60 if h_wfamminsH!=. 
replace FcareH = h_wfamhrsH if h_wfamminsH==.
label variable FcareH "(gen) Family care HD"
*	- for women:
gen FcareW = h_wfamhrsW+h_wfamminsW/60 if h_wfamminsW!=. 
replace FcareW = h_wfamhrsW if h_wfamminsW==.
label variable FcareW "(gen) Family care WF"
*	- assume zero care for family if missing value:
replace FcareH = 0 if FcareH==.
replace FcareW = 0 if FcareW==.
drop h_wfamhrs* h_wfammins*

*	Weekly care for others (i.e. non-family members):
*	- for men:
gen OcareH = h_wothrshrsH+h_wothrsminsH/60 if h_wothrsminsH!=. 
replace OcareH = h_wothrshrsH if h_wothrsminsH==.
label variable OcareH "(gen) Care for others HD"
*	- for women:
gen OcareW = h_wothrshrsW+h_wothrsminsW/60 if h_wothrsminsW!=. 
replace OcareW = h_wothrshrsW if h_wothrsminsW==.
label variable OcareW "(gen) Care for others WF"
*	- assume zero care for others if missing value:
replace OcareH = 0 if OcareH==.
replace OcareW = 0 if OcareW==.
drop h_wothrshrs* h_wothrsmins*

*	Weekly hours for further schooling:
*	- for men:
gen SchoolingH = h_schlhrsH+h_schlminsH/60 if h_schlminsH!=. 
replace SchoolingH = h_schlhrsH if h_schlminsH==.
label variable SchoolingH "(gen) Schooling time HD"
*	- for women:
gen SchoolingW = h_schlhrsW+h_schlminsW/60 if h_schlminsW!=. 
replace SchoolingW = h_schlhrsW if h_schlminsW==.
label variable SchoolingW "(gen) Schooling time WF"
*	- assume zero schooling time if missing value:
replace SchoolingH = 0 if SchoolingH==.
replace SchoolingW = 0 if SchoolingW==.
drop h_schlhrs* h_schlmins*

*	Weekly hours for administrative chores and finances:
*	- for men:
gen AdminH = h_adminhrsH+h_adminminsH/60 if h_adminminsH!=. 
replace AdminH = h_adminhrsH if h_adminminsH==.
label variable AdminH "(gen) Admin chores HD"
*	- for women:
gen AdminW = h_adminhrsW+h_adminminsW/60 if h_adminminsW!=. 
replace AdminW = h_adminhrsW if h_adminminsW==.
label variable AdminW "(gen) Admin chores WF"
*	- assume zero admin chores time if missing value:
replace AdminH = 0 if AdminH==.
replace AdminW = 0 if AdminW==.
drop h_adminhrs* h_adminmins*

*	Weekly hours for sleep and rest:
*	- for men:
gen SleepH = h_sleephrsH+h_sleepminsH/60 if h_sleepminsH!=. 
replace SleepH = h_sleephrsH if h_sleepminsH==.
label variable SleepH "(gen) Sleep time HD"
*	- for women:
gen SleepW = h_sleephrsW+h_sleepminsW/60 if h_sleepminsW!=. 
replace SleepW = h_sleephrsW if h_sleepminsW==.
label variable SleepW "(gen) Sleep time WF"
drop h_sleephrs* h_sleepmins*

*	Weekly hours for all other activities:
*	- for men:
gen OtherH = h_otherhrsH+h_otherminsH/60 if h_otherminsH!=. 
replace OtherH = h_otherhrsH if h_otherminsH==.
label variable OtherH "(gen) Other activities HD"
*	- for women:
gen OtherW = h_otherhrsW+h_otherminsW/60 if h_otherminsW!=. 
replace OtherW = h_otherhrsW if h_otherminsW==.
label variable OtherW "(gen) Other activities WF"
*	- assume zero time for other activities if missing value:
replace OtherH = 0 if OtherH==.
replace OtherW = 0 if OtherW==.
drop h_otherhrs* h_othermins*


/*******************************************************************************
Distinction between families with and without children
*******************************************************************************/

*	Split sample with respect to whether household has children or not, using 
*	variable 'dm_numkids' from hbox: 
preserve
keep if dm_numkids==0 
save "$DATAdir/panel_childless_$today.dta", replace
restore

*	Keep families with children:
keep if dm_numkids>0
save "$DATAdir/panel_childful_$today.dta", replace

*** end of do file ***
