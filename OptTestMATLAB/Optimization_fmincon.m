clc, clear, format longg;
%READ Thrust File
file='../OptTestMATLAB/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);


%Read Time Step from initial guess
steps=10;
TimeStep=zeros(steps,1);
for i=1:steps
TimeStep(i)=ThrustProfile(i+1,1) - ThrustProfile(i,1);
end

%Converts to vector
Thrust=zeros(43,1);
Thrust(1:11)=ThrustProfile(:,2);
Thrust(12:22)=ThrustProfile(:,3);
Thrust(23:33)=ThrustProfile(:,4);
Thrust(34:43)=TimeStep;%Time

%Bounds
lb=zeros(1,length(Thrust)); ub=lb;
lb(1:length(Thrust)-steps)=-15;
ub(1:length(Thrust)-steps)=15;
lb(length(Thrust)-steps+1:end)=8640*5;
ub(length(Thrust)-steps+1:end)=86400*5;

x0=Thrust;
options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter',...
                     'MaxIterations',300,'OptimalityTolerance',5e-4,...
                     'ConstraintTolerance',5e-4);%'StepTolerance',1e-10);



%'ObjectiveLimit',1526);
%options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter',...
%                     'ObjectiveLimit',1526,'UseParallel','always');
%Load Script --> Run Fmincon
load_gmat();
Ans1=gmat.gmat.LoadScript("../OptTestMATLAB/OptTestMatlab.script");
if Ans1 == 1
    tic
    [xOpt, fOpt, exitflag, output, lambda]=fmincon("ObjFunc",x0, [],[],[],[],lb,ub,"NonLinCons",options);
    toc
else
    fprintf("Fail to load script\n");
end


