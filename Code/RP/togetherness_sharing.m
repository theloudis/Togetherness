function [pass,fvalue] = togetherness_sharing(l,Cp,T,Ck,deltam,deltaK,gamma,vv,spec)

V = size(T,1);

smallnumber = 0.0005;

%% Variables:
nrpref = 3*V*V ; % binary preference variables
nrpric = 2*V ; % delta1J,delta2J 
nrtime = 3*V ; % t1,t2,tJ
nrvars = nrpref + nrpric + nrtime ;

%% Constraints:
nrineqconstraints = 2*V*V + 2*V*(V-1)*(V-2) + 2*V*V + V*V + V*(V-1)*(V-2) + V*V ;
nreqconstraints = 2*V + 2*V ;

A = zeros(nrvars+V,nrineqconstraints);
Aeq = zeros(nrvars+V,nreqconstraints);

b = zeros(1,nrineqconstraints);
beq = zeros(1,nreqconstraints);

for m=1:2
    for s=1:V
        for v=1:V
            Pmsv(s,v,m)=Cp(s,1)+(deltam(s,1)+deltam(s,2)+gamma(s,1))*(l(s,3))+deltam(s,m)*(l(s,m)-l(v,m))+1;            
        end
    end
end
for s=1:V
    for v=1:V
        Ksv(s,v)=(Ck(s,1)-Ck(v,1))+deltaK(s,1)*T(s,1)+deltaK(s,2)*T(s,2)+deltaK(s,3)*(min(T(s,:)))+1;        
    end
end

r = 1;

%% PART I : GARP for parents m=1,2 
% opening GARP
for m=1:2
    for s=1:V
        for v=1:V
            A((m-1)*V*V+(s-1)*V+v,r) = -Pmsv(s,v,m);
            A(nrpref+(m-1)*V+s,r) = l(s,3)-l(v,3);
                        
            b(1,r) = 0-smallnumber-deltam(s,m)*(l(s,m)-l(v,m))-(Cp(s,1)-Cp(v,1))/2;
            
            r = r+1;
        end
    end
end
% transitivity
for m=1:2
    for s=1:V 
        for u=[1:s-1,s+1:V] 
            for v=[1:u-1,u+1:V] 
                if ~isequal(v,s)
                    
                    A((m-1)*V*V+(s-1)*V+u,r) = 1;
                    A((m-1)*V*V+(u-1)*V+v,r) = 1;
                    A((m-1)*V*V+(s-1)*V+v,r) = -1;
                    
                    b(1,r)=1;
                    
                    r = r+1;
                end
            end
        end
    end
end
% closing GARP
for m=1:2
    for s=1:V
        for v=1:V
            A((m-1)*V*V+(s-1)*V+v,r) = Pmsv(v,s,m);
            A(nrpref+(m-1)*V+v,r) = l(v,3)-l(s,3);
                                    
            b(1,r) = Pmsv(v,s,m)-deltam(v,m)*(l(v,m)-l(s,m))-(Cp(v,1)-Cp(s,1))/2;
            
            r = r+1;
        end
    end
end

%% PART II : GARP for children
% opening GARP
for s=1:V
    for v=1:V
        A(2*V*V+(s-1)*V+v,r) = -Ksv(s,v);
        for n=1:3
            A(nrpref+nrpric+(s-1)*3+n,r) = deltaK(s,n);
            A(nrpref+nrpric+(v-1)*3+n,r) = -deltaK(s,n);
        end
        
        b(1,r) = 0-smallnumber-(Ck(s,1)-Ck(v,1));

        r = r+1;
    end
end
% transitivity
for s=1:V
    for u=[1:s-1,s+1:V]
        for v=[1:u-1,u+1:V]
            if ~isequal(v,s)

                A(2*V*V+(s-1)*V+u,r) = 1;
                A(2*V*V+(u-1)*V+v,r) = 1;
                A(2*V*V+(s-1)*V+v,r) = -1;
                b(1,r) = 1;

                r = r+1;
            end
        end
    end
end
% closing GARP
for s=1:V
    for v=1:V
        A(2*V*V+(s-1)*V+v,r) = Ksv(v,s);
        for n=1:3
            A(nrpref+nrpric+(v-1)*3+n,r) = deltaK(v,n);
            A(nrpref+nrpric+(s-1)*3+n,r) = -deltaK(v,n);
        end
        b(1,r) = Ksv(v,s)-(Ck(v,1)-Ck(s,1));

        r = r+1;
    end
end

r = 1;

%% PART III : Individual total childcare = private + joint childcare
for m=1:2
    for s=1:V
        Aeq(nrpref+nrpric+(s-1)*3+m,r) = 1;
        Aeq(nrpref+nrpric+(s-1)*3+3,r) = 1;
        
        beq(1,r) = T(s,m);
        
        r = r+1;
    end
end

%% PART V : Joint leisure FOCs
for s=1:V
    Aeq(nrpref+s,r) = 1;
    Aeq(nrpref+V+s,r) = 1;
    
    beq(1,r) = deltam(s,1) + deltam(s,2) + gamma(s,1);
    
    r = r+1;
end

%% PART VII : Define resource shares
for s=1:V
    Yp(s,1) = Cp(s,1) + deltam(s,1)*l(s,1) + deltam(s,2)*l(s,2) + (deltam(s,1)+deltam(s,2)+gamma(s,1))*l(s,3);
    
    Aeq(nrpref+s,r) = -l(s,3);
    Aeq(nrvars+s,r) = Yp(s,1);
    
    beq(1,r) = deltam(s,1)*l(s,1)+0.5*Cp(s,1);
    
    r = r+1;
end

%% PART V : Objective function: Minimize or maximize resource share
f = zeros(nrvars+V,1);
if strcmp(spec,'lb')==1
   f(nrvars+vv,1) = 1;
elseif strcmp(spec,'ub')==1
   f(nrvars+vv,1) = -1;
end

% impose standard lower and upper bounds
lb = zeros(nrvars+V,1);
ub = Inf(nrvars+V,1);
ub(1:nrpref,1) = ones(nrpref,1);

intcon = (1:nrpref)';
options = optimoptions(@intlinprog,'Display','off');

% call optimizer
try
    [x,fmin,exitflag]=intlinprog(f,intcon,A',b',Aeq',beq',lb,ub,[],options);
catch
    exitflag=-99;
end

% generate output
if exitflag>0
    pass=1;
else
    pass=NaN;
end
if strcmp(spec,'lb')
   if pass==1
       fvalue=fmin;
   else
       fvalue=NaN;
   end
elseif strcmp(spec,'ub')
    if pass==1
       fvalue=-fmin;
    else
       fvalue=NaN;
    end
end