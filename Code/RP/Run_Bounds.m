function Bounds = Run_Bounds(allvarsdata)

G = 36; % number of groups

LB = 10000*ones(G,1);
LBhh = [];

UB = -10000*ones(G,1);
UBhh = [];

group = allvarsdata(:,3);

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

%% Call togetherness
for g = 1:G
    
    w_dg = w(group==g,:);
    
    h_dg = h(group==g,:);
    hreg_dg = hreg(group==g,:);
    hirreg_dg = hirreg(group==g,:);
    
    l_dg = l(group==g,:);
    Cp_dg = Cp(group==g,1);
    
    T_dg = T(group==g,:);
    Ck_dg = Ck(group==g,1);
    
    V = size(Cp_dg,1);
    
    %% Compute LB
    % Set wk and gamma parameter
    % w_k
    for wktest = 0:1
        if wktest == 0
            wk_dg = zeros(V,1); % day care costs
        elseif wktest == 1
            wk_dg = zeros(V,1);
            for i = 1:V
                wk_dg(i,1) = (1/3) * min(w_dg(i,1),w_dg(i,2));
            end
        end
        % markup
        for gamma_markup = 1:0.25:1.5
            % Compute wreg and wirreg
            wreg_dg = zeros(V,2);
            wirreg_dg = 100000*ones(V,2);
            for i = 1:V
                for m = 1:2
                    % Recovery of wreg and wirreg from w, H, hreg and hirreg
                    wreg_dg(i,m) = w_dg(i,m)*h_dg(i,m) / (hreg_dg(i,m) + gamma_markup*hirreg_dg(i,m));
                    wirreg_dg(i,m) = gamma_markup*wreg_dg(i,m);
                end
            end
            
            % Compute deltam, deltaK, gamma and set TC2
            deltam=zeros(V,2);
            deltaK=zeros(V,3);
            gamma=zeros(V,1);
            
            for i = 1:V
                % Husband works most regular hours
                if hreg_dg(i,1)>=hreg_dg(i,2)
                    
                    deltam(i,2) = wreg_dg(i,2);
                    gamma(i,1) = (wirreg_dg(i,2) - wreg_dg(i,2));
                    deltam(i,1) = w_dg(i,1) - gamma(i,1);
                    deltaK(i,1) = deltam(i,1) - wk_dg(i,1);
                    deltaK(i,2) = deltam(i,2) - wk_dg(i,1);
                    deltaK(i,3) = deltam(i,1) + deltam(i,2) + gamma(i,1) - wk_dg(i,1);
                    
                % Wife works (strictly) most regular hours
                elseif hreg_dg(i,1)<hreg_dg(i,2)
                    
                    deltam(i,1) = wreg_dg(i,1);
                    gamma(i,1) = (wirreg_dg(i,1) - wreg_dg(i,1));
                    deltam(i,2) = w_dg(i,2) - gamma(i,1);
                    deltaK(i,1) = deltam(i,1) - wk_dg(i,1);
                    deltaK(i,2) = deltam(i,2) - wk_dg(i,1);
                    deltaK(i,3) = deltam(i,1) + deltam(i,2) + gamma(i,1) - wk_dg(i,1);
                    
                end
            end
            
            [pass,test,tJlbselect] = togetherness_bounds_main(l_dg,Cp_dg,T_dg,Ck_dg,deltam,deltaK,gamma,'lb');
            if pass == 1 && test<=LB(g,1) && min(min(deltam))>=0 && min(min(deltaK))>=0 && min(gamma)>=0
                LB(g,1) = test;
            end
        end
    end
    
    if LB(g,1)<10000
        LBhh=[LBhh;repmat(LB(g,1),V,1)];
    else
        LBhh=[LBhh;repmat(200,V,1)];
    end
    
    %% Compute UB
    % Set wk and gamma parameter
    % w_k
    for wktest = 0:1
        if wktest == 0
            wk_dg = zeros(V,1); % day care costs
        elseif wktest == 1
            for i = 1:V
                wk_dg(i,1) = (1/3) * min(w_dg(i,1),w_dg(i,2));
            end
        end
        % markup
        for gamma_markup = 1:0.25:1.5
            % Compute wreg and wirreg
            wreg_dg = zeros(V,2);
            wirreg_dg = 100000*ones(V,2);
            for i = 1:V
                for m = 1:2
                    % Recovery of wreg and wirreg from w, H, hreg and hirreg
                    wreg_dg(i,m) = w_dg(i,m)*h_dg(i,m) / (hreg_dg(i,m) + gamma_markup*hirreg_dg(i,m));
                    wirreg_dg(i,m) = gamma_markup*wreg_dg(i,m);
                end
            end
            
            % Compute deltam, deltaK, gamma and set TC2
            deltam=zeros(V,2);
            deltaK=zeros(V,3);
            gamma=zeros(V,1);
            
            for i = 1:V
                % Husband works most regular hours
                if hreg_dg(i,1)>=hreg_dg(i,2)
                    
                    deltam(i,2) = wreg_dg(i,2);
                    gamma(i,1) = (wirreg_dg(i,2) - wreg_dg(i,2));
                    deltam(i,1) = w_dg(i,1) - gamma(i,1);
                    deltaK(i,1) = deltam(i,1) - wk_dg(i,1);
                    deltaK(i,2) = deltam(i,2) - wk_dg(i,1);
                    deltaK(i,3) = deltam(i,1) + deltam(i,2) + gamma(i,1) - wk_dg(i,1);
                    
                % Wife works (strictly) most regular hours
                elseif hreg_dg(i,1)<hreg_dg(i,2)
                    
                    deltam(i,1) = wreg_dg(i,1);
                    gamma(i,1) = (wirreg_dg(i,1) - wreg_dg(i,1));
                    deltam(i,2) = w_dg(i,2) - gamma(i,1);
                    deltaK(i,1) = deltam(i,1) - wk_dg(i,1);
                    deltaK(i,2) = deltam(i,2) - wk_dg(i,1);
                    deltaK(i,3) = deltam(i,1) + deltam(i,2) + gamma(i,1) - wk_dg(i,1);
                    
                end
            end
            
            [pass,test,tJubselect] = togetherness_bounds_main(l_dg,Cp_dg,T_dg,Ck_dg,deltam,deltaK,gamma,'ub');
            if pass == 1 && test>=UB(g,1) && min(min(deltam))>=0 && min(min(deltaK))>=0 && min(gamma)>=0
                UB(g,1) = test;
            end
        end
    end
    
    if UB(g,1)>-10000
        UBhh=[UBhh;repmat(UB(g,1),V,1)];
    else
        UBhh=[UBhh;repmat(-200,V,1)];
    end
end

Bounds = [min(LB(LB<10000)) min(UB(UB>-10000));mean(LB(LB<10000)) mean(UB(UB>-10000)); max(LB(LB<10000)) max(UB(UB>-10000))];

end