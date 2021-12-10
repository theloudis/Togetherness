
/*******************************************************************************
	
	This code implements the sample selection and constructs new variables.
	Specifically it:
	- obtains age of gender of youngest child
	- calculates the quantity of external childcare.
	- constructs parental and child consumption.
	- constructs the weekly total time budgets.
	- normalizes the time variables so that the weekly budget adds up to 168 hrs.
	- statistically imputes children's consumption in few households for whom
	  children's consumption is not observed.
	- constructs regular and irregular work variables.
	- exports dataset.
	____________________________________________________________________________

	Filename: 	CTV_05_Childful.do
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
use "$DATAdir/panel_childful_$today.dta", clear


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


/*******************************************************************************
Quantity of external childcare (Tk)
*******************************************************************************/
	
* 	Parents report how many 'part-days' they use external childcare for, 
*	including formal (eg. nurseries) and informal care (eg. grandparents). 
*	A part-day refers to either a morning or an afternoon. We transform this to 
*	hours by multiplying each part-day by 4 hours. 
*	Note: there are two relevant variables, one for children up to 6 years old
*	and another one for children older than 6 years.

*	Obtain total hours of external childcare:
gen Tk04H = 4*k_ptdays04H
gen Tk95H = 4*k_ptdays95H
gen Tk04W = 4*k_ptdays04W
gen Tk95W = 4*k_ptdays95W
drop k_ptdays*

*	There is a second measure of external childcare that overlaps substantially
*	with the measure above for both parents (and more so for younger children). 
*	We thus drop the 2nd measure (it has smaller coverage by construction) 
*	unless the 1st measure is missing:
replace Tk04H = k_whours04H if Tk04H==. & k_whours04H!=.
replace Tk95H = k_whours95H if Tk95H==. & k_whours95H!=.
replace Tk04W = k_whours04W if Tk04W==. & k_whours04W!=.
replace Tk95W = k_whours95W if Tk95W==. & k_whours95W!=.
drop k_whours*

*	Generate total external childcare as reported by each parent, replace
*	missing values with zeroes:
gen TkH = Tk04H+Tk95H 
gen TkW = Tk04W+Tk95W
label variable TkH "(gen) External childcare HD"
label variable TkW "(gen) External childcare WF"
drop Tk04* Tk95*
foreach var of varlist TkH TkW {
	replace `var' = 0 if `var'==.
}
* 
* 	The parents may disagree about how much external childcare there is. To 
*	resolve the disagreement, we generate two additional measures of external 
* 	childcare alongside the father's and mother's response:
*	-measure 1: take the maximum of the two responses
gen 	Tkmax = TkH if TkH>=TkW
replace Tkmax = TkW if TkH<TkW
label variable Tkmax "(gen) Max external childcare"
*	-measure 2: take the minimum of the two responses
gen 	Tkmin = TkH if TkH<=TkW
replace Tkmin = TkW if TkH>TkW
label variable Tkmin "(gen) Min external childcare"

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
*	It does not include food at home (see step 3 below).
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
gen todrop = (Cp_v1==. | Cp_v1==0 | Cp_v2==. | Cp_v2==0)	/* 11 same observations have zero consumption regardless the consumption measure we employ*/

* 	Drop few observations for which there is a massive discrepancy between
*	spouses' respective consumption responses:
gen dcons = abs(Cp_v1-Cp_v2)
replace todrop = 1 if dcons>2000 
drop if todrop==1
drop dcons todrop

*	We need to select one consumption measure so we select consumption 
*	as reported by the wife:
rename Cp_v2 Cp
label variable Cp "(gen) total expenditure parents"
drop Cp_v1

*	Construct children's expenditure by aggregating elementary items while
*	treating missing values as zeroes. Children's expenditure consists of:
*		-eating at home
*		-food and drinks outside the house
*		-cigarettes and other tobacco products
*		-clothing
*		-personal care products and services
*		-medical costs not covered by insurance
*		-leisure time expenditure
*		-schooling and further schooling
*		-gifts and presents
*		-other children's expenditure.
*	Questions for children's expenditure are asked to either the father or the
*	the mother. However, in approximate 4% of households, neither the father nor
*	the mother respond. In those cases, as well as in cases where children's
*	total expenditure is exactly zero, we impute statistically the level of
*	children's expenditure (further down).
egen consk_Hresponds = rowtotal(c_kdfoodinH c_kfoodoutH c_ktobaccoH c_kclothesH c_kpcareH c_kmedicalH c_kleisureH c_kschlH c_kgiftsH c_kotherH) if c_krespondentH==1
egen consk_Wresponds = rowtotal(c_kdfoodinW c_kfoodoutW c_ktobaccoW c_kclothesW c_kpcareW c_kmedicalW c_kleisureW c_kschlW c_kgiftsW c_kotherW) if c_krespondentW==1
gen Ck = consk_Hresponds if c_krespondentH==1
replace Ck = consk_Wresponds if c_krespondentW==1
label variable Ck "(gen) total expenditure children"
drop consk_*responds c_kdfoodin* c_kfoodout* c_ktobacco* c_kclothes* c_kpcare* c_kmedical* c_kleisure* c_kschl* c_kgifts* c_kother*

*	Monthly expenditure on children's daycare:
*	Note: -999999 indicates the partner is the one who knows this information.
gen Kk = .
label variable Kk "(gen) expenditure daycare"
replace c_dcareH = 0 if c_dcareH==.
replace c_dcareW = 0 if c_dcareW==.
replace Kk = 0 if c_dcareH==-999999 & c_dcareW==-999999
replace Kk = c_dcareH if c_dcareH!=-999999 & c_dcareW==-999999
replace Kk = c_dcareW if c_dcareH==-999999 & c_dcareW!=-999999
replace Kk = 0		  if c_dcareH==0       & c_dcareW==0
replace Kk = c_dcareH if c_dcareH>0        & c_dcareW==0	
replace Kk = c_dcareW if c_dcareH==0       & c_dcareW>0		
replace Kk = c_dcareW if c_dcareH>0        & c_dcareW>0
drop c_dcare* c_cc*

*	Convert monthly amounts to weekly:
foreach cvar of varlist Cp Ck Kk {
	replace `cvar' = 7*(`cvar'/30)
}


/*******************************************************************************
Request appropriate wages
*******************************************************************************/

*	Drop if hourly wage of either spouse is missing (:zero hours) or is above 
*	EUR300/hour (:likely measurement error).
gen todrop = (wH==0 | wH==. | wH>300 | wW==0 | wW==. | wW>300)
drop if todrop==1
drop todrop


/*******************************************************************************
Construct the weekly time budgets
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


/*******************************************************************************
Rescale time use variables; obtain commuting-adjusted hours
*******************************************************************************/

*	Rescale time variables including public leisure:
foreach timevar of varlist CommutingH ChoresH PcareH TH ParentcareH FcareH OcareH LH LpH SchoolingH AdminH SleepH OtherH {
	replace `timevar' = `timevar'*((168-hH)/rTimeH)
}
foreach timevar of varlist CommutingW ChoresW PcareW TW ParentcareW FcareW OcareW LW LpW SchoolingW AdminW SleepW OtherW {
	replace `timevar' = `timevar'*((168-hW)/rTimeW)
}
*	Obtain composite work hours adding commuting time to hours; adjust wages
*	accordingly:
*	Note: commuting-adjusted hours & wages are used in one of our robsutness
*	checks. We impose a maximum of 30 weekly commuting hours (=6 hours per day 
*	x 5 days per week).
gen 	hH_commu = hH + CommutingH if CommutingH<=30
replace hH_commu = hH if CommutingH>30
gen 	hW_commu = hW + CommutingW if CommutingW<=30
replace hW_commu = hW if CommutingW>30
gen 	wH_commu = (y_nmhatH*12)/(hH_commu*52)
gen 	wW_commu = (y_nmhatW*12)/(hW_commu*52)
label variable hH_commu "(gen) wk hours market work - adj. commuting"
label variable hW_commu "(gen) wk hours market work - adj. commuting"
label variable wH_commu "(gen) hourly wage - adj. commuting"
label variable wW_commu "(gen) hourly wage - adj. commuting"
drop y_nm*

*	Generate unique joint leisure variable. The only measure of joint 
*	leisure that implies non-negative private leisure for both spouses 
*	is the minimum reported public leisure:
gen Lp = LpH if LpH<=LpW
replace Lp = LpW if LpH>LpW
gen lH = LH-Lp
gen lW = LW-Lp
label variable Lp "(gen) wk hours public leisure"
label variable lH "(gen) wk hours private leisure" 
label variable lW "(gen) wk hours private leisure" 
drop rTime*


/*******************************************************************************
Timing of market work indicators
*******************************************************************************/

*	The survey provides a list of questions for whether one works irregular
*	hours such as evenings, nights, or wekends. These variables are:
*	(1) w_irregulreq :: 
*		Does your job often require you to work outside regular office hours, 
*		that is, during hours other than between 7 a.m. and 6 p.m.?
*			1	yes, I work in shifts
*			2	yes, I (almost) always work in the evening or at night
*			3	yes, I often work outside regular office hours
*			4	no
*	(2) w_evenings ::
*		During the course of the week, do you sometimes work in the evening 
*		between 6 p.m. and midnight? If so, how often does this happen?
*			1	no, I never work in the evening
*			2	I rarely work in the evening
*			3	I work one or more evenings once every few weeks
*			4	I work one or more evenings almost every week
*	(3) w_nights ::
*		During the course of the week, do you sometimes work at night (after 
*		midnight)? If so, how often does that happen?
*			1	no, I never work at night
*			2	I rarely work at night
*			3	I work at night once every few weeks
*			4	I work at night almost every week
*	(4) w_wkends ::
*		Do you ever work during the weekend?
*			1	no, I never work during the weekend
*			2	I rarely work during the weekend
*			3	I work during the weekend once every few weeks
*			4	I work during the weekend almost every week
*	(5) w_home ::
* 		Do you have a (partial) 'working-at-home day'?
*			1	no
*			2	yes, less than one day per week
*			3	yes, about one day per week
*			4	yes, more than one day per week
* 	(6) w_irregulcho ::
*		Do you work irregular hours?
*			1	often
*			2	sometimes
*			3	never

*	We assume no irregularity in the timing of market work whenevever there is
*	a missing value (so we assign the corresponding 'no' category):
foreach var of varlist w_irregulreq* {
	replace `var' = 4 if `var'==.
}
foreach var of varlist w_evenings* {
	replace `var' = 1 if `var'==.
}
foreach var of varlist w_nights* {
	replace `var' = 1 if `var'==.
}
foreach var of varlist w_wkends* {
	replace `var' = 1 if `var'==.
}
foreach var of varlist w_home* {
	replace `var' = 1 if `var'==.
}
foreach var of varlist w_irregulcho* {
	replace `var' = 3 if `var'==.
}
*	We use 'w_irregulcho' to determine the fraction of a worker's time 
*	spent in regular and irregular hours. We generate `hours regular` and
*	`hours irregular` given the answer supplied to 'w_irregulcho'. We repeat
*	twice for baseline hours and hours adjusted for commuting.

*	Generate regular and irregular hours variables:
gen hH_R = .
gen hH_I = .
gen hW_R = .
gen hW_I = .
gen hH_commu_R = .
gen hH_commu_I = .
gen hW_commu_R = .
gen hW_commu_I = .
*	-label variables:
label variable hH_R "(gen) wk REG hours market work"
label variable hH_I "(gen) wk IRREG hours market work"
label variable hW_R "(gen) wk REG hours market work"
label variable hW_I "(gen) wk IRREG hours market work"
label variable hH_commu_R "(gen) wk REG hours market work - adj. commuting"
label variable hH_commu_I "(gen) wk IRREG hours market work - adj. commuting"
label variable hW_commu_R "(gen) wk REG hours market work - adj. commuting"
label variable hW_commu_I "(gen) wk IRREG hours market work - adj. commuting"

*	Calculate hours - baseline hours:
*	-husband:
replace hH_R = hH 		if w_irregulchoH==3
replace hH_I = 0 		if w_irregulchoH==3		/* never  */
replace hH_R = 0.75*hH 	if w_irregulchoH==2
replace hH_I = 0.25*hH 	if w_irregulchoH==2		/* smtimes*/
replace hH_R = 0.5*hH 	if w_irregulchoH==1
replace hH_I = 0.5*hH 	if w_irregulchoH==1		/* often  */
*	-wife:
replace hW_R = hW 		if w_irregulchoW==3
replace hW_I = 0 		if w_irregulchoW==3		/* never  */
replace hW_R = 0.75*hW 	if w_irregulchoW==2
replace hW_I = 0.25*hW 	if w_irregulchoW==2		/* smtimes*/
replace hW_R = 0.5*hW 	if w_irregulchoW==1	
replace hW_I = 0.5*hW 	if w_irregulchoW==1		/* often  */

*	Calculate hours - hours adjusted for commuting:
*	-husband:
replace hH_commu_R = hH_commu 		if w_irregulchoH==3
replace hH_commu_I = 0 				if w_irregulchoH==3		/* never  */
replace hH_commu_R = 0.75*hH_commu 	if w_irregulchoH==2
replace hH_commu_I = 0.25*hH_commu 	if w_irregulchoH==2		/* smtimes*/
replace hH_commu_R = 0.5*hH_commu 	if w_irregulchoH==1
replace hH_commu_I = 0.5*hH_commu 	if w_irregulchoH==1		/* often  */
*	-wife:
replace hW_commu_R = hW_commu 		if w_irregulchoW==3
replace hW_commu_I = 0 				if w_irregulchoW==3		/* never  */
replace hW_commu_R = 0.75*hW_commu 	if w_irregulchoW==2
replace hW_commu_I = 0.25*hW_commu 	if w_irregulchoW==2		/* smtimes*/
replace hW_commu_R = 0.5*hW_commu 	if w_irregulchoW==1	
replace hW_commu_I = 0.5*hW_commu 	if w_irregulchoW==1		/* often  */

*	We also generate a secondary irregularity measure (used in the robustness
*	checks) based only on the incident of evening or night work.
*	-husband:
gen 	irregulH = 3 if (w_eveningsH==1 & w_nightsH==1) | (w_eveningsH==. & w_nightsH==.)
replace irregulH = 1 if  w_eveningsH==4 | w_nightsH==4
replace irregulH = 2 if  irregulH==.
*	-wife:
gen 	irregulW = 3 if (w_eveningsW==1 & w_nightsW==1) | (w_eveningsW==. & w_nightsW==.)
replace irregulW = 1 if  w_eveningsW==4 | w_nightsW==4
replace irregulW = 2 if  irregulW==.

*	Generate regular and irregular hours variables:
gen hH_R2 = .
gen hH_I2 = .
gen hW_R2 = .
gen hW_I2 = .
gen hH_commu_R2 = .
gen hH_commu_I2 = .
gen hW_commu_R2 = .
gen hW_commu_I2 = .
*	-label variables:
label variable hH_R2 "(gen) wk REG hours market work"
label variable hH_I2 "(gen) wk IRREG hours market work"
label variable hW_R2 "(gen) wk REG hours market work"
label variable hW_I2 "(gen) wk IRREG hours market work"
label variable hH_commu_R2 "(gen) wk REG hours market work - adj. commuting"
label variable hH_commu_I2 "(gen) wk IRREG hours market work - adj. commuting"
label variable hW_commu_R2 "(gen) wk REG hours market work - adj. commuting"
label variable hW_commu_I2 "(gen) wk IRREG hours market work - adj. commuting"

*	Calculate hours using secondary irregularity measure - baseline hours:
*	-husband:
replace hH_R2 = hH 			if irregulH==3
replace hH_I2 = 0 			if irregulH==3		/* never  */
replace hH_R2 = 0.75*hH 	if irregulH==2
replace hH_I2 = 0.25*hH 	if irregulH==2		/* smtimes*/
replace hH_R2 = 0.5*hH 		if irregulH==1
replace hH_I2 = 0.5*hH 		if irregulH==1		/* often  */
*	-wife:
replace hW_R2 = hW 			if irregulW==3
replace hW_I2 = 0 			if irregulW==3		/* never  */
replace hW_R2 = 0.75*hW 	if irregulW==2
replace hW_I2 = 0.25*hW 	if irregulW==2		/* smtimes*/
replace hW_R2 = 0.5*hW 		if irregulW==1	
replace hW_I2 = 0.5*hW 		if irregulW==1		/* often  */

*	Calculate hours using secondary irregularity measure - hours adjusted for commuting:
*	-husband:
replace hH_commu_R2 = hH_commu 		if irregulH==3
replace hH_commu_I2 = 0 			if irregulH==3		/* never  */
replace hH_commu_R2 = 0.75*hH_commu if irregulH==2
replace hH_commu_I2 = 0.25*hH_commu if irregulH==2		/* smtimes*/
replace hH_commu_R2 = 0.5*hH_commu 	if irregulH==1
replace hH_commu_I2 = 0.5*hH_commu 	if irregulH==1		/* often  */
*	-wife:
replace hW_commu_R2 = hW_commu 		if irregulW==3
replace hW_commu_I2 = 0 			if irregulW==3		/* never  */
replace hW_commu_R2 = 0.75*hW_commu if irregulW==2
replace hW_commu_I2 = 0.25*hW_commu if irregulW==2		/* smtimes*/
replace hW_commu_R2 = 0.5*hW_commu 	if irregulW==1	
replace hW_commu_I2 = 0.5*hW_commu 	if irregulW==1		/* often  */


/*******************************************************************************
Consolidate occupational sectors; assortative patterns by occupation
*******************************************************************************/

*	Current values for the occupational sectors (w_sectorH w_sectorW) are:
*		1 	agriculture
*		2   mining
*		3 	industrial
*		4 	utilities
*		5 	construction
*		6 	retail
*		7 	catering
*		8 	transport
*		9 	financial
*		10 	business 
*		11 	government
*		12  education
*		13  healthcare
*		14  culture
*		15  other 

*	Consolidate sector values into 1-10 scale:
gen w_sectorH_neo = w_sectorH
gen w_sectorW_neo = w_sectorW
foreach var of varlist w_sectorH w_sectorW {
	replace `var'_neo = 1  if `var'==1 | `var'==2 		/* agriculture and mining in the same category 		*/
	replace `var'_neo = 2  if `var'==3 | `var'==5 		/* industrial and construction in the same category */
	replace `var'_neo = 3  if `var'==4 | `var'==8 		/* utilities and transport in the same category 	*/
	replace `var'_neo = 4  if `var'==6 | `var'==7 		/* catering and retail in the same category 		*/
	replace `var'_neo = 5  if `var'==9 | `var'==10 		/* financial and business in the same category 		*/
	replace `var'_neo = 6  if `var'==11 				/* government 										*/
	replace `var'_neo = 7  if `var'==12 				/* education 										*/ 
 	replace `var'_neo = 8  if `var'==13 				/* healthcare 										*/
	replace `var'_neo = 9  if `var'==14 				/* culture 											*/
	replace `var'_neo = 0  if `var'==15 				/* other 											*/
	replace `var'_neo = -1 if `var'==. 					/* missing sector 									*/
	label variable `var'_neo "consolidated sector variable"
}
*	Define value labels:
#delimit;
label define sectorl 	1 	"agriculture"  			2 	"industry, construct."  
						3 	"utilities, transport"  4 	"catering, retail"  
						5 	"financial, business"  	6 	"government" 
						7 	"education"  			8 	"healthcare"  
						9 	"culture" 				0 	"other" 
						-1 	"missing" ;
#delimit cr						
label values w_sectorH_neo w_sectorW_neo sectorl

*	Count families in each spousal sectoral combination:
preserve
collapse (count) year, by(w_sectorH_neo w_sectorW_neo)
sort w_sectorH_neo w_sectorW_neo
rename year frequency
label variable frequency "number of households in the sample"

*	Draw spousal occupational sector heatmap (online appendix figure D.1a):
#delimit;
twoway 	(contour frequency w_sectorH_neo w_sectorW_neo, heatmap ccuts(0(2)32)
					xlabel( 1 	"agriculture"  
							2 	"industry, construct."  
							3 	"utilities, transport"  
							4 	"catering, retail"  
							5 	"financial, business"  
							6 	"government" 
							7 	"education"  
							8 	"healthcare"  
							9 	"culture" 
							0 	"other" 
							-1 	"missing",
							angle(35) labsize(small)) 
					xtitle("occupation sector wife")
					ylabel( 1 	"agriculture"  
							2 	"industry, construct."  
							3 	"utilities, transport"  
							4 	"catering, retail"  
							5 	"financial, business"  
							6 	"government" 
							7 	"education"  
							8 	"healthcare"  
							9 	"culture" 
							0 	"other" 
							-1 	"missing",
							angle(horizontal) labsize(small))
					ytitle("occupation sector husband")
					zlabel(,labsize(small))
					ztitle(,size(small) orientation(rvertical))) 
					(function y=x, range(w_sectorH_neo) lwidth(1) lcolor(red)),
					graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/FigD1a.pdf", as(pdf) replace
cap : window manage close graph
restore

*	Gen indicator variable = 1 if spouses work in the same sector:
gen assort_occupation = (w_sectorH_neo==w_sectorW_neo)
label variable assort_occupation 	"assortative indicator: sector"


/*******************************************************************************
Occupation & profession variables by incidence of irregular work
*******************************************************************************/

*	Variables 'irr_m' equal 1 if individual reports some irregular work:
gen irrH=w_irregulchoH!=3	
gen irrW=w_irregulchoW!=3

*	Label sector variable:
label define sector 1 "agriculture" 3 "industrial" 4 "utilities" 5 "construction" 6 "retail" 7 "catering" 8 "transport" 9 "financial" 10 "business" 11 "government" 12 "education" 13 "healthcare" 14 "culture" 15 "other", modify
label values w_sectorH w_sectorW .
label values w_sectorH w_sectorW sector, nofix

*	Calculate proportions in sectors, by irregular work (men), and export:
eststo clear
bys w_sectorH : eststo : estpost tabulate irrH, nototal
esttab /*using $EXPORTSdir/occupations_childful_$today.csv*/, cells(pct(fmt(2))) nostar varlabels(`e(labels)') label nodepvar varwidth(40) replace

*	Calculate proportions in sectors, by irregular work (women), and export:	
eststo clear
bys w_sectorW : eststo : estpost tabulate irrW, nototal
esttab /*using $EXPORTSdir/occupations_childful_$today.csv*/, cells(pct(fmt(2))) nostar varlabels(`e(labels)') label nodepvar varwidth(40) append


/*******************************************************************************
Assortative patterns by education
*******************************************************************************/

*	Current values for education (dm_educH dm_educW) are:
*		1 	primary
*		2 	intermediate secondary
*		3   higher secondary
*		4 	vocational education
*		5 	university
*		6 	post graduate
*		7 	other
*		9 	not yet started education

*	Consolidate education values into 0-6 scale:
gen educH_cont = dm_educH						
replace educH_cont = 1 if dm_educH>6		/* odd education categories	*/
label variable educH_cont 	"consolidated education HD"
gen educW_cont = dm_educW
replace educW_cont = 1 if dm_educW>6		/* odd education categories	*/
label variable educW_cont 	"consolidated education WF"
#delimit;
label define educl 	1 "primary"				2 "intermediate secondary"
					3 "higher secondary" 	4 "vocational education"
					5 "university" 			6 "post graduate" ;
#delimit cr						
label values educH_cont educW_cont educl

*	Count families in each spousal education combination:
preserve
collapse (count) year, by(educH_cont educW_cont)
sort educH_cont educW_cont
rename year frequency
label variable frequency "number of households in the sample"

*	Draw spousal education heatmap (online appendix figure D.1b)::
#delimit;
twoway 	(contour frequency educH_cont educW_cont, heatmap ccuts(0(5)80)
					xlabel( 1 "primary"				
							2 "intermediate secondary"
							3 "higher secondary" 	
							4 "vocational education"
							5 "university" 			
							6 "post graduate",
							angle(35) labsize(small)) 
					xtitle("education wife")
					ylabel( 1 "primary"				
							2 "intermediate secondary"
							3 "higher secondary" 	
							4 "vocational education"
							5 "university" 			
							6 "post graduate",
							angle(horizontal) labsize(small))
					ytitle("education husband")
					zlabel(,labsize(small))
					ztitle(,size(small) orientation(rvertical))) 
					(function y=x, range(educH_cont) lwidth(1) lcolor(red)),
					graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/FigD1b.pdf", as(pdf) replace
cap : window manage close graph
restore

*	Gen indicator variable = 1 if spouses have same educational attainment:
gen assort_education = (educH_cont==educW_cont)
label variable assort_education 	"assortative indicator: education"


/*******************************************************************************
Spouse gap variables, we correlate with the derived sharing rule
*******************************************************************************/

*	Age gap:
gen gap_age_l = dm_ageH - dm_ageW
label variable gap_age_l 		"Spousal age gap (level)"

*	Leisure gap:
gen gap_leisure_l = LH - LW
gen gap_leisure_r = LH/LW
label variable gap_leisure_l 	"Spousal leisure gap  (level)"
label variable gap_leisure_r 	"Spousal leisure gap  (ratio)"

*	Childcare gap:
gen gap_childcare_l = TH - TW
gen gap_childcare_r = TH/TW
label variable gap_childcare_l 	"Spousal childcare gap  (level)"
label variable gap_childcare_r 	"Spousal childcare gap  (ratio)"

*	Chores gap:
gen gap_chores_l = ChoresH - ChoresW
gen gap_chores_r = ChoresH/ChoresW
label variable gap_chores_l 	"Spousal general chores gap  (level)"
label variable gap_chores_r 	"Spousal general chores gap  (ratio)"

*	Admin chores gap:
gen gap_admin_l = AdminH - AdminW
gen gap_admin_r = AdminH/AdminW
label variable gap_admin_l 		"Spousal admin chores gap (level)"
label variable gap_admin_r 		"Spousal admin chores gap (ratio)"

*	Gender wage gap:
gen gap_wage_l = wH - wW
gen gap_wage_r = wH/wW
label variable gap_wage_l 		"Spousal wage gap (level)"
label variable gap_wage_r 		"Spousal wage gap (ratio)"


/*******************************************************************************
Division of chores variables, we correlate with the derived sharing rule
*******************************************************************************/

*	The following set of variables ask the female spouse who in the household 
* 	is mostly responsible for certain errands and tasks:
*	- h_hdivfoodW 		food preparation
*	- h_hdivlaundryW 	laundry, ironing
*	- h_hdivcleanW  	house cleaning
*	- h_hdivoddW  		odd jobs in and around the household
*	- h_hdivfinancW  	financial administration errands
*	- h_hdivgroceryW  	grocery shopping
*	- h_hdivplaykW  	storyreading, playing games, other forms of play with the child
*	- h_hdivdrivekW     drive to/from daycare or school, attending activities with the child
*	- h_hdivtalkkW		talking about problems in school or about manners with the child
*	- h_hdivgooutkW     small outings to cinema, zoo, etc. with the child
*
*	The answers are categorical, work is done (1) mostly by female spouse, 
*	(2) female spouse does more than male, (3) roughly equally, (4) male spouse 
*	does more than female, (5) mostly by male spouse. We recast these answers
*	to a 1-3 scale: (1) female spouse does more than male, (2) mostly equally, 
*	(3) male spouse does more than female.

*	-food preparation:
gen div_food = .
replace div_food = 1 if h_hdivfoodW==1 | h_hdivfoodW==2
replace div_food = 2 if h_hdivfoodW==3
replace div_food = 3 if h_hdivfoodW==4 | h_hdivfoodW==5
label variable div_food 	"division food preparation"

*	-laundry, ironing:
gen div_laundry = .
replace div_laundry = 1 if h_hdivlaundryW==1 | h_hdivlaundryW==2
replace div_laundry = 2 if h_hdivlaundryW==3
replace div_laundry = 3 if h_hdivlaundryW==4 | h_hdivlaundryW==5
label variable div_laundry 	"division laundry, ironing"

*	-house cleaning:
gen div_cleaning = .
replace div_cleaning = 1 if h_hdivcleanW==1 | h_hdivcleanW==2
replace div_cleaning = 2 if h_hdivcleanW==3
replace div_cleaning = 3 if h_hdivcleanW==4 | h_hdivcleanW==5
label variable div_cleaning 	"division house cleaning"

*	-odd jobs in and around the household:
gen div_oddjobs = .
replace div_oddjobs = 1 if h_hdivoddW==1 | h_hdivoddW==2
replace div_oddjobs = 2 if h_hdivoddW==3
replace div_oddjobs = 3 if h_hdivoddW==4 | h_hdivoddW==5
label variable div_oddjobs 	"division odd jobs"

*	-financial administration errands:
gen div_finance = .
replace div_finance = 1 if h_hdivfinancW==1 | h_hdivfinancW==2
replace div_finance = 2 if h_hdivfinancW==3
replace div_finance = 3 if h_hdivfinancW==4 | h_hdivfinancW==5
label variable div_finance 	"division financial errands"

*	-grocery shopping:
gen div_grocery = .
replace div_grocery = 1 if h_hdivgroceryW==1 | h_hdivgroceryW==2
replace div_grocery = 2 if h_hdivgroceryW==3
replace div_grocery = 3 if h_hdivgroceryW==4 | h_hdivgroceryW==5
label variable div_grocery 	"division grocery shopping"

*	-storyreading, playing games, other forms of play with the child:
gen div_playk = .
replace div_playk = 1 if h_hdivplaykW==1 | h_hdivplaykW==2
replace div_playk = 2 if h_hdivplaykW==3
replace div_playk = 3 if h_hdivplaykW==4 | h_hdivplaykW==5
label variable div_playk 	"division storyreading, playing"

*	-drive to/from daycare or school, attending activities with the child:
gen div_drivek = .
replace div_drivek = 1 if h_hdivdrivekW==1 | h_hdivdrivekW==2
replace div_drivek = 2 if h_hdivdrivekW==3
replace div_drivek = 3 if h_hdivdrivekW==4 | h_hdivdrivekW==5
label variable div_drivek 	"division drive, attend activities"

*	-talking about problems in school or about manners with the child:
gen div_talkk = .
replace div_talkk = 1 if h_hdivtalkkW==1 | h_hdivtalkkW==2
replace div_talkk = 2 if h_hdivtalkkW==3
replace div_talkk = 3 if h_hdivtalkkW==4 | h_hdivtalkkW==5
label variable div_talkk 	"division talking, manners"

*	-small outings to cinema, zoo, etc. with the child:
gen div_gooutk = .
replace div_gooutk = 1 if h_hdivgooutkW==1 | h_hdivgooutkW==2
replace div_gooutk = 2 if h_hdivgooutkW==3
replace div_gooutk = 3 if h_hdivgooutkW==4 | h_hdivgooutkW==5
label variable div_gooutk 	"division small outings"

drop h_hdiv*


/*******************************************************************************
Impute children's consumption
*******************************************************************************/

*	Impute missing children's consumption: 
*	Note 1: We impute children's consumption for few households for which Ck
*	is missing. The imputation is statistical: we regress Ck (non-missing in 
*	the majority of households) on demographics, work hours, and parents'
*	consumption; then we predict Ck for few households for whom Ck was 
*	previously missing. The regression is not 'causal' but 'statistical'. 
*	We must assume that the unobservables are identically distributed 
*	between households with missing and households with non-missing Ck.

*	-generate imputed indicator:
gen Ck_imputed = Ck==.
gen dum_2kid = dm_ak2youngest!=.

*	-impute Ck:
#delimit;
reg Ck i.year i.dm_fstatus i.dm_dwelling
	dm_ageH i.dm_educH dm_ageW i.dm_educW
	i.dm_nummems i.dm_numkids dm_akyoungest i.dm_gkyoungest dum_2kid
	Cp hH hW if Ck_imputed==0 ;	
#delimit cr 
predict Ck_imp if Ck_imputed==1, xb
replace Ck = Ck_imp if Ck_imputed==1 & Ck_imp>=0
replace Ck = 0 		if Ck_imputed==1 & Ck_imp<0
label variable Ck "(gen/imp) total consumption children"
drop Ck_imp* dum_2kid	

*	Export final dataset:
qui compress
save "$DATAdir/selected_wchildren_$today.dta", replace

*** end of do file ***
