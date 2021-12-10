function pass = togetherness_egoistic(l,Cp,T,Ck,deltam,deltaK,gamma)

V = size(T,1);

smallnumber = 0.0005;

%% Variables:
nrpref = 3*V*V ; % binary preference variables
nrvars = nrpref ;

%% Constraints:
nrineqconstraints = 2*V*V + 2*V*(V-1)*(V-2) + 2*V*V + V*V + V*(V-1)*(V-2) + V*V ;

A = zeros(nrvars,nrineqconstraints);
b = zeros(1,nrineqconstraints);

for m=1:2
    for s=1:V
        for v=1:V
            Pmsv(s,v,m)=Cp(s,1)+(deltam(s,1)+deltam(s,2)+gamma(s,1))*(l(s,3))+deltam(s,m)*(l(s,m)-l(v,m))+1;            
        end
    end
end
for s=1:V
    for v=1:V
        Ksv(s,v)=(Ck(s,1)-Ck(v,1))+deltaK(s,1)*T(s,1)+deltaK(s,2)*T(s,2)+1;        
    end
end

r = 1;

%% PART I : GARP for parents m=1,2 
% opening GARP
for m=1:2
    for s=1:V
        for v=1:V
            A((m-1)*V*V+(s-1)*V+v,r) = -Pmsv(s,v,m);
            
            b(1,r) = 0-smallnumber-(Cp(s,1)-Cp(v,1))/2-deltam(s,m)*(l(s,m)+l(s,3)-l(v,m)-l(v,3));
            
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
                       
            b(1,r) = Pmsv(v,s,m)-(Cp(v,1)-Cp(s,1))/2-deltam(v,m)*(l(v,m)+l(v,3)-l(s,m)-l(s,3));
            
            r = r+1;
        end
    end
end

%% PART II : GARP for children
% opening GARP
for s=1:V
    for v=1:V
        A(2*V*V+(s-1)*V+v,r) = -Ksv(s,v);
        
        b(1,r) = 0-smallnumber-(Ck(s,1)-Ck(v,1))-deltaK(s,1)*(T(s,1)-T(v,1))-deltaK(s,2)*(T(s,2)-T(v,2));

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
        
        b(1,r) = Ksv(v,s)-(Ck(v,1)-Ck(s,1))-deltaK(v,1)*(T(v,1)-T(s,1))-deltaK(v,2)*(T(v,2)-T(s,2));

        r = r+1;
    end
end

%% PART III : Arbitrary objective function
f = zeros(nrvars,1);

% impose standard lower and upper bounds
lb = zeros(nrvars,1);
ub = ones(nrvars,1);
intcon = (1:nrpref)';
options = optimoptions(@intlinprog,'Display','off');

% call optimizer
try
    [x,fmin,exitflag]=intlinprog(f,intcon,A',b',[],[],lb,ub,[],options);
catch
    exitflag=-99;
end

% generate output
if exitflag>0
    pass=1;
else
    pass=NaN;
end
