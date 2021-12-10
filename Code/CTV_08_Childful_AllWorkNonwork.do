
/*******************************************************************************
	
	This code implements the sample selection on families with children
	without requiring participation into the labor market. It then calculates
	and reports average participation statistics.
	____________________________________________________________________________

	Filename: 	CTV_08_Childful_AllWorkNonwork.do
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
use "$DATAdir/panel_childful_workuncond_$today.dta", clear


/*******************************************************************************
Labor market earnings
*******************************************************************************/

*	Tag those who report zero monthly (or missing) earnings:
gen todrop = (y_nmhatH==. | y_nmhatW==.)
drop if todrop==1
drop todrop

*	Market work is reported in two modules: Core Module 6 'Work and Schooling'
*	and Assembled Study 34 'Consumption & Time-Use'. We mainly use information
*	from Module 6 as this has a better coverage. However, when this is not
*	available, we also use information from Module 34. 
*	Note: In all cases we impose a theoretical maximum of 84 weekly market work hours
*	(=16.8 hours per day x 5 days per week, 7.2 remaining daily hours are for 
*	sleep; or 12 hours per day x 7 days per week).

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
drop w_paidwork* y_nm* w_whrs* w_wmins* w_hrs6* w_2ndjob* w_hrs34*


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

*	Generate joint leisure variable:
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
Age of children, admissible information on children
*******************************************************************************/

*	Generate children's age for all children:
foreach v of varlist dm_ybk* {
	gen agek_`v' = year-`v'
}
drop dm_ybk* dm_lhk*

*	Based on the age of children, we generate two new variables per spouse:
*	-the number of all children in the household:
egen numkidsH = rownonmiss(agek_dm_ybk*H)
egen numkidsW = rownonmiss(agek_dm_ybk*W)
*	-the age of the youngest child:
egen ageyH = rowmin(agek_dm_ybk*H)
egen ageyW = rowmin(agek_dm_ybk*W)

*	The number of children by this new measure may differ from 'dm_numkids' as
*	the latter is the modal value by year from hbox or because of genuinely
*	missing data in the year of birth of children. We drop households who
*	appear childless by this measure as we want to be confident that children
*	are indeed present in the household:
gen todrop = (numkidsH==0 | numkidsW==0)
drop if todrop==1
drop todrop

*	Drop households whose youngest child is older than 12 years:
gen todrop = (ageyH>12 | ageyW>12)
drop if todrop==1
drop todrop

*	Retrieve gender of youngest child (as reported by the male):
foreach v of varlist agek_dm_ybk*H {
	gen d`v' = `v'-ageyH
}
egen howmanyyoungestH=anycount(dagek_dm_ybk*H), v(0) /*how many youngest children?*/
gen dm_gkyoungestH = .
gen which_kidH = "" 
forv i=1 2 to 7 { 
    replace which_kidH = "agek_dm_ybk`i'H" if agek_dm_ybk`i'H==ageyH & howmanyyoungestH==1
	replace dm_gkyoungestH = dm_gk`i'H if which_kidH=="agek_dm_ybk`i'H"
	replace agek_dm_ybk`i'H = . if which_kidH=="agek_dm_ybk`i'H" 	/*Black out info on youngest child*/
	replace dm_gk`i'H = . if which_kidH=="agek_dm_ybk`i'H"			/*Black out info on youngest child*/
}
replace dm_gkyoungestH = 3 if howmanyyoungestH==2
drop dagek_dm_ybk*H

*	Retrieve gender of youngest child (as reported by the female):
foreach v of varlist agek_dm_ybk*W {
	gen d`v' = `v'-ageyW
}
egen howmanyyoungestW=anycount(dagek_dm_ybk*W), v(0)
gen dm_gkyoungestW = .
gen which_kidW = "" 
forv i=1 2 to 7 { 
    replace which_kidW = "agek_dm_ybk`i'W" if agek_dm_ybk`i'W==ageyW & howmanyyoungestW==1
	replace dm_gkyoungestW = dm_gk`i'W if which_kidW=="agek_dm_ybk`i'W"
	replace agek_dm_ybk`i'W = . if which_kidW=="agek_dm_ybk`i'W" 	/*Black out info on youngest child*/
	replace dm_gk`i'W = . if which_kidW=="agek_dm_ybk`i'W"			/*Black out info on youngest child*/
}
replace dm_gkyoungestW = 3 if howmanyyoungestW==2
drop dagek_dm_ybk*W

*	Obtain age of second youngest child:
egen age2yH = rowmin(agek_dm_ybk*H) if numkidsH>1
egen age2yW = rowmin(agek_dm_ybk*W) if numkidsW>1
drop agek_dm*

*	Drop households in which the spouses disagree on the age & gender of 
*	children, or households who report that not all children are alive (this is
*	because we don't know which ones may not be alive):
gen todrop = (ageyH!=ageyW | dm_gkyoungestH!=dm_gkyoungestW | age2yH!=age2yW)
replace todrop = 1 if dm_allkaliveH==2 | dm_allkaliveW==2
drop if todrop==1
drop todrop dm_allkalive*

*	Rename age & gender variables:
drop ageyH dm_gkyoungestH age2yH 
rename ageyW dm_akyoungest
rename dm_gkyoungestW dm_gkyoungest
rename age2yW dm_ak2youngest
label variable dm_akyoungest "(gen) Age youngest child"
label variable dm_ak2youngest "(gen) Age 2nd youngest child"
label variable dm_gkyoungest "(gen) Gender youngest child"
label define gyounhestl 1 "boy" 2 "girl" 3 "two youngest kids"
label values dm_gkyoungest gyounhestl
drop howmanyyoungest* which_kid* dm_gk*H dm_gk*W numkids* 
order nohouse_encr year nomem_encr* dm_age* dm_nummems dm_numkids dm_mstatus dm_akyoungest dm_gkyoungest dm_ak2youngest

*	Drop households for whom composite childcare of a parent is missing (this
*	affects very few families only):
gen todrop = (TH==. | TW==.)
drop if todrop==1
drop todrop

*	Drop redundant variables:
#delimit;
drop 	k_nursery* k_daycare* k_bfschlcare* k_afschlcare* k_hostparent* 
		k_pdsitteraw* k_pdsitterhm* k_unpdsitter* k_othercare* k_nocare* 
		k_whositter* k_schl* ;
#delimit cr


/*******************************************************************************
Consumption variables
*******************************************************************************/

*	Construct parents' expenditure by aggregating elementary consumption items 
*	in 4 steps. In each step we add up various elementary items treating missing
*	values as zeroes.

*	Step 1 - Assemble private expenditure by each partner. Private expenditure
*	consists of:
*		-food and drinks outside the house
*		-cigarettes and other tobacco products
*		-clothing
*		-personal care products and services
*		-medical costs not covered by insurance
*		-leisure time expenditure
*		-further schooling
*		-donations and gifts
*		-other expenditure incurred by oneself.
*	It does not include food at home.
egen priH = rowtotal(c_foodoutH c_tobaccoH c_clothesH c_pcareH c_medicalH c_leisureH c_schlH c_giftsH c_otherH)
egen priW = rowtotal(c_foodoutW c_tobaccoW c_clothesW c_pcareW c_medicalW c_leisureW c_schlW c_giftsW c_otherW)
drop c_myfoodin* c_foodout* c_tobacco* c_clothes* c_pcare* c_medical* c_leisure* c_schl* c_gifts* c_other*

*	Step 2 - Assemble parents' public expenditure at the household level. 
*	Public expenditure consists of:
*		-mortgage (interest plus amortization)
*		-rent
*		-household utilities
*		-transport costs
*		-insurances
*		-alimony and financial support for children not living at home
*		-servicing costs of debts and loans
*		-daytrips and holidays with whole or part of the family
*		-cleaning or maintaining house/garden
*		-eating at home (excluding food of children; see step 3 below)
*		-other public expenditure.
*	Note: both spouses report household level expenditure. We thus construct two
*	variables for household-level expenditure, one that reflects the husband's
*	responses, and another that reflects the wife's. When one of them reports
*	"I am not the one that knows about this", we use the response by the other.
*	--Step 2A - Public expenditure as reported primarily by husband:
qui gen c_mortg = .
qui gen c_rent = .
qui gen c_utils = .
qui gen c_trnsprt = .
qui gen c_insur = .
qui gen c_alimony = .
qui gen c_loans = .
qui gen c_holiday = .
qui gen c_maintain = .
qui gen c_foodin = . 
qui gen c_hhother = .
foreach var of varlist c_mortg c_rent c_utils c_trnsprt c_insur c_alimony c_loans c_holiday c_maintain c_foodin c_hhother {
	replace `var' = `var'H if `var'H!=-999999
	replace `var' = `var'W if (`var'H==-999999 | `var'H==.) & `var'W!=-999999
}
egen pub_byH =  rowtotal(c_mortg c_rent c_utils c_trnsprt c_insur c_alimony c_loans c_holiday c_maintain c_foodin c_hhother)
drop c_mortg c_rent c_utils c_trnsprt c_insur c_alimony c_loans c_holiday c_maintain c_foodin c_hhother
*	--Step 2B - Public expenditure as reported primarily by wife:
qui gen c_mortg = .
qui gen c_rent = .
qui gen c_utils = .
qui gen c_trnsprt = .
qui gen c_insur = .
qui gen c_alimony = .
qui gen c_loans = .
qui gen c_holiday = .
qui gen c_maintain = .
qui gen c_foodin = .
qui gen c_hhother = .
foreach var of varlist c_mortg c_rent c_utils c_trnsprt c_insur c_alimony c_loans c_holiday c_maintain c_foodin c_hhother {
	replace `var' = `var'W if `var'W!=-999999
	replace `var' = `var'H if (`var'W==-999999 | `var'W==.) & `var'H!=-999999
}
egen pub_byW =  rowtotal(c_mortg c_rent c_utils c_trnsprt c_insur c_alimony c_loans c_holiday c_maintain c_foodin c_hhother)
drop c_mortg* c_rent* c_utils* c_trnsprt* c_insur* c_alimony* c_loans* c_holiday* c_maintain* c_foodin* c_hhother* c_otfoodin* c_yrfoodin*

*	Step 3 - Add up parents' total (public and private) consumption:
*	Note 1: As per above, we create two measures of total parental consumption,
*	one that reflects mainly the husband's responses for the public elements, 
*	and another one that reflects the wife's.
*	Note 2: Food at home includes (i) food consumed by the husband alone, (ii) 
*	food by the wife alone, (iii) food by children, (iv) food by other household 
*	members, and (v) true 'public' food. What goes into parental utility is the 
*	public and private components of food of all household members (i+ii+iv+v),
*	excluding food of children (iii). Therefore we need to subtract the latter.
gen Cp_v1 = priH + priW + pub_byH 
replace Cp_v1 = Cp_v1 - c_kdfoodinH if c_kdfoodinH!=.
gen Cp_v2 = priH + priW + pub_byW 
replace Cp_v2 = Cp_v2 - c_kdfoodinW if c_kdfoodinW!=.
drop priH priW pub_by*

*	Drop if consumption is zero or missing:
gen todrop = (Cp_v1==. | Cp_v1==0 | Cp_v2==. | Cp_v2==0)

* 	Drop few observations for which there is a massive discrepancy between
*	spouses' respective consumption responses:
gen dcons = abs(Cp_v1-Cp_v2)
replace todrop = 1 if dcons>2000 
drop if todrop==1
drop dcons todrop

*	Save childful dataset at this stage, for use with time use data:
qui compress
save "$DATAdir/selected_wchildren_allworknonwork_$today.dta", replace


/*******************************************************************************
Request appropriate wages
*******************************************************************************/

*	Drop if hourly wage of either spouse is above EUR300/hour (:likely measurement error):
gen todrop = ((wH>300 & wH!=.) | (wW>300 & wW!=.))
drop if todrop==1
drop todrop


/*******************************************************************************
Construct weekly time budget
*******************************************************************************/

*	We construct the total weekly time budget of each spouse as the sum of 
*	time they spend on all baseline time uses. This must add up to 168 hours 
*	(24hrs per day x 7days per week). The baseline uses of time meant to 
*	exhaust the time endowment are:
*	1.  market work
*	2.  commuting time to/from work or school
*	3.  chores
*	4.  personal care
*   5. 	childcare and activities with children
*	6.  helping parents
*	7. 	helping other family members
*	8.  helping non-family members
* 	9.  leisure
*	10. further schooling
*   11. administrative chores
*	12. sleeping and relaxing
*	13. all other activities
*	Note: respondents are explictly asked to submit time spent on those 
*	activities in such a way so that total time is 168 hours.
egen TimeH = rsum(hH CommutingH ChoresH PcareH TH ParentcareH FcareH OcareH LH SchoolingH AdminH SleepH OtherH)
egen TimeW = rsum(hW CommutingW ChoresW PcareW TW ParentcareW FcareW OcareW LW SchoolingW AdminW SleepW OtherW)
	
*	The time budgets often do not exactly equal 168 hours so we normalize all 
*	activities so that total time equals 168. We keep market work outside this 
*	normalization because it is often around 40 (FT) or 20-25 hours (PT) per week:
gen rTimeH = TimeH - hH
gen rTimeW = TimeW - hW
	
*	In very few cases residual time rTime is 0, indicating that there the
*	individual engages in no activities other than work. We treat this as 
*	measurement error and we drop any such observations:
gen todrop = (rTimeH==0 | rTimeW==0)
drop if todrop==1
drop todrop

*	Generate unique joint leisure variable. The only measure of public 
*	leisure that implies non-negative private leisure for both spouses 
*	is the minimum reported public leisure:
gen Lp = LpH if LpH<=LpW
replace Lp = LpW if LpH>LpW
gen lH = LH-Lp
gen lW = LW-Lp
label variable Lp "(gen) wk hours public leisure"
label variable lH "(gen) wk hours private leisure" 
label variable lW "(gen) wk hours private leisure" 
drop rTime* Time*


/*******************************************************************************
Generate and report proportions of market participation 
(mentioned in section I and appendix A.2)
*******************************************************************************/

*	Generate:
gen participateH = (wH>0 & wH!=.)
gen participateW = (wW>0 & wW!=.)

*	Summarize:
sum participate*


/*******************************************************************************
Leisure & childcare descriptives table (appendix A.2, table A.3)
*******************************************************************************/

*	Label variables:
label variable LH "leisure male"
label variable LW "leisure female"
label variable Lp "joint leisure"
label variable TH "childcare male"
label variable TW "childcare female"

*	Summarize and export:
eststo clear
estpost summarize LH LW Lp TH TW, de listwise 
#delimit;
esttab using "$EXPORTSdir/TableA3.tex", replace
	cells("mean(fmt(1)) p50(fmt(1)) p10(fmt(1)) p90(fmt(1))")
	collabels("mean" "median" "10\textsuperscript{th} pct." "90\textsuperscript{th} pct.") 
	label ;
#delimit cr


/*******************************************************************************
Leisure & childcare correlations table (appendix A.2, table A.4)
*******************************************************************************/

*	Generate log time use variables:
gen lLH = log(LH)
gen lLW = log(LW)
gen lLp = log(Lp)
gen lTH = log(TH)
gen lTW = log(TW)

*	Y = Private leisure, joint leisure, childcare
*	X = Private leisure, joint leisure, childcare
eststo clear
eststo: reg lLH lLW lLp lTH lTW, vce(cluster nohouse_encr)
eststo: reg lLW lLH lLp lTH lTW, vce(cluster nohouse_encr)
eststo: reg lLp lLH lLW lTH lTW, vce(cluster nohouse_encr)
eststo: reg lTH lLH lLW lLp lTW, vce(cluster nohouse_encr)
eststo: reg lTW lLH lLW lLp lTH, vce(cluster nohouse_encr)
#delimit;
estout using "$EXPORTSdir/TableA4.tex", replace
	mlabels("leisure male" "leisure female" "joint leisure" "childcare male" "childcare female")
	varlabels(	lLH 	"leisure male" 
				lLW 	"leisure female" 
				lLp 	"joint leisure" 
				lTH 	"childcare male" 
				lTW 	"childcare female")
	cells("b(fmt(3))" "se(par fmt(3))") label order(lLH lLW lLp lTH lTW) 
	style(tex) drop(_cons) ;	
#delimit cr

*** end of do file ***
