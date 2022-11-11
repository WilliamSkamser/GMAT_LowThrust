clc, clear, format longg;
%READ Thrust File
file='../GeostationaryOrbit_LowThrust/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);

%Converts to vector
NumberOfSteps=100; 

Thrust=zeros(((NumberOfSteps+1)*3),1);
Thrust(1:(NumberOfSteps+1))=ThrustProfile(:,2);
Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) )=ThrustProfile(:,3);
Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) )=ThrustProfile(:,4);

%Inital guess 
x0=Thrust;
%Bounds
lb=0*ones(1,length(x0)); ub=10*ones(1,length(x0));
options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter','MaxIterations',100,'OptimalityTolerance',1e-4);

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


