function [valuelJ,valuewK,valuetJ] = Run_Value(allvarsdata,atype)

group = allvarsdata(:,3);
if min(group) < 0
    group = -group;
end

%% Select wage vars
if ismember(atype,[0,2:5])
    w = allvarsdata(:,8:2:10);
else
    w = allvarsdata(:,9:2:11); % with commuting
end

%% Select time and consumption vars
if ismember(atype,[0,2:5])
    h = allvarsdata(:,[12,22]);
    hreg = allvarsdata(:,[14,24]);
    hirreg = allvarsdata(:,[15,25]);
elseif atype == 1
    h = allvarsdata(:,[13,23]); % with commuting
    hreg = allvarsdata(:,[16,26]); % with commuting
    hirreg = allvarsdata(:,[17,27]); % with commuting
end

l = allvarsdata(:,32:34);
T = allvarsdata(:,37:38);

Cp = allvarsdata(:,35);
Ck = allvarsdata(:,36);

year = allvarsdata(:,68);
cpi = allvarsdata(:,69);

G = max(group); % number of groups

valuewK = [];
valuelJ = [];
valuetJ = [];

%% Call togetherness
for g = 1:G
    
    w_g = w(group==g,:);
    
    h_g = h(group==g,:);
    hreg_g = hreg(group==g,:);
    hirreg_g = hirreg(group==g,:);
    
    l_g = l(group==g,:);
    Cp_g = Cp(group==g,1);
    
    T_g = T(group==g,:);
    Ck_g = Ck(group==g,1);
    
    year_g = year(group==g,1);
    cpi_g = cpi(group==g,1);
    
    V = size(Cp_g,1);
        
    sumwf_g = 1000;
    wftauJ_g = [];
    wfall_g = [];
    
    if atype == 4 % 66-33-0
        for i = 1:V
            for m = 1:2
                if abs(hirreg_g(i,m) - 0.25*h_g(i,m)) <= 0.00001
                    hirreg_g(i,m) = 0.33*h_g(i,m);
                    hreg_g(i,m) = (1-0.33)*h_g(i,m);
                elseif abs(hirreg_g(i,m) - 0.5*h_g(i,m)) <= 0.00001
                    hirreg_g(i,m) = 0.66*h_g(i,m);
                    hreg_g(i,m) = (1-0.66)*h_g(i,m);
                end
            end
        end
    end
    
    %% Determine accidental overlap
    for overlap=0:0.05:0.2-(atype==2)*0.1-(~ismember(atype,[2,3]))*0.2
        %% Set wk and tauJ parameter
        % w_k
        for wktest = 0:1
            if wktest == 0
                wk_g = zeros(V,1); % day care costs
            elseif wktest == 1
                wk_g = zeros(V,1);
                for i = 1:V
                    wk_g(i,1) = (1/3) * min(w_g(i,1),w_g(i,2));
                end
            end
            % markup
            for tauJ_markup = 1:0.25:1.5
                
                %% Compute wreg and wirreg
                wreg_g = zeros(V,2);
                wirreg_g = 100000*ones(V,2);
                for i = 1:V
                    for m = 1:2
                        % Recovery of wreg and wirreg from w, H, hreg and hirreg
                        wreg_g(i,m) = w_g(i,m)*h_g(i,m) / (hreg_g(i,m) + tauJ_markup*hirreg_g(i,m));
                        wirreg_g(i,m) = tauJ_markup*wreg_g(i,m);
                    end
                end
                
                %% Compute deltam, deltaK, tauJ and set TC2
                deltam=zeros(V,2);
                deltaK=zeros(V,3);
                tauJ=zeros(V,1);
                
                for i = 1:V
                    % Husband works most regular hours
                    if hreg_g(i,1)+overlap*hirreg_g(i,1)>=hreg_g(i,2)+overlap*hirreg_g(i,2)
                        
                        deltam(i,2) = wreg_g(i,2);
                        tauJ(i,1) = (wirreg_g(i,2) - wreg_g(i,2))/(1-overlap);
                        deltam(i,1) = w_g(i,1) - tauJ(i,1);
                        deltaK(i,1) = deltam(i,1) - wk_g(i,1);
                        deltaK(i,2) = deltam(i,2) - wk_g(i,1);
                        deltaK(i,3) = deltam(i,1) + deltam(i,2) + tauJ(i,1) - wk_g(i,1);
                        
                    % Wife works (strictly) most regular hours
                    elseif hreg_g(i,1)+overlap*hirreg_g(i,1)<hreg_g(i,2)+overlap*hirreg_g(i,2)
                        
                        deltam(i,1) = wreg_g(i,1);
                        tauJ(i,1) = (wirreg_g(i,1) - wreg_g(i,1))/(1-overlap);
                        deltam(i,2) = w_g(i,2) - tauJ(i,1);
                        deltaK(i,1) = deltam(i,1) - wk_g(i,1);
                        deltaK(i,2) = deltam(i,2) - wk_g(i,1);
                        deltaK(i,3) = deltam(i,1) + deltam(i,2) + tauJ(i,1) - wk_g(i,1);
                        
                    end
                end
                
                testsumwf = sum(wk_g./cpi_g) + sum(tauJ./cpi_g);
                if atype == 5
                    test = togetherness_measurement(l_g,Cp_g,T_g,Ck_g,deltam,deltaK,tauJ);
                else
                    test = togetherness(l_g,Cp_g,T_g,Ck_g,deltam,deltaK,tauJ);
                end
                
                if test==1 && testsumwf<=sumwf_g && min(min(deltam))>=0 && min(min(deltaK))>=0 && min(tauJ)>=0
                    sumwf_g = testsumwf;
                    
                    wfwk_g = wk_g./cpi_g;
                    wftauJ_g = tauJ./cpi_g;
                    wfall_g = wk_g./cpi_g + tauJ./cpi_g;
                end
                
            end
        end
    end
    
    if sumwf_g < 1000
        valuewK=[valuewK;wfwk_g];
        valuelJ=[valuelJ;wftauJ_g];
        valuetJ=[valuetJ;wfall_g];
    end
    
end

end