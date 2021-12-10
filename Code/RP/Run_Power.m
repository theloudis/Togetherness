function [powerCR,powerTCR,passCR,passTCR] = Run_Power(allvarsdata,atype)

rng default

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
Tk = allvarsdata(:,39);

Cp = allvarsdata(:,35);
Ck = allvarsdata(:,36);

G = max(group); % number of groups
B = 100; % number of iterations

passCR = zeros(G,B);
passTCR = zeros(G,B);

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
    
    Tk_g = Tk(group==g,1);
    
    V = size(Cp_g,1);
    
    y_g = Cp_g + Ck_g - w_g(:,1).*h_g(:,1) - w_g(:,2).*h_g(:,2) ;
    time1_g = h_g(:,1) + l_g(:,1) + l_g(:,3) + T_g(:,1) ;
    time2_g = h_g(:,2) + l_g(:,2) + l_g(:,3) + T_g(:,2) ;
    
    for b = 1:B
        l_rand = zeros(V,3);
        T_rand = zeros(V,2);
        h_rand = zeros(V,2);
        hreg_rand = zeros(V,2);
        hirreg_rand = zeros(V,2);
        randy = zeros(V,1);
        Cp_rand = zeros(V,1);
        Ck_rand = zeros(V,1);
        
        if max(Ck) ~= 0
            for i = 1:V
                randy(i,1) = -99;
                while randy(i,1)<0
                    
                    % Simulate joint time
                    randjoint = 0.25*rand;
                    l_rand(i,3) = randjoint*min(time1_g(i,1),time2_g(i,1));
                    
                    % Simulate time use
                    randtime = -log(rand(3,2));
                    
                    h_rand(i,1) = randtime(1,1)*(time1_g(i,1)-l_rand(i,3))/sum(randtime(:,1));
                    h_rand(i,2) = randtime(1,2)*(time2_g(i,1)-l_rand(i,3))/sum(randtime(:,2));
                    l_rand(i,1) = randtime(2,1)*(time1_g(i,1)-l_rand(i,3))/sum(randtime(:,1));
                    l_rand(i,2) = randtime(2,2)*(time2_g(i,1)-l_rand(i,3))/sum(randtime(:,2));
                    T_rand(i,1) = randtime(3,1)*(time1_g(i,1)-l_rand(i,3))/sum(randtime(:,1));
                    T_rand(i,2) = randtime(3,2)*(time2_g(i,1)-l_rand(i,3))/sum(randtime(:,2));
                    
                    % Simulate irregular hours
                    randirreg = 0.33*rand(1,2);
                    
                    hirreg_rand(i,:) = randirreg.*h_rand(i,:);
                    hreg_rand(i,:) = (1-randirreg).*h_rand(i,:);
                    
                    % Simulate consumption shares
                    randy(i,1) = y_g(i,1) + w_g(i,1).*h_rand(i,1) + w_g(i,2).*h_rand(i,2);
                    
                    randshare = rand;
                    
                    Cp_rand(i,1) = randshare*randy(i,1);
                    Ck_rand(i,1) = (1-randshare)*randy(i,1);
                    
                end
            end
        elseif max(Ck) == 0
            for i = 1:V
                Cp_rand(i,1) = -99;
                while Cp_rand(i,1)<0
                    
                    % Simulate joint time
                    randjoint = 0.25*rand;
                    l_rand(i,3) = randjoint*min(time1_g(i,1),time2_g(i,1));
                    
                    % Simulate time use
                    randtime = -log(rand(2,2));
                    
                    h_rand(i,1) = randtime(1,1)*(time1_g(i,1)-l_rand(i,3))/sum(randtime(:,1));
                    h_rand(i,2) = randtime(1,2)*(time2_g(i,1)-l_rand(i,3))/sum(randtime(:,2));
                    l_rand(i,1) = randtime(2,1)*(time1_g(i,1)-l_rand(i,3))/sum(randtime(:,1));
                    l_rand(i,2) = randtime(2,2)*(time2_g(i,1)-l_rand(i,3))/sum(randtime(:,2));
                    
                    % Simulate irregular hours
                    randirreg = 0.33*rand(1,2);
                    
                    hirreg_rand(i,:) = randirreg.*h_rand(i,:);
                    hreg_rand(i,:) = (1-randirreg).*h_rand(i,:);
                    
                    % Simulate consumption shares
                    Cp_rand(i,1) = y_g(i,1) + w_g(i,1).*h_rand(i,1) + w_g(i,2).*h_rand(i,2);
                end
            end
        end
        
        %% Call Togetherness w/o costs
        % w_k
        wk_g = zeros(V,1);
        % markup
        tauJ_markup = 1;
        
        deltam=zeros(V,2);
        deltaK=zeros(V,3);
        tauJ=zeros(V,1);
        
        for i = 1:V
            deltam(i,1) = w_g(i,1);
            deltam(i,2) = w_g(i,2);
            tauJ(i,1) = 0;
            deltaK(i,1) = deltam(i,1);
            deltaK(i,2) = deltam(i,2);
            deltaK(i,3) = deltam(i,1) + deltam(i,2);
        end
        
        if atype == 5
            testCR = togetherness_measurement(l_rand,Cp_rand,T_rand,Ck_rand,deltam,deltaK,tauJ);
        else
            testCR = togetherness(l_rand,Cp_rand,T_rand,Ck_rand,deltam,deltaK,tauJ);
        end
        if testCR==1
            passCR(g,b) = 1;
        end
        
        %% Call Togetherness w costs
        for overlap=0:0.05:0.2-(atype==2)*0.1-(~ismember(atype,[2,3]))*0.2
            %% Set wk and tauJ parameter
            % w_k
            for wktest = 0:1
                if wktest == 0
                    wk_g = zeros(V,1); % day care costs
                elseif wktest == 1
                    for i = 1:V
                        wk_g(i,1) = (1/3) * min(w_g(i,1),w_g(i,2));
                    end
                end
                % markup
                for tauJ_markup = 1:0.25:1.5
                    %% Compute wreg and wirreg
                    wreg_rand = zeros(V,2);
                    wirreg_rand = 100000*ones(V,2);
                    for i = 1:V
                        for m = 1:2
                            % Recovery of wreg and wirreg from w, H, hreg and hirreg
                            wreg_rand(i,m) = w_g(i,m)*h_rand(i,m) / (hreg_rand(i,m) + tauJ_markup*hirreg_rand(i,m));
                            wirreg_rand(i,m) = tauJ_markup*wreg_rand(i,m);
                        end
                    end
                    
                    %% Compute deltam, deltaK, tauJ and set TC2
                    deltam=zeros(V,2);
                    deltaK=zeros(V,3);
                    tauJ=zeros(V,1);
                    
                    for i = 1:V
                        % husband works most regular hours
                        if hreg_rand(i,1)+overlap*hirreg_rand(i,1)>=hreg_rand(i,2)+overlap*hirreg_rand(i,2)
                            
                            deltam(i,2) = wreg_rand(i,2);
                            tauJ(i,1) = (wirreg_rand(i,2) - wreg_rand(i,2))/(1-overlap);
                            deltam(i,1) = w_g(i,1) - tauJ(i,1);
                            deltaK(i,1) = deltam(i,1) - wk_g(i,1);
                            deltaK(i,2) = deltam(i,2) - wk_g(i,1);
                            deltaK(i,3) = deltam(i,1) + deltam(i,2) + tauJ(i,1) - wk_g(i,1);
                            
                        % wife works (strictly) most regular hours
                        elseif hreg_rand(i,1)+overlap*hirreg_rand(i,1)<hreg_rand(i,2)+overlap*hirreg_rand(i,2)
                            
                            deltam(i,1) = wreg_rand(i,1);
                            tauJ(i,1) = (wirreg_rand(i,1) - wreg_rand(i,1))/(1-overlap);
                            deltam(i,2) = w_g(i,2) - tauJ(i,1);
                            deltaK(i,1) = deltam(i,1) - wk_g(i,1);
                            deltaK(i,2) = deltam(i,2) - wk_g(i,1);
                            deltaK(i,3) = deltam(i,1) + deltam(i,2) + tauJ(i,1) - wk_g(i,1);
                            
                        end
                    end
                    
                    if atype == 5
                        testTCR = togetherness_measurement(l_rand,Cp_rand,T_rand,Ck_rand,deltam,deltaK,tauJ);
                    else
                        testTCR = togetherness(l_rand,Cp_rand,T_rand,Ck_rand,deltam,deltaK,tauJ);
                    end
                    if testTCR==1 && min(min(deltam))>=0 && min(min(deltaK))>=0 && min(tauJ)>=0
                        passTCR(g,b) = 1;
                    end
                end
            end
        end
    end
end

powerCR = 1 - mean(mean(passCR));
powerTCR = 1 - mean(mean(passTCR));

end