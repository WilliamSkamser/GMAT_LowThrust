clc, clear, format longg;
%READ Thrust File
file='../OptTestMATLAB/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);

%Converts to vector
Thrust=zeros(33,1);
Thrust(1:11)=ThrustProfile(:,2);
Thrust(12:22)=ThrustProfile(:,3);
Thrust(23:33)=ThrustProfile(:,4);

%Inital guess 
x0=Thrust;
%Bounds
lb=0*ones(1,length(x0)); ub=10*ones(1,length(x0));
options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter');

%Load Script --> Run Fmincon
load_gmat();
Ans1=gmat.gmat.LoadScript("../OptTestMATLAB/OptTestMatlab.script");
if Ans1 == 1
    [xOpt, fOpt, exitflag, output, lambda]=fmincon("ObjFunc",x0, [],[],[],[],lb,ub,"NonLinCons",options);
else
    fprintf("Fail to load script\n");
end


