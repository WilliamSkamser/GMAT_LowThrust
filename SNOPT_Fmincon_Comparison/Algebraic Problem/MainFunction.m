clear, clc, format longg

%Design Variable 
% initial guess
x= [2;2;2];
%lower and upper bounds
xlow = [-inf;-inf;-inf];
xupp = [inf; inf; inf];

%Objective Function
%bounds on objective function
Flow=zeros(3, 1);
Fupp=zeros(3, 1);
Flow(1) = -inf;
Fupp(1) = +Inf;
%bounds on equality constraints
Flow(2) = 0.0;
Fupp(2) = 0.0;
%bounds of inequality constraints
Flow(3) = -inf;
Fupp(3) = 0;

%Multiplier and state of design variable x and function F
xmul = zeros(3, 1);
xstate = zeros(3, 1);
Fmul = zeros(3, 1);
Fstate = zeros(3, 1);

%%Fmincon
optionsFMC=optimoptions('fmincon','Algorithm', 'sqp','Display','iter');
[xOpt,fOpt,exitflag,output2,lambda]=fmincon("objFuncFMC",x,[],[],[],[],...
    xlow,xupp,"nlconsFMC",optionsFMC);
[c,ceq]=nlconsFMC(xOpt);
fprintf("\n\n");

%%SNOPT
snscreen on;  
%create summary file
snsummary('SNOPt_summary.txt');
[x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
    snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate, 'objFuncSNOPT');
[FOut, G] = objFuncSNOPT(x);

fprintf("\n\n");
fprintf("Fmincon x output is \n")
disp(xOpt)
fprintf("Fmincon ObjFunction output is %d \n",objFuncFMC(xOpt))
fprintf("Fmincon Inequality Constraint output is %d \n",c)
fprintf("Fmincon Equality Constraint output is %d \n\n",ceq)
fprintf("SNOPT x output is \n")
disp(x)
fprintf("SNOPT ObjFunction output is %d \n",FOut(1))
fprintf("SNOPT Inequality Constraint output is %d \n",FOut(3))
fprintf("SNOPT Equality Constraint output is %d \n",FOut(2))


