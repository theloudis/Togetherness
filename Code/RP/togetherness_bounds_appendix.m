function [pass,fvalue,xselect] = togetherness_bounds_appendix(l,Cp,T,Ck,deltam,deltaK,gamma,flexpar,spec)

V = size(T,1);

smallnumber = 0.0005;

%% Variables:
nrpref = 3*V*V ; % binary preference variables
nrpric = 2*V ; % delta1J,delta2J
nrtime = 3*V ; % t1,t2,tJ
nrvars = nrpref + nrpric + nrtime + 1;

%% Constraints:
nrineqconstraints = 2*V*V + 2*V*(V-1)*(V-2) + 2*V*V + V*V + V*(V-1)*(V-2) + V*V + 2*sum(min(T,[],2)>0);
nreqconstraints = 3*V + 1;

A = zeros(nrvars,nrineqconstraints);
Aeq = zeros(nrvars,nreqconstraints);

b = zeros(1,nrineqconstraints);
beq = zeros(1,nreqconstraints);

for m=1:2
    for s=1:V
        for v=1:V
            Pmsv(s,v,m)=(Cp(s,1)-Cp(v,1))/2+(deltam(s,1)+deltam(s,2)+gamma(s,1))*(l(s,3))+deltam(s,m)*(l(s,m)-l(v,m))+1;
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

%% PART III : Proportion of joint childcare cannot deviate more than 'flexpar' from average proportion 
for s=1:V
    if min(T(s,1),T(s,2))>0
       A(nrpref+nrpric+(s-1)*3+3,r) = 1/min(T(s,1),T(s,2));
       A(nrvars,r) = -1;
       b(1,r) = flexpar;
       r = r+1;
       
       A(nrpref+nrpric+(s-1)*3+3,r) = -1/min(T(s,1),T(s,2));
       A(nrvars,r) = 1;
       b(1,r) = flexpar;
       r = r+1;     
    end
end

%% PART IV : Individual total childcare = private + joint childcare
r = 1;
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

%% PART VI : Impose that final variable (nrvars) is average proportion of joint childcare
counts=0;
for s=1:V
    if min(T(s,1),T(s,2))>0
        Aeq(nrpref+nrpric+(s-1)*3+3,r) = 1/min(T(s,1),T(s,2));
        counts=counts+1;
    end
end
Aeq(nrvars,r) = -counts;

beq(1,r) = 0;

%% PART V : Objective function: Minimize or maximize average proportion of joint childcare
f = zeros(nrvars,1);
if strcmp(spec,'lb')==1
   f(nrvars,1) = 1;
elseif strcmp(spec,'ub')==1
   f(nrvars,1) = -1;
end

% impose standard lower and upper bounds
lb = zeros(nrvars,1);
ub = Inf(nrvars,1);
ub(1:nrpref,1) = ones(nrpref,1);
intcon = (1:nrpref)';
options = optimoptions(@intlinprog,'IntegerPreprocess','none','Display','off');

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
       xselect=x(nrpref+nrpric+3:3:nrpref+nrpric+nrtime,1);
   else
       fvalue=NaN;
       xselect=repmat(200,V,1);
   end
elseif strcmp(spec,'ub')
    if pass==1
       fvalue=-fmin;
       xselect=x(nrpref+nrpric+3:3:nrpref+nrpric+nrtime,1);
   else
       fvalue=NaN;
       xselect=repmat(-200,V,1);
   end
end