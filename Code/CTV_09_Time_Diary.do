
/*******************************************************************************
	
	This code matches the pre-processed and aggregated LISS time diary data
	in 2013, formally LISS time use module 122, with data from the household 
	box and modules 5 & 6 in 2013. It implements a sample selection similar to 
	the one in the  main study (not conditional on labor market participation), 
	and calculates time diary moments that appear in the discussion in 
	appendix A.2.
	Specifically, the code:
	-imports the pre-processed and aggregated time diary data, formally LISS 
	 time use module 122, conducted in 2013.
	-generates time use variables from the time diary that are comparable to
	 those in the survey data.
	-merges the module with household box information and modules 5 & 6 in 2013.
	-carries out sample selection similar to the baseline.
	____________________________________________________________________________

	Filename: 	CTV_09_Time_Diary.do
	Author: 	Alexandros Theloudis (a.theloudis@gmail.com)
	Date: 		Autumn 2021
	Paper: 		Togetherness in the Household 
				Sam Cosaert and Alexandros Theloudis and Bertrand Verheyden

*******************************************************************************/

*	Initial statements:
clear
set more off
version 16.1


/*******************************************************************************
Import pre-processed and aggregated time diary data (LISS time use module 122)
*******************************************************************************/

*	Note: The time diary data (csv files below) are for 224 individuals who
*	completed the time diary in 2013. The data aggregate detailed time use over
*	10-minute intervals on three separate days that a diary is administered: 
*	day 1, day 2, and day 3 if either day 1 or day 2 was not completed. 

*	The aggregation of the low-level 10-minute interval information in the raw
*	data is coded in a separate file 'LISS_Time_Diary_Aggregation.r'. 
*	Please run that file first in order to create files
*		- Day1_processed.csv
*		- Day2_processed.csv
*		- Day3_processed.csv;
*	running 'LISS_Time_Diary_Aggregation.r' requires access to the raw LISS
*	data. Public access to the data is possible after creating an account 
*	and signing the appropriate agreement on https://www.dataarchive.lissdata.nl.
* 	Alternatively, use the processed data (csv files) we offer as part of our 
*	replication package.

*	Import day 1:
import delimited "$DATAdir/LISS_Time_Use/Day1_processed.csv", delimiter(";") clear
gen day = 1
tempfile day1
save `day1'

*	Import day 2:
import delimited "$DATAdir/LISS_Time_Use/Day2_processed.csv", delimiter(";") clear
gen day = 2
tempfile day2
save `day2'

*	Importa day 3:
import delimited "$DATAdir/LISS_Time_Use/Day3_processed.csv", delimiter(";") clear
gen day = 3
tempfile day3
save `day3'

*	Append separate days together:
use `day1', clear
append using `day2' `day3'

*	Rename variable names:
rename id 			nomem_encr
rename _total 		Sleep_total
rename _partner 	Sleep_partner
rename _children 	Sleep_children
rename _all 		Sleep_all
rename v6 			Eat_total
rename v7 			Eat_partner
rename v8 			Eat_children
rename v9 			Eat_all
rename v10 			Personal_total
rename v11 			Personal_partner
rename v12 			Personal_children
rename v13 			Personal_all
rename v14 			Work_total
rename v15 			Work_partner
rename v16 			Work_children
rename v17 			Work_all
rename v18 			Study_total
rename v19 			Study_partner
rename v20 			Study_children
rename v21 			Study_all
rename v22 			Chores_total
rename v23 			Chores_partner
rename v24 			Chores_children
rename v25 			Chores_all
rename v26 			Shopping_total
rename v27 			Shopping_partner
rename v28 			Shopping_children
rename v29 			Shopping_all
rename v30 			Care_total
rename v31 			Care_partner
rename v32 			Care_children
rename v33 			Care_all
rename v34 			Social_total
rename v35 			Social_partner
rename v36 			Social_children
rename v37 			Social_all
rename v38 			Otherleisure_total
rename v39 			Otherleisure_partner
rename v40 			Otherleisure_children
rename v41 			Otherleisure_all
rename v42 			Computer_total
rename v43 			Computer_partner
rename v44 			Computer_children
rename v45 			Computer_all
rename v46 			Tvbooks_total
rename v47 			Tvbooks_partner
rename v48 			Tvbooks_children
rename v49 			Tvbooks_all
rename v50 			Travel_total
rename v51 			Travel_partner
rename v52 			Travel_children
rename v53 			Travel_all
rename v54 			LISS_total
rename v55 			LISS_partner
rename v56 			LISS_children
rename v57 			LISS_all
rename v58 			Childcare_total
rename v59 			Childcare_partner
rename v60 			Childcare_children
rename v61 			Childcare_all

*	Reshape to wide, save:
reshape wide Sleep* Eat* Personal* Work* Study* Chores* Shopping* Care* Social* Otherleisure* Computer* Tvbooks* Travel* LISS* Childcare*, i(nomem_encr) j(day)

* 	Generate leisure variable per day, summing up sub-categories of leisure:
gen Leisure_total1 	 = Social_total1 + Otherleisure_total1 + Computer_total1 + Tvbooks_total1
gen Leisure_total2 	 = Social_total2 + Otherleisure_total2 + Computer_total2 + Tvbooks_total2
gen Leisure_total3 	 = Social_total3 + Otherleisure_total3 + Computer_total3 + Tvbooks_total3
gen Leisure_partner1 = Social_partner1 + Otherleisure_partner1 + Computer_partner1 + Tvbooks_partner1
gen Leisure_partner2 = Social_partner2 + Otherleisure_partner2 + Computer_partner2 + Tvbooks_partner2
gen Leisure_partner3 = Social_partner3 + Otherleisure_partner3 + Computer_partner3 + Tvbooks_partner3
drop Social_* Otherleisure_* Computer_* Tvbooks_*

*	Save temporarily:
compress
tempfile LISStimediary
save `LISStimediary' 


/*******************************************************************************
Household composition from LISS core modules
*******************************************************************************/

*	Use data:
use "$DATAdir/2013_$today.dta", clear

* 	Check spouses agree that they have been with the same partner:
gen todrop = (dm_samepartnerH!=dm_samepartnerW)
drop if todrop==1
drop todrop dm_samepartner*

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
Labor market earnings, hours, wages from LISS core module
*******************************************************************************/

*	Remove income variables that are not needed; use imputed net monthly income
*	(available from hbox) as the relevant earnings variable per spouse. This 
*	variable has slightly larger coverage in the sample compared to non-imputed 
*	ones. There are only very small differences between the moments of this 
*	variable and of the non-imputed ones.
drop y_gm* y_nmH y_nmW y_hh*mhat*

*	Tag those who report missing monthly earnings:
gen todrop = (y_nmhatH==. | y_nmhatW==.)
drop if todrop==1
drop todrop

*	Market work is now reported only in Core Module 6 'Work and Schooling'.
*	Note: We impose a theoretical maximum of 84 weekly market work hours 
*	(=16.8 hours per day x 5 days per week, 7.2 remaining daily hours are for 
*	sleep; or 12 hours per day x 7 days per week). 

*	-male hours Core Module 6:
gen hH = w_hrs6H if w_hrs6H<=84
replace hH = hH + w_2ndjobwhrsH if w_2ndjobH!=3
replace hH = . if hH>84

*	-female hours Core Module 6:
gen hW = w_hrs6W if w_hrs6W<=84 
replace hW = hW + w_2ndjobwhrsW if w_2ndjobW!=3
replace hW = . if hW>84

*	-label market work variables:
foreach var of varlist hH hW {
	label variable `var' "(gen) wk hours market work"
}

*	Generate hourly wages as annual earnings over annual hours:
gen wH = (y_nmhatH*12)/(hH*52)
label variable wH "(gen) hourly wage"
gen wW = (y_nmhatW*12)/(hW*52)
label variable wW "(gen) hourly wage"

*	Drop unneeded labor market participation variables:
drop w_hrs6* w_2ndjob* 


/*******************************************************************************
Age of children, admissible information on children from LISS core module
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

*	Drop households in which the spouses disagree on the age & gender of 
*	children, or households who report that not all children are alive (this is
*	because we don't know which ones may not be alive):
gen todrop = (ageyH!=ageyW | dm_gkyoungestH!=dm_gkyoungestW)
replace todrop = 1 if dm_allkaliveH==2 | dm_allkaliveW==2
drop if todrop==1
drop todrop dm_allkalive*

*	Rename age & gender variables:
drop ageyH dm_gkyoungestH 
rename ageyW dm_akyoungest
rename dm_gkyoungestW dm_gkyoungest
label variable dm_akyoungest "(gen) Age youngest child"
label variable dm_gkyoungest "(gen) Gender youngest child"
label define gyounhestl 1 "boy" 2 "girl" 3 "two youngest kids"
label values dm_gkyoungest gyounhestl
drop howmanyyoungest* which_kid* dm_gk*H dm_gk*W numkids* 
order nohouse_encr year nomem_encr* dm_age* dm_nummems dm_numkids dm_mstatus dm_akyoungest dm_gkyoungest


/*******************************************************************************
Convert to long; match survey and time use data
*******************************************************************************/

*	LISS 2013 dataset now contains all those households that satisfy our  
*	baseline selection criteria. 
keep nohouse_encr year nomem_encr* dm_age* dm_educ* h* wH wW

*	The LISS time diary was conducted end of 2012 and (mostly) beginning of
*	2013. However some subjects may be matchable to the 2012 selected data,
*	rather the 2013. Here we bring in and append the 2012 data.
tempfile liss2013
save `liss2013'
use "$DATAdir/selected_wchildren_allworknonwork_$today.dta", clear
keep if year==2012

*	Append 2013 data:
append using `liss2013'
keep nohouse_encr year nomem_encr* dm_age* dm_educ* hH hW wH wW

*	We now convert to long, keeping track of the gender of the person, in order 
*	to match with time diary data.
rename nomem_encrH nomem_encr1
rename nomem_encrW nomem_encr2
rename dm_ageH dm_age1
rename dm_ageW dm_age2
rename dm_educH dm_educ1
rename dm_educW dm_educ2
rename hH h1 
rename hW h2 
rename wH w1
rename wW w2

*	Reshape to long, generate household member gender variable:
reshape long nomem_encr dm_age dm_educ h w, i(nohouse_encr year) j(gender)

*	Given that we have two years of data, some individuals may appear twice in
*	the master data. However, they appear only once in the time use data, so
*	we only keep one copy of each individual in here:
sort nomem_encr year
by nomem_encr : egen maxyear = max(year)
keep if year==maxyear
drop maxyear

*	Match with processed LISS time diary:
merge 1:1 nomem_encr using `LISStimediary'
keep if _merge==3
drop _merge

*	No matched indivdiual has time use data on 3rd day; drop 3rd day:
sum *3
drop *3

*	Generate total hours day 1 and day 2; drop if either is under 1400 (a day 
*	has 1440 minutes):
#delimit; 
egen daytotal_1 = rowtotal( Sleep_total1 Eat_total1 Personal_total1 Work_total1 
							Study_total1 Chores_total1 Shopping_total1 Care_total1 
							Leisure_total1 Travel_total1 LISS_total1 ) ;
egen daytotal_2 = rowtotal( Sleep_total2 Eat_total2 Personal_total2 Work_total2
							Study_total2 Chores_total2 Shopping_total2 Care_total2 
							Leisure_total2 Travel_total2 LISS_total2 ) ;
#delimit cr
drop if daytotal_1 < 1400 | daytotal_2 < 1400


/*******************************************************************************
Obtain limited summary statistics from LISS time diary
*******************************************************************************/

*	We summarize market work hours on day 1 & 2. There are no people reporting
*	work on day 2 so, consistent with the survey design, we infer that day 2
*	is a "weekend" day. 
sum Work_total*

*	We convert the work, leisure, and childcare variables to weekly amounts by
*	multiplying work by 5, while leisure/childcare by 5 during workdays and by
*	2 during weekends, then adding up. We divide by 60 to convert to hours:
gen Work_total_weekly 		= 5*(Work_total1/60)
gen Leisure_total_weekly 	= 5*(Leisure_total1/60) + 2*(Leisure_total2/60)
gen Leisure_partner_weekly 	= 5*(Leisure_partner1/60) + 2*(Leisure_partner2/60)
gen Childcare_total_weekly 	= 5*(Childcare_total1/60) + 2*(Childcare_total2/60)
gen Childcare_partner_weekly= 5*(Childcare_partner1/60) + 2*(Childcare_partner2/60)
drop Leisure_total1 Leisure_total2 Leisure_partner1 Leisure_partner2

*	We observe hours of market work from Core Module 6. Here we calculate the 
*	ratio of those hours to the market hours people report in the LISS time use
*	to see how far off they are. To calculate any meaningful summary stats,
*	we need to focus on those who report similar numbers in both measures.
scatter h Work_total_weekly
cap : window manage close graph
gen hours_ratio = Work_total_weekly / h
sum hours_ratio

*	We want to calculate summary statistics for leisure and childcare. We 
*	calculate those unconditionally, but also conditionally on the work hours 
*	in LISS time use being not too far off from work hours in Core Module 6. 
*	The idea behind the latter is that a discrepancy between the work measures
*	indicates that the time period when the Core Module is collected differs
*	fundamentally from the time period the LISS time use reflects, so we can't
*	easily compare the two.
sum Leisure_total_weekly
local avg_Leisure_total_weekly = r(mean)
sum Leisure_partner_weekly
local avg_Leisure_partner_weekly = r(mean)
di `avg_Leisure_partner_weekly'/`avg_Leisure_total_weekly'

sum Childcare_total_weekly
local avg_Childcare_total_weekly = r(mean)
sum Childcare_partner_weekly
local avg_Childcare_partner_weekly = r(mean)
di `avg_Childcare_partner_weekly'/`avg_Childcare_total_weekly'

sum Leisure_total_weekly if hours_ratio>0.5 & hours_ratio<1.5
local avg_Leisure_total_weekly = r(mean)
sum Leisure_partner_weekly if hours_ratio>0.5 & hours_ratio<1.5
local avg_Leisure_partner_weekly = r(mean)
di `avg_Leisure_partner_weekly'/`avg_Leisure_total_weekly'

sum Childcare_total_weekly if hours_ratio>0.5 & hours_ratio<1.5
local avg_Childcare_total_weekly = r(mean)
sum Childcare_partner_weekly if hours_ratio>0.5 & hours_ratio<1.5
local avg_Childcare_partner_weekly = r(mean)
di `avg_Childcare_partner_weekly'/`avg_Childcare_total_weekly'

*** end of do file ***
