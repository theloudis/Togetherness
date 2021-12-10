
/*******************************************************************************
	
	This code implements the sample selection of childless families from the 
	point where childless families are split off from the overall sample.
	Specifically it:
	- constructs adult consumption.
	- constructs the weekly total time budgets.
	- normalizes time variables so that weekly time budget adds up to 168 hrs.
	- constructs regular and irregular work variables.
	- exports dataset.
	____________________________________________________________________________

	Filename: 	CTV_06_Childless.do
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
use "$DATAdir/panel_childless_$today.dta", clear


/*******************************************************************************
Presence of children
*******************************************************************************/

*	Despite this dataset being conditional on 'dm_numkids==0', the question on
*	the 'age of children' reveals that there are still children in the
* 	household. These are mainly children who are:
*	- (much) older than 16 years old [the large majority] and pose no threat to
*	  our identification.
*	- some much younger children (possibly newborn ones) who were coded as '0'
*	  in the hbox variable 'dm_numkids' possibly because the age of children 
*	  question is asked at the time of the module 5 questionnaire whereas
*	  'dm_numkids'is the modal value per year. 
*	To be confident we are truly capturing childless couples, we drop the
*	households that likely fall in the second category above.

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

*	We keep those who strictly have no children as well as those who have 
*	grown-up children (i.e. age 17 and higher). We assume that the latter type
*	of 'children' do not require childcare and they do not affect their parents'
*	time budget in any other way:
keep if (numkidsH==0 & numkidsW==0) | (ageyH>16 & ageyW>16)

*	Drop all children related variables:
drop numkids* agey* agek* dm_gk* k_* c_k* c_cc* y_cc* dm_numkids dm_allkalive* c_dcare*


/*******************************************************************************
Consumption variables
*******************************************************************************/

*	Construct adults' expenditure by aggregating elementary consumption items 
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
*		-eating at home
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
*	Note: As per above, we create two measures of total parental consumption,
*	one that reflects mainly the husband's responses for the public elements, 
*	and another one that reflects the wife's.
gen Cp_v1 = priH + priW + pub_byH 
gen Cp_v2 = priH + priW + pub_byW 
drop priH priW pub_by*

*	Drop if consumption is zero or missing:
gen todrop = (Cp_v1==. | Cp_v1==0 | Cp_v2==. | Cp_v2==0)	/* 6 observations have zero consumption regardless the consumption measure we employ*/

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
*   5. 	childcare and activities with children (==0 in this sample)
*	6.  helping parents
*	7. 	helping other family members
*	8.  helping non-family members
* 	9.  leisure
*	10. further schooling
*   11. administrative chores
*	12. sleeping and relaxing
*	13. all other activities
replace TH = 0
replace TW = 0
egen TimeH = rsum(hH CommutingH ChoresH PcareH TH ParentcareH FcareH OcareH LH SchoolingH AdminH SleepH OtherH)
egen TimeW = rsum(hW CommutingW ChoresW PcareW TW ParentcareW FcareW OcareW LW SchoolingW AdminW SleepW OtherW)
	
*	The time budgets often do not exactly equal 168 hours so we normalize all 
*	activities so that total time equals 168. We keep market work outside this 
*	normalization because it is often around 40 (FT) or 20-25 hours (PT) per week:
gen rTimeH = TimeH - hH
gen rTimeW = TimeW - hW
	
*	In very few cases residual time rTime may be 0, indicating that the
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
* is the minimum reported public leisure:
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
esttab /*using $EXPORTSdir/occupations_childless_$today.csv*/, cells(pct(fmt(2))) nostar varlabels(`e(labels)') label nodepvar varwidth(40) replace

*	Calculate proportions in sectors, by irregular work (women), and export:	
eststo clear
bys w_sectorW : eststo : estpost tabulate irrW, nototal
esttab /*using $EXPORTSdir/occupations_childless_$today.csv*/, cells(pct(fmt(2))) nostar varlabels(`e(labels)') label nodepvar varwidth(40) append


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
*		8/9 not yet started education

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
restore

*	Gen indicator variable = 1 if spouses have same educational attainment:
gen assort_education = (educH_cont==educW_cont)
label variable assort_education 	"assortative indicator: education"


/*******************************************************************************
Spouse gap variables
*******************************************************************************/

*	Age gap:
gen gap_age_l = dm_ageH - dm_ageW
label variable gap_age_l 		"Spousal age gap (level)"

*	Leisure gap:
gen gap_leisure_l = LH - LW
gen gap_leisure_r = LH/LW
label variable gap_leisure_l 	"Spousal leisure gap  (level)"
label variable gap_leisure_r 	"Spousal leisure gap  (ratio)"

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
Division of chores variables
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

drop h_hdiv* 

*	Export final dataset:
qui compress
save "$DATAdir/selected_nochildren_$today.dta", replace
	
*** end of do file ***
