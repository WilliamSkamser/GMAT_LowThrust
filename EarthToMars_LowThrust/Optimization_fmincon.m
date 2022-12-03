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
MassFlowRate=4.2231e-6;

Thrust=zeros(((NumberOfSteps+1)*3 + 1),1);
Thrust(1:(NumberOfSteps+1))=ThrustProfile(:,2);
Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) )=ThrustProfile(:,3);
Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) )=ThrustProfile(:,4);
Thrust(end)=RunTime;

lb=zeros(1,length(Thrust)); ub=lb;
lb(1:length(Thrust)-1)=-0.1;
ub(1:length(Thrust)-1)=0.1;
lb(end)=0; ub(end)=(TotalFuelMass/MassFlowRate); %Max Runtime

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


%   Add Magnitude Part to NonLin
        %run
        %fix bug
%   Add anything else
%   Add Nested Fmincon for that reruns the whole optimization with new
%   Start time 
