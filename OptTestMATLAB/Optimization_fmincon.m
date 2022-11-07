clc, clear, format longg;
%READ Thrust File
file='C:/GMAT_Repo/OptTestMATLAB/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);

%Converts to vector
Thrust=zeros(33,1);
Thrust(1:11)=ThrustProfile(:,2);
Thrust(12:22)=ThrustProfile(:,3);
Thrust(23:33)=ThrustProfile(:,4);

%ThrustProfileNew(:,2)=Thrust(1:11);
%ThrustProfileNew(:,3)=Thrust(12:22);
%ThrustProfileNew(:,4)=Thrust(23:33);
%ThrustProfileNew(:,1)=ThrustProfile(:,1);
%ThrustProfileNew(:,5)=ThrustProfile(:,5)

%Inital guess 
x0=Thrust;
%Bounds
lb=0; ub=10;
options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter');
[xOpt, fOpt, exitflag, output, lambda]=fmincon("ObjFunc",x0, [],[],[],[],[],[],"NonLinCons",options);
%[xOpt, fOpt, exitflag, output, lambda]=fmincon("objFunc",x0, A,b, Aeq, beq, lb, ub,"nlcons",options);


%Equality constraints 
%Aeq=[1 2 0];
%beq=5;
%Inequality constraints 
%A=[1,-2,3; 0,2,3;3 -1 0];
%b=[3;5;2];  
%Inital guess 
%x0= [2;2;2];
%fmincon
%options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter');
%[xOpt, fOpt, exitflag, output, lambda]=fmincon("objFunc",x0, A,b, Aeq, beq, [],[],"nlcons",options);