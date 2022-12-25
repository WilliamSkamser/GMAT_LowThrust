clc, clear, format longg;
%READ Thrust File
file='../Fmincon/ThrustProfileInitalGuess.thrust';
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
                        %Add Propgation time
%Bounds
lb=zeros(1,length(Thrust)); ub=lb;
lb(1:length(Thrust)-steps)=-11.75;
ub(1:length(Thrust)-steps)=11.75;
lb(length(Thrust)-steps+1:end)=8640;
ub(length(Thrust)-steps+1:end)=86400*3;



x0=Thrust;
options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter',...
                     'MaxIterations',300,'OptimalityTolerance',5e-4,...
                     'ConstraintTolerance',5e-4,'StepTolerance',1e-11);

%'ObjectiveLimit',1526);
%options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter',...
%                     'ObjectiveLimit',1526,'UseParallel','always');
%Load Script --> Run Fmincon
load_gmat();
Ans1=gmat.gmat.LoadScript("../Fmincon/OptTestMatlab.script");
if Ans1 == 1
    tic
    [xOpt, fOpt, exitflag, output, lambda]=fmincon("ObjFunc",x0, [],[],[],[],lb,ub,"NonLinCons",options);
    toc
else
    fprintf("Fail to load script\n");
end
%% Output Save
%{
No script provided to load.
 Iter  Func-count            Fval   Feasibility   Step Length       Norm of   First-order  
                                                                       step    optimality
    0          44    3.618536e+02     3.530e+03     1.000e+00     0.000e+00     3.147e+00  
    1          88    4.575560e+02     2.851e+03     1.000e+00     2.843e+01     1.250e+03  
    2         137    4.609281e+02     2.532e+03     1.681e-01     5.956e+00     1.200e+03  
    3         193    4.599096e+02     2.498e+03     1.384e-02     6.102e-01     1.180e+03  
    4         349    4.599096e+02     2.498e+03     8.273e-13     3.887e-11     1.180e+03  

Converged to an infeasible point.

fmincon stopped because the size of the current step is less than
the value of the step size tolerance but constraints are not
satisfied to within the value of the constraint tolerance.

<stopping criteria details>
Elapsed time is 633.280723 seconds.
%}
