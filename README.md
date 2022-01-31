# Togetherness in the Household
This repository contains the code that allows the replication of my paper **Togetherness in the Household**, forthcoming at _AEJ-Micro_. The paper is coauthored with [Sam Cosaert](https://www.sites.google.com/site/samlcosaert/home) and Bertrand Verheyden.

**Togetherness in the Household** develops a collective household model with private and joint uses of time. In this model, the _timing_ of a family member's market work matters for how much time the members can spend jointly and together with one another (what we call _togetherness_). The paper uses time use and consumption data in the Dutch [Longitudinal Internet studies for the Social Sciences](https://www.lissdata.nl/Home) (LISS) to:
* quantify the benefits and costs of togetherness between spouses;
* understand how togetherness interacts with other time uses.

Apart from the purpose of **replicating** the paper, this code may also be useful to researchers who want to operationalise the time use and consumption data in the **LISS** in years 2009-2012. 

The code may also be useful to people who want to use **revealed preferences** to estimate (bounds on) parameters of interest in a variety of settings; our code shows how this can be done through developing and implementing a **mixed integer linear program**. 

The journal website of the paper is: [AEJ-Micro website](https://www.aeaweb.org/articles?id=10.1257/mic.20200220).

# Replication package details

The replication package has two parts, one for data management & preparation and another one for the revealed preferences analysis. We first give a short description of what each code/script does. Then, we give instructions for how to run the code using ```STATA``` and ```MATLAB``` (both programs are needed).

## Data management & preparation

The following files operationalize the LISS consumption and time use data:

* ```CTV_01_Shell.do``` calls all other do files sequentially. To do so, it first sets the computer directories, defines global variables, and downloads necessary packages from the Internet.

* ```CTV_02_HouseholdBox.do``` and ```CTV_03_YearlyData.do``` extract the LISS data. The first script uses data from the LISS household box in 2007-2017, selects demographic and income background variables, implements some baseline sample selection, and collapses the data to one record by individual per year. The second script uses yearly data from several LISS Core and Assembled modules (the modules are where most LISS variables are kept), keeps a subset of variables per year, merges information across these modules and the household box, performs a baseline sample selection, and appends the yearly data in 2009, 2010, and 2012, to construct the panel data in ```panel_all_AEJ_Accepted.dta```. To run these two scripts, researchers need access to the raw LISS data. We do not include the raw data files as part of this repository but public access is possible after creating an account and signing the appropriate agreement on https://www.dataarchive.lissdata.nl. We provide ```panel_all_AEJ_Accepted.dta``` as part of the replication package, so researchers can skip these two scripts and run the code from ```CTV_04_VarsAndSelection.do``` onward.

* ```CTV_04_VarsAndSelection.do``` carries out sample selection and constructs new variables. Specifically, the script selects households on the basis of consistency of supplied information, age of parents and children, consumption, and market participation. It constructs new variables for hourly wages, market hours, household time use, and it creates separate samples for families with children whose parents participate in the labor market (the basis for our baseline sample), families with children regardless the labor market status of parents, and childless families.

* ```CTV_05_Childful.do``` and ```CTV_06_Childless.do``` carry out the final sample selection and variable harmonization in the sample of families with children whose parents participate in the labor market (our baseline sample) and the sample of childless families respectively.

* ```CTV_07_Export.do``` generates homogeneous groups of households within our baseline sample, in the sample of childless families, and in various subsamples used in our robustness analysis. It then exports the data in appropriate form for the revealed preferences analysis. The script requires consumer price index data from Statistics Netherlands, which we provide as part of the replication package in ```Dutch_CPI_March2019.csv```.

* ```CTV_08_Childful_AllWorkNonwork.do``` carries out sample selection in the sample of families with children whose parents may or may not participate in the labor market. This sample appears in the discussion in our online appendix A.2.

* ```CTV_09_Time_Diary.do``` summarizes the small time diary available in the LISS, formally Time Diary module 122. The script matches the time diary data in 2013 with the yearly survey data in ```2013_AEJ_Accepted.dta```, which we provide as part of the replication package. It implements a sample selection similar to our baseline sample and calculates time diary moments that appear in the discussion in our online appendix A.2. The script uses the processed time diary data in ```Day1_processed.csv```, ```Day2_processed.csv```, and ```Day3_processed.csv```. Processing of the time diary data takes place in ```LISS_Time_Diary_Aggregation.R```, using the raw LISS time diary subject to the rules of accessing the data above. We provide the processed time diary data files as part of the replication package (the ```csv``` files mentioned above), so researchers can skip ```LISS_Time_Diary_Aggregation.R``` (which requires software ```R```) and run ```CTV_09_Time_Diary.do``` seamlessly.

* ```CTV_10_Descriptives.do``` produces most figures and tables in the text, and exports them in folder Exports. This file runs only _after_ the revealed preferences analysis is complete, as I explain further in the instructions subsequently.


## Revealed preferences analysis

The following scripts carry out the revealed preferences analysis:

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

## Instructions to users

To run the code, download the replication folder to your computer and update the directories within ```CTV_01_Shell.do``` and ```Run_All.m``` to reflect this folder. Then:

1. Run ```CTV_01_Shell.do```. This will call all other data management & preparation scripts on ```STATA```. To run this script, access to the raw LISS data is needed. Public access to the data is possible after creating an account and signing the appropriate agreement on https://www.dataarchive.lissdata.nl. Without access to the raw data, comment out the call to ```CTV_02_HouseholdBox.do``` and ```CTV_03_YearlyData.do``` within ```CTV_01_Shell.do```, and run the code from ```CTV_04_VarsAndSelection.do``` onward. This requires the assembled data ```panel_all_AEJ_Accepted.dta```, which we provide in the replication package.

2. The last STATA script called by ```CTV_01_Shell.do``` is ```CTV_10_Descriptives.do```. This script will stop with an error as it requires inputs produced in the revealed preferences analysis. As soon as this error occurs, please do not quit ```STATA``` but move on to ```MATLAB``` and run ```Run_All.m```. This calls all other ```MATLAB``` scripts and functions, generating and exporting a number of revealed preferences results, including main text tables 6, 7, 8, 9, and online appendix tables C.1 and D.1. All final exports are saved in folder ```Exports```, while several intermediate files are saved in folder ```Data```. Script ```Run_All.m``` will typically take about half a day to run, depending on the user’s computer specifications.
 
3. As soon as ```Run_All.m``` completes, move back to ```STATA``` and run ```CTV_10_Descriptives.do``` (if the user has quit ```STATA``` in the meantime, they can run ```CTV_01_Shell.do``` again; this will not interfere with the revealed preferences results). ```CTV_10_Descriptives.do``` produces all other tables and figures, namely main text tables 1, 2, 5, online appendix tables A.1-A.2, main text figures 1-9, and online appendix figures C.1 and D.1. Two final tables, appendix tables A.3-A.4, concern the sample of families with children whose parents may or may not participate in the market; these are previously generated in ```CTV_08_Childful_AllWorkNonwork.do```. All tables and figures are saved in folder ```Exports```.


**Note**: Users who want to download and use the raw LISS data should additionally do the following prior to steps 1-3 above: 

1. Download the LISS household box in ```STATA``` format covering at least years 2009-2013 and name the file ```RawAllYears_HouseholdBox.dta```. 

2. Download the yearly LISS modules 5, 6, 34 in ```STATA``` format in years 2009, 2010, 2012, name each file ```RawYYYY_X.dta``` where ```YYYY``` is 2009, 2010, 2012 respectively and ```X``` is the module number 5, 6, 34. 

3. Save all files in a folder of their choice and update the path to this folder in ```RAWDATAdir``` at the beginning of ```CTV_01_Shell.do```. 


Users who want to download and use the raw LISS time diary data should also do the following: 

4. Repeat steps ```2.``` and ```3.``` for LISS modules 5, 6 in year 2013. 

5. Download the LISS time diary module 122 in ```STATA``` format and save it as ```LISS_TimeUse2013.dta```.

6. Update the path to this file at the top of ```LISS_Time_Diary_Aggregation.R```.
