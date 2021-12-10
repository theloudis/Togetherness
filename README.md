# Togetherness
This repository contains the code that allows the replication of my paper **Togetherness in the Household**, accepted at _AEJ-Micro_ conditionally on data replication. The paper is coauthored with [Sam Cosaert](https://www.sites.google.com/site/samlcosaert/home) and Bertrand Verheyden.

**Togetherness in the Household** uses time use and consumption data in the [Dutch Longitudinal Internet studies for the Social Sciences](https://www.lissdata.nl/Home) (LISS) to:
* quantify the benefits and costs of togetherness (time spent jointly and together) between spouses;
* understand how togetherness interacts with other time uses, such as the amount and timing of market work.

Apart from the purpose of **replicating** the paper, this code may also be useful to researchers who want to operationalise the time use and consumption data in the **LISS** in years 2009-2012. It may also be useful to people who want to use **revealed preferences** to estimate (bounds on) parameters of interest in a variety of settings; our code shows how this can be done in practice. 

The journal website of the paper is: TBD when cleared for publication.

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
