# Togetherness in the Household
This repository contains the code that allows the replication of my paper **Togetherness in the Household**, forthcoming at _AEJ-Micro_. The paper is coauthored with [Sam Cosaert](https://www.sites.google.com/site/samlcosaert/home) and Bertrand Verheyden.

**Togetherness in the Household** develops a collective household model with private and joint uses of time. In this model, the _timing_ of a family member's market work matters for how much time the members can spend jointly and together with one another (what we call _togetherness_). 

The paper uses time use and consumption data in the Dutch [Longitudinal Internet studies for the Social Sciences](https://www.lissdata.nl/Home) (LISS) to:
* quantify the benefits and costs of togetherness between spouses;
* understand how togetherness interacts with other time uses.

Apart from the purpose of **replicating** the paper, this code can also be used by researchers who want to operationalise the time use and consumption data in the **LISS** in years 2009-2012. 

The code may also be useful to people who want to use **revealed preferences** to estimate (bounds on) parameters of interest in a variety of settings; our code shows how this can be done through developing and implementing a **mixed integer linear program**. 

The journal website of the paper is: [AEJ-Micro website](https://www.aeaweb.org/articles?id=10.1257/mic.20200220).


-------

# Replication package details

## 1. Data sources

The main data we use come from the Dutch Longitudinal Study for the Social Sciences. Public access to the data is possible after signing a statement of use on [www.dataarchive.lissdata.nl](https://www.dataarchive.lissdata.nl). Upon receipt of the signed statement, the user will re-ceive a password enabling them to download the data. Please allow up to five working days for the LISS to process the request and create the account.

The LISS consists of several modules, each one covering a given topic. The empirical analysis in the paper combines data from the following four modules:

1. _1 Background Variables_, previously called Household Box

The background variables are available on a monthly basis. To replicate our analysis, the user must download all monthly instances from November 2007 until June 2017. This is a total of 116 files, named consecutively as follows:

```
English 2007 November     avars_200711_EN_3.0p.zip
English 2007 December     avars_200712_EN_2.0p.zip
English 2008 January      avars_200801_EN_2.0p.zip
English 2008 February     avars_200802_EN_3.0p.zip
...
English 2017 March        avars_201703_EN_1.0p.zip
English 2017 April        avars_201704_EN_1.0p.zip
English 2017 May          avars_201705_EN_1.0p.zip
English 2017 June         avars_201706_EN_1.0p.zip
```

The user must uncompress the ```zip``` files and retain the ```STATA``` counterpart of each one of them, that is, the ```.dta``` file that otherwise shares the same name as the ```zip``` download.

2. _Core Study 5 Family and Household_

The family and household variables are available on a yearly basis. To replicate our analysis, the user must download waves 2 (for calendar year 2009), 3 (for 2010), 5 (for 2012), and 6 (for 2013) in ```STATA``` format. This is a total of 4 files, named as follows:

```
English STATA file     cf09b_EN_2.2p.dta
English STATA file     cf10c_EN_1.0p.dta
English STATA file     cf12e_EN_2.1p.dta
English STATA file     cf13f_EN_1.1p.dta
```

3. _Core Study 6 Work and Schooling_

The work and schooling variables are available on a yearly basis. To replicate our analysis, the user must download waves 2 (for calendar year 2009), 3 (for 2010), 5 (for 2012), and 6 (for 2013) in ```STATA``` format. This is a total of 4 files, named as follows:

```
English STATA file     cw09b_EN_3.0p.dta
English STATA file     cw10c_EN_1.0p.dta
English STATA file     cw12e_EN_1.0p.dta
English STATA file     cw13f_EN_1.0p.dta
```

4. _Assembled Study 34 Time Use and Consumption_

The time use and consumption variables are available intermittently on an annual basis. To replicate our analysis, the user must download waves 1 (for calendar year 2009), 2 (for 2010), and 3 (for 2012) in ```STATA``` format. This is a total of 3 files, named as follows:

```
English STATA file     bf09a_EN_1.0p.dta
English STATA file     bf10b_EN_1.1p.dta
English STATA file     bf12c_EN_1.0p.dta
```

In addition to the four modules above, Section A.2 of the online appendix makes reference to a small time diary conducted by LISS in year 2013. This is officially _Assembled Study 122 Time Use Study_. To replicate the statements made in that section, the user must download the mobile app part of the time diary, formally study _2 Working with the TBO LISS app_. This is a total of 1 file, named as follows:

```
Dutch STATA file (in Dutch)    ht13a_NL_2.0p.dta
```

## 2. Contents of replication package

The replication package has two parts, one for data management & preparation and another one for the revealed preferences analysis.

### Data management & preparation

The following files operationalize the LISS consumption and time use data:
```
**item name**                              **type**     **directory**
CTV_01_Shell.do                            code         ./Code
CTV_02_HouseholdBox.do                     code         ./Code
CTV_03_YearlyData.do                       code         ./Code
CTV_04_VarsAndSelection.do                 code         ./Code
CTV_05_Childful.do                         code         ./Code
CTV_06_Childless.do                        code         ./Code
CTV_07_Export.do                           code         ./Code
CTV_08_Childful_AllWorkNonwork.do          code         ./Code
CTV_09_Time_Diary.do                       code         ./Code
CTV_10_Descriptives.do                     code         ./Code
LISS_Time_Diary_Aggregation.R              code         ./Code
panel_all_AEJ_Accepted.dta                 data         ./Data
2013_AEJ_Accepted.dta                      data         ./Data
Dutch_CPI_March2019.csv                    data         ./Data
Day1_processed.csv                         data         ./Data/LISS_Time_Use
Day2_processed.csv                         data         ./Data/LISS_Time_Use
Day3_processed.csv                         data         ./Data/LISS_Time_Use
Exports                                    folder       ./
```

The content of these files is as follows:

* ```CTV_01_Shell.do``` calls all other ```do``` files sequentially. To do so, it first sets the computer directories, defines global variables, and downloads necessary packages from the Internet.

* ```CTV_02_HouseholdBox.do``` and ```CTV_03_YearlyData.do``` extract the LISS data. The first script uses the LISS background variables (household box) in 2007-2017, selects demographic and income variables, implements some baseline sample selection, and collapses the data to one record by individual per year. The second script uses yearly data from the various Core and Assembled modules (the modules are where most LISS variables are kept), keeps a subset of variables per year, merges information across these modules and the household box, performs a baseline sample selection, and appends the yearly data in 2009, 2010, and 2012, to construct the panel data in ```panel_all_AEJ_Accepted.dta```. To run these two scripts, researchers need access to the raw LISS data listed in section 1 above. We do not include the raw data files but we provide ```panel_all_AEJ_Accepted.dta``` as part of the replication package, so researchers can skip these two scripts and run the code from ```CTV_04_VarsAndSelection.do``` onward.

* ```CTV_04_VarsAndSelection.do``` carries out sample selection and constructs new variables. Specifically, the script selects households on the basis of consistency of supplied information, age of parents and children, consumption, and market participation. It constructs new variables for hourly wages, market hours, household time use, and it creates separate samples for families with children whose parents participate in the labor market (the basis for our baseline sample), families with children regardless the labor market status of parents, and childless families.

* ```CTV_05_Childful.do``` and ```CTV_06_Childless.do``` carry out the final sample selection and variable harmonization in the sample of families with children whose parents participate in the labor market (our baseline sample) and the sample of childless families respectively.

* ```CTV_07_Export.do``` generates homogeneous groups of households within our baseline sample, in the sample of childless families, and in various subsamples used in our robustness analysis. It then exports the data in appropriate form for the revealed preferences analysis. The script requires consumer price index data from Statistics Netherlands, which we provide as part of the replication package in ```Dutch_CPI_March2019.csv```.

* ```CTV_08_Childful_AllWorkNonwork.do``` carries out sample selection in the sample of families with children whose parents may or may not participate in the labor market. This sample appears in the discussion in our online appendix A.2.

* ```CTV_09_Time_Diary.do``` summarizes the small time diary available in the LISS, formally _Assembled Study 122 Time Use Study_. The script matches the time diary data in 2013 with the yearly survey data in ```2013_AEJ_Accepted.dta```, which we provide as part of the replicationpackage. It implements a sample selection similar to our baseline sample and calculates time diary moments that appear in the discussion in online appendix A.2. The script uses the processed time diary data in ```Day1_processed.csv```, ```Day2_processed.csv```, and ```Day3_processed.csv```. Processing of the time diary data takes place in ```LISS_Time_Diary_Aggregation.R```, using the raw _Assembled Study 122 Time Use Study_ data mentioned in section 1 above. We provide the processed time diary data files as part of the replication package (the ```csv``` files mentioned just above), so researchers can skip ```LISS_Time_Diary_Aggregation.R``` (which requires software ```R```) and run ```CTV_09_Time_Diary.do``` seamlessly.

* ```CTV_10_Descriptives.do``` produces most figures and tables in the text, and exports them in folder Exports. This file runs only _after_ the revealed preferences analysis is complete, as I explain further in the instructions subsequently.


### Revealed preferences analysis

The following scripts carry out the revealed preferences analysis:
```
**item name**                              **type**     **directory**
Run_All.m                                  code         ./Code
Run_Passrates.m                            code         ./Code/RP
Run_Power.m                                code         ./Code/RP
Run_Value.m                                code         ./Code/RP
Run_Shares.m                               code         ./Code/RP
Run_Bounds.m                               code         ./Code/RP
Run_BoundsAppendix.m                       code         ./Code/RP
Run_Gap.m                                  code         ./Code/RP
togetherness.m                             code         ./Code/RP
togetherness_measurement.m                 code         ./Code/RP
togetherness_egoistic.m                    code         ./Code/RP
togetherness_sharing.m                     code         ./Code/RP
togetherness_bounds_main.m                 code         ./Code/RP
togetherness_bounds_appendix.m             code         ./Code/RP
```

The content of these files is as follows:

* ```Run_All.m``` calls all other ```MATLAB``` scripts and functions, generating and exporting the revealed preferences results. Results in the paper are based on ```MATLAB 2020a```.

* ```Run_Passrates.m``` computes the pass rates, i.e., the fraction of households and groups consistent with A-CR, CR, and T-CR. Input ```atype``` sets the type of analysis (baseline ```= 0```, with commuting ```= 1```, with overlap ```= 2``` or ```= 3```, with alternative definition of irregular work ```= 4```, with measurement error ```= 5```).

* ```Run_Power.m``` computes the discriminatory power for all groups (```atype``` sets the type of analysis as above). It first simulates 100 random data sets per group of households and then checks consistency of the random data with CR and T-CR.

* ```Run_Value.m``` computes the value of togetherness (```atype``` sets the type of analysis as above).

* ```Run_Shares.m``` computes lower and upper bounds on male resource shares consistent with the revealed preference conditions of T-CR.

* ```Run_Bounds.m``` computes lower and upper bounds on the average proportion of joint childcare.

* ```Run_BoundsAppendix.m``` minimizes variation in the proportion of joint childcare across households in the same group. It then computes lower and upper bounds on the average proportion of joint childcare consistent with this minimal variation. The function finally reports bounds on joint childcare in the households consistent with T-CR as well as naive bounds (between 0 and the smallest of two individual total childcare variables).

* ```Run_Gap.m``` computes the cost of forgone flexibility (the smallest possible wage premium consistent with T-CR) keeping the cost of forgone specialization at zero. It also generates an indicator for who in the household forgoes this flexibility (men or women).

* ```togetherness.m``` formulates the **mixed integer linear program** to test consistency with T-CR. It writes the revealed preference inequalities and equalities in matrix format, and finally calls the ```intlinprog``` solver.

* ```togetherness_measurement.m``` formulates the mixed integer linear program to test consistency with T-CR with measurement error. It writes the revealed preference inequalities and equalities in matrix format, and finally calls the ```intlinprog``` solver.

* ```togetherness_egoistic.m``` formulates the mixed integer linear program to test consistency with a collective model in which all consumption and time use is purely private. It writes the revealed preference inequalities in matrix format and calls ```intlinprog```.

* ```togetherness_sharing.m``` formulates the mixed integer linear program to recover male resource shares consistent with T-CR. It writes the revealed preference inequalities and equalities in matrix format, adds an objective function to find the smallest/largest possible male resource share, and finally calls ```intlinprog```.

* ```togetherness_bounds_main.m``` formulates the mixed integer linear program to recover lower or upper bounds on the average proportion of joint childcare. It writes the revealed preference inequalities and equalities in matrix format, adds an objective function to find the smallest/largest average fraction of joint childcare, and calls ```intlinprog```.

* ```togetherness_bounds_appendix.m``` formulates the mixed integer linear program to recover (a) the minimum variation in the proportion of joint childcare among households consistent with T-CR, and (b) bounds on the average proportion of joint childcare subject to the minimum variation found in (a). It writes the revealed preference inequalities and equalities in matrix format, adds an objective function to minimize variation in joint childcare or to minimize/maximize the average fraction of joint childcare, and finally calls the ```intlinprog``` solver.

## 3. Replication instructions

To run the code, download the replication folder to your computer and update the directories within ```CTV_01_Shell.do``` and ```Run_All.m``` to reflect this folder. Then:

1. Run ```CTV_01_Shell.do```. This will call all other data management & preparation scripts on ```STATA```. To run this script, users need access to the raw LISS data listed in section 1 above. Public access to the data is possible after creating an account and signing the appropriate statement on [www.dataarchive.lissdata.nl](https://www.dataarchive.lissdata.nl). Without access to the raw data, comment out the call to ```CTV_02_HouseholdBox.do``` and ```CTV_03_YearlyData.do``` within ```CTV_01_Shell.do```, and run the code from ```CTV_04_VarsAndSelection.do``` onward. This requires the assembled data ```panel_all_AEJ_Accepted.dta```, which we provide in the replication package. Users who want to use the raw LISS data should do the following: (1.) download all files mentioned in section 1 of this note; (2.) rename certain files as follows, and (3.) save all files in a folder of their choice and update the path to this folder in ```RAWDATAdir``` at the beginning of ```CTV_01_Shell.do```. Users who want to also use the raw LISS time diary mentioned in the online appendix should additionally do the following: (4.) open ```ht13a_NL_2.0p.dta``` and export it in ```csv``` format with name ```LISS_TimeUse2013.csv;``` (5.) update the path to this file at the top of ```LISS_Time_Diary_Aggregation.R```.
```
**old name**              **new name**
cf09b_EN_2.2p.dta         Raw2009_5.dta
cf10c_EN_1.0p.dta         Raw2010_5.dta
cf12e_EN_2.1p.dta         Raw2012_5.dta
cf13f_EN_1.1p.dta         Raw2013_5.dta
cw09b_EN_3.0p.dta         Raw2009_6.dta
cw10c_EN_1.0p.dta         Raw2010_6.dta
cw12e_EN_1.0p.dta         Raw2012_6.dta
cw13f_EN_1.0p.dta         Raw2013_6.dta
bf09a_EN_1.0p.dta         Raw2009_34.dta
bf10b_EN_1.1p.dta         Raw2010_34.dta
bf12c_EN_1.0p.dta         Raw2012_34.dta
```

2. The last STATA script called by ```CTV_01_Shell.do``` is ```CTV_10_Descriptives.do```. This script will stop with an error as it requires inputs produced in the revealed preferences analysis. As soon as this error occurs, please do not quit ```STATA``` but move on to ```MATLAB``` and run ```Run_All.m```. This calls all other ```MATLAB``` scripts and functions, generating and exporting a number of revealed preferences results, including main text tables 6, 7, 8, 9, and online appendix tables C.1 and D.1. All final exports are saved in folder ```Exports```, while several intermediate files are saved in folder ```Data```. Script ```Run_All.m``` will typically take about half a day to run, depending on the user’s computer specifications.
 
3. As soon as ```Run_All.m``` completes, move back to ```STATA``` and run ```CTV_10_Descriptives.do``` (if the user has quit ```STATA``` in the meantime, they can run ```CTV_01_Shell.do``` again; this will not interfere with the revealed preferences results). ```CTV_10_Descriptives.do``` produces all other tables and figures, namely main text tables 1, 2, 5, online appendix tables A.1-A.2, main text figures 1-9, and online appendix figures C.1 and D.1. Two final tables, appendix tables A.3-A.4, concern the sample of families with children whose parents may or may not participate in the market; these are previously generated in ```CTV_08_Childful_AllWorkNonwork.do```. All tables and figures are saved in folder ```Exports```.
