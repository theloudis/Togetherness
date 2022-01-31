
/*******************************************************************************
	
	This code exports the data in appropriate form for the RP analysis after 
	importing annual price levels from Statistics Netherlands.
	It treats the sample of families with children separately from the sample 
	of childless families. For each of these samples, the code:
	- generates homogeneous groups of households separately for families with 
	  children and families without.
	- generates homogeneous groups of households separately for couples that 
	  are assortatively matched and those who are not.
	- generates indicator variables for which regime the household belongs 
	  w.r.t. the overlap of spouses' regular and irregular hours. 
	- appends families with children and childless families.
	- exports spreadsheet that contains all the data: 'children' indicates 
	  whether this is a sample with or without children, 'amatching' indicates
	  the assortative matching status of the sample.
	- exports a spreadsheet that counts the size of each group in each file. 
	____________________________________________________________________________

	Filename: 	CTV_07_Export.do
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
Obtain CPI
*******************************************************************************/

*	Import CPI data and standardize:
*	Note: These data are downloaded from Statistics Netherlands; the download 
*	link is https://opendata.cbs.nl/statline/portal.html?_la=en&_catalog=CBS&tableId=70936eng&_theme=1046
clear
import delimited "$DATAdir/Dutch_CPI_March2019.csv", delimiter(";") 
keep periods annualrateofchangederived_2
keep if periods=="2009JJ00" | periods=="2010JJ00" | periods=="2011JJ00" | periods=="2012JJ00"
gen year = 2009 if periods=="2009JJ00"
replace year = 2010 if periods=="2010JJ00"
replace year = 2011 if periods=="2011JJ00"
replace year = 2012 if periods=="2012JJ00"
rename annualrateofchangederived_2 inflation
drop periods

*	Calculate price levels over years:
gen cpi = 100 if year==2009
replace cpi = cpi[_n-1]*(1+inflation/100) if year>2009

*	Recast to base year 2012 and save:
gen base_2012 = cpi if year==2012
egen base = total(base_2012)
replace cpi = cpi/base
keep year cpi
save "$DATAdir/cpi_$today.dta", replace


/*******************************************************************************
Tabulate number of children among childfull and childless households
*******************************************************************************/

*	Load data - append data on childless:
use "$DATAdir/selected_wchildren_$today.dta", clear
append using "$DATAdir/selected_nochildren_$today.dta"

*	Tabulate number of children and export table:
replace dm_numkids = 0 if dm_numkids==.
estpost tabulate dm_numkids
#delimit;
esttab . /*using $EXPORTSdir/children_number_$today.csv*/, replace 
	cells("b pct(fmt(2)) cumpct(fmt(2))") noobs ;
#delimit cr


/*******************************************************************************
Tabulate occupational and educational assortative mating among childful
*******************************************************************************/

*	Load data:
use "$DATAdir/selected_wchildren_$today.dta", clear

*	Tabulate assortative mating indicators and export:
estpost tabulate assort*
#delimit;
esttab . /*using $EXPORTSdir/assortative_patterns_$today.csv*/, replace 	
		cell(b) unstack noobs eqlabels(, lhs("assort_sector"))  
		mtitle(`e(colvar)') nonum ;
#delimit cr


/*******************************************************************************
********************************************************************************
Homogenous groups of families with children
********************************************************************************
*******************************************************************************/

*	Load data:
use "$DATAdir/selected_wchildren_$today.dta", clear

*	Merge with CPI data:
merge m:1 year using "$DATAdir/cpi_$today.dta"
drop if _merge!=3
drop _merge

*	We generate indicator variables to define group membership. We generate 36 
*	equisized groups defined by the following variables:
*	-1: calendar year:
gen year_cell = .							/* defines year cell */
replace	year_cell = 1 if year==2009			/* year 2009 */
replace year_cell = 2 if year==2010			/* year 2010 */
replace year_cell = 3 if year==2012 		/* year 2012 */
*	-2: age of youngest child:
gen agek_cell = .							/* defines age cell	 */
qui egen p50 = pctile(dm_akyoungest), p(50)
replace agek_cell = 1 if dm_akyoungest<p50	/* ages 0-5  */
replace agek_cell = 2 if agek_cell==.		/* ages 6-12 */
drop p50
*	-3: parental age:
*	Note: we generate a joint age variable by multiplying the spouses' 
*	respective ages.
gen age_cell = .							/* defines age cell			*/
gen age = dm_ageH*dm_ageW
*	-4: parental education:
*	Note: we generate a joint education variable by multiplying the spouses' 
*	respective educations.
gen educ_cell = .							/* defines education cell	*/
gen education = educH_cont*educW_cont

*	Make group assignemnts defined by the tertiles of the distributions of the 
*	spouses' age (product) and the median of their joint education:
forv i = 1/3 {
	forv j = 1/2 {
		*assign age cell:
		qui egen p33 = pctile(age) if year_cell==`i' & agek_cell==`j', p(33)
		qui egen p67 = pctile(age) if year_cell==`i' & agek_cell==`j', p(67)
		replace age_cell = 1 if year_cell==`i' & agek_cell==`j' & age<p33
		replace age_cell = 2 if year_cell==`i' & agek_cell==`j' & age>=p33 & age<=p67
		replace age_cell = 3 if year_cell==`i' & agek_cell==`j' & age_cell==.
		drop p33 p67
		forv a = 1/3 {
			*assign education cell:
			qui sum education if year_cell==`i' & agek_cell==`j' & age_cell==`a', de
			replace educ_cell = 1 if year_cell==`i' & agek_cell==`j' & age_cell==`a' & education>=r(p50)
			replace educ_cell = 2 if year_cell==`i' & agek_cell==`j' & age_cell==`a' & educ_cell==.
		}
	}
}
*	Summarize assignment cutoffs to report in section IV.A of the paper:
qui egen p33 = pctile(age), p(33)
qui egen p67 = pctile(age), p(67)
qui gen p33_spouse = p33 / dm_ageH
qui gen p67_spouse = p67 / dm_ageH
sum p33_spouse p67_spouse
qui sum education, de
local education_med = r(p50)
qui sum educH_cont, de
local educH_med = r(p50)
di `education_med'/`educH_med'
*label list OPLMET
drop p33* p67* age education

*	Define group identifier and children variable and save:
egen group = group(year_cell agek_cell age_cell educ_cell)
gen children  = 100
gen amatching = 0
sort group

*	Assign households to regimes w.r.t. second togetherness constraint:
*	Note: we repeat four times for all mutual combinations of 1) baseline 
*	regular/irregular hours, 2) hours that account for commuting, and 3/4) 
*	the two measures of irregular work:
gen 	regime = 2 if (hH_R>hW_R) & (hH_I<hW_I)
replace regime = 3 if (hH_R<hW_R) & (hH_I>hW_I)
replace regime = 1 if regime==.
gen 	regime_commu = 2 if (hH_commu_R>hW_commu_R) & (hH_commu_I<hW_commu_I)
replace regime_commu = 3 if (hH_commu_R<hW_commu_R) & (hH_commu_I>hW_commu_I)
replace regime_commu = 1 if regime_commu==.
gen 	regime2 = 2 if (hH_R2>hW_R2) & (hH_I2<hW_I2)
replace regime2 = 3 if (hH_R2<hW_R2) & (hH_I2>hW_I2)
replace regime2 = 1 if regime2==.
gen 	regime_commu2 = 2 if (hH_commu_R2>hW_commu_R2) & (hH_commu_I2<hW_commu_I2)
replace regime_commu2 = 3 if (hH_commu_R2<hW_commu_R2) & (hH_commu_I2>hW_commu_I2)
replace regime_commu2 = 1 if regime_commu2==.

*	Temporarily save:
tempfile Export_wchildren
qui save `Export_wchildren'


/*******************************************************************************
********************************************************************************
Homogenous groups of families with children when
spousal time budgets add up to between 164 & 172 hours
Groups by: calendar year, youngest child's age, parental education
********************************************************************************
*******************************************************************************/


* 	Load data:
use "$DATAdir/selected_wchildren_$today.dta", clear
*	Merge with CPI data:
merge m:1 year using "$DATAdir/cpi_$today.dta"
drop if _merge!=3
drop _merge

*	Keep families for whom both spouse's weekly time budgets add up to
*	between 164 and 172 hours:
keep if TimeH>=164 & TimeH<=172 & TimeW>=164 & TimeW<=172

*	We generate indicator variables to define group membership. We generate 12 
*	equisized groups defined by the following variables:
*	-1: calendar year:
gen year_cell = .							/* defines year cell */
replace	year_cell = 1 if year==2009			/* year 2009 */
replace year_cell = 2 if year==2010			/* year 2010 */
replace year_cell = 3 if year==2012 		/* year 2012 */
*	-2: age of youngest child:
gen agek_cell = .							/* defines age cell	 */
qui egen p50 = pctile(dm_akyoungest), p(50)
replace agek_cell = 1 if dm_akyoungest<p50	/* ages 0-5  */
replace agek_cell = 2 if agek_cell==.		/* ages 6-12 */
drop p50
*	-3: parental education:
*	Note: we generate a joint education variable by multiplying the spouses' 
*	respective educations.
gen educ_cell = .							/* defines education cell	*/
gen education = educH_cont*educW_cont

*	Make group assignemnts defined by the tertiles of the distributions of the 
*	spouses' median of their joint education:
forv i = 1/3 {
	forv j = 1/2 {
		*assign education cell:
		qui sum education if year_cell==`i' & agek_cell==`j', de
		replace educ_cell = 1 if year_cell==`i' & agek_cell==`j' & education>=r(p50)
		replace educ_cell = 2 if year_cell==`i' & agek_cell==`j' & educ_cell==.
	}
}

*	Define group identifier and children variable and save:
egen group = group(year_cell agek_cell educ_cell)
gen children  = 101
gen amatching = 0
sort group

*	Assign households to regimes w.r.t. second togetherness constraint:
*	Note: we repeat four times for all mutual combinations of 1) baseline 
*	regular/irregular hours, 2) hours that account for commuting, and 3/4) 
*	the two measures of irregular work:
gen 	regime = 2 if (hH_R>hW_R) & (hH_I<hW_I)
replace regime = 3 if (hH_R<hW_R) & (hH_I>hW_I)
replace regime = 1 if regime==.
gen 	regime_commu = 2 if (hH_commu_R>hW_commu_R) & (hH_commu_I<hW_commu_I)
replace regime_commu = 3 if (hH_commu_R<hW_commu_R) & (hH_commu_I>hW_commu_I)
replace regime_commu = 1 if regime_commu==.
gen 	regime2 = 2 if (hH_R2>hW_R2) & (hH_I2<hW_I2)
replace regime2 = 3 if (hH_R2<hW_R2) & (hH_I2>hW_I2)
replace regime2 = 1 if regime2==.
gen 	regime_commu2 = 2 if (hH_commu_R2>hW_commu_R2) & (hH_commu_I2<hW_commu_I2)
replace regime_commu2 = 3 if (hH_commu_R2<hW_commu_R2) & (hH_commu_I2>hW_commu_I2)
replace regime_commu2 = 1 if regime_commu2==.

*	Temporarily save:
tempfile Export_wchildren_101
qui save `Export_wchildren_101'


/*******************************************************************************
********************************************************************************
Homogenous groups of families with 1 or 2 children only
Groups by: calendar year, youngest child's age, parental age
********************************************************************************
*******************************************************************************/

*	Load data:
use "$DATAdir/selected_wchildren_$today.dta", clear

*	Merge with CPI data:
merge m:1 year using "$DATAdir/cpi_$today.dta"
drop if _merge!=3
drop _merge

*	Keep families with 1 or 2 children only:
keep if dm_numkids<=2

*	We generate indicator variables to define group membership. We generate 18 
*	equisized groups defined by the following variables:
*	-1: calendar year:
gen year_cell = .							/* defines year cell */
replace	year_cell = 1 if year==2009			/* year 2009 */
replace year_cell = 2 if year==2010			/* year 2010 */
replace year_cell = 3 if year==2012 		/* year 2012 */
*	-2: age of youngest child:
gen agek_cell = .							/* defines age cell	 */
qui egen p50 = pctile(dm_akyoungest), p(50)
replace agek_cell = 1 if dm_akyoungest<p50	/* ages 0-5  */
replace agek_cell = 2 if agek_cell==.		/* ages 6-12 */
drop p50
*	-3: parental age:
*	Note: we generate a joint age variable by multiplying the spouses' 
*	respective ages.
gen age_cell = .							/* defines age cell			*/
gen age = dm_ageH*dm_ageW

*	Make group assignemnts defined by the tertiles of the distributions of the 
*	spouses' age (product):
forv i = 1/3 {
	forv j = 1/2 {
		*assign age cell:
		qui egen p33 = pctile(age) if year_cell==`i' & agek_cell==`j', p(33)
		qui egen p67 = pctile(age) if year_cell==`i' & agek_cell==`j', p(67)
		replace age_cell = 1 if year_cell==`i' & agek_cell==`j' & age<p33
		replace age_cell = 2 if year_cell==`i' & agek_cell==`j' & age>=p33 & age<=p67
		replace age_cell = 3 if year_cell==`i' & agek_cell==`j' & age_cell==.
		drop p33 p67
	}
}

*	Define group identifier and children variable and save:
egen group = group(year_cell agek_cell age_cell)
gen children  = 1
gen amatching = 0
sort group

*	Assign households to regimes w.r.t. second togetherness constraint:
*	Note: we repeat four times for all mutual combinations of 1) baseline 
*	regular/irregular hours, 2) hours that account for commuting, and 3/4) 
*	the two measures of irregular work:
gen 	regime = 2 if (hH_R>hW_R) & (hH_I<hW_I)
replace regime = 3 if (hH_R<hW_R) & (hH_I>hW_I)
replace regime = 1 if regime==.
gen 	regime_commu = 2 if (hH_commu_R>hW_commu_R) & (hH_commu_I<hW_commu_I)
replace regime_commu = 3 if (hH_commu_R<hW_commu_R) & (hH_commu_I>hW_commu_I)
replace regime_commu = 1 if regime_commu==.
gen 	regime2 = 2 if (hH_R2>hW_R2) & (hH_I2<hW_I2)
replace regime2 = 3 if (hH_R2<hW_R2) & (hH_I2>hW_I2)
replace regime2 = 1 if regime2==.
gen 	regime_commu2 = 2 if (hH_commu_R2>hW_commu_R2) & (hH_commu_I2<hW_commu_I2)
replace regime_commu2 = 3 if (hH_commu_R2<hW_commu_R2) & (hH_commu_I2>hW_commu_I2)
replace regime_commu2 = 1 if regime_commu2==.

*	Temporarily save:
tempfile Export_wchildren_1
qui save `Export_wchildren_1'


/*******************************************************************************
********************************************************************************
Homogenous groups of families with 3+ children
Groups by: calendar year, youngest child's age, parental age
********************************************************************************
*******************************************************************************/

*	Load data:
use "$DATAdir/selected_wchildren_$today.dta", clear

*	Merge with CPI data:
merge m:1 year using "$DATAdir/cpi_$today.dta"
drop if _merge!=3
drop _merge

*	Keep families with 3+ children:
keep if dm_numkids>2

*	We generate indicator variables to define group membership. We generate 18 
*	equisized groups defined by the following variables:
*	-1: calendar year:
gen year_cell = .							/* defines year cell */
replace	year_cell = 1 if year==2009			/* year 2009 */
replace year_cell = 2 if year==2010			/* year 2010 */
replace year_cell = 3 if year==2012 		/* year 2012 */
*	-2: age of youngest child:
gen agek_cell = .							/* defines age cell	 */
qui egen p50 = pctile(dm_akyoungest), p(50)
replace agek_cell = 1 if dm_akyoungest<p50	/* ages 0-5  */
replace agek_cell = 2 if agek_cell==.		/* ages 6-12 */
drop p50
*	-3: parental age:
*	Note: we generate a joint age variable by multiplying the spouses' 
*	respective ages.
gen age_cell = .							/* defines age cell			*/
gen age = dm_ageH*dm_ageW

*	Make group assignemnts defined by the tertiles of the distributions of the 
*	spouses' age (product):
forv i = 1/3 {
	forv j = 1/2 {
		*assign age cell:
		qui egen p33 = pctile(age) if year_cell==`i' & agek_cell==`j', p(33)
		qui egen p67 = pctile(age) if year_cell==`i' & agek_cell==`j', p(67)
		replace age_cell = 1 if year_cell==`i' & agek_cell==`j' & age<p33
		replace age_cell = 2 if year_cell==`i' & agek_cell==`j' & age>=p33 & age<=p67
		replace age_cell = 3 if year_cell==`i' & agek_cell==`j' & age_cell==.
		drop p33 p67
	}
}

*	Define group identifier and children variable and save:
egen group = group(year_cell agek_cell age_cell)
gen children  = 11
gen amatching = 0
sort group

*	Assign households to regimes w.r.t. second togetherness constraint:
*	Note: we repeat four times for all mutual combinations of 1) baseline 
*	regular/irregular hours, 2) hours that account for commuting, and 3/4) 
*	the two measures of irregular work:
gen 	regime = 2 if (hH_R>hW_R) & (hH_I<hW_I)
replace regime = 3 if (hH_R<hW_R) & (hH_I>hW_I)
replace regime = 1 if regime==.
gen 	regime_commu = 2 if (hH_commu_R>hW_commu_R) & (hH_commu_I<hW_commu_I)
replace regime_commu = 3 if (hH_commu_R<hW_commu_R) & (hH_commu_I>hW_commu_I)
replace regime_commu = 1 if regime_commu==.
gen 	regime2 = 2 if (hH_R2>hW_R2) & (hH_I2<hW_I2)
replace regime2 = 3 if (hH_R2<hW_R2) & (hH_I2>hW_I2)
replace regime2 = 1 if regime2==.
gen 	regime_commu2 = 2 if (hH_commu_R2>hW_commu_R2) & (hH_commu_I2<hW_commu_I2)
replace regime_commu2 = 3 if (hH_commu_R2<hW_commu_R2) & (hH_commu_I2>hW_commu_I2)
replace regime_commu2 = 1 if regime_commu2==.

*	Temporarily save:
tempfile Export_wchildren_11
qui save `Export_wchildren_11'


/*******************************************************************************
********************************************************************************
Homogenous groups of childless families
********************************************************************************
*******************************************************************************/

*	Load data:
use "$DATAdir/selected_nochildren_$today.dta", clear

*	Merge with CPI data:
merge m:1 year using "$DATAdir/cpi_$today.dta"
drop if _merge!=3
drop _merge

*	We generate indicator variables to define group membership. We generate 24 
*	equisized groups defined by the following variables:
*	-1: calendar year:
gen year_cell = .							/* defines year cell */
replace	year_cell = 1 if year==2009			/* year 2009 */
replace year_cell = 2 if year==2010			/* year 2010 */
replace year_cell = 3 if year==2012 		/* year 2012 */
*	-2: spousal age:
*	Note: we generate a joint age variable by multiplying the spouses' 
*	respective ages.
gen age_cell = .							/* defines age cell			*/
gen age = dm_ageH*dm_ageW
*	-3: parental education:
*	Note: we generate a joint education variable by multiplying the spouses' 
*	respective educations.
gen educ_cell = .							/* defines education cell	*/
gen education = educH_cont*educW_cont

*	Make group assignments defined by the distributions of spousal age and
* 	joint education:
forv i = 1/4 {
	*assign age cell:
	qui egen p25 = pctile(age) if year_cell==`i', p(25)
	qui egen p50 = pctile(age) if year_cell==`i', p(50)
	qui egen p75 = pctile(age) if year_cell==`i', p(75)
	replace age_cell = 1 if year_cell==`i' & age<p25
	replace age_cell = 2 if year_cell==`i' & age>=p25 & age<p50
	replace age_cell = 3 if year_cell==`i' & age>=p50 & age<p75
	replace age_cell = 4 if year_cell==`i' & age_cell==.
	drop p25 p50 p75
	forv a = 1/4 {
		*assign education cell:
		qui sum education if year_cell==`i' & age_cell==`a', de
		replace educ_cell = 1 if year_cell==`i' & age_cell==`a' & education<r(p50)
		replace educ_cell = 2 if year_cell==`i' & age_cell==`a' & educ_cell==.
	}
}
drop age education

*	Define group identifier and children variable:
egen group = group(year_cell age_cell educ_cell)
replace group = -group	/* to distinguish from groups of families with children*/
gen children  = 0
gen amatching = 0
sort group

*	Assign households to regimes w.r.t. second togetherness constraint:
*	Note: we repeat four times for all mutual combinations of 1) baseline 
*	regular/irregular hours, 2) hours that account for commuting, and 3/4) 
*	the two measures of irregular work:
gen 	regime = 2 if (hH_R>hW_R) & (hH_I<hW_I)
replace regime = 3 if (hH_R<hW_R) & (hH_I>hW_I)
replace regime = 1 if regime==.
gen 	regime_commu = 2 if (hH_commu_R>hW_commu_R) & (hH_commu_I<hW_commu_I)
replace regime_commu = 3 if (hH_commu_R<hW_commu_R) & (hH_commu_I>hW_commu_I)
replace regime_commu = 1 if regime_commu==.
gen 	regime2 = 2 if (hH_R2>hW_R2) & (hH_I2<hW_I2)
replace regime2 = 3 if (hH_R2<hW_R2) & (hH_I2>hW_I2)
replace regime2 = 1 if regime2==.
gen 	regime_commu2 = 2 if (hH_commu_R2>hW_commu_R2) & (hH_commu_I2<hW_commu_I2)
replace regime_commu2 = 3 if (hH_commu_R2<hW_commu_R2) & (hH_commu_I2>hW_commu_I2)
replace regime_commu2 = 1 if regime_commu2==.

*	Temporarily save:
tempfile Export_nochildren
qui save `Export_nochildren'


/*******************************************************************************
********************************************************************************
Homogenous groups of families with children; POSITIVE matching on education
Groups by: calendar year, youngest child's age, parental age 
********************************************************************************
*******************************************************************************/

*	Load data:
use "$DATAdir/selected_wchildren_$today.dta", clear

*	Merge with CPI data:
merge m:1 year using "$DATAdir/cpi_$today.dta"
drop if _merge!=3
drop _merge

*	Keep households in which both spouses have same education level:
keep if  assort_education==1 	/* positively matched on education */

*	We generate indicator variables to define group membership. We generate 18 
*	equisized groups defined by the following variables:
*	-1: calendar year:
gen year_cell = .							/* defines year cell */
replace	year_cell = 1 if year==2009			/* year 2009 */
replace year_cell = 2 if year==2010			/* year 2010 */
replace year_cell = 3 if year==2012 		/* year 2012 */
*	-2: age of youngest child:
gen agek_cell = .							/* defines age cell	 */
qui egen p50 = pctile(dm_akyoungest), p(50)
replace agek_cell = 1 if dm_akyoungest<p50	/* ages 0-5  */
replace agek_cell = 2 if agek_cell==.		/* ages 6-12 */
drop p50
*	-3: parental age:
*	Note: we generate a joint age variable by multiplying the spouses' 
*	respective ages.
gen age_cell = .							/* defines age cell			*/
gen age = dm_ageH*dm_ageW

*	Make group assignemnts defined by the tertiles of the distributions of the 
*	spouses' age (product):
forv i = 1/3 {
	forv j = 1/2 {
		*assign age cell:
		qui egen p33 = pctile(age) if year_cell==`i' & agek_cell==`j', p(33)
		qui egen p67 = pctile(age) if year_cell==`i' & agek_cell==`j', p(67)
		replace age_cell = 1 if year_cell==`i' & agek_cell==`j' & age<p33
		replace age_cell = 2 if year_cell==`i' & agek_cell==`j' & age>=p33 & age<=p67
		replace age_cell = 3 if year_cell==`i' & agek_cell==`j' & age_cell==.
		drop p33 p67
	}
}

*	Define group identifier and children variable and save:
egen group = group(year_cell agek_cell age_cell)
gen children  = 100
gen amatching = 1
sort group

*	Assign households to regimes w.r.t. second togetherness constraint:
*	Note: we repeat four times for all mutual combinations of 1) baseline 
*	regular/irregular hours, 2) hours that account for commuting, and 3/4) 
*	the two measures of irregular work:
gen 	regime = 2 if (hH_R>hW_R) & (hH_I<hW_I)
replace regime = 3 if (hH_R<hW_R) & (hH_I>hW_I)
replace regime = 1 if regime==.
gen 	regime_commu = 2 if (hH_commu_R>hW_commu_R) & (hH_commu_I<hW_commu_I)
replace regime_commu = 3 if (hH_commu_R<hW_commu_R) & (hH_commu_I>hW_commu_I)
replace regime_commu = 1 if regime_commu==.
gen 	regime2 = 2 if (hH_R2>hW_R2) & (hH_I2<hW_I2)
replace regime2 = 3 if (hH_R2<hW_R2) & (hH_I2>hW_I2)
replace regime2 = 1 if regime2==.
gen 	regime_commu2 = 2 if (hH_commu_R2>hW_commu_R2) & (hH_commu_I2<hW_commu_I2)
replace regime_commu2 = 3 if (hH_commu_R2<hW_commu_R2) & (hH_commu_I2>hW_commu_I2)
replace regime_commu2 = 1 if regime_commu2==.

*	Temporarily save:
tempfile Export_assort_plus1
qui save `Export_assort_plus1'


/*******************************************************************************
********************************************************************************
Homogenous groups of families with children; NEGATIVE matching on education
Groups by: calendar year, youngest child's age, parental age 
********************************************************************************
*******************************************************************************/

*	Load data:
use "$DATAdir/selected_wchildren_$today.dta", clear

*	Merge with CPI data:
merge m:1 year using "$DATAdir/cpi_$today.dta"
drop if _merge!=3
drop _merge

*	Keep households in which the spouses have different education levels:
keep if  assort_education==0 	/* negatively matched on education */

*	We generate indicator variables to define group membership. We generate 18 
*	equisized groups defined by the following variables:
*	-1: calendar year:
gen year_cell = .							/* defines year cell */
replace	year_cell = 1 if year==2009			/* year 2009 */
replace year_cell = 2 if year==2010			/* year 2010 */
replace year_cell = 3 if year==2012 		/* year 2012 */
*	-2: age of youngest child:
gen agek_cell = .							/* defines age cell	 */
qui egen p50 = pctile(dm_akyoungest), p(50)
replace agek_cell = 1 if dm_akyoungest<p50	/* ages 0-5  */
replace agek_cell = 2 if agek_cell==.		/* ages 6-12 */
drop p50
*	-3: parental age:
*	Note: we generate a joint age variable by multiplying the spouses' 
*	respective ages.
gen age_cell = .							/* defines age cell			*/
gen age = dm_ageH*dm_ageW

*	Make group assignemnts defined by the tertiles of the distributions of the 
*	spouses' age (product):
forv i = 1/3 {
	forv j = 1/2 {
		*assign age cell:
		qui egen p33 = pctile(age) if year_cell==`i' & agek_cell==`j', p(33)
		qui egen p67 = pctile(age) if year_cell==`i' & agek_cell==`j', p(67)
		replace age_cell = 1 if year_cell==`i' & agek_cell==`j' & age<p33
		replace age_cell = 2 if year_cell==`i' & agek_cell==`j' & age>=p33 & age<=p67
		replace age_cell = 3 if year_cell==`i' & agek_cell==`j' & age_cell==.
		drop p33 p67
	}
}

*	Define group identifier and children variable and save:
egen group = group(year_cell agek_cell age_cell)
gen children  = 100
gen amatching = -1
sort group

*	Assign households to regimes w.r.t. second togetherness constraint:
*	Note: we repeat four times for all mutual combinations of 1) baseline 
*	regular/irregular hours, 2) hours that account for commuting, and 3/4) 
*	the two measures of irregular work:
gen 	regime = 2 if (hH_R>hW_R) & (hH_I<hW_I)
replace regime = 3 if (hH_R<hW_R) & (hH_I>hW_I)
replace regime = 1 if regime==.
gen 	regime_commu = 2 if (hH_commu_R>hW_commu_R) & (hH_commu_I<hW_commu_I)
replace regime_commu = 3 if (hH_commu_R<hW_commu_R) & (hH_commu_I>hW_commu_I)
replace regime_commu = 1 if regime_commu==.
gen 	regime2 = 2 if (hH_R2>hW_R2) & (hH_I2<hW_I2)
replace regime2 = 3 if (hH_R2<hW_R2) & (hH_I2>hW_I2)
replace regime2 = 1 if regime2==.
gen 	regime_commu2 = 2 if (hH_commu_R2>hW_commu_R2) & (hH_commu_I2<hW_commu_I2)
replace regime_commu2 = 3 if (hH_commu_R2<hW_commu_R2) & (hH_commu_I2>hW_commu_I2)
replace regime_commu2 = 1 if regime_commu2==.

*	Temporarily save:
tempfile Export_assort_minus1
qui save `Export_assort_minus1.dta'


/*******************************************************************************
Export all data in one file
*******************************************************************************/

*	Append different data versions into one file:
*	-baseline file with children:
use `Export_wchildren', clear
*	-families for whom weekly time budgets add up to between 164-172:
qui append using `Export_wchildren_101'
*	-families with 1-2 children only:
qui append using `Export_wchildren_1'
*	-families with 3+ children:
qui append using `Export_wchildren_11'
*	-families without children:
qui append using `Export_nochildren'
*	-families positively matched on education:
qui append using `Export_assort_plus1'
*	-families negatively matched on education and/or occupational sector:
qui append using `Export_assort_minus1'

*	Order variables:
#delimit;
order 	children amatching group regime* 
		wH* wW* 
		hH hH_commu 
		hH_R  hH_I  hH_commu_R  hH_commu_I 
		hH_R2 hH_I2 hH_commu_R2 hH_commu_I2 
		hW hW_commu
		hW_R  hW_I  hW_commu_R  hW_commu_I 
		hW_R2 hW_I2 hW_commu_R2 hW_commu_I2 
		lH lW Lp Cp Ck TH TW Tk* educH_cont educW_cont
		gap* ChoresH AdminH div_* ;
#delimit cr

*	Export data in excel:
preserve
keep group children amatching year cpi regime* hH* hW* wH* wW* Cp Tk* Lp lH lW Ck TH TW gap* div_* ChoresH AdminH educH_cont educW_cont
label drop _all
recast float *
*	-export, sort in a stable way to that results for predictive success do not 
*	 change when when replicating the exercice (predictive success applies 
*	 random numbers for budget share sequentially on our households; their 
* 	 sorting should be the same across replications; this does not make any 
* 	 difference in economic sense but small unimportant differences in some 
*	 numbers may arise if the sorting is not stable)
sort children amatching group wW wH lH lW, stable
*export excel using "$DATAdir/dataexport_$today", firstrow(variables) replace
export delimited using "$DATAdir/dataexport_$today", replace
restore

*	Export data/group sample sizes:
preserve
collapse (count) wH, by(children amatching group)
rename wH numobs
qui egen min_numobs = min(numobs), by(children amatching)
qui egen max_numobs = max(numobs), by(children amatching)
export excel using "$DATAdir/groupsize_$today", firstrow(variables) replace
restore

*	Save single full file; erase unneeded files:
drop c_krespondentH c_krespondentW year_cell agek_cell age_cell educ_cell nomem_encrH nomem_encrW 
qui save "$DATAdir/final_data_$today.dta", replace

*** end of do file ***
