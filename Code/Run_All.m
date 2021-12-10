%% Run RP programs for "Togetherness in the household", AEJMicro
%{
	This script runs the RP programs for "Togetherness in the household", 
    accepted at AEJMicro. Specifically it:
	- calculates the model pass rates in table 6.
	- calculates power and predictive success in table 7.
	- exports data on the distribution of predictive success in various 
      models, used in figure 6 (the figure is created by STATA 
      script CTV_10_Descriptives.do).
	- calculates the distribution of bounds of joint childcare in table 8.
    - exports data on the distribution of the value of togetherness, used 
      in figures 7 & 8 (the figures are created by STATA script 
      CTV_10_Descriptives.do).
    - calculates the male resource shares and exports data, used in
      figure 9 (figure created by STATA script CTV_10_Descriptives.do).
    - calculates the distribution of bounds of joint childcare under 
      additional restrictions, used in online appendix table C.1 and 
      figure C.1 (figure created by STATA script CTV_10_Descriptives.do).
    - produces all robustness results in table 9 and online appendix table D.1.
	_______________________________________________________________________

	Filename: 	Run_All.m
	Author: 	Sam Cosaert
	Date: 		Autumn 2021
	Paper: 		Togetherness in the Household, AEJ Micro
				Sam Cosaert and Alexandros Theloudis and Bertrand Verheyden
    _______________________________________________________________________
%}

clear;
clc;
global REPdir EXPORTSdir DATAdir CODEdir ;

%	Set path to replication package directory:
REPdir      = '/Users/atheloudis/Dropbox/Projects Finished/Published/Togetherness/Replication_Package/' ;  % <--- new users: please edit this line approproately!

%   Then we declare approproate subfolders, and we add to working path:
EXPORTSdir 	= strcat(REPdir,'Exports/') ;
DATAdir 	= strcat(REPdir,'Data/') ;
CODEdir 	= strcat(REPdir,'Code/') ;
cd(CODEdir)
addpath('RP') ;
addpath(EXPORTSdir) 
addpath(DATAdir)
addpath(CODEdir)

%   Declare filename and read:
filename = strcat(DATAdir,'dataexport_AEJ_Accepted.csv');
allvars = importdata(filename);
allvars = allvars.data ;

% Select baseline:
dataset = [100 0]; 
allvarsdata = allvars(allvars(:,1)==dataset(1,1) & allvars(:,2)==dataset(1,2),:);


%% Table 6.

[passrate,passnrgroups,passnrhhCR,passnrhhTCR,passnrhhACR,passindicator] = Run_Passrates(allvarsdata,0);

Table6 = [passrate' passnrgroups' [passnrhhCR;passnrhhTCR;passnrhhACR]];
csvwrite(strcat(EXPORTSdir,'Table6.csv'),round(Table6,2));


%% Table 7.

[powerCR,powerTCR,passCR,passTCR] = Run_Power(allvarsdata,0);

psCR = passrate(1,1)+powerCR-1;
psTCR = passrate(1,2)+powerTCR-1;
for g = 1:36
    powerCRg(g,1)=1-mean(passCR(g,:));
    powerTCRg(g,1)=1-mean(passTCR(g,:));
    psCRg(g,1)=powerCRg(g,1)+passindicator(g,1)-1;
    psTCRg(g,1)=powerTCRg(g,1)+passindicator(g,2)-1;
end

Table7 = [powerCR std(powerCRg) psCR std(psCRg);powerTCR std(powerTCRg) psTCR std(psTCRg)];
csvwrite(strcat(EXPORTSdir,'Table7.csv'),round(Table7,2));


%% Figure 6.

[fCR,xCR] = ecdf(psCRg);
[fTCR,xTCR] = ecdf(psTCRg);

cdf_CR = [xCR fCR];
dlmwrite(strcat(DATAdir,'PowerLJ.txt'),cdf_CR);

cdf_TCR = [xTCR fTCR];
dlmwrite(strcat(DATAdir,'PowerTC.txt'),cdf_TCR);


%% Table 8.

Table8 = Run_Bounds(allvarsdata);
csvwrite(strcat(EXPORTSdir,'Table8.csv'),round(Table8,2));


%% Figure 7.

[valuelJ,valuewK,valuetJ] = Run_Value(allvarsdata,0);

[ftauJ,xtauJ] = ecdf(valuelJ);
[fwk,xwk] = ecdf(valuewK);
[fcost,xcost] = ecdf(valuetJ);

cdf_tauJ = [xtauJ,ftauJ];
dlmwrite(strcat(DATAdir,'valueleisure.txt'),cdf_tauJ);

cdf_wk = [xwk,fwk];
dlmwrite(strcat(DATAdir,'pricechildcare.txt'),cdf_wk);

cdf_cost = [xcost,fcost];
dlmwrite(strcat(DATAdir,'valuechildcare.txt'),cdf_cost);


%% Figure 8.

[wfallnocell,hregindicatornocell] = Run_Gap(allvarsdata);

[fmalep,xmalep] = ecdf(wfallnocell(hregindicatornocell==0));
[ffemalep,xfemalep] = ecdf(wfallnocell(hregindicatornocell==1));

cdf_malep = [xmalep,fmalep];
dlmwrite(strcat(DATAdir,'men.txt'),cdf_malep);

cdf_femalep = [xfemalep,ffemalep];
dlmwrite(strcat(DATAdir,'women.txt'),cdf_femalep);


%% Figure 9.

Resourceshares = Run_Shares(allvarsdata);
csvwrite(strcat(DATAdir,'resourcesharing.csv'),Resourceshares);


%% Table C.1 and Figure C.1. 

[tJlb,tJub,naivelb,naiveub] = Run_BoundsAppendix(allvarsdata);
appendixbounds = [naivelb tJlb tJub naiveub];
csvwrite(strcat(DATAdir,'appendixbounds.csv'),appendixbounds);

TableC1 = [min(tJlb(tJlb<200)) min(tJub(tJub>-200)) min(naiveub(naiveub>-200));...
    prctile(tJlb(tJlb<200),25) prctile(tJub(tJub>-200),25) prctile(naiveub(naiveub>-200),25);...
    median(tJlb(tJlb<200)) median(tJub(tJub>-200)) median(naiveub(naiveub>-200));...
    mean(tJlb(tJlb<200)) mean(tJub(tJub>-200)) mean(naiveub(naiveub>-200));...
    prctile(tJlb(tJlb<200),75) prctile(tJub(tJub>-200),75) prctile(naiveub(naiveub>-200),75);...
    max(tJlb(tJlb<200)) max(tJub(tJub>-200)) max(naiveub(naiveub>-200))];
csvwrite(strcat(EXPORTSdir,'TableC1.csv'),round(TableC1,2));


%% Table 9.

dataset = [repmat([100 0],6,1);101 0];
analysistype = [0;1;2;3;4;5;0];

for datanr = 1:7
%     1: baseline
%     2: commuting
%     3: 10% overlap
%     4: 20% overlap
%     5: 66-33-0
%     6: measurement error
%     7: time budgets check

    allvarsdata = allvars(allvars(:,1)==dataset(datanr,1) & allvars(:,2)==dataset(datanr,2),:);
    atype = analysistype(datanr,1);
    
    [passrate,passnrgroups,passnrhhCR,passnrhhTCR,passnrhhACR,passindicator] = Run_Passrates(allvarsdata,atype);
    
    [powerCR,powerTCR,passCR,passTCR] = Run_Power(allvarsdata,atype);
    psCR = passrate(1,1)+powerCR-1;
    psTCR = passrate(1,2)+powerTCR-1;
    
    [valuelJ,valuewK,valuetJ] = Run_Value(allvarsdata,atype);
    valuelJ_min = min(valuelJ);
    valuelJ_q1 = prctile(valuelJ,25);
    valuelJ_median = median(valuelJ);
    valuelJ_mean = mean(valuelJ);
    valuelJ_q3 = prctile(valuelJ,75);
    valuelJ_max = max(valuelJ);
    
    valuetJ_min = min(valuetJ);
    valuetJ_q1 = prctile(valuetJ,25);
    valuetJ_median = median(valuetJ);
    valuetJ_mean = mean(valuetJ);
    valuetJ_q3 = prctile(valuetJ,75);
    valuetJ_max = max(valuetJ);
    
    Table9(1:4,datanr) = [passrate(1,1);passrate(1,2);passnrgroups(1,2);passnrhhTCR];
    Table9(5:8,datanr) = [powerCR;powerTCR;psCR;psTCR];
    Table9(9:18,datanr) = [valuelJ_q1;valuelJ_median;valuelJ_mean;valuelJ_q3;valuelJ_max;valuetJ_q1;valuetJ_median;valuetJ_mean;valuetJ_q3;valuetJ_max];

end
csvwrite(strcat(EXPORTSdir,'Table9.csv'),round(Table9,2));


%% Table D.1

dataset = [100 0;1 0;11 0;0 0;100 1;100 -1];  
analysistype = [0;0;0;0;0;0;0];

for datanr = 1:6
%     1: main sample
%     2: 1-2 children
%     3: 3+ children
%     4: no children
%     5: positive matching
%     6: negative matching
        
    allvarsdata = allvars(allvars(:,1)==dataset(datanr,1) & allvars(:,2)==dataset(datanr,2),:);
    if datanr == 4
       allvarsdata(:,36) = zeros(length(allvarsdata(:,36)),1); % Ck = 0 for childless couples
    end
    atype = analysistype(datanr,1);
    
    [passrate,passnrgroups,passnrhhCR,passnrhhTCR,passnrhhACR,passindicator] = Run_Passrates(allvarsdata,atype);
    
    [powerCR,powerTCR,passCR,passTCR] = Run_Power(allvarsdata,atype);
    psCR = passrate(1,1)+powerCR-1;
    psTCR = passrate(1,2)+powerTCR-1;

    [valuelJ,valuewK,valuetJ] = Run_Value(allvarsdata,atype);
    valuelJ_min = min(valuelJ);
    valuelJ_q1 = prctile(valuelJ,25);
    valuelJ_median = median(valuelJ);
    valuelJ_mean = mean(valuelJ);
    valuelJ_q3 = prctile(valuelJ,75);
    valuelJ_max = max(valuelJ);
    
    valuetJ_min = min(valuetJ);
    valuetJ_q1 = prctile(valuetJ,25);
    valuetJ_median = median(valuetJ);
    valuetJ_mean = mean(valuetJ);
    valuetJ_q3 = prctile(valuetJ,75);
    valuetJ_max = max(valuetJ);
    
    TableD1(1:4,datanr) = [passrate(1,1);passrate(1,2);passnrgroups(1,2);passnrhhTCR];
    TableD1(5:8,datanr) = [powerCR;powerTCR;psCR;psTCR];
    TableD1(9:18,datanr) = [valuelJ_q1;valuelJ_median;valuelJ_mean;valuelJ_q3;valuelJ_max;valuetJ_q1;valuetJ_median;valuetJ_mean;valuetJ_q3;valuetJ_max];

end
csvwrite(strcat(EXPORTSdir,'TableD1.csv'),round(TableD1,2));
