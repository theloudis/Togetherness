function [passrate,passnrgroups,passnrhhCR,passnrhhTCR,passnrhhACR,passindicator] = Run_Passrates(allvarsdata,atype)

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

G = max(group); % number of groups

passindicator = zeros(G,3);
passallhhCR = [];
passallhhTCR = [];
passallhhACR = [];

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
    
    V = size(Cp_g,1);
          
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
                
                if wktest == 0 && tauJ_markup == 1
                    if atype == 5
                        testCR = togetherness_measurement(l_g,Cp_g,T_g,Ck_g,deltam,deltaK,tauJ);
                    else
                        testCR = togetherness(l_g,Cp_g,T_g,Ck_g,deltam,deltaK,tauJ);
                    end
                    testACR = togetherness_egoistic(l_g,Cp_g,T_g,Ck_g,deltam,deltaK,tauJ);
                    
                    if testCR == 1
                        passindicator(g,1)=1;
                    end
                    if testACR == 1
                        passindicator(g,3)=1;
                    end
                end
                
                if atype == 5
                    testTCR = togetherness_measurement(l_g,Cp_g,T_g,Ck_g,deltam,deltaK,tauJ);
                else
                    testTCR = togetherness(l_g,Cp_g,T_g,Ck_g,deltam,deltaK,tauJ);
                end
                if testTCR==1 && min(min(deltam))>=0 && min(min(deltaK))>=0 && min(tauJ)>=0
                    passindicator(g,2)=1;
                end
            end
        end
     end   
     if passindicator(g,1)==1
         passallhhCR=[passallhhCR;tauJ];
     end
     if passindicator(g,2)==1
         passallhhTCR=[passallhhTCR;tauJ];
     end
     if passindicator(g,3)==1
         passallhhACR=[passallhhACR;tauJ];
     end     
end

passrate = sum(passindicator,1)/G;
passnrgroups = sum(passindicator,1);
passnrhhCR = length(passallhhCR);
passnrhhTCR = length(passallhhTCR);
passnrhhACR = length(passallhhACR);

end