function [passindicator,x] = togetherness_measurement(l,Cp,T,Ck,deltam,deltaK,tauJ)

V = size(T,1);

smallnumber = 0.0005;

%% Variables:
nrpref = 3*V*V ; % binary preference variables
nrpric = 2*V ; % delta1J,delta2J
nrtime = 3*V ; % t1,t2,tJ
nrerror = 2*V ; % epsilon
nrvars = nrpref + nrpric + nrtime + nrerror;

%% Constraints:
nrineqconstraints = 2*V*V + 2*V*(V-1)*(V-2) + 2*V*V + V*V + V*(V-1)*(V-2) + V*V ;
nreqconstraints = 3*V; 

A = zeros(nrvars,nrineqconstraints);
Aeq = zeros(nrvars,nreqconstraints);

b = zeros(1,nrineqconstraints);
beq = zeros(1,nreqconstraints);

r = 1;

for m=1:2
    for s=1:V
        for v=1:V
            Pmsv(s,v,m)=(Cp(s,1)-Cp(v,1))/2+(deltam(s,1)+deltam(s,2)+tauJ(s,1))*(l(s,3))+deltam(s,m)*(l(s,m)-l(v,m))+1;
        end
    end
end
for s=1:V
    for v=1:V
        Ksv(s,v)=(Ck(s,1)-Ck(v,1))+deltaK(s,1)*(T(s,1)*1.01)+deltaK(s,2)*(T(s,2)*1.01)+deltaK(s,3)*min(T(s,:)*1.01)+1;
    end
end

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

%% PART III : Individual total childcare = private + joint childcare
r = 1;
for m=1:2
    for s=1:V
        Aeq(nrpref+nrpric+(s-1)*3+m,r) = 1;
        Aeq(nrpref+nrpric+(s-1)*3+3,r) = 1;
        Aeq(nrpref+nrpric+nrtime+(m-1)*V+s,r) = -1;
        beq(1,r) = T(s,m);
        
        r = r+1;
    end
end

%% PART IV : Joint leisure FOCs
for s=1:V
    Aeq(nrpref+s,r) = 1;
    Aeq(nrpref+V+s,r) = 1;
    
    beq(1,r) = deltam(s,1) + deltam(s,2) + tauJ(s,1);
    
    r = r+1;
end

%% PART V : Arbitrary objective function
f = zeros(nrvars,1);

% impose standard lower and upper bounds
lb = zeros(nrvars,1);
ub = Inf(nrvars,1);
ub(1:nrpref,1) = ones(nrpref,1);
for m=1:2
    for s=1:V
        lb(nrpref+nrpric+nrtime+(m-1)*V+s,1) = -0.01*T(s,m);
        ub(nrpref+nrpric+nrtime+(m-1)*V+s,1) = 0.01*T(s,m);
    end
end
intcon = (1:nrpref)';
options = optimoptions(@intlinprog,'Display','off');

% call optimizer
try
    [x,fmin,exitflag]=intlinprog(f,intcon,A',b',Aeq',beq',lb,ub,options);
catch
    exitflag=-99;
end

% generate output
if exitflag>0
    passindicator=1;
else
    passindicator=0;
end