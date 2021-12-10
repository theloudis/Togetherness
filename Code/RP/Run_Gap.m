function [wfallnocell,hregindicatornocell] = Run_Gap(allvarsdata)

group = allvarsdata(:,3);

G = 36; % number of groups

sumwf = 10000*ones(G,1);
passindicator = zeros(G,1);

wfall = cell(G,1);
wfwk = cell(G,1);
wftauJ = cell(G,1);
hregindicator = cell(G,1);

%% Select wage vars
w = allvarsdata(:,8:2:10);
    
%% Select time and consumption vars
h = allvarsdata(:,[12,22]);
hreg = allvarsdata(:,[14,24]);
hirreg = allvarsdata(:,[15,25]);

l = allvarsdata(:,32:34);
T = allvarsdata(:,37:38);

Cp = allvarsdata(:,35);
Ck = allvarsdata(:,36);

year = allvarsdata(:,68);
cpi = allvarsdata(:,69);

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
    
    year_g = mean(year(group==g,1));
    cpi_g = mean(cpi(group==g,1));
    
    V = size(Cp_g,1);
    
    %% Set wk and tauJ parameter
    % w_k
    for wktest = 0
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
                if hreg_g(i,1)>hreg_g(i,2)
                    
                    deltam(i,2) = wreg_g(i,2);
                    tauJ(i,1) = (wirreg_g(i,2) - wreg_g(i,2));
                    deltam(i,1) = w_g(i,1) - tauJ(i,1);
                    deltaK(i,1) = deltam(i,1) - wk_g(i,1);
                    deltaK(i,2) = deltam(i,2) - wk_g(i,1);
                    deltaK(i,3) = deltam(i,1) + deltam(i,2) + tauJ(i,1) - wk_g(i,1);
                    
                % Wife works most regular hours
                elseif hreg_g(i,1)<=hreg_g(i,2)
                    
                    deltam(i,1) = wreg_g(i,1);
                    tauJ(i,1) = (wirreg_g(i,1) - wreg_g(i,1));
                    deltam(i,2) = w_g(i,2) - tauJ(i,1);
                    deltaK(i,1) = deltam(i,1) - wk_g(i,1);
                    deltaK(i,2) = deltam(i,2) - wk_g(i,1);
                    deltaK(i,3) = deltam(i,1) + deltam(i,2) + tauJ(i,1) - wk_g(i,1);
                    
                end
            end
            
            testsumwf = sum(wk_g/cpi_g) + sum(tauJ/cpi_g);
            test = togetherness(l_g,Cp_g,T_g,Ck_g,deltam,deltaK,tauJ);
            
            if test==1 && testsumwf<=sumwf(g,1) && min(min(deltam))>=0 && min(min(deltaK))>=0 && min(tauJ)>=0
                passindicator(g,1) = 1;
                sumwf(g,1) = testsumwf;
                wfwk{g,1} = wk_g/cpi_g;
                wftauJ{g,1} = tauJ/cpi_g;
                wfall{g,1} = wk_g/cpi_g + tauJ/cpi_g;
                for i = 1:V
                    if hreg_g(i,1)>hreg_g(i,2)
                        hregindicator{g,1}(i,1)=1;
                    elseif hreg_g(i,1)<=hreg_g(i,2)
                        hregindicator{g,1}(i,1)=0;
                    end
                end             
            end
            
        end
    end
    disp(['Finished group ',num2str(g)])
end

%% pass rates.
passrate = sum(passindicator(:,1))/G;

max(passrate)

wfallnocell = [];
hregindicatornocell = [];
for g = 1:G
    wfallnocell = [wfallnocell;wfall{g,1}];
    hregindicatornocell = [hregindicatornocell;hregindicator{g,1}];
end

end