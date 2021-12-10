
/*******************************************************************************
	
	This code uses yearly data from several LISS Core and Assembled studies in  
	2009, 2010 and 2012. The choice of years is determined by consistent 
	availability of Assembled Study 34 (the consumption module). The code then:
	- keeps a subset of variables per year
	- merges information across these modules and the household box
	- renames variables
	- performs a baseline selection on the basis that a household consists of 
      exactly two spouses who live together and are of opposite sex
	- appends the yearly data to construct a single panel dataset
	____________________________________________________________________________

	Filename: 	CTV_03_YearlyData.do
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
Data from 2009 wave
*******************************************************************************/

*	Use 'Core Study 5: Family and Household':
qui use "$RAWDATAdir/Raw2009_5.dta", clear
#delimit;
keep nomem_encr nohouse_encr
	cf09b024 cf09b402 cf09b025 cf09b030 cf09b037 cf09b038 cf09b039 cf09b040 
	cf09b041 cf09b042 cf09b043 cf09b044 cf09b045 cf09b046 cf09b047 cf09b048 
	cf09b049 cf09b050 cf09b051 cf09b052 cf09b068 cf09b069 cf09b070 cf09b071 
	cf09b072 cf09b073 cf09b074 cf09b075 cf09b076 cf09b077 cf09b078 cf09b079 
	cf09b080 cf09b081 cf09b082 cf09b083 cf09b084 cf09b085 cf09b086 cf09b087 
	cf09b088 cf09b089 cf09b090 cf09b091 cf09b092 cf09b093 cf09b094 cf09b095 
	cf09b096 cf09b097 cf09b164 cf09b187 cf09b188 cf09b189 cf09b190 cf09b191 
	cf09b192 cf09b198 cf09b199 cf09b200 cf09b201 cf09b238 cf09b239 cf09b240 
	cf09b241 cf09b242 cf09b243 cf09b244 cf09b245 cf09b246 cf09b247 cf09b248 
	cf09b249 cf09b250 cf09b251 cf09b252 cf09b253 cf09b254 cf09b255 cf09b256 
	cf09b257 cf09b258 cf09b259 cf09b260 cf09b261 cf09b262 cf09b263 cf09b264 
	cf09b265 cf09b266 cf09b327 cf09b328 cf09b329 cf09b330 cf09b331 cf09b332 
	cf09b333 cf09b334 cf09b335 cf09b336 cf09b337 cf09b338 cf09b339 cf09b382 
	cf09b384 cf09b386 cf09b387 ;
#delimit cr
foreach var of varlist cf* {
   local varlabel : variable label `var'
   label variable `var' "(5) `varlabel'"
}
save "$DATAdir/2009_5.dta", replace

*	Use 'Core Study 6: Work and Schooling':
qui use "$RAWDATAdir/Raw2009_6.dta", clear
#delimit;
keep nomem_encr nohouse_encr
	cw09b001 cw09b121 cw09b127 cw09b136 cw09b138 cw09b139 cw09b140 cw09b141 
	cw09b142 cw09b143 cw09b144 cw09b402 cw09b404 cw09b405 cw09b425 cw09b446 ;
#delimit cr
foreach var of varlist cw* {
   local varlabel : variable label `var'
   label variable `var' "(6) `varlabel'"
}
save "$DATAdir/2009_6.dta", replace

*	Use 'Assembled Study 34: Time Use and Consumption':
qui use "$RAWDATAdir/Raw2009_34.dta", clear
#delimit;
keep nomem_encr nohouse_encr
    bf09a003 bf09a005 bf09a006 bf09a007 bf09a008 bf09a009 bf09a010 bf09a011 
	bf09a012 bf09a013 bf09a014 bf09a015 bf09a016 bf09a017 bf09a018 bf09a019 
	bf09a020 bf09a021 bf09a022 bf09a023 bf09a024 bf09a025 bf09a026 bf09a027 
	bf09a028 bf09a029 bf09a030 bf09a064 bf09a065 bf09a066 bf09a067 bf09a068 
	bf09a069 bf09a070 bf09a071 bf09a072 bf09a073 bf09a074 bf09a075 bf09a076 
	bf09a077 bf09a091 bf09a092 bf09a093 bf09a094 bf09a095 bf09a096 bf09a097 
	bf09a098 bf09a099 bf09a100 bf09a101 bf09a102 bf09a103 bf09a105 bf09a106 
	bf09a107 bf09a108 bf09a109 bf09a110 bf09a111 bf09a112 bf09a113 bf09a118 ;
#delimit cr
foreach var of varlist bf* {
   local varlabel : variable label `var'
   label variable `var' "(34) `varlabel'"
}
save "$DATAdir/2009_34.dta", replace

* 	Merge information by individual/household across studies in 2009:
*	Note: not all individuals participate in all 3 core studies. We naturally 
*	drop these people because information on them is incomplete (_merge==1/2).
use "$DATAdir/2009_5.dta", clear
foreach y in 6 34 {
	merge 1:1 nomem_encr nohouse_encr using "$DATAdir/2009_`y'.dta"
	drop if _merge!=3
	drop _merge
}
*	Check that there are no duplicate person in the merged dataset:
duplicates tag nomem_encr nohouse_encr, gen(dupltag)
sum dupltag
if r(mean)!=0 {
	error
}
drop dupltag

*	Generate year variable:
gen year=2009
order nomem_encr nohouse_encr year

* 	Merge with data from household box:
*	Note: those not merged from 'master' are people previously dropped from
*	household box (eg. mainly children). Those not merged from 'using' either
*	don't appear in 'master' because of non-response in one of the studies or
*	because they only appear in other years.
merge 1:1 nomem_encr nohouse_encr year using "$DATAdir/hbox2009_2017_$today.dta"
drop if _merge!=3
drop _merge
sort nohouse_encr nomem_encr year

*	(Re)name variables:
*	The rule for the first letters of a variable name is as follows:
*		- dm_ : denotes 'demographics' variables
*		- w_  : denotes 'work' and work related variables
*		- y_  : denotes 'income' and income related variables
*		- l_  : denotes 'leisure' and leisure related variables
*		- h_  : denotes 'household work' and chores related variables
*		- k_  : denotes 'kids' and variables relating to kids activities
*		- c_  : denotes 'consumption' and expenditure related variables
*	All variable labels contain '(##)' to indicate the LISS core or assembled 
*	study that they are extracted from.
rename cf09b024 dm_haspartner
rename cf09b402 dm_samepartner
rename cf09b025 dm_livewpartner
rename cf09b030 dm_marriedwpartner
rename cf09b037 dm_ybk1
rename cf09b038 dm_ybk2
rename cf09b039 dm_ybk3
rename cf09b040 dm_ybk4
rename cf09b041 dm_ybk5
rename cf09b042 dm_ybk6
rename cf09b043 dm_ybk7
rename cf09b044 dm_ybk8
rename cf09b045 dm_ybk9
rename cf09b046 dm_ybk10
rename cf09b047 dm_ybk11
rename cf09b048 dm_ybk12
rename cf09b049 dm_ybk13
rename cf09b050 dm_ybk14
rename cf09b051 dm_ybk15
rename cf09b052 dm_allkalive
rename cf09b068 dm_gk1
rename cf09b069 dm_gk2
rename cf09b070 dm_gk3
rename cf09b071 dm_gk4
rename cf09b072 dm_gk5
rename cf09b073 dm_gk6
rename cf09b074 dm_gk7
rename cf09b075 dm_gk8
rename cf09b076 dm_gk9
rename cf09b077 dm_gk10
rename cf09b078 dm_gk11
rename cf09b079 dm_gk12
rename cf09b080 dm_gk13
rename cf09b081 dm_gk14
rename cf09b082 dm_gk15
rename cf09b083 dm_lhk1
rename cf09b084 dm_lhk2
rename cf09b085 dm_lhk3
rename cf09b086 dm_lhk4
rename cf09b087 dm_lhk5
rename cf09b088 dm_lhk6
rename cf09b089 dm_lhk7
rename cf09b090 dm_lhk8
rename cf09b091 dm_lhk9
rename cf09b092 dm_lhk10
rename cf09b093 dm_lhk11
rename cf09b094 dm_lhk12
rename cf09b095 dm_lhk13
rename cf09b096 dm_lhk14
rename cf09b097 dm_lhk15
rename cf09b164 l_lpubfreq
rename cf09b187 h_hdivfood
rename cf09b188 h_hdivlaundry
rename cf09b189 h_hdivclean
rename cf09b190 h_hdivodd
rename cf09b191 h_hdivfinanc
rename cf09b192 h_hdivgrocery
rename cf09b198 h_hdivplayk
rename cf09b199 h_hdivdrivek
rename cf09b200 h_hdivtalkk
rename cf09b201 h_hdivgooutk
rename cf09b238 k_nursery04
rename cf09b239 k_daycare04
rename cf09b240 k_bfschlcare04
rename cf09b241 k_afschlcare04
rename cf09b242 k_hostparent04
rename cf09b243 k_pdsitteraw04
rename cf09b244 k_pdsitterhm04
rename cf09b245 k_unpdsitter04
rename cf09b246 k_othercare04
rename cf09b247 k_nocare04
rename cf09b248 k_whositter04
rename cf09b249 k_ptdays04
rename cf09b250 k_whours04
rename cf09b251 c_ccare04
rename cf09b252 k_schl1
rename cf09b253 k_schl2
rename cf09b254 k_schl3
rename cf09b255 k_schl4
rename cf09b256 k_schl5
rename cf09b257 k_schl6
rename cf09b258 k_schl7
rename cf09b259 k_schl8
rename cf09b260 k_schl9
rename cf09b261 k_schl10
rename cf09b262 k_schl11
rename cf09b263 k_schl12
rename cf09b264 k_schl13
rename cf09b265 k_schl14
rename cf09b266 k_schl15
rename cf09b327 k_bfschlcare95
rename cf09b328 k_afschlcare95
rename cf09b329 k_bwschlcare95
rename cf09b330 k_hostparent95
rename cf09b331 k_pdsitteraw95
rename cf09b332 k_pdsitterhm95
rename cf09b333 k_unpdsitter95
rename cf09b334 k_othercare95
rename cf09b335 k_nocare95
rename cf09b336 k_whositter95
rename cf09b337 k_ptdays95
rename cf09b338 k_whours95
rename cf09b339 c_ccare95
rename cf09b382 c_ccare
rename cf09b384 y_ccsubsamt
rename cf09b386 y_ccsuppt
rename cf09b387 y_ccsuppamt
rename cw09b001 w_paidwork
rename cw09b121 w_empltype
rename cw09b127 w_hrs6
rename cw09b136 w_comumins6
rename cw09b138 w_irregulreq
rename cw09b139 w_evenings
rename cw09b140 w_nights
rename cw09b141 w_wkends
rename cw09b142 w_home
rename cw09b143 w_2ndjob
rename cw09b144 w_2ndjobwhrs
rename cw09b402 w_sector
rename cw09b404 w_occupation
rename cw09b405 w_firstoccu
rename cw09b425 w_irregulcho
rename cw09b446 w_hrstension
rename bf09a003 c_krespondent
rename bf09a005 w_whrs
rename bf09a006 w_wmins
rename bf09a007 w_comuhrs
rename bf09a008 w_comumins
rename bf09a009 h_chorshrs
rename bf09a010 h_chorsmins
rename bf09a011 h_pcarehrs
rename bf09a012 h_pcaremins
rename bf09a013 h_wkidshrs
rename bf09a014 h_wkidsmins
rename bf09a015 h_wparshrs
rename bf09a016 h_wparsmins
rename bf09a017 h_wfamhrs
rename bf09a018 h_wfammins
rename bf09a019 h_wothrshrs
rename bf09a020 h_wothrsmins
rename bf09a021 l_lhrs
rename bf09a022 l_lmins
rename bf09a023 h_schlhrs
rename bf09a024 h_schlmins
rename bf09a025 h_adminhrs
rename bf09a026 h_adminmins
rename bf09a027 h_sleephrs
rename bf09a028 h_sleepmins
rename bf09a029 h_otherhrs
rename bf09a030 h_othermins
rename bf09a064 l_lpubhrs
rename bf09a065 l_lpubmins
rename bf09a066 c_mortg
rename bf09a067 c_rent
rename bf09a068 c_utils
rename bf09a069 c_trnsprt
rename bf09a070 c_insur
rename bf09a071 c_dcare
rename bf09a072 c_alimony
rename bf09a073 c_loans
rename bf09a074 c_holiday
rename bf09a075 c_maintain
rename bf09a076 c_foodin
rename bf09a077 c_hhother
rename bf09a091 c_myfoodin
rename bf09a092 c_yrfoodin
rename bf09a093 c_kdfoodin
rename bf09a094 c_otfoodin
rename bf09a095 c_foodout
rename bf09a096 c_tobacco
rename bf09a097 c_clothes
rename bf09a098 c_pcare
rename bf09a099 c_medical
rename bf09a100 c_leisure
rename bf09a101 c_schl
rename bf09a102 c_gifts
rename bf09a103 c_other
rename bf09a105 c_kfoodout
rename bf09a106 c_ktobacco
rename bf09a107 c_kclothes
rename bf09a108 c_kpcare
rename bf09a109 c_kmedical
rename bf09a110 c_kleisure
rename bf09a111 c_kschl
rename bf09a112 c_kgifts
rename bf09a113 c_kother
rename bf09a118 dm_commit

*	Assemble two-spouse opposite-sex households in four steps:
*	1. Drop very few households who report in Core Study 5 (collected in March) 
*	that they don't have a partner even though the background variables (hbox) 
*	don't reflect this. Drop those who don't live with their partner:
drop if dm_haspartner!=1
drop dm_haspartner
drop if dm_livewpartner!=1
drop dm_livewpartner
*	2. Measure how many observations we have per household; drop if != 2. These
*  	are households where one spouse failed to complete at least one of the three
*	core studies required for completeness of our data:
by nohouse_encr : egen numobs = count(year)
drop if numobs!=2
drop numobs
*	3. Request couples to consist of individuals of different gender:
by nohouse_encr : egen sexes = sum(dm_gender)
drop if sexes!=3	/* 3 == male (1) + female (2) */
drop sexes
*	4. Drop few (if any) households where both spouses appear as household head:
gen head=dm_position==1
by nohouse_encr : egen heads=sum(head)
drop if heads!=1
drop head*

*	Restructure data so that now one observation refers to one household with 
*	information for both spouses. Copy and paste variable labels:
gen spouse = "H" if dm_gender==1
replace spouse = "W" if dm_gender==2
drop dm_gender
foreach v of var dm_* l_* h_* w_* c_* k_* y_* { 
	local l`v'H : variable label `v' 
	local l`v'W : variable label `v'
}
reshape wide nomem_encr dm_* l_* h_* w_* c_* k_* y_*, i(nohouse_encr year) j(spouse) string
order nohouse_encr year nomem_encr* dm_* y_* w_* l_* h_* k_* c_*
drop dm_position*
foreach v of var dm_* y_* w_* l_* h_* k_* c_* { 
	label variable `v' "`l`v''"
}

* 	Save household dataset for year 2009:
qui compress
save "$DATAdir/2009.dta", replace
erase "$DATAdir/2009_5.dta"
erase "$DATAdir/2009_6.dta"
erase "$DATAdir/2009_34.dta"


/*******************************************************************************
Data from 2010 wave
*******************************************************************************/

*	Use 'Core Study 5: Family and Household':
qui use "$RAWDATAdir/Raw2010_5.dta", clear
#delimit;
keep nomem_encr nohouse_encr
	cf10c024 cf10c402 cf10c025 cf10c030 cf10c037 cf10c038 cf10c039 cf10c040
	cf10c041 cf10c042 cf10c043 cf10c044 cf10c045 cf10c046 cf10c047 cf10c048
	cf10c049 cf10c050 cf10c051 cf10c052 cf10c068 cf10c069 cf10c070 cf10c071
	cf10c072 cf10c073 cf10c074 cf10c075 cf10c076 cf10c077 cf10c078 cf10c079
	cf10c080 cf10c081 cf10c082 cf10c083 cf10c084 cf10c085 cf10c086 cf10c087
	cf10c088 cf10c089 cf10c090 cf10c091 cf10c092 cf10c093 cf10c094 cf10c095
	cf10c096 cf10c097 cf10c164 cf10c187 cf10c188 cf10c189 cf10c190 cf10c191
	cf10c192 cf10c198 cf10c199 cf10c200 cf10c201 cf10c238 cf10c239 cf10c240
	cf10c241 cf10c242 cf10c243 cf10c244 cf10c245 cf10c246 cf10c247 cf10c248
	cf10c249 cf10c250 cf10c251 cf10c252 cf10c253 cf10c254 cf10c255 cf10c256
	cf10c257 cf10c258 cf10c259 cf10c260 cf10c261 cf10c262 cf10c263 cf10c264
	cf10c265 cf10c266 cf10c327 cf10c328 cf10c329 cf10c330 cf10c331 cf10c332	
	cf10c333 cf10c334 cf10c335 cf10c336 cf10c337 cf10c338 cf10c339 cf10c382
	cf10c384 cf10c386 cf10c387 ;
#delimit cr
foreach var of varlist cf* {
   local varlabel : variable label `var'
   label variable `var' "(5) `varlabel'"
}
save "$DATAdir/2010_5.dta", replace

*	Use 'Core Study 6: Work and Schooling':
qui use "$RAWDATAdir/Raw2010_6.dta", clear
#delimit;
keep nomem_encr nohouse_encr
	cw10c001 cw10c121 cw10c127 cw10c136 cw10c138 cw10c139 cw10c140 cw10c141	
	cw10c142 cw10c143 cw10c144 cw10c402 cw10c404 cw10c405 cw10c425 cw10c446 ;
#delimit cr
foreach var of varlist cw* {
   local varlabel : variable label `var'
   label variable `var' "(6) `varlabel'"
}
save "$DATAdir/2010_6.dta", replace

*	Use 'Assembled Study 34: Time Use and Consumption':
qui use "$RAWDATAdir/Raw2010_34.dta", clear
#delimit;
keep nomem_encr nohouse_encr
	bf10b003 bf10b005 bf10b006 bf10b007 bf10b008 bf10b009 bf10b010 bf10b011 
	bf10b012 bf10b013 bf10b014 bf10b015 bf10b016 bf10b017 bf10b018 bf10b019
	bf10b020 bf10b021 bf10b022 bf10b023 bf10b024 bf10b025 bf10b026 bf10b027
	bf10b028 bf10b029 bf10b030 bf10b064 bf10b065 bf10b066 bf10b067 bf10b068
	bf10b069 bf10b070 bf10b071 bf10b072 bf10b073 bf10b074 bf10b075 bf10b076
	bf10b077 bf10b091 bf10b092 bf10b093 bf10b094 bf10b095 bf10b096 bf10b097
	bf10b098 bf10b099 bf10b100 bf10b101 bf10b102 bf10b103 bf10b105 bf10b106
	bf10b107 bf10b108 bf10b109 bf10b110 bf10b111 bf10b112 bf10b113 bf10b118 ;
#delimit cr
foreach var of varlist bf* {
   local varlabel : variable label `var'
   label variable `var' "(34) `varlabel'"
}
save "$DATAdir/2010_34.dta", replace

* 	Merge information by individual/household across studies in 2010:
*	Note: not all individuals participate in all 3 core studies. We naturally 
*	drop these people because information on them is incomplete (_merge==1/2).
use "$DATAdir/2010_5.dta", clear
foreach y in 6 34 {
	merge 1:1 nomem_encr nohouse_encr using "$DATAdir/2010_`y'.dta"
	drop if _merge!=3
	drop _merge
}
*	Check that there are no duplicate person in the merged dataset:
duplicates tag nomem_encr nohouse_encr, gen(dupltag)
sum dupltag
if r(mean)!=0 {
	error
}
drop dupltag

*	Generate year variable:
gen year=2010
order nomem_encr nohouse_encr year

* 	Merge with data from household box:
*	Note: those not merged from 'master' are people previously dropped from
*	household box (eg. mainly children). Those not merged from 'using' either
*	don't appear in 'master' because of non-response in one of the studies or
*	because they only appear in other years.
merge 1:1 nomem_encr nohouse_encr year using "$DATAdir/hbox2009_2017_$today.dta"
drop if _merge!=3
drop _merge
sort nohouse_encr nomem_encr year

*	(Re)name variables:
*	The rule for the first letters of a variable name is as follows:
*		- dm_ : denotes 'demographics' variables
*		- w_  : denotes 'work' and work related variables
*		- y_  : denotes 'income' and income related variables
*		- l_  : denotes 'leisure' and leisure related variables
*		- h_  : denotes 'household work' and chores related variables
*		- k_  : denotes 'kids' and variables relating to kids activities
*		- c_  : denotes 'consumption' and expenditure related variables
*	All variable labels contain '(##)' to indicate the LISS core or assembled 
*	study that they are extracted from.
rename cf10c024 dm_haspartner
rename cf10c402 dm_samepartner
rename cf10c025 dm_livewpartner
rename cf10c030 dm_marriedwpartner
rename cf10c037 dm_ybk1
rename cf10c038 dm_ybk2
rename cf10c039 dm_ybk3
rename cf10c040 dm_ybk4
rename cf10c041 dm_ybk5
rename cf10c042 dm_ybk6
rename cf10c043 dm_ybk7
rename cf10c044 dm_ybk8
rename cf10c045 dm_ybk9
rename cf10c046 dm_ybk10
rename cf10c047 dm_ybk11
rename cf10c048 dm_ybk12
rename cf10c049 dm_ybk13
rename cf10c050 dm_ybk14
rename cf10c051 dm_ybk15
rename cf10c052 dm_allkalive
rename cf10c068 dm_gk1
rename cf10c069 dm_gk2
rename cf10c070 dm_gk3
rename cf10c071 dm_gk4
rename cf10c072 dm_gk5
rename cf10c073 dm_gk6
rename cf10c074 dm_gk7
rename cf10c075 dm_gk8
rename cf10c076 dm_gk9
rename cf10c077 dm_gk10
rename cf10c078 dm_gk11
rename cf10c079 dm_gk12
rename cf10c080 dm_gk13
rename cf10c081 dm_gk14
rename cf10c082 dm_gk15
rename cf10c083 dm_lhk1
rename cf10c084 dm_lhk2
rename cf10c085 dm_lhk3
rename cf10c086 dm_lhk4
rename cf10c087 dm_lhk5
rename cf10c088 dm_lhk6
rename cf10c089 dm_lhk7
rename cf10c090 dm_lhk8
rename cf10c091 dm_lhk9
rename cf10c092 dm_lhk10
rename cf10c093 dm_lhk11
rename cf10c094 dm_lhk12
rename cf10c095 dm_lhk13
rename cf10c096 dm_lhk14
rename cf10c097 dm_lhk15
rename cf10c164 l_lpubfreq
rename cf10c187 h_hdivfood
rename cf10c188 h_hdivlaundry
rename cf10c189 h_hdivclean
rename cf10c190 h_hdivodd
rename cf10c191 h_hdivfinanc
rename cf10c192 h_hdivgrocery
rename cf10c198 h_hdivplayk
rename cf10c199 h_hdivdrivek
rename cf10c200 h_hdivtalkk
rename cf10c201 h_hdivgooutk
rename cf10c238 k_nursery04
rename cf10c239 k_daycare04
rename cf10c240 k_bfschlcare04
rename cf10c241 k_afschlcare04
rename cf10c242 k_hostparent04
rename cf10c243 k_pdsitteraw04
rename cf10c244 k_pdsitterhm04
rename cf10c245 k_unpdsitter04
rename cf10c246 k_othercare04
rename cf10c247 k_nocare04
rename cf10c248 k_whositter04
rename cf10c249 k_ptdays04
rename cf10c250 k_whours04
rename cf10c251 c_ccare04
rename cf10c252 k_schl1
rename cf10c253 k_schl2
rename cf10c254 k_schl3
rename cf10c255 k_schl4
rename cf10c256 k_schl5
rename cf10c257 k_schl6
rename cf10c258 k_schl7
rename cf10c259 k_schl8
rename cf10c260 k_schl9
rename cf10c261 k_schl10
rename cf10c262 k_schl11
rename cf10c263 k_schl12
rename cf10c264 k_schl13
rename cf10c265 k_schl14
rename cf10c266 k_schl15
rename cf10c327 k_bfschlcare95
rename cf10c328 k_afschlcare95
rename cf10c329 k_bwschlcare95
rename cf10c330 k_hostparent95
rename cf10c331 k_pdsitteraw95
rename cf10c332 k_pdsitterhm95
rename cf10c333 k_unpdsitter95
rename cf10c334 k_othercare95
rename cf10c335 k_nocare95
rename cf10c336 k_whositter95
rename cf10c337 k_ptdays95
rename cf10c338 k_whours95
rename cf10c339 c_ccare95
rename cf10c382 c_ccare
rename cf10c384 y_ccsubsamt
rename cf10c386 y_ccsuppt
rename cf10c387 y_ccsuppamt
rename cw10c001 w_paidwork
rename cw10c121 w_empltype
rename cw10c127 w_hrs6
rename cw10c136 w_comumins6
rename cw10c138 w_irregulreq
rename cw10c139 w_evenings
rename cw10c140 w_nights
rename cw10c141 w_wkends
rename cw10c142 w_home
rename cw10c143 w_2ndjob
rename cw10c144 w_2ndjobwhrs
rename cw10c402 w_sector
rename cw10c404 w_occupation
rename cw10c405 w_firstoccu
rename cw10c425 w_irregulcho
rename cw10c446 w_hrstension
rename bf10b003 c_krespondent
rename bf10b005 w_whrs
rename bf10b006 w_wmins
rename bf10b007 w_comuhrs
rename bf10b008 w_comumins
rename bf10b009 h_chorshrs
rename bf10b010 h_chorsmins
rename bf10b011 h_pcarehrs
rename bf10b012 h_pcaremins
rename bf10b013 h_wkidshrs
rename bf10b014 h_wkidsmins
rename bf10b015 h_wparshrs
rename bf10b016 h_wparsmins
rename bf10b017 h_wfamhrs
rename bf10b018 h_wfammins
rename bf10b019 h_wothrshrs
rename bf10b020 h_wothrsmins
rename bf10b021 l_lhrs
rename bf10b022 l_lmins
rename bf10b023 h_schlhrs
rename bf10b024 h_schlmins
rename bf10b025 h_adminhrs
rename bf10b026 h_adminmins
rename bf10b027 h_sleephrs
rename bf10b028 h_sleepmins
rename bf10b029 h_otherhrs
rename bf10b030 h_othermins
rename bf10b064 l_lpubhrs
rename bf10b065 l_lpubmins
rename bf10b066 c_mortg
rename bf10b067 c_rent
rename bf10b068 c_utils
rename bf10b069 c_trnsprt
rename bf10b070 c_insur
rename bf10b071 c_dcare
rename bf10b072 c_alimony
rename bf10b073 c_loans
rename bf10b074 c_holiday
rename bf10b075 c_maintain
rename bf10b076 c_foodin
rename bf10b077 c_hhother
rename bf10b091 c_myfoodin
rename bf10b092 c_yrfoodin
rename bf10b093 c_kdfoodin
rename bf10b094 c_otfoodin
rename bf10b095 c_foodout
rename bf10b096 c_tobacco
rename bf10b097 c_clothes
rename bf10b098 c_pcare
rename bf10b099 c_medical
rename bf10b100 c_leisure
rename bf10b101 c_schl
rename bf10b102 c_gifts
rename bf10b103 c_other
rename bf10b105 c_kfoodout
rename bf10b106 c_ktobacco
rename bf10b107 c_kclothes
rename bf10b108 c_kpcare
rename bf10b109 c_kmedical
rename bf10b110 c_kleisure
rename bf10b111 c_kschl
rename bf10b112 c_kgifts
rename bf10b113 c_kother
rename bf10b118 dm_commit

*	Assemble two-spouse opposite-sex households in four steps:
*	1. Drop very few households who report in Core Study 5 (collected in March) 
*	that they don't have a partner even though the background variables (hbox) 
*	don't reflect this. Drop those who don't live with their partner:
drop if dm_haspartner!=1
drop dm_haspartner
drop if dm_livewpartner!=1
drop dm_livewpartner
*	2. Measure how many observations we have per household; drop if != 2. These
*  	are households where one spouse failed to complete at least one of the three
*	core studies required for completeness of our data:
by nohouse_encr : egen numobs = count(year)
drop if numobs!=2
drop numobs
*	3. Request couples to consist of individuals of different gender:
by nohouse_encr : egen sexes = sum(dm_gender)
drop if sexes!=3	/* 3 == male (1) + female (2) */
drop sexes
*	4. Drop few (if any) households where both spouses appear as household head:
gen head=dm_position==1
by nohouse_encr : egen heads=sum(head)
drop if heads!=1
drop head*

*	Restructure data so that now one observation refers to one household with 
*	information for both spouses:
gen spouse = "H" if dm_gender==1
replace spouse = "W" if dm_gender==2
drop dm_gender
foreach v of var dm_* l_* h_* w_* c_* k_* y_* { 
	local l`v'H : variable label `v' 
	local l`v'W : variable label `v'
}
reshape wide nomem_encr dm_* l_* h_* w_* c_* k_* y_*, i(nohouse_encr year) j(spouse) string
order nohouse_encr year nomem_encr* dm_* y_* w_* l_* h_* k_* c_*
drop dm_position*
foreach v of var dm_* y_* w_* l_* h_* k_* c_* { 
	label variable `v' "`l`v''"
}

* 	Save household dataset for year 2010:
qui compress
save "$DATAdir/2010.dta", replace
erase "$DATAdir/2010_5.dta"
erase "$DATAdir/2010_6.dta"
erase "$DATAdir/2010_34.dta"


/*******************************************************************************
Data from 2012 wave
*******************************************************************************/

*	Use 'Core Study 5: Family and Household':
qui use "$RAWDATAdir/Raw2012_5.dta", clear
#delimit;
keep nomem_encr
	cf12e024 cf12e402 cf12e025 cf12e030 cf12e037 cf12e038 cf12e039 cf12e040
	cf12e041 cf12e042 cf12e043 cf12e044 cf12e045 cf12e046 cf12e047 cf12e048
	cf12e049 cf12e050 cf12e051 cf12e052 cf12e068 cf12e069 cf12e070 cf12e071
	cf12e072 cf12e073 cf12e074 cf12e075 cf12e076 cf12e077 cf12e078 cf12e079
	cf12e080 cf12e081 cf12e082 cf12e083 cf12e084 cf12e085 cf12e086 cf12e087 
	cf12e088 cf12e089 cf12e090 cf12e091 cf12e092 cf12e093 cf12e094 cf12e095
	cf12e096 cf12e097 cf12e164 cf12e187 cf12e188 cf12e189 cf12e190 cf12e191
	cf12e192 cf12e198 cf12e199 cf12e200 cf12e201 cf12e238 cf12e239 cf12e240
	cf12e241 cf12e242 cf12e243 cf12e244 cf12e245 cf12e246 cf12e247 cf12e248
	cf12e249 cf12e250 cf12e252 cf12e253 cf12e254 cf12e255 cf12e256 cf12e257 
	cf12e258 cf12e259 cf12e260 cf12e261 cf12e262 cf12e263 cf12e264 cf12e265 
	cf12e266 cf12e327 cf12e328 cf12e329 cf12e330 cf12e331 cf12e332 cf12e333 
	cf12e334 cf12e335 cf12e336 cf12e337 cf12e338 cf12e386 ;
#delimit cr
foreach var of varlist cf* {
   local varlabel : variable label `var'
   label variable `var' "(5) `varlabel'"
}
save "$DATAdir/2012_5.dta", replace

*	Use 'Core Study 6: Work and Schooling':
qui use "$RAWDATAdir/Raw2012_6.dta", clear
#delimit;
keep nomem_encr
	cw12e001 cw12e121 cw12e127 cw12e136 cw12e138 cw12e139 cw12e140 cw12e141
	cw12e142 cw12e143 cw12e144 cw12e402 cw12e404 cw12e405 cw12e425 cw12e446 ;
#delimit cr
foreach var of varlist cw* {
   local varlabel : variable label `var'
   label variable `var' "(6) `varlabel'"
}
save "$DATAdir/2012_6.dta", replace

*	Use 'Assembled Study 34: Time Use and Consumption':
qui use "$RAWDATAdir/Raw2012_34.dta", clear
#delimit;
keep nomem_encr
	bf12c003 bf12c005 bf12c006 bf12c007 bf12c008 bf12c009 bf12c010 bf12c011
	bf12c012 bf12c013 bf12c014 bf12c015 bf12c016 bf12c017 bf12c018 bf12c019
	bf12c020 bf12c021 bf12c022 bf12c023 bf12c024 bf12c025 bf12c026 bf12c027
	bf12c028 bf12c029 bf12c030 bf12c064 bf12c065 bf12c066 bf12c067 bf12c068
	bf12c069 bf12c070 bf12c071 bf12c072 bf12c073 bf12c074 bf12c075 bf12c076
	bf12c077 bf12c091 bf12c092 bf12c093 bf12c094 bf12c095 bf12c096 bf12c097
	bf12c098 bf12c099 bf12c100 bf12c101 bf12c102 bf12c103 bf12c105 bf12c106
	bf12c107 bf12c108 bf12c109 bf12c110 bf12c111 bf12c112 bf12c113 bf12c118 ;
#delimit cr
foreach var of varlist bf* {
   local varlabel : variable label `var'
   label variable `var' "(34) `varlabel'"
}
save "$DATAdir/2012_34.dta", replace

* 	Merge information by individual/household across studies in 2012:
*	Note: not all individuals participate in all 3 core studies. We naturally 
*	drop these people because information on them is incomplete (_merge==1/2).
use "$DATAdir/2012_5.dta", clear
foreach y in 6 34 {
	merge 1:1 nomem_encr using "$DATAdir/2012_`y'.dta"
	drop if _merge!=3
	drop _merge
}
*	Check that there are no duplicate person in the merged dataset:
duplicates tag nomem_encr, gen(dupltag)
sum dupltag
if r(mean)!=0 {
	error
}
drop dupltag

*	Generate year variable:
gen year=2012

* 	Merge with data from household box:
*	Note: those not merged from 'master' are people previously dropped from
*	household box (eg. mainly children). Those not merged from 'using' either
*	don't appear in 'master' because of non-response in one of the studies or
*	because they only appear in other years.
merge 1:1 nomem_encr year using "$DATAdir/hbox2009_2017_$today.dta"
drop if _merge!=3
drop _merge
order nomem_encr nohouse_encr year
sort nohouse_encr nomem_encr year

*	(Re)name variables:
*	The rule for the first letters of a variable name is as follows:
*		- dm_ : denotes 'demographics' variables
*		- w_  : denotes 'work' and work related variables
*		- y_  : denotes 'income' and income related variables
*		- l_  : denotes 'leisure' and leisure related variables
*		- h_  : denotes 'household work' and chores related variables
*		- k_  : denotes 'kids' and variables relating to kids activities
*		- c_  : denotes 'consumption' and expenditure related variables
*	All variable labels contain '(##)' to indicate the LISS core or assembled 
*	study that they are extracted from.
rename cf12e024 dm_haspartner
rename cf12e402 dm_samepartner
rename cf12e025 dm_livewpartner
rename cf12e030 dm_marriedwpartner
rename cf12e037 dm_ybk1
rename cf12e038 dm_ybk2
rename cf12e039 dm_ybk3
rename cf12e040 dm_ybk4
rename cf12e041 dm_ybk5
rename cf12e042 dm_ybk6
rename cf12e043 dm_ybk7
rename cf12e044 dm_ybk8
rename cf12e045 dm_ybk9
rename cf12e046 dm_ybk10
rename cf12e047 dm_ybk11
rename cf12e048 dm_ybk12
rename cf12e049 dm_ybk13
rename cf12e050 dm_ybk14
rename cf12e051 dm_ybk15
rename cf12e052 dm_allkalive
rename cf12e068 dm_gk1
rename cf12e069 dm_gk2
rename cf12e070 dm_gk3
rename cf12e071 dm_gk4
rename cf12e072 dm_gk5
rename cf12e073 dm_gk6
rename cf12e074 dm_gk7
rename cf12e075 dm_gk8
rename cf12e076 dm_gk9
rename cf12e077 dm_gk10
rename cf12e078 dm_gk11
rename cf12e079 dm_gk12
rename cf12e080 dm_gk13
rename cf12e081 dm_gk14
rename cf12e082 dm_gk15
rename cf12e083 dm_lhk1
rename cf12e084 dm_lhk2
rename cf12e085 dm_lhk3
rename cf12e086 dm_lhk4
rename cf12e087 dm_lhk5
rename cf12e088 dm_lhk6
rename cf12e089 dm_lhk7
rename cf12e090 dm_lhk8
rename cf12e091 dm_lhk9
rename cf12e092 dm_lhk10
rename cf12e093 dm_lhk11
rename cf12e094 dm_lhk12
rename cf12e095 dm_lhk13
rename cf12e096 dm_lhk14
rename cf12e097 dm_lhk15
rename cf12e164 l_lpubfreq
rename cf12e187 h_hdivfood
rename cf12e188 h_hdivlaundry
rename cf12e189 h_hdivclean
rename cf12e190 h_hdivodd
rename cf12e191 h_hdivfinanc
rename cf12e192 h_hdivgrocery
rename cf12e198 h_hdivplayk
rename cf12e199 h_hdivdrivek
rename cf12e200 h_hdivtalkk
rename cf12e201 h_hdivgooutk
rename cf12e238 k_nursery04
rename cf12e239 k_daycare04
rename cf12e240 k_bfschlcare04
rename cf12e241 k_afschlcare04
rename cf12e242 k_hostparent04
rename cf12e243 k_pdsitteraw04
rename cf12e244 k_pdsitterhm04
rename cf12e245 k_unpdsitter04
rename cf12e246 k_othercare04
rename cf12e247 k_nocare04
rename cf12e248 k_whositter04
rename cf12e249 k_ptdays04
rename cf12e250 k_whours04
gen c_ccare04 = .
rename cf12e252 k_schl1
rename cf12e253 k_schl2
rename cf12e254 k_schl3
rename cf12e255 k_schl4
rename cf12e256 k_schl5
rename cf12e257 k_schl6
rename cf12e258 k_schl7
rename cf12e259 k_schl8
rename cf12e260 k_schl9
rename cf12e261 k_schl10
rename cf12e262 k_schl11
rename cf12e263 k_schl12
rename cf12e264 k_schl13
rename cf12e265 k_schl14
rename cf12e266 k_schl15
rename cf12e327 k_bfschlcare95
rename cf12e328 k_afschlcare95
rename cf12e329 k_bwschlcare95
rename cf12e330 k_hostparent95
rename cf12e331 k_pdsitteraw95
rename cf12e332 k_pdsitterhm95
rename cf12e333 k_unpdsitter95
rename cf12e334 k_othercare95
rename cf12e335 k_nocare95
rename cf12e336 k_whositter95
rename cf12e337 k_ptdays95
rename cf12e338 k_whours95
gen c_ccare95 = .
gen c_ccare = .
gen y_ccsubsamt = .
rename cf12e386 y_ccsuppt
gen y_ccsuppamt = .
rename cw12e001 w_paidwork
rename cw12e121 w_empltype
rename cw12e127 w_hrs6
rename cw12e136 w_comumins6
rename cw12e138 w_irregulreq
rename cw12e139 w_evenings
rename cw12e140 w_nights
rename cw12e141 w_wkends
rename cw12e142 w_home
rename cw12e143 w_2ndjob
rename cw12e144 w_2ndjobwhrs
rename cw12e402 w_sector
rename cw12e404 w_occupation
rename cw12e405 w_firstoccu
rename cw12e425 w_irregulcho
rename cw12e446 w_hrstension
rename bf12c003 c_krespondent
rename bf12c005 w_whrs
rename bf12c006 w_wmins
rename bf12c007 w_comuhrs
rename bf12c008 w_comumins
rename bf12c009 h_chorshrs
rename bf12c010 h_chorsmins
rename bf12c011 h_pcarehrs
rename bf12c012 h_pcaremins
rename bf12c013 h_wkidshrs
rename bf12c014 h_wkidsmins
rename bf12c015 h_wparshrs
rename bf12c016 h_wparsmins
rename bf12c017 h_wfamhrs
rename bf12c018 h_wfammins
rename bf12c019 h_wothrshrs
rename bf12c020 h_wothrsmins
rename bf12c021 l_lhrs
rename bf12c022 l_lmins
rename bf12c023 h_schlhrs
rename bf12c024 h_schlmins
rename bf12c025 h_adminhrs
rename bf12c026 h_adminmins
rename bf12c027 h_sleephrs
rename bf12c028 h_sleepmins
rename bf12c029 h_otherhrs
rename bf12c030 h_othermins
rename bf12c064 l_lpubhrs
rename bf12c065 l_lpubmins
rename bf12c066 c_mortg
rename bf12c067 c_rent
rename bf12c068 c_utils
rename bf12c069 c_trnsprt
rename bf12c070 c_insur
rename bf12c071 c_dcare
rename bf12c072 c_alimony
rename bf12c073 c_loans
rename bf12c074 c_holiday
rename bf12c075 c_maintain
rename bf12c076 c_foodin
rename bf12c077 c_hhother
rename bf12c091 c_myfoodin
rename bf12c092 c_yrfoodin
rename bf12c093 c_kdfoodin
rename bf12c094 c_otfoodin
rename bf12c095 c_foodout
rename bf12c096 c_tobacco
rename bf12c097 c_clothes
rename bf12c098 c_pcare
rename bf12c099 c_medical
rename bf12c100 c_leisure
rename bf12c101 c_schl
rename bf12c102 c_gifts
rename bf12c103 c_other
rename bf12c105 c_kfoodout
rename bf12c106 c_ktobacco
rename bf12c107 c_kclothes
rename bf12c108 c_kpcare
rename bf12c109 c_kmedical
rename bf12c110 c_kleisure
rename bf12c111 c_kschl
rename bf12c112 c_kgifts
rename bf12c113 c_kother
rename bf12c118 dm_commit

*	Assemble two-spouse opposite-sex households in four steps:
*	1. Drop very few households who report in Core Study 5 (collected in March) 
*	that they don't have a partner even though the background variables (hbox) 
*	don't reflect this. Drop those who don't live with their partner:
drop if dm_haspartner!=1
drop dm_haspartner
drop if dm_livewpartner!=1
drop dm_livewpartner
*	2. Measure how many observations we have per household; drop if != 2. These
*  	are households where one spouse failed to complete at least one of the three
*	core studies required for completeness of our data:
by nohouse_encr : egen numobs = count(year)
drop if numobs!=2
drop numobs
*	3. Request couples to consist of individuals of different gender:
by nohouse_encr : egen sexes = sum(dm_gender)
drop if sexes!=3	/* 3 == male (1) + female (2) */
drop sexes
*	4. Drop few (if any) households where both spouses appear as household head:
gen head=dm_position==1
by nohouse_encr : egen heads=sum(head)
drop if heads!=1
drop head*

*	Restructure data so that now one observation refers to one household with 
*	information for both spouses:
gen spouse = "H" if dm_gender==1
replace spouse = "W" if dm_gender==2
drop dm_gender
foreach v of var dm_* l_* h_* w_* c_* k_* y_* { 
	local l`v'H : variable label `v' 
	local l`v'W : variable label `v'
}
reshape wide nomem_encr dm_* l_* h_* w_* c_* k_* y_*, i(nohouse_encr year) j(spouse) string
order nohouse_encr year nomem_encr* dm_* y_* w_* l_* h_* k_* c_*
drop dm_position*
foreach v of var dm_* y_* w_* l_* h_* k_* c_* { 
	label variable `v' "`l`v''"
}

* 	Save household dataset for year 2012:
qui compress
save "$DATAdir/2012.dta", replace
erase "$DATAdir/2012_5.dta"
erase "$DATAdir/2012_6.dta"
erase "$DATAdir/2012_34.dta"


/*******************************************************************************
Data from 2013 wave (used only with time diary data)
*******************************************************************************/

*	Use 'Core Study 5: Family and Household':
qui use "$RAWDATAdir/Raw2013_5.dta", clear
#delimit;
keep nomem_encr
	cf13f024 cf13f402 cf13f025 cf13f030 cf13f037 cf13f038 cf13f039 cf13f040 
	cf13f041 cf13f042 cf13f043 cf13f044 cf13f045 cf13f046 cf13f047 cf13f048 
	cf13f049 cf13f050 cf13f051 cf13f052 cf13f068 cf13f069 cf13f070 cf13f071 
	cf13f072 cf13f073 cf13f074 cf13f075 cf13f076 cf13f077 cf13f078 cf13f079 
	cf13f080 cf13f081 cf13f082 cf13f083 cf13f084 cf13f085 cf13f086 cf13f087 
	cf13f088 cf13f089 cf13f090 cf13f091 cf13f092 cf13f093 cf13f094 cf13f095 
	cf13f096 cf13f097 ;
#delimit cr
foreach var of varlist cf* {
   local varlabel : variable label `var'
   label variable `var' "(5) `varlabel'"
}
save "$DATAdir/2013_5.dta", replace

*	Use 'Core Study 6: Work and Schooling':
qui use "$RAWDATAdir/Raw2013_6.dta", clear
#delimit;
keep nomem_encr
	cw13f127 cw13f143 cw13f144 ;
#delimit cr
foreach var of varlist cw* {
   local varlabel : variable label `var'
   label variable `var' "(6) `varlabel'"
}
save "$DATAdir/2013_6.dta", replace

* 	Merge information by individual/household across studies in 2013:
*	Note: not all individuals participate in both 2 core studies. We naturally 
*	drop these people because information on them is incomplete (_merge==1/2).
use "$DATAdir/2013_5.dta", clear
merge 1:1 nomem_encr using "$DATAdir/2013_6.dta"
drop if _merge!=3
drop _merge

*	Check that there are no duplicate person in the merged dataset:
duplicates tag nomem_encr, gen(dupltag)
sum dupltag
if r(mean)!=0 {
	error
}
drop dupltag

*	Generate year variable:
gen year=2013

* 	Merge with data from household box:
*	Note: those not merged from 'master' are people previously dropped from
*	household box (eg. mainly children). Those not merged from 'using' either
*	don't appear in 'master' because of non-response in one of the studies or
*	because they only appear in other years.
merge 1:1 nomem_encr year using "$DATAdir/hbox2009_2017_$today.dta"
drop if _merge!=3
drop _merge
order nomem_encr nohouse_encr year
sort nohouse_encr nomem_encr year

*	(Re)name variables:
*	The rule for the first letters of a variable name is as follows:
*		- dm_ : denotes 'demographics' variables
*		- w_  : denotes 'work' and work related variables
*		- y_  : denotes 'income' and income related variables
*		- l_  : denotes 'leisure' and leisure related variables
*		- h_  : denotes 'household work' and chores related variables
*		- k_  : denotes 'kids' and variables relating to kids activities
*		- c_  : denotes 'consumption' and expenditure related variables
*	All variable labels contain '(##)' to indicate the LISS core or assembled 
*	study that they are extracted from.
rename cf13f024 dm_haspartner
rename cf13f402 dm_samepartner
rename cf13f025 dm_livewpartner
rename cf13f030 dm_marriedwpartner
rename cf13f037 dm_ybk1
rename cf13f038 dm_ybk2
rename cf13f039 dm_ybk3
rename cf13f040 dm_ybk4
rename cf13f041 dm_ybk5
rename cf13f042 dm_ybk6
rename cf13f043 dm_ybk7
rename cf13f044 dm_ybk8
rename cf13f045 dm_ybk9
rename cf13f046 dm_ybk10
rename cf13f047 dm_ybk11
rename cf13f048 dm_ybk12
rename cf13f049 dm_ybk13
rename cf13f050 dm_ybk14
rename cf13f051 dm_ybk15
rename cf13f052 dm_allkalive
rename cf13f068 dm_gk1
rename cf13f069 dm_gk2
rename cf13f070 dm_gk3
rename cf13f071 dm_gk4
rename cf13f072 dm_gk5
rename cf13f073 dm_gk6
rename cf13f074 dm_gk7
rename cf13f075 dm_gk8
rename cf13f076 dm_gk9
rename cf13f077 dm_gk10
rename cf13f078 dm_gk11
rename cf13f079 dm_gk12
rename cf13f080 dm_gk13
rename cf13f081 dm_gk14
rename cf13f082 dm_gk15
rename cf13f083 dm_lhk1
rename cf13f084 dm_lhk2
rename cf13f085 dm_lhk3
rename cf13f086 dm_lhk4
rename cf13f087 dm_lhk5
rename cf13f088 dm_lhk6
rename cf13f089 dm_lhk7
rename cf13f090 dm_lhk8
rename cf13f091 dm_lhk9
rename cf13f092 dm_lhk10
rename cf13f093 dm_lhk11
rename cf13f094 dm_lhk12
rename cf13f095 dm_lhk13
rename cf13f096 dm_lhk14
rename cf13f097 dm_lhk15
rename cw13f127 w_hrs6
rename cw13f143 w_2ndjob
rename cw13f144 w_2ndjobwhrs

*	Assemble two-spouse opposite-sex households in four steps:
*	1. Drop very few households who report in Core Study 5 (collected in March) 
*	that they don't have a partner even though the background variables (hbox) 
*	don't reflect this. Drop those who don't live with their partner:
drop if dm_haspartner!=1
drop dm_haspartner
drop if dm_livewpartner!=1
drop dm_livewpartner
*	2. Measure how many observations we have per household; drop if != 2. These
*  	are households where one spouse failed to complete at least one of the three
*	core studies required for completeness of our data:
by nohouse_encr : egen numobs = count(year)
drop if numobs!=2
drop numobs
*	3. Request couples to consist of individuals of different gender:
by nohouse_encr : egen sexes = sum(dm_gender)
drop if sexes!=3	/* 3 == male (1) + female (2) */
drop sexes
*	4. Drop few (if any) households where both spouses appear as household head:
gen head=dm_position==1
by nohouse_encr : egen heads=sum(head)
drop if heads!=1
drop head*

*	Restructure data so that now one observation refers to one household with 
*	information for both spouses:
gen spouse = "H" if dm_gender==1
replace spouse = "W" if dm_gender==2
drop dm_gender
foreach v of var dm_* w_* y_* { 
	local l`v'H : variable label `v' 
	local l`v'W : variable label `v'
}
reshape wide nomem_encr dm_* w_* y_*, i(nohouse_encr year) j(spouse) string
order nohouse_encr year nomem_encr* dm_* y_* w_* 
drop dm_position*
foreach v of var dm_* y_* w_* { 
	label variable `v' "`l`v''"
}

* 	Save household dataset for year 2013:
qui compress
save "$DATAdir/2013_$today.dta", replace
erase "$DATAdir/2013_5.dta"
erase "$DATAdir/2013_6.dta"


/*******************************************************************************
Append yearly data for main use (excluding 2013 data)
*******************************************************************************/

use "$DATAdir/2009.dta", clear
append using "$DATAdir/2010.dta" "$DATAdir/2012.dta"
sort nohouse_encr year

* 	Confirm that households consists of same two spouses over time. Otherwise 
*	update household identifier to reflect new household:
gen newH = 0
by nohouse_encr : egen minyr = min(year)
replace newH = newH[_n-1]+1 if nomem_encrH!=nomem_encrH[_n-1] & year!=minyr
replace nohouse_encr = nohouse_encr+0.1*newH
drop newH minyr
sort nohouse_encr year
gen newW = 0
by nohouse_encr : egen minyr = min(year)
replace newW = newW[_n-1]+1 if nomem_encrW!=nomem_encrW[_n-1] & year!=minyr
replace nohouse_encr = nohouse_encr+0.01*newW
drop newW minyr
sort nohouse_encr year

*	No family has more than 7 children. Drop variables for child #8 and above:
#delimit;
drop dm_ybk8H-dm_ybk15H dm_ybk8W-dm_ybk15W dm_gk8H-dm_gk15H dm_gk8W-dm_gk15W 
     dm_lhk8H-dm_lhk15H dm_lhk8W-dm_lhk15W k_schl8H-k_schl15H k_schl8W-k_schl15W ;
#delimit cr

*	Save data:
qui compress
save "$DATAdir/panel_all_$today.dta", replace
erase "$DATAdir/2009.dta"
erase "$DATAdir/2010.dta"
erase "$DATAdir/2012.dta"
erase "$DATAdir/hbox2009_2017_$today.dta"

*** end of do file ***
