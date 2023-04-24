clc, clear, format longg;
%READ Thrust File
file='../EarthToMars_LowThrust/InitialGuessThrustProfile.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);
NumberOfSteps=200;


%{
    %Old Method
%Read Time Step from initial guess
TimeStep=zeros(NumberOfSteps,1);
for i=1:NumberOfSteps
TimeStep(i)=ThrustProfile(i+1,1) - ThrustProfile(i,1);
end

Thrust=zeros(((NumberOfSteps+1)*3 + NumberOfSteps),1);
Thrust(1:(NumberOfSteps+1))=ThrustProfile(:,2);
Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) )=ThrustProfile(:,3);
Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) )=ThrustProfile(:,4);
Thrust( ((NumberOfSteps+1)*3 + 1) : ((NumberOfSteps+1)*3 + NumberOfSteps) )=TimeStep;

Magnitude=zeros(NumberOfSteps+1,1);
for i=1:NumberOfSteps+1
Magnitude(i)=norm([ThrustProfile(i,2) ThrustProfile(i,3) ThrustProfile(i,4)]);
end

%Bounds
lb=zeros(1,length(Thrust)); ub=lb;
lb(1:length(Thrust)-NumberOfSteps)=-0.1;
ub(1:length(Thrust)-NumberOfSteps)=0.1;
%lb(length(Thrust)-NumberOfSteps+1:end)=864*5;
%ub(length(Thrust)-NumberOfSteps+1:end)=8640*5;
%}


RunTime=ThrustProfile(end,1);
TotalFuelMass=400;
Magnitude=0.116;
ISP=2800;
g=9.80665;
MaxMassFlowRate=Magnitude / (ISP * g);




%%%%MassFlowRate=4.2231e-6;

Thrust=zeros(((NumberOfSteps+1)*3 + 1),1);
Thrust(1:(NumberOfSteps+1))=ThrustProfile(:,2);
Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) )=ThrustProfile(:,3);
Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) )=ThrustProfile(:,4);
Thrust(end)=RunTime;

lb=zeros(1,length(Thrust)); ub=lb;
lb(1:length(Thrust)-1)=-Magnitude;
ub(1:length(Thrust)-1)=Magnitude;
lb(end)=0; ub(end)=(TotalFuelMass/MaxMassFlowRate); %Max Runtime

%Inital guess 
x0=Thrust;

options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter',...
                     'MaxIterations',300,'OptimalityTolerance',5e-4,...
                     'ConstraintTolerance',5e-4,'StepTolerance',1e-10);
%options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter','MaxIterations',100,'OptimalityTolerance',1e-4);

%Load Script --> Run Fmincon
load_gmat();
Ans1=gmat.gmat.LoadScript("../EarthToMars_LowThrust/GMATScriptEarthMars_plots.script");
if Ans1 == 1
    tic
    [xOpt, fOpt, exitflag, output, lambda]=fmincon("ObjFunc",x0, [],[],[],[],lb,ub,"NonLinCons",options);
    toc
else
    fprintf("Fail to load script\n");
end


%{ 
OUTPUT:

No script provided to load.
 Iter  Func-count            Fval   Feasibility   Step Length       Norm of   First-order  
                                                                       step    optimality
    0         605    3.522291e+02     2.472e+08     1.000e+00     0.000e+00     4.223e-06  
    1        1212    3.521415e+02     2.472e+08     4.900e-01     2.074e+04     4.223e-06  
    2        1818    3.556514e+02     2.472e+08     7.000e-01     8.311e+05     4.223e-06  
    3        2423    3.880455e+02     2.472e+08     1.000e+00     7.671e+06     4.223e-06  
    4        3031    3.686485e+02     2.472e+08     3.430e-01     4.593e+06     4.223e-06  
    5        3647    3.692684e+02     2.472e+08     1.977e-02     1.468e+05     4.223e-06  
    6        4254    3.789818e+02     2.472e+08     4.900e-01     2.300e+06     4.223e-06  
    7        4318    3.789818e+02     2.472e+08     1.220e-10     6.630e-03     4.223e-06  

Converged to an infeasible point.

fmincon stopped because the size of the current step is less than
the value of the step size tolerance but constraints are not
satisfied to within the value of the constraint tolerance.

<stopping criteria details>
Elapsed time is 3867.268945 seconds.


%}




