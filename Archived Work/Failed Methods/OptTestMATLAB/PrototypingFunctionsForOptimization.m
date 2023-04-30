clc, clear, format longg;
%script used to run parts fmincon optimization for prototyping
%READ Thrust File
file='../OptTestMATLAB/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);

steps=10;
%Read Time Step from initial guess
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
                     'ConstraintTolerance',5e-4);
                 
ISP=1500;
g=9.80665;
%mdot= Tmag/(ISP*g0)?
MassUsed=0;

%Converts back to Matrix;
ThrustProfileNew(:,2)=Thrust(1:11);
ThrustProfileNew(:,3)=Thrust(12:22);
ThrustProfileNew(:,4)=Thrust(23:33);
%Converts Time step into time column
for i=1:steps
ThrustProfileNew(i+1,1)=ThrustProfileNew(i,1) + Thrust(i+33);
end


%ThrustProfileNew(2:steps+1,1)=Thrust(34:43)
for i=1:10
    ThrustProfileNew(i,5)=norm(ThrustProfileNew(i,2:4)) / (ISP * g); %mass flow rate 
    
    MassUsed=MassUsed+(ThrustProfileNew(i,5) * (ThrustProfileNew(i+1,1) - ThrustProfileNew(i,1)) );
end
     cons=zeros(steps,1);   
Aeq = zeros(steps,3);
beq= ones(steps,1);
for i=1:steps %if the optimization varibles are a unit vector then can use an equallity contraint within opt
    cons(i)=sqrt((ThrustProfileNew(i,2))^2 + (ThrustProfileNew(i,3))^2 + (ThrustProfileNew(i,4))^2);
    Aeq(i,1)= Thrust(i);
    Aeq(i,2)= Thrust(i+steps);
    Aeq(i,3)= Thrust(i+(2*steps));
end

ThrustTime=864000.0; 
%WRITE Thrust Run Time
file3='../OptTestMATLAB/ThrustRunTime.txt';
fid3 = fopen(file3, 'w');
fprintf(fid3, '%d', ThrustTime);
fclose(fid3);





%read file 


%ThrustVec(1) +

