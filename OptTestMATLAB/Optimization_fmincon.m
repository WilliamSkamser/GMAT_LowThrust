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
                        %Add Propgation time
%Bounds
lb=zeros(1,length(Thrust)); ub=lb;
lb(1:length(Thrust)-steps)=-11.75;
ub(1:length(Thrust)-steps)=11.75;
lb(length(Thrust)-steps+1:end)=8640;
ub(length(Thrust)-steps+1:end)=86400*3;
                                        %Bounds for Propagation time
%Constraint magnitude   Must be a nonlinear eq
%mag=15;
%Aeq = zeros(steps,3);
%beq= ones(steps,1);
%for i=1:steps 
%    Aeq(i,1)= 1/mag;
%    Aeq(i,2)= 1/mag;
 %   Aeq(i,3)= 1/mag;
%end


x0=Thrust;
options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter',...
                     'MaxIterations',300,'OptimalityTolerance',5e-4,...
                     'ConstraintTolerance',5e-4,'StepTolerance',1e-11);

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
%{
%OUTLOOK
No script provided to load.
 Iter  Func-count            Fval   Feasibility   Step Length       Norm of   First-order  
                                                                       step    optimality
    0          44    3.618536e+02     3.530e+03     1.000e+00     0.000e+00     3.147e+00  
    1          89    4.238471e+02     2.238e+03     7.000e-01     2.184e+01     1.228e+03  
    2         135    4.405810e+02     2.167e+03     4.900e-01     7.529e+03     6.071e+07  
    3         181    4.512972e+02     1.909e+03     4.900e-01     2.445e+03     4.918e+07  
    4         276    4.512972e+02     1.909e+03     1.259e-08     2.916e-03     4.918e+07  
    5         323    4.427385e+02     1.916e+03     3.430e-01     9.187e+04     2.734e+08  
    6         407    4.427385e+02     1.916e+03     6.367e-07     1.593e-01     2.734e+08  
    7         458    4.375792e+02     1.209e+03     8.235e-02     1.677e+04     3.065e+08  
    8         510    4.382812e+02     1.635e+03     5.765e-02     1.721e+04     3.282e+08  
    9         595    4.382812e+02     1.635e+03     4.457e-07     1.391e-01     3.282e+08  
   10         653    4.380452e+02     1.635e+03     6.782e-03     2.118e+03     3.281e+08  
   11         707    4.373342e+02     1.629e+03     2.825e-02     8.967e+03     3.407e+08  
   12         762    4.368812e+02     1.628e+03     1.977e-02     5.813e+03     3.484e+08  
   13         816    4.363862e+02     1.619e+03     2.825e-02     7.744e+03     3.589e+08  
   14         868    4.355995e+02     1.615e+03     5.765e-02     1.391e+04     3.827e+08  
   15         951    4.355995e+02     1.615e+03     9.095e-07     2.537e-01     3.827e+08  
   16        1004    4.347972e+02     1.613e+03     4.035e-02     1.108e+04     3.953e+08  
   17        1058    4.344346e+02     1.607e+03     2.825e-02     8.694e+03     4.051e+08  
   18        1113    4.341125e+02     1.602e+03     1.977e-02     5.039e+03     4.120e+08  
   19        1166    4.334584e+02     1.605e+03     4.035e-02     1.031e+04     4.260e+08  
   20        1219    4.333004e+02     1.604e+03     4.035e-02     1.045e+04     4.380e+08  
   21        1301    4.333004e+02     1.604e+03     1.299e-06     4.077e-01     4.379e+08  
   22        1358    4.332923e+02     1.605e+03     9.689e-03     2.719e+03     4.410e+08  
   23        1440    4.332923e+02     1.605e+03     1.299e-06     3.029e-01     4.409e+08  
   24        1492    4.324111e+02     1.606e+03     5.765e-02     1.371e+04     4.583e+08  
   25        1545    4.323216e+02     1.607e+03     4.035e-02     1.098e+04     4.726e+08  
   26        1627    4.323216e+02     1.607e+03     1.299e-06     3.182e-01     4.726e+08  
   27        1683    4.324439e+02     1.606e+03     1.384e-02     4.550e+03     4.756e+08  
   28        1765    4.324439e+02     1.606e+03     1.299e-06     3.586e-01     4.756e+08  
   29        1857    4.324439e+02     1.606e+03     3.670e-08     1.220e-02     4.756e+08  
 Iter  Func-count            Fval   Feasibility   Step Length       Norm of   First-order  
                                                                       step    optimality
   30        1954    4.324439e+02     1.606e+03     6.169e-09     2.067e-03     4.756e+08  
   31        2051    4.324439e+02     1.606e+03     6.169e-09     7.610e-04     4.756e+08  
   32        2154    4.324439e+02     1.606e+03     7.257e-10     8.614e-05     4.756e+08  
   33        2261    4.324439e+02     1.606e+03     1.743e-10     2.084e-05     4.756e+08  
   34        2374    4.324439e+02     1.606e+03     2.050e-11     2.447e-06     4.756e+08  
   35        2492    4.324439e+02     1.606e+03     3.446e-12     4.120e-07     4.757e+08  
   36        2608    4.324439e+02     1.606e+03     7.032e-12     8.360e-07     4.756e+08  
   37        2766    4.324439e+02     1.606e+03     5.791e-13     1.295e-07     4.756e+08  

Converged to an infeasible point.

fmincon stopped because the size of the current step is less than
the value of the step size tolerance but constraints are not
satisfied to within the value of the constraint tolerance.

<stopping criteria details>
Elapsed time is 3745.866965 seconds.
%}

