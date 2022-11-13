clc, clear, format longg;
%READ Thrust File
file='../GeostationaryOrbit_LowThrust/ThrustProfileInitialGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);


%Read Time Step from initial guess
NumberOfSteps=100; 
TimeStep=zeros(NumberOfSteps,1);
for i=1:NumberOfSteps
TimeStep(i)=ThrustProfile(i+1,1) - ThrustProfile(i,1);
end

%Converts to vector
%Thrust=zeros(43,1);
%Thrust(1:11)=ThrustProfile(:,2);
%Thrust(12:22)=ThrustProfile(:,3);
%Thrust(23:33)=ThrustProfile(:,4);
%Thrust(34:43)=TimeStep;%Time

Thrust=zeros(((NumberOfSteps+1)*3 + NumberOfSteps),1);
Thrust(1:(NumberOfSteps+1))=ThrustProfile(:,2);
Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) )=ThrustProfile(:,3);
Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) )=ThrustProfile(:,4);
Thrust( ((NumberOfSteps+1)*3 + 1) : ((NumberOfSteps+1)*3 + NumberOfSteps) )=TimeStep;

%Bounds
lb=zeros(1,length(Thrust)); ub=lb;
lb(1:length(Thrust)-NumberOfSteps)=-15;
ub(1:length(Thrust)-NumberOfSteps)=15;
lb(length(Thrust)-NumberOfSteps+1:end)=864*5;
ub(length(Thrust)-NumberOfSteps+1:end)=8640*5;




%Inital guess 
x0=Thrust;

options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter',...
                     'MaxIterations',300,'OptimalityTolerance',5e-4,...
                     'ConstraintTolerance',5e-4);
%options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter','MaxIterations',100,'OptimalityTolerance',1e-4);

%Load Script --> Run Fmincon
load_gmat();
Ans1=gmat.gmat.LoadScript("../GeostationaryOrbit_LowThrust/GMAT_Script.script");
if Ans1 == 1
    tic
    [xOpt, fOpt, exitflag, output, lambda]=fmincon("ObjFunc",x0, [],[],[],[],lb,ub,"NonLinCons",options);
    toc
else
    fprintf("Fail to load script\n");
end


