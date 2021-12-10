
/*******************************************************************************
	
	This code produces summary statistics and figures in our baseline estimating
	sample (children==100 & amatching==0). Specifically it produces or plots:
	- aggregate, average, and joint leisure (figure 1)
	- parents' childcare (figure 2)
	- parents' engagement in childcare activities (figure 3)
	- spouses' irregular work frequency (figure 4)
	- variation in incidence of irregular work, by education (figure 5) 
	- leisure & childcare descriptives table (table 1)
	- leisure & childcare regressions tables
	  with & without additional controls (tables 2, appendix tables A.1, A.2) 
	- other statistics reported in the text (e.g. average number of children)				 
	- summary statistics table (table 5) 
	- distribution of predictive success in various figures (figure 6)
	- distribution of value of togetherness (figure 7)
	- distribution of forgone earnings among men and women (figure 8)
	- sharing rule bounds (figure 9)
	- joint childcare bounds (appendix figure C.1)
	
	Attention:
	----------
	To seamlessly run this file, please first run the RP program on Matlab,
	Run_All.m, where a number of items called in the present script are created.
	____________________________________________________________________________

	Filename: 	CTV_10_Descriptives.do
	Author: 	Alexandros Theloudis (a.theloudis@gmail.com)
	Date: 		Autumn 2021
	Paper: 		Togetherness in the Household 
				Sam Cosaert and Alexandros Theloudis and Bertrand Verheyden

*******************************************************************************/

*	Initial statements:
clear
set more off
version 16.1

*	Use data, keep baseline sample with children:
use "$DATAdir/final_data_$today.dta", clear
keep if children==100 & amatching==0 


/*******************************************************************************
Figure joint leisure (section I, figure 1)
*******************************************************************************/

*	Generate total and average individual leisure:
gen Ltot = LH+LW
gen Lavg = (LH+LW)/2

*	Generate continuum of households and tag 10th and 90th pct household:
sort Ltot
gen hh_cont = (_n/_N)
egen tenth_hh = pctile(hh_cont), p(10)
egen ninety_hh = pctile(hh_cont), p(90)

*	Retrieve leisure of median, 10th and 90th household:
*	-aggregate total leisure:
gen median_Ltot = Ltot if hh_cont==0.5
gen tenth_Ltot = Ltot if hh_cont==tenth_hh
gen ninety_Ltot = Ltot if hh_cont==ninety_hh
*	-average leisure:
gen median_Lavg = Lavg if hh_cont==0.5
gen tenth_Lavg = Lavg if hh_cont==tenth_hh
gen ninety_Lavg = Lavg if hh_cont==ninety_hh
qui sum median_Ltot
local median_Ltot = r(mean)
qui sum tenth_Ltot
local tenth_Ltot = r(mean)
qui sum ninety_Ltot
local ninety_Ltot = r(mean)
*	-report numbers of average leisure:
drop tenth_hh ninety_hh
sum tenth* median* ninety*

*	Visualize total and average individual leisure, as well as public leisure:
#delimit;
twoway 	(area Ltot hh_cont, lcolor(gs10) lpattern(solid)) 
		(function y=0.5, horizontal range(0 `median_Ltot') 	lcolor(black) lpattern(dash) lwidth(medthick))
		(function y=0.1, horizontal range(0 `tenth_Ltot') 	lcolor(black) lpattern(dash) lwidth(medthick))
		(function y=0.9, horizontal range(0 `ninety_Ltot') 	lcolor(black) lpattern(dash) lwidth(medthick))
		(scatter Ltot hh_cont, msymbol(smcircle) mcolor(gs10) msize(medsmall))
		(scatter Lavg hh_cont, msymbol(circle_hollow) mcolor(black) msize(medium))
		(scatter Lp hh_cont, msymbol(plus) mcolor(red) msize(medium)), 
		ylabel(0(20)140) ytitle("hours per week")
		xlabel(none) xtitle("households, ordered from least to most average leisure")
		legend(	order(5 6 7 2)
				label(5 "Sum of spouses' leisures") 
				label(6 "Average of spouses' leisures") 
				label(7 "Joint leisure") 
				label(2 "10{sup:th}, median, 90{sup:th} household")
				rows(4) position(11) ring(0))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig1.pdf", as(pdf) replace
cap : window manage close graph
drop hh_cont tenth_* median_* ninety_*

*	Count and display the fraction of households for which public leisure is
*	strictly positive:
gen positive_lJ = Lp>0
sum positive_lJ
drop positive_lJ

*	Summarize joint leisure in detail:	
sum Lp, de


/*******************************************************************************
Figure childcare (section I, figure 2)
*******************************************************************************/

*	Regress male total childcare on female total childcare, get R squared:
qui regress TH TW
local beta: display %5.2f _b[TW]
local sebeta: display %5.2f _se[TW]

*	Visualize total individual childcare:
#delimit;
twoway 	(scatter TH TW, msymbol(circle_hollow) mcolor(black) msize(medium))
		(lfit TH TW, lcolor(red) lwidth(thick) lpattern(dash)), 
		ylabel(0(10)50) ytitle("fathers' childcare hours per week")
		xlabel(0(10)80) xtitle("mothers' childcare hours per week")
		legend(	order(1 2)
				label(1 "Parents' childcare") 
				label(2 "Linear fit, `=ustrunescape("\u03B2\u0302")'=`beta' (s.e.=`sebeta')")
				rows(2) position(11) ring(0))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig2.pdf", as(pdf) replace
cap : window manage close graph

*	Summary statistics for TH and TW:
sum TH TW, de

*	Count and display the fraction of mothers & fathers for which public 
*	leisure is strictly positive:
gen positive_TH = (TH>0 & TH!=.)
sum positive_TH
gen positive_TW = (TW>0 & TW!=.)
sum positive_TW
drop positive_TH positive_TW


/*******************************************************************************
Figure childcare engagement (section I, figure 3)
*******************************************************************************/

*	Obtain summary statistics of different categories:
qui sum div_playk
local ss = `r(N)'
forvalues v = 1/3 {
	qui count if div_playk == `v'
	qui gen mostly_`v'_1 = `r(N)'/`ss'
}
forvalues v = 1/3 {
	qui count if div_drivek == `v'
	qui gen mostly_`v'_2 = `r(N)'/`ss'
}
forvalues v = 1/3 {
	qui count if div_talkk == `v'
	qui gen mostly_`v'_3 = `r(N)'/`ss'
}
forvalues v = 1/3 {
	qui count if div_gooutk == `v'
	qui gen mostly_`v'_4 = `r(N)'/`ss'
}

*	Collapse data:
preserve
collapse (mean) mostly_*
gen dataset = 0
reshape long mostly_1_ mostly_2_ mostly_3_, i(dataset) j(errand)
rename mostly_1_ mostly_wife
rename mostly_2_ equally
rename mostly_3_ mostly_husband
qui replace mostly_wife 	= 100*mostly_wife
qui replace equally 		= 100*equally
qui replace mostly_husband 	= 100*mostly_husband

*	Create bar chart and export:
#delimit;
graph 	hbar (asis) equally mostly_wife mostly_husband, 
		over(errand, 
			 sort(equally) descending
			 relabel(1 `" "storyreading" "playing" "'
					 2 `" "accompany" "in activities" "'
					 3 `" "talking" "advising" "'
					 4 `" "small" "outings" "')) stack 
		bar(1, color(gs7) 	lpattern(dash_dot) lcolor(red)) 
		bar(2, color(gs10) 	lpattern(dot) lcolor(red)) 
		bar(3, color(gs13) 	lpattern(dash) lcolor(red)) 
		blabel(bar, position(center) format(%9.0f) color(black) size(medlarge))
		ytitle("percentage of households")
		legend(	label(1 "both parents equally") 
				label(2 "mostly mother") 
				label(3 "mostly father") 
				rows(1) position(6))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig3.pdf", as(pdf) replace
cap : window manage close graph
restore


/*******************************************************************************
Figure market work schedule (section I, figure 4)
*******************************************************************************/

*	Label:
*	Note: 'catplot' below interchanges the axis and axis labels. So while the
*	vertical axis plots the husband's category, it makes appear the label of
*	the wife's variable. Therefore I switch the axis labels below. 
label variable w_irregulchoW "husband works irregular hours"

*	Visualize timing of market work:
#delimit;
catplot w_irregulchoW, over(w_irregulchoH)
		stack asyvars percent
		subtitle(, pos(9) ring(1) bcolor(none) nobexpand place(e)) 
		ytitle("percentage of households") 
		bar(1, bcolor(gs12)) bar(2, bcolor(gs8)) bar(3, bcolor(gs3)) 
		legend(	order(1 2 3) rows(3) position(1) ring(0) subtitle("wife works" "irregular hours:", justification(left)))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig4.pdf", as(pdf) replace
cap : window manage close graph

*	Tabulate:
label variable w_irregulchoW "(6) Do you work irregular hours?"
tab w_irregulchoH, freq
tab w_irregulchoW, freq
tab w_irregulchoH w_irregulchoW, freq


/*******************************************************************************
Longitudinal variation in incidence of irregular work (section I, figure 5)
	- count observations per panel length
	- generate indicators for variation in incidence of irregular work
	- plot variation in incidence of irregular work (by education)
	- obtain probabilities of job/occupation change by irregular work variation
*******************************************************************************/

*	Count observations by panel length:
*	-length of panel:
sort nohouse_encr year 
by nohouse_encr : egen length = count(year)
*	-unique households:
preserve
collapse (count) nohouse_encr, by(length)
rename nohouse_encr total_obs
tempfile total_obs
save `total_obs'
restore
*	-number of observations:
preserve
collapse (mean) year length, by(nohouse_encr)
drop year
collapse (count) nohouse_encr, by(length)
rename nohouse_encr unique_hh
merge 1:1 length using `total_obs', nogen
insobs 1
qui sum unique_hh
replace unique_hh = r(sum) if length==.
qui sum total_obs
replace total_obs = r(sum) if length==.
*	-aesthetics:
gen 	slength = ""
replace slength = "observed once"	if length==1
replace slength = "observed twice" 	if length==2
replace slength = "observed thrice" if length==3
replace slength = "total" 			if length==.
drop length
order slength
*	-export as table:
*export excel using "$EXPORTSdir/Variation_irregular_work_$today.xlsx", firstrow(variables) replace
restore

* 	Measure variation in incidence of irregular work:
by nohouse_encr : egen sd_irregulchoH = sd(w_irregulchoH)
by nohouse_encr : egen sd_irregulchoW = sd(w_irregulchoW)
*	-indicator variable if incidence of irregular work varies over time;
*	-count how many observations (out of total sample size) are associated 
*	with households for whom irregular work incidence varies over time:
gen schedule_changeH = (sd_irregulchoH~=0 & sd_irregulchoH~=.)
gen schedule_changeW = (sd_irregulchoW~=0 & sd_irregulchoW~=.)
count if sd_irregulchoH~=0 & sd_irregulchoH~=.
local numobsH = r(N) 		/* number of observations */
count if sd_irregulchoW~=0 & sd_irregulchoW~=.
local numobsW = r(N) 		/* number of observations */

* 	Measure variation in job/occupation:
replace w_occupationH = -9 if w_occupationH==.
replace w_occupationW = -9 if w_occupationW==.
by nohouse_encr : egen sd_occupaH = sd(w_occupationH)
by nohouse_encr : egen sd_occupaW = sd(w_occupationW)
*	-indicator variable if job/occupation varies over time:
gen job_changeH = (sd_occupaH~=0 & sd_occupaH~=.)
gen job_changeW = (sd_occupaW~=0 & sd_occupaW~=.)

* 	Collapse data; new dataset is one observation per household; record 
*	education level of each spouse:
collapse (mean) length schedule_changeH schedule_changeW job_changeH job_changeW (max) maxedH = educH_cont maxedW = educW_cont, by(nohouse_encr)

*	Drop households that appear in the panel data only once; we can't use them
*	to measure variation in the incidence of irregular work:
drop if length==1

*	Estimate probability of job change by variation of irregular work:
preserve
collapse (mean) job_changeW, by(schedule_changeW)
rename schedule_changeW schedule_change
tempfile job_changeW
save `job_changeW'
restore	
preserve
collapse (mean) job_changeH, by(schedule_changeH)
rename schedule_changeH schedule_change
merge 1:1 schedule_change using `job_changeW', nogen
*	-export as table:
*export excel using "$EXPORTSdir/Variation_irregular_work_jobchange_$today.xlsx", sheet("baseline") firstrow(variables) replace
restore

*	Measure variation in incidence of irregular work, as well as number of
*	unique households that exhibit such variation:
*	-irregular work of men:
sum schedule_changeH
local meanH = round(100*r(mean),.1)
local numhouseholds = r(N)
count if schedule_changeH==1
local numhhH = r(N)
*	-irregular work of women:
sum schedule_changeW
local meanW = round(100*r(mean),.1)
count if schedule_changeW==1
local numhhW = r(N)
*	-irregular work of either men or women:
count if schedule_changeH==1 | schedule_changeW==1
local numhhHW = r(N)

*	Collapse data to averages:
preserve
collapse (mean) schedule_changeH schedule_changeW
gen educ = 0
order educ
tempfile schedule_change
save `schedule_change'
restore

*	Consolidate education:
foreach educvar of varlist maxedH maxedW {
	replace `educvar' = 1 if `educvar'==2
	replace `educvar' = 1 if `educvar'==3
	replace `educvar' = 2 if `educvar'==4
	replace `educvar' = 3 if `educvar'==5
	replace `educvar' = 3 if `educvar'==6
}

*	Collapse data to averages by education:
*	-irregular work of men:
preserve
collapse (mean) schedule_changeH, by(maxedH)
rename maxedH educ
tempfile schedule_change_educH
save `schedule_change_educH'
restore
*	-irregular work of women:
preserve
collapse (mean) schedule_changeW, by(maxedW)
rename maxedW educ
tempfile schedule_change_educW
save `schedule_change_educW'
restore

*	Pool data together:
use `schedule_change_educH', clear
merge 1:1 educ using `schedule_change_educW', nogen
append using `schedule_change'
sort educ

*	Convert to percentages:
replace schedule_changeH = 100*schedule_changeH
replace schedule_changeW = 100*schedule_changeW

*	Draw figure that visualizes variation of incidence of irregular work:
#delimit;
graph hbar 	schedule_changeH schedule_changeW, 
			over(educ,
			relabel(1 `" "all education" "levels" "'
					2 `" "primary and" "secondary" "'			
					3 "vocational"
					4 `" "university and" "post graduate" "')) 
			bar(1,color(gs5) 	lcolor(black)) 
			bar(2,color(gs14) 	lcolor(black) lwidth(0.3))
			ytitle("percentage of households for whom incidence" "of irregular work varies over 2009-12")
			legend( subtitle("Irregular work of:", 
							 position(11) color(black) size(medsmall))
					label(1 "male spouse") 
					label(2 "female spouse") 
					rows(2) position(5) ring(0)) ylabel(0(20)80)
			text(33.5 93  "`meanH'% : `numhhH' unique households and `numobsH' observations", place(e) color(black) size(small))
			text(36.5 83  "`meanW'% : `numhhW' unique households and `numobsW' observations", place(e) color(black) size(small)) 
			graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig5.pdf", as(pdf) replace
cap : window manage close graph

*	Reload baseline data:
clear
use "$DATAdir/final_data_$today.dta", clear
keep if children==100 & amatching==0


/*******************************************************************************
Longitudinal variation in incidence of irregular work bundling often & sometimes together
(figure used as part of our response to a referee)
	- generate indicators for incidence of irregular work bundling often & sometimes
	- generate indicators for variation in incidence of irregular work
	- plot variation in incidence of irregular work (by education)
	- obtain probabilities of job/occupation change by irregular work variation
*******************************************************************************/

*	Count observations by panel length:
sort nohouse_encr year 
by nohouse_encr : egen length = count(year)

*	Generate new irregular work indicators that bundle answers 'often' and 
*	'sometimes' together: 
gen 	w_irregulchoH_bundled = 1 if w_irregulchoH==1 | w_irregulchoH==2
replace w_irregulchoH_bundled = 2 if w_irregulchoH==3
gen 	w_irregulchoW_bundled = 1 if w_irregulchoW==1 | w_irregulchoW==2
replace w_irregulchoW_bundled = 2 if w_irregulchoW==3

* 	Measure variation in incidence of irregular work:
by nohouse_encr : egen sd_irregulchoH_bundled = sd(w_irregulchoH_bundled)
by nohouse_encr : egen sd_irregulchoW_bundled = sd(w_irregulchoW_bundled)
*	-indicator variable if incidence of irregular work varies over time;
*	-count how many observations (out of total sample size) are associated 
*	with households for whom irregular work incidence varies over time:
gen schedule_changeH = (sd_irregulchoH_bundled~=0 & sd_irregulchoH_bundled~=.)
gen schedule_changeW = (sd_irregulchoW_bundled~=0 & sd_irregulchoW_bundled~=.)
count if sd_irregulchoH_bundled~=0 & sd_irregulchoH_bundled~=.
local numobsH = r(N) 		/* number of observations */
count if sd_irregulchoW_bundled~=0 & sd_irregulchoW_bundled~=.
local numobsW = r(N) 		/* number of observations */

* 	Measure variation in job/occupation:
replace w_occupationH = -9 if w_occupationH==.
replace w_occupationW = -9 if w_occupationW==.
by nohouse_encr : egen sd_occupaH = sd(w_occupationH)
by nohouse_encr : egen sd_occupaW = sd(w_occupationW)
*	-indicator variable if job/occupation varies over time:
gen job_changeH = (sd_occupaH~=0 & sd_occupaH~=.)
gen job_changeW = (sd_occupaW~=0 & sd_occupaW~=.)

* 	Collapse data; new dataset is one observation per household; record 
*	education level of each spouse:
collapse (mean) length schedule_changeH schedule_changeW job_changeH job_changeW (max) maxedH = educH_cont maxedW = educW_cont, by(nohouse_encr)

*	Drop households that appear in the panel data only once; we can't use them
*	to measure variation in the incidence of irregular work:
drop if length==1

*	Estimate probability of job change by variation of irregular work:
preserve
collapse (mean) job_changeW, by(schedule_changeW)
rename schedule_changeW schedule_change
tempfile job_changeW
save `job_changeW'
restore	
preserve
collapse (mean) job_changeH, by(schedule_changeH)
rename schedule_changeH schedule_change
merge 1:1 schedule_change using `job_changeW', nogen
*	-export as table:
*export excel using "$EXPORTSdir/Variation_irregular_work_jobchange_$today.xlsx", sheet("bundled") firstrow(variables) sheetreplace
restore

*	Measure variation in incidence of irregular work, as well as number of
*	unique households that exhibit such variation:
*	-irregular work of men:
sum schedule_changeH
local meanH = round(100*r(mean),.1)
local numhouseholds = r(N)
count if schedule_changeH==1
local numhhH = r(N)
*	-irregular work of women:
sum schedule_changeW
local meanW = round(100*r(mean),.1)
count if schedule_changeW==1
local numhhW = r(N)
*	-irregular work of either men or women:
count if schedule_changeH==1 | schedule_changeW==1
local numhhHW = r(N)

*	Collapse data to averages:
preserve
collapse (mean) schedule_changeH schedule_changeW
gen educ = 0
order educ
tempfile schedule_change
save `schedule_change'
restore

*	Consolidate education:
foreach educvar of varlist maxedH maxedW {
	replace `educvar' = 1 if `educvar'==2
	replace `educvar' = 1 if `educvar'==3
	replace `educvar' = 2 if `educvar'==4
	replace `educvar' = 3 if `educvar'==5
	replace `educvar' = 3 if `educvar'==6
}

*	Collapse data to averages by education:
*	-irregular work of men:
preserve
collapse (mean) schedule_changeH, by(maxedH)
rename maxedH educ
tempfile schedule_change_educH
save `schedule_change_educH'
restore
*	-irregular work of women:
preserve
collapse (mean) schedule_changeW, by(maxedW)
rename maxedW educ
tempfile schedule_change_educW
save `schedule_change_educW'
restore

*	Pool data together:
use `schedule_change_educH', clear
merge 1:1 educ using `schedule_change_educW', nogen
append using `schedule_change'
sort educ

*	Convert to percentages:
replace schedule_changeH = 100*schedule_changeH
replace schedule_changeW = 100*schedule_changeW

*	Draw figure that visualizes variation of incidence of irregular work:
#delimit;
graph hbar 	schedule_changeH schedule_changeW, 
			over(educ,
			relabel(1 `" "all education" "levels" "'
					2 `" "primary and" "secondary" "'			
					3 "vocational"
					4 `" "university and" "post graduate" "'))  
			bar(1,color(gs5) 	lcolor(black)) 
			bar(2,color(gs14) 	lcolor(black) lwidth(0.3))
			ytitle("percentage of households for whom incidence" "of irregular work varies over 2009-12")
			legend( subtitle("Irregular work of:", 
							 position(11) color(black) size(medsmall))
					label(1 "male spouse") 
					label(2 "female spouse") 
					rows(2) position(5) ring(0)) ylabel(0(20)80)
			text(28.5 93  "`meanH'% : `numhhH' unique households and `numobsH' observations", place(e) color(black) size(small))
			text(29.5 83  "`meanW'% : `numhhW' unique households and `numobsW' observations", place(e) color(black) size(small)) 
			graphregion(color(white)) scheme(lean1) ;
#delimit cr
*graph export "$EXPORTSdir/Variation_irregular_work_bundled_$today.pdf", as(pdf) replace
cap : window manage close graph

*	Reload baseline data:
clear
use "$DATAdir/final_data_$today.dta", clear
keep if children==100 & amatching==0


/*******************************************************************************
Table leisure & childcare descriptives table (section I, table 1)
*******************************************************************************/

*	Label variables:
label variable LH "leisure male"
label variable LW "leisure female"
label variable Lp "joint leisure"
label variable TH "childcare male"
label variable TW "childcare female"

*	Summarize and export:
estpost summarize LH LW Lp TH TW, de listwise 
#delimit;
esttab . using "$EXPORTSdir/Table1.tex", replace 
	cells("mean(fmt(1)) p50(fmt(1)) p10(fmt(1)) p90(fmt(1))") 
	collabels("mean" "median" "10\textsuperscript{th} pct." "90\textsuperscript{th} pct.") 
	label noobs ;
#delimit cr


/*******************************************************************************
Table leisure & childcare regressions (section I and appendix A)
*******************************************************************************/

*	Generate log time use variables:
gen lhH = log(hH)
gen lhW = log(hW)
gen lLH = log(LH)
gen lLW = log(LW)
gen lLp = log(Lp)
gen lTH = log(TH)
gen lTW = log(TW)

*	Generate demographics regressors:
gen youngH  = (dm_ageH<=40)
gen youngW  = (dm_ageW<=40)
gen ageK46  = (dm_akyoungest>3 & dm_akyoungest<=6)
gen ageK712 = (dm_akyoungest>6 & dm_akyoungest<=12)

*	Generate irregular work indicators:
gen irregH = (w_irregulchoH!=3)
gen irregW = (w_irregulchoW!=3)

*	Generate local list of RHS variables that are always included:
global rhsvars irregH irregW gap_age_l ageK*

*	Consolidate occupation variables and label values:
replace w_occupationH = 8 if w_occupationH==9
replace w_occupationW = 8 if w_occupationW==9
#delimit;
label define occupl 	1 	"higher academic or independent professional"  			
						2 	"higher supervisory profession"  
						3 	"intermediate academic or independent"  
						4 	"intermediate supervisory or commercial"  
						5 	"other mental work"  	
						6 	"skilled and supervisory manual work" 
						7 	"semi-skilled manual work"  			
						8 	"trained manual work" ;
#delimit cr	
label values w_occupationH w_occupationW occupl

*	Consolidate education:
preserve
foreach educvar of varlist educH_cont  educW_cont  {
	replace `educvar' = 2 if `educvar'==3
	replace `educvar' = 3 if `educvar'==4
	replace `educvar' = 4 if `educvar'==5
	replace `educvar' = 5 if `educvar'==6
}
cap : label drop educl
#delimit;
label define educl 	1 "primary"				2 "secondary"
					3 "vocational"			4 "university" 			
					5 "post graduate" ;
#delimit cr						
label values educH_cont educW_cont educl

*	REGRESSION TABLE A.1 IN APPENDIX  ------------------------------------------
*	Y = Private leisure, joint leisure, childcare, all in logs
*	X = Private leisure, joint leisure, childcare, all in logs
eststo clear
eststo: reg lLH lLW lLp lTH lTW, vce(cluster nohouse_encr)
eststo: reg lLW lLH lLp lTH lTW, vce(cluster nohouse_encr) 
eststo: reg lLp lLH lLW lTH lTW, vce(cluster nohouse_encr)
eststo: reg lTH lLH lLW lLp lTW, vce(cluster nohouse_encr) 
eststo: reg lTW lLH lLW lLp lTH, vce(cluster nohouse_encr)
#delimit;
estout using "$EXPORTSdir/TableA1.tex", replace
	mlabels("leisure male" "leisure female" "joint leisure" "childcare male" "childcare female")
	varlabels(	_cons 	"constant" 
				lLH 	"leisure male" 
				lLW 	"leisure female" 
				lLp 	"joint leisure" 
				lTH 	"childcare male" 
				lTW 	"childcare female")
	cells("b(fmt(3))" "se(par fmt(3))") label style(tex) 
	order(lLH lLW lLp lTH lTW) drop(_cons) ;
#delimit cr

*	REGRESSION TABLE 2 IN TEXT  ------------------------------------------------
*	Y = Private leisure, joint leisure, childcare, all in logs
*	X = Gender wage & gaps, and indicators for irregular work & age of youngest child
eststo clear
eststo: reg lLH gap_wage_l ${rhsvars}, vce(cluster nohouse_encr)
eststo: reg lLW gap_wage_l ${rhsvars}, vce(cluster nohouse_encr)
eststo: reg lLp gap_wage_l ${rhsvars}, vce(cluster nohouse_encr)
eststo: reg lTH gap_wage_l ${rhsvars}, vce(cluster nohouse_encr)
eststo: reg lTW gap_wage_l ${rhsvars}, vce(cluster nohouse_encr)
#delimit;
estout using "$EXPORTSdir/Table2.tex", replace
	mlabels("leisure male" "leisure female" "joint leisure" "childcare male" "childcare female")
	varlabels(	_cons 		"constant" 
				irregH 		"1[irregular work male]" 
				irregW 		"1[irregular work female]" 
				gap_age_l 	"gender age gap" 
				ageK46 		"1[child 4-6 yrs]" 
				ageK712 	"1[child 7-12 yrs]" 
				gap_wage_l 	"gender wage gap")
	cells("b(fmt(3))" "se(par fmt(3))") 
	stats(r2 N, fmt(2 0)) label style(tex) ;	
#delimit cr

*	REGRESSION TABLE A.2 IN APPENDIX  ------------------------------------------
*	Y = Private leisure, joint leisure, childcare, all in logs
*	X = Gender wage & gaps, and indicators for irregular work & age of youngest child,
*		education controls and occupation sector controls
eststo clear
eststo: reg lLH gap_wage_l ${rhsvars} i.educH_cont i.w_occupationH, vce(cluster nohouse_encr)
eststo: reg lLW gap_wage_l ${rhsvars} i.educW_cont i.w_occupationW, vce(cluster nohouse_encr)
eststo: reg lLp gap_wage_l ${rhsvars} i.educH_cont i.w_occupationH i.educW_cont i.w_occupationW, vce(cluster nohouse_encr)
eststo: reg lTH gap_wage_l ${rhsvars} i.educH_cont i.w_occupationH, vce(cluster nohouse_encr)
eststo: reg lTW gap_wage_l ${rhsvars} i.educW_cont i.w_occupationW, vce(cluster nohouse_encr)
#delimit;
estout using "$EXPORTSdir/TableA2.tex", replace
	mlabels("leisure male" "leisure female" "joint leisure" "childcare male" "childcare female")
	varlabels(	_cons 		"constant" 
				irregH 		"1[irregular work male]" 
				irregW 		"1[irregular work female]" 
				gap_age_l 	"gender age gap" 
				ageK46 		"1[child 4-6 yrs]" 
				ageK712 	"1[child 7-12 yrs]" 
				gap_wage_l 	"gender wage gap")
	cells("b(fmt(3)) se(par fmt(3))") 
	stats(r2 N, fmt(2 0)) label style(tex) 
	drop(1.educH_cont 1.educW_cont 1.w_occupationH 1.w_occupationW) ;	
#delimit cr
restore


/*******************************************************************************
Private and joint leisure proportions positive (section II.C)
*******************************************************************************/

*	Count and display the fraction of households for which leisure is
*	strictly positive:
gen positive_lH = lH>0
sum positive_lH
gen positive_lW = lW>0
sum positive_lW
gen positive_Lp = Lp>0
sum positive_Lp
drop positive_lH positive_lW positive_Lp


/*******************************************************************************
Time depth of sample (section IV.A)
*******************************************************************************/

*	Count how many times we typically observe households:
preserve
keep children amatching group nohouse_encr year
bys nohouse_encr : egen length = count(year)
collapse (mean) length, by(nohouse_encr)
tab length
restore


/*******************************************************************************
Number of children (section IV.A)
*******************************************************************************/

*	Count frequency of different household compositions w.r.t. children:
preserve
keep children amatching group nohouse_encr year dm_numkids
sum dm_numkids 
local ss = r(N)
count if dm_numkids==1
di  r(N)/`ss'
count if dm_numkids==2
di  r(N)/`ss'
count if dm_numkids>2
di  r(N)/`ss'
restore


/*******************************************************************************
Summary statistics table (section IV.A, table 5)
*******************************************************************************/

*	Generate temporary new variables (levels):
gen minT = TH if TH<=TW
replace minT = TW if TW<TH
gen rwH = wH / cpi
gen rwW = wW / cpi
gen rCp = Cp / cpi
gen rCk = Ck / cpi
gen collH  = (dm_educH==5 | dm_educH==6)
gen collW  = (dm_educW==5 | dm_educW==6)
gen married = dm_mstatus==1
gen positive_irregularH = (hH_I>0)
gen positive_irregularW = (hW_I>0)
qui sum group
gen num_groups = r(max)
bys group : egen num_hhs = count(group)

* 	Calculate summary statistics for baseline sample and export:	
cap eststo clear
*	-men & household:
preserve
rename dm_ageH dm_age
rename collH coll
rename lH l
rename TH T
rename hH_R h_R
rename positive_irregularH positive_irregular
rename hH_I h_I
rename rwH rw
eststo: estpost summarize dm_age coll l T h_R positive_irregular h_I rw dm_akyoungest dm_numkids married Lp minT rCp rCk num_groups num_hhs
restore
*	-women:
preserve
rename dm_ageW dm_age
rename collW coll
rename lW l
rename TW T
rename hW_R h_R
rename positive_irregularW positive_irregular
rename hW_I h_I
rename rwW rw
eststo: estpost summarize dm_age coll l T h_R positive_irregular h_I rw
restore
*	-export to tables:
preserve
rename dm_ageH dm_age
rename collH coll
rename lH l
rename TH T
rename hH_R h_R
rename positive_irregularH positive_irregular
rename hH_I h_I
rename rwH rw
label variable dm_age				"age"
label variable coll 				"1[university education or similar]"
label variable l 					"private leisure"
label variable T 					"childcare"
label variable h_R 					"regular work hours"
label variable positive_irregular	"1[irregular work hours$>0$]"
label variable h_I 					"irregular work hours"
label variable rw 					"observed hourly wage (in euro)"
label variable dm_akyoungest 		"age youngest child"
label variable dm_numkids 			"number of children"
label variable married				"1[married]"
label variable Lp 					"joint leisure"
label variable minT					"minimum of parents' childcare"
label variable rCp 					"parental consumption (in euro)"
label variable rCk 					"child consumption (in euro)"
label variable num_groups 			"\# of household groups"
label variable num_hhs				"\# of households in a group"
esttab using "$EXPORTSdir/Table5.tex", replace cells("mean(fmt(2)) sd(fmt(2))") label
restore


/*******************************************************************************
Figure predictive success (section IV.B, figure 6)
*******************************************************************************/

*	Import data on predictive success of two models:
*	-CR model
infile success ecdf using "$DATAdir/PowerLJ.txt", clear
qui gen model = 1
tempfile crmodel
save `crmodel' 
*	-T-CR model
infile success ecdf using "$DATAdir/PowerTC.txt", clear
qui gen model = 2
append using `crmodel' 

*	Visualize predictive success:
#delimit;
twoway 	(line ecdf success if model==1, lpattern(dash) lwidth(medthick) lcolor(blue)) 
		(line ecdf success if model==2, lpattern(solid) lwidth(medthick) lcolor(red)), 
		xline(0.0, lwidth(1) lc(gs11))
		ylabel(0(.2)1.0) ytitle("empirical CDF")
		xlabel(-1.0(.2)1.0) xtitle("predictive success")
		legend(	label(1 "CR") 
				label(2 "T-CR") 
				rows(2) position(11) ring(0))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig6.pdf", as(pdf) replace
cap : window manage close graph
erase "$DATAdir/PowerLJ.txt" 
erase "$DATAdir/PowerTC.txt"


/*******************************************************************************
Figure value of togetherness (section IV.C, figure 7)
*******************************************************************************/

*	Import data on value of togetherness for different components:
*	-Value joint childcare
infile value ecdf using "$DATAdir/valuechildcare.txt", clear
qui gen item = 1
tempfile valuechildcare
save `valuechildcare' 
*	-Price market childcare
infile value ecdf using "$DATAdir/pricechildcare.txt", clear
qui gen item = 2
tempfile pricechildcare
save `pricechildcare' 
*	-Value joint leisure
infile value ecdf using "$DATAdir/valueleisure.txt", clear
qui gen item = 3
append using `pricechildcare' 
append using `valuechildcare' 

*	Visualize value of togetherness:
#delimit;
twoway 	(line ecdf value if item==1 & value<=10 & ecdf!=0, lpattern(solid) lwidth(medthick) lcolor(blue)) 
		(line ecdf value if item==2 & value<=10 & ecdf!=0, lpattern(longdash) lwidth(medthick) lcolor(black))
		(line ecdf value if item==3 & value<=10 & ecdf!=0, lpattern(shortdash) lwidth(medthick) lcolor(red)), 
		ylabel(0(.2)1.0) ytitle("empirical CDF")
		xlabel(0.0(1)10.0) xtitle("price of 1hr of joint time (over 1hr of private time by each spouse), in {c 0128}")
		legend(	label(1 "value of joint childcare") 
				label(2 "price of market childcare") 
				label(3 "value of joint leisure")
				rows(3) position(5) ring(0))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig7.pdf", as(pdf) replace
cap : window manage close graph
erase "$DATAdir/valuechildcare.txt"
erase "$DATAdir/pricechildcare.txt"
erase "$DATAdir/valueleisure.txt"


/*******************************************************************************
Figure value of togetherness, forgone earnings only (section V.A, figure 8)
*******************************************************************************/

*	Import data on value of togetherness for different types of household:
*	-Households for whom h1R>h2R
infile value ecdf using "$DATAdir/women.txt", clear
qui gen household = 1
tempfile women
save `women' 
*	-Households for whom h1R<h2R
infile value ecdf using "$DATAdir/men.txt", clear
qui gen household = 2
append using `women' 

*	Visualize value of togetherness:
#delimit;
twoway 	(line ecdf value if household==1 & value<=10 & ecdf!=0, lpattern(longdash) lwidth(medthick) lcolor(blue)) 
		(line ecdf value if household==2 & value<=10 & ecdf!=0, lpattern(shortdash) lwidth(medthick) lcolor(red)), 
		ylabel(0(.2)1.0) ytitle("empirical CDF")
		xlabel(0.0(1)10.0) xtitle("price of 1hr of joint time (over 1hr of private time by each spouse), in {c 0128}")
		legend(	subtitle("member who can" "increase togetherness:", justification(right))
				label(1 "female") 
				label(2 "male") 
				rows(2) position(5) ring(0))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig8.pdf", as(pdf) replace
cap : window manage close graph
erase "$DATAdir/women.txt"
erase "$DATAdir/men.txt"


/*******************************************************************************
Bounds on sharing rule (section V.A, figure 9)
*******************************************************************************/

*	Import bounds on resource shares and rename variables:
import delimited using "$DATAdir/resourcesharing.csv", clear
rename v1 lb
rename v2 ub
rename v3 gap_admin_l

*	Keep baseline households who are consistent with T-CR model:
keep if lb!=200 & ub!=-200

*	Obtain mean bounds as the average of the lower and upper bound:
gen bmean = 0.5*(lb+ub)

*	Visualize baseline bounds against admin chores gap:
#delimit;
twoway 	(scatter lb gap_admin_l, msymbol(smcircle_hollow) mcolor(red)) 
		(scatter ub gap_admin_l, msymbol(smtriangle_hollow) mcolor(blue)) 
		(qfit lb gap_admin_l, lcolor(red) lwidth(thick) lpattern(solid)) 
		(qfit ub gap_admin_l, lcolor(blue) lwidth(thick) lpattern(solid)),
		ylabel(0.1(.2).9) ytitle("male resource share")
		xtitle("administrative chores and errands, gender gap")
		legend(	order(2 1)
				subtitle("Bounds and" "quadratic fit")
				label(1 "lower bound") 
				label(2 "upper bound") 
				rows(2) position(1) ring(0))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/Fig9.pdf", as(pdf) replace
cap : window manage close graph
erase "$DATAdir/resourcesharing.csv"


/*******************************************************************************
Figure bounds joint childcare (appendix C.3, figure C.1)
*******************************************************************************/

*	Import RP bounds on jopint childcare data:
import delimited using "$DATAdir/appendixbounds.csv", clear
rename v1 naive_lb
rename v2 estimated_lb
rename v3 estimated_ub
rename v4 naive_ub

*	Keep baseline households who are consistent with T-CR model:
keep if estimated_lb!=200 & estimated_ub!=-200

*	Generate midpoint of estimated bounds and sort; generate continuum of 
*	households:
gen midpoint = estimated_lb+(estimated_ub-estimated_lb)/2
sort midpoint
gen hh_cont = (_n/_N)

*	Visualize bounds on joint childcare:
#delimit;
twoway 	(function y=0.0, range(0 1) lcolor(red) lpattern(dash) lwidth(thick))
		(rspike estimated_lb estimated_ub hh_cont, lcolor(gs1))
		(scatter naive_ub hh_cont, msymbol(circle) mcolor(blue) msize(small)),
		ylabel(0(5)50) ytitle("hours per week")
		xlabel(none) xtitle("rational households (T-CR), ordered by bounds midpoint")
		legend(	order(2 1 3)
				label(2 "estimated bounds joint childcare") 
				label(3 "naive upper bound") 
				label(1 "naive lower bound") 
				rows(3) position(11) ring(0))
		graphregion(color(white)) scheme(lean1) ;
#delimit cr
graph export "$EXPORTSdir/FigC1.pdf", as(pdf) replace
cap : window manage close graph
erase "$DATAdir/appendixbounds.csv"

*** end of do file ***
