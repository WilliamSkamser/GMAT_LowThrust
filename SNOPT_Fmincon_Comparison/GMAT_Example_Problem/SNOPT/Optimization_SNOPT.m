clc, clear, format longg;
%READ Thrust File
file='../SNOPT/ThrustProfileInitalGuess.thrust';
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
lb(1:length(Thrust)-steps)=-11.75;
ub(1:length(Thrust)-steps)=11.75;
lb(length(Thrust)-steps+1:end)=8640;
ub(length(Thrust)-steps+1:end)=86400*3;

%lower and upper bounds
xlow = lb.';
xupp = ub.';

%Objective Function
%bounds on objective function
Flow=zeros(7, 1);
Fupp=zeros(7, 1);
Flow(1) = 0;
Fupp(1) = inf;

%bounds of inequality constraints
Flow(2) = 0;
Fupp(2) = inf;
Flow(3) = 0;
Fupp(3) = inf;
%bounds on equality constraints
Flow(4) = 0.0;
Fupp(4) = 0.0;
Flow(5) = 0.0;
Fupp(5) = 0.0;
Flow(6) = 0.0;
Fupp(6) = 0.0;
Flow(7) = 0.0;
Fupp(7) = 0.0;
%Multiplier and state of design variable x and function F
xmul = zeros(43, 1);
xstate = zeros(43, 1);
Fmul = zeros(7, 1);
Fstate = zeros(7, 1);

x=Thrust;

%% SNOPT
ObjAdd =0; %Add value to objective Row
ObjRow =1; %Tell the Optimizer which row of F is the objective function

snscreen on;  
%snset("Minimize")
%create summary file
snsummary('SNOPt_summary.txt');
%tolerance values, 1e-6 by default 
snsetr('Major feasibility tolerance',1e-6); 
snsetr('Major optimality tolerance',1e-6);
snsetr('Minor feasibility tolerance',1e-6);
snsetr('Minor optimality tolerance',1e-6);

snseti('Time limit',86400) %Sets time limit to 1 day (in seconds)
snseti('Major iteration limit', 50); %This Part works
%snseti('Line search algorithm', 0)%Backtracking line search
%978.350514 seconds
%4030.811555 seconds
%snseti('Line search algorithm', 1)%Cubic interpolation line search
%Elapsed time is 957.632867 seconds.
%4036.226564 seconds
%snseti('Line search algorithm', 2)%Quadratic interpolation line search
%Elapsed time is 959.322889 seconds.
%4047.746310 seconds.
snseti('Line search algorithm', 3)%More-Thuente line search
%960.379717 seconds
%Elapsed time is 3730.946508 seconds.
%7.43932190598278 faster 


load_gmat();
Ans1=gmat.gmat.LoadScript("../SNOPT/OptTestMatlab.script");
if Ans1 == 1
    tic
[x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
    snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate, 'objFuncSNOPT', ObjAdd, ObjRow);
    toc
else
    fprintf("Fail to load script\n");
end
%{
Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    10      2  2.8E-03     11  2.3E-04  6.4E-03  1.0369496E+03     13 1.5E+00
 
 SNOPTA EXIT  30 -- resource limit error
 SNOPTA INFO  32 -- major iteration limit reached

 Problem name
 No. of iterations                  88   Objective            4.3481542123E+02
 No. of major iterations            10   Linear    obj. term  0.0000000000E+00
 Penalty parameter           1.462E+00   Nonlinear obj. term  4.3481542123E+02
 User function calls (total)       481   Calls with modes 1,2 (known g)     11
 Calls for forward differencing    440   Calls for central differencing      0
 No. of superbasics                 13   No. of basic nonlinears             4
 No. of degenerate steps             0   Percentage                       0.00
 Max x                      38 8.6E+04   Max pi                      3 1.7E+05
 Max Primal infeas           0 0.0E+00   Max Dual infeas             1 1.1E+03
 Nonlinear constraint violn    2.0E+01
 
 

 Solution printed on file   9
 
 Time for MPS input                             0.00 seconds
 Time for solving problem                     370.56 seconds
 Time for solution output                       0.00 seconds
 Time for constraint functions                371.30 seconds
 Time for objective function                    0.00 seconds
Elapsed time is 978.350514 seconds.

Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    10      1  1.8E-03     11  2.3E-04  6.5E-03  1.0343519E+03     14 1.4E+00
 
 SNOPTA EXIT  30 -- resource limit error
 SNOPTA INFO  32 -- major iteration limit reached

 Problem name
 No. of iterations                  87   Objective            4.3482030711E+02
 No. of major iterations            10   Linear    obj. term  0.0000000000E+00
 Penalty parameter           1.447E+00   Nonlinear obj. term  4.3482030711E+02
 User function calls (total)       481   Calls with modes 1,2 (known g)     11
 Calls for forward differencing    440   Calls for central differencing      0
 No. of superbasics                 14   No. of basic nonlinears             4
 No. of degenerate steps             0   Percentage                       0.00
 Max x                      38 8.6E+04   Max pi                      3 1.7E+05
 Max Primal infeas           0 0.0E+00   Max Dual infeas             1 1.1E+03
 Nonlinear constraint violn    2.0E+01
 
 

 Solution printed on file   9
 
 Time for MPS input                             0.00 seconds
 Time for solving problem                     362.73 seconds
 Time for solution output                       0.00 seconds
 Time for constraint functions                363.53 seconds
 Time for objective function                    0.00 seconds
Elapsed time is 957.632867 seconds.





 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    10      1  1.8E-03     11  2.3E-04  6.5E-03  1.0343519E+03     14 1.4E+00
 
 SNOPTA EXIT  30 -- resource limit error
 SNOPTA INFO  32 -- major iteration limit reached

 Problem name
 No. of iterations                  87   Objective            4.3482030711E+02
 No. of major iterations            10   Linear    obj. term  0.0000000000E+00
 Penalty parameter           1.447E+00   Nonlinear obj. term  4.3482030711E+02
 User function calls (total)       481   Calls with modes 1,2 (known g)     11
 Calls for forward differencing    440   Calls for central differencing      0
 No. of superbasics                 14   No. of basic nonlinears             4
 No. of degenerate steps             0   Percentage                       0.00
 Max x                      38 8.6E+04   Max pi                      3 1.7E+05
 Max Primal infeas           0 0.0E+00   Max Dual infeas             1 1.1E+03
 Nonlinear constraint violn    2.0E+01
 
 

 Solution printed on file   9
 
 Time for MPS input                             0.00 seconds
 Time for solving problem                     360.62 seconds
 Time for solution output                       0.00 seconds
 Time for constraint functions                361.33 seconds
 Time for objective function                    0.00 seconds
Elapsed time is 959.322889 seconds.
%}


%{
 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    50     43  9.9E-05     60  2.1E-04  1.0E-02  1.6811074E+03     17 6.3E+00
 
 SNOPTA EXIT  30 -- resource limit error
 SNOPTA INFO  32 -- major iteration limit reached

 Problem name
 No. of iterations                1393   Objective            4.1775572949E+02
 No. of major iterations            50   Linear    obj. term  0.0000000000E+00
 Penalty parameter           6.258E+00   Nonlinear obj. term  4.1775572949E+02
 User function calls (total)      2624   Calls with modes 1,2 (known g)     60
 Calls for forward differencing   2400   Calls for central differencing      0
 No. of superbasics                 17   No. of basic nonlinears             4
 No. of degenerate steps             0   Percentage                       0.00
 Max x                      32 9.1E+04   Max pi                      3 3.8E+03
 Max Primal infeas           0 0.0E+00   Max Dual infeas             1 3.9E+01
 Nonlinear constraint violn    1.9E+01
 
 

 Solution printed on file   9
 
 Time for MPS input                             0.00 seconds
 Time for solving problem                    1979.94 seconds
 Time for solution output                       0.00 seconds
 Time for constraint functions               1980.59 seconds
 Time for objective function                    0.00 seconds
Elapsed time is 4030.811555 seconds.








 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    50     43  9.9E-05     60  2.1E-04  1.0E-02  1.6811074E+03     17 6.3E+00
 
 SNOPTA EXIT  30 -- resource limit error
 SNOPTA INFO  32 -- major iteration limit reached

 Problem name
 No. of iterations                1393   Objective            4.1775572949E+02
 No. of major iterations            50   Linear    obj. term  0.0000000000E+00
 Penalty parameter           6.258E+00   Nonlinear obj. term  4.1775572949E+02
 User function calls (total)      2624   Calls with modes 1,2 (known g)     60
 Calls for forward differencing   2400   Calls for central differencing      0
 No. of superbasics                 17   No. of basic nonlinears             4
 No. of degenerate steps             0   Percentage                       0.00
 Max x                      32 9.1E+04   Max pi                      3 3.8E+03
 Max Primal infeas           0 0.0E+00   Max Dual infeas             1 3.9E+01
 Nonlinear constraint violn    1.9E+01
 
 

 Solution printed on file   9
 
 Time for MPS input                             0.00 seconds
 Time for solving problem                    1981.91 seconds
 Time for solution output                       0.00 seconds
 Time for constraint functions               1982.47 seconds
 Time for objective function                    0.00 seconds
Elapsed time is 4036.226564 seconds.






 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    50     43  9.9E-05     60  2.1E-04  1.0E-02  1.6811074E+03     17 6.3E+00
 
 SNOPTA EXIT  30 -- resource limit error
 SNOPTA INFO  32 -- major iteration limit reached

 Problem name
 No. of iterations                1393   Objective            4.1775572949E+02
 No. of major iterations            50   Linear    obj. term  0.0000000000E+00
 Penalty parameter           6.258E+00   Nonlinear obj. term  4.1775572949E+02
 User function calls (total)      2624   Calls with modes 1,2 (known g)     60
 Calls for forward differencing   2400   Calls for central differencing      0
 No. of superbasics                 17   No. of basic nonlinears             4
 No. of degenerate steps             0   Percentage                       0.00
 Max x                      32 9.1E+04   Max pi                      3 3.8E+03
 Max Primal infeas           0 0.0E+00   Max Dual infeas             1 3.9E+01
 Nonlinear constraint violn    1.9E+01
 
 

 Solution printed on file   9
 
 Time for MPS input                             0.00 seconds
 Time for solving problem                    1989.41 seconds
 Time for solution output                       0.00 seconds
 Time for constraint functions               1990.06 seconds
 Time for objective function                    0.00 seconds
Elapsed time is 4047.746310 seconds.
%}

