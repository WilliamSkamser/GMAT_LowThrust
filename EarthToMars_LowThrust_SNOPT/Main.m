clc
clear all;
close all;
format longg;

global NumberOfSteps
global Th
global mdot
global AU
global TU
%lobal my_dir
global headlines
global t1

% Load Semi-Analytic Solution
load('EMTG_GMATdata.mat')

%READ initial guess with 200 steps
fileG='../EarthToMars_LowThrust_SNOPT/GMAT_thrust.txt';
fIDG=fopen(fileG,'r');
AG=textscan(fIDG, '%f %f %f %f', 'headerlines',1);
InitialGuess_Data2=cell2mat(AG);
fclose(fIDG);
NumberOfSteps_i=size(InitialGuess_Data2(:,1));
Alpha_i=InitialGuess_Data2(:,2);
Beta_i=InitialGuess_Data2(:,3);
Time_i=InitialGuess_Data2(end,1);
%% Constants

muS = 1.32712440018e+11;   % Km^3/sec^2 
g   = 9.81;                 % m/s^2
AU  = 149598000;            % km
TU  = sqrt(AU^3/muS);       % sec
VU  = AU/TU;                % km/sec

Th = 0.1;               % kg m/s^2
Isp = 2800;             % s^-1
Vex = Isp*g;            % m/s
m0  = 1000;             % kg
mdot  = GMAT_data.MassFlowRate;
t1=juliandate(2023,07,20,00,00,00);

% Obtain the Time steps
%NumberOfSteps = length(GMAT_data.Time)-2;%Cut-off ends %100 steps
NumberOfSteps=NumberOfSteps_i(1);   %200 steps
%% Initial Guess vector (Alpha, Beta, TOF)

%x=[GMAT_data.Alpha;GMAT_data.Beta;GMAT_data.TOF/TU]; %100 Steps
x=[Alpha_i;Beta_i;Time_i/TU];  %200 Steps
% Bounds
lb = [-ones(NumberOfSteps,1)*pi;    % Alpha
      -ones(NumberOfSteps,1)*pi;    % Beta  
      10*86400/TU];             % TOF (TU) %900
  
ub = [ones(NumberOfSteps,1)*pi;     % Alpha 
      ones(NumberOfSteps,1)*pi;     % Beta 
      3500*86400/TU];            % TOF (TU) %1100
     %3500 works
%{     
%lower and upper bounds
xlow = lb;
xupp = ub;
%bounds on objective function
Flow=zeros(7, 1);
Fupp=zeros(7, 1);
Flow(1) = 0;
Fupp(1) = ub(end);%inf;
%bounds of constraints
Flow(2:7) = 0;
Fupp(2:7) = 0;
%Multiplier and state of design variable x and function F
xmul = zeros(length(lb), 1); %Lagrange multipliers
xstate = zeros(length(lb), 1);
Fmul = zeros(7, 1); %Lagrange multipliers
Fstate = zeros(7, 1);
%}
% Directory Path to create Temp Files
my_dir = 'C:/GMAT_Repo/EarthToMars_LowThrust_SNOPT';

% Headlines for the Thrust File
headlines = ['BeginThrust{ThrustSegment1}', newline,...
    'Start_Epoch = 20 Jul 2023 00:00:00.000',newline,...
    'Thrust_Vector_Coordinate_System = SunICRF',newline,...  
    'Thrust_Vector_Interpolation_Method  = None',newline,... %%CubicSpline
    'Mass_Flow_Rate_Interpolation_Method = None',newline,...
    'ModelThrustAndMassRate'];              

%% SNOPT Optimization Routine
%{
ObjAdd =0; %Add value to objective Row
ObjRow =1; %Tell the Optimizer which row of F is the objective function

snscreen on;  
snsummary('SNOPt_summary.txt');
%tolerance values, 1e-6 by default 
snsetr('Major feasibility tolerance',1e-6); 
snsetr('Major optimality tolerance',9.9e+1);%1e-6);
snsetr('Minor feasibility tolerance',1e-6);
snsetr('Minor optimality tolerance',9.9e+1);%1e-6);

snseti('Time limit',345600);%86400) %Sets time limit to 1 day (in seconds)
snseti('Major iteration limit', 5000);
snseti('Line search algorithm', 3)%More-Thuente line search
%Around 5% faster than default ,0) Backtracking line search
%}
load_gmat(); %Load GMAT here tends to cause higher likelihood of SNOPT crashing MATLAB

tic
%[x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
%    snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate, 'objFunc_conFunc', ObjAdd, ObjRow);

options=optimoptions('fmincon','Algorithm', 'sqp','Display','iter',...
                     'MaxIterations',200,'OptimalityTolerance',1e-6,...
                     'ConstraintTolerance',1e-6,'MaxFunctionEvaluations',9e+09);
[xOpt, fOpt, exitflag, output, lambda]=fmincon("ObjFunc",x, [],[],[],[],lb,ub,"NonLinCons",options);

toc

%% Solution Visualization
[DataOpt,ThrustAccOpt,TOFOpt] = SolutionVisualization(x);


%{
No script provided to load.
Your initial point x0 is not between bounds lb and ub; FMINCON
shifted x0 to satisfy the bounds.
 Iter  Func-count            Fval   Feasibility   Step Length       Norm of   First-order  
                                                                       step    optimality
    0         402    1.660585e+01     1.589e+00     1.000e+00     0.000e+00     1.000e+00  
    1         804    1.938948e+01     8.505e-01     1.000e+00     1.064e+01     2.011e+02  
    2        1206    1.879245e+01     5.466e-01     1.000e+00     1.177e+01     5.392e+00  
    3        1608    1.905738e+01     3.956e-02     1.000e+00     3.573e+00     6.661e+00  
    4        2011    1.882032e+01     2.709e-02     1.000e+00     3.748e+00     1.106e+01  
    5        2413    1.871320e+01     9.354e-03     1.000e+00     1.775e+00     6.101e-01  
    6        2815    1.871944e+01     2.788e-04     1.000e+00     1.642e-01     3.668e-01  
    7        3217    1.869438e+01     9.197e-05     1.000e+00     1.832e-01     5.673e-01  
    8        3619    1.859967e+01     8.921e-04     1.000e+00     7.117e-01     3.736e-01  
    9        4021    1.837686e+01     3.064e-03     1.000e+00     1.769e+00     1.491e-01  
   10        4423    1.799493e+01     1.724e-02     1.000e+00     3.165e+00     1.253e+00  
   11        4825    1.784501e+01     5.141e-03     1.000e+00     1.546e+00     7.317e-01  
   12        5227    1.768636e+01     6.243e-03     1.000e+00     1.769e+00     6.956e-01  
   13        5629    1.747080e+01     1.632e-02     1.000e+00     2.358e+00     3.998e-01  
   14        6031    1.709794e+01     7.951e-02     1.000e+00     4.544e+00     3.195e-01  
   15        6433    1.698900e+01     2.506e-02     1.000e+00     2.461e+00     5.682e-01  
   16        6835    1.685295e+01     3.329e-02     1.000e+00     2.750e+00     1.065e+00  
   17        7237    1.681679e+01     8.217e-03     1.000e+00     1.514e+00     3.460e-01  
   18        7639    1.678768e+01     3.789e-03     1.000e+00     1.101e+00     5.831e-01  
   19        8041    1.674094e+01     2.251e-03     1.000e+00     7.233e-01     6.560e-01  
   20        8443    1.666172e+01     4.841e-03     1.000e+00     1.053e+00     8.482e-01  
   21        8845    1.656175e+01     7.746e-03     1.000e+00     1.400e+00     4.537e-01  
   22        9247    1.647224e+01     4.717e-03     1.000e+00     1.229e+00     3.225e-01  
   23        9649    1.642767e+01     1.854e-03     1.000e+00     7.595e-01     6.208e-01  
   24       10051    1.639640e+01     9.219e-04     1.000e+00     5.513e-01     4.276e-01  
   25       10453    1.632122e+01     4.453e-03     1.000e+00     1.323e+00     5.853e-01  
   26       10855    1.627646e+01     2.820e-03     1.000e+00     9.022e-01     3.166e-01  
   27       11257    1.621270e+01     5.838e-03     1.000e+00     1.395e+00     4.364e-01  
   28       11659    1.618223e+01     3.027e-03     1.000e+00     9.403e-01     3.442e-01  
   29       12061    1.615553e+01     2.454e-03     1.000e+00     8.372e-01     5.418e-01  
 Iter  Func-count            Fval   Feasibility   Step Length       Norm of   First-order  
                                                                       step    optimality
   30       12463    1.610969e+01     6.726e-03     1.000e+00     1.381e+00     5.737e-01  
   31       12865    1.609898e+01     1.193e-03     1.000e+00     5.481e-01     3.637e-01  
   32       13267    1.607666e+01     2.224e-03     1.000e+00     7.660e-01     4.793e-01  
   33       13669    1.603000e+01     8.127e-03     1.000e+00     1.421e+00     5.032e-01  
   34       14071    1.600631e+01     3.800e-03     1.000e+00     8.450e-01     3.416e-01  
   35       14473    1.599686e+01     2.289e-03     1.000e+00     6.269e-01     1.063e-01  
   36       14875    1.598332e+01     2.404e-03     1.000e+00     6.278e-01     2.593e-01  
   37       15277    1.597301e+01     1.660e-03     1.000e+00     5.079e-01     2.316e-01  
   38       15679    1.595131e+01     3.589e-03     1.000e+00     8.164e-01     3.109e-01  
   39       16081    1.594027e+01     5.048e-04     1.000e+00     4.498e-01     2.183e-01  
   40       16483    1.592463e+01     7.837e-04     1.000e+00     6.279e-01     3.161e-01  
   41       16885    1.590815e+01     9.190e-04     1.000e+00     7.209e-01     3.235e-01  
   42       17287    1.588275e+01     3.308e-03     1.000e+00     1.242e+00     3.966e-01  
   43       17689    1.588143e+01     5.885e-04     1.000e+00     3.748e-01     3.370e-01  
   44       18091    1.586716e+01     1.272e-03     1.000e+00     6.123e-01     5.654e-01  
   45       18493    1.585585e+01     6.002e-04     1.000e+00     3.595e-01     4.230e-01  
   46       18895    1.582171e+01     5.027e-03     1.000e+00     1.057e+00     4.546e-01  
   47       19297    1.582457e+01     9.166e-04     1.000e+00     5.875e-01     8.211e-02  
   48       19699    1.582096e+01     5.832e-04     1.000e+00     4.186e-01     1.399e-01  
   49       20101    1.581437e+01     8.040e-04     1.000e+00     5.221e-01     1.541e-01  
   50       20503    1.580976e+01     2.590e-04     1.000e+00     3.480e-01     1.511e-01  
   51       20905    1.579840e+01     6.953e-04     1.000e+00     6.454e-01     2.513e-01  
   52       21307    1.579514e+01     2.082e-04     1.000e+00     2.436e-01     3.131e-01  
   53       21709    1.578284e+01     1.607e-03     1.000e+00     6.251e-01     4.291e-01  
   54       22111    1.577213e+01     2.477e-03     1.000e+00     7.457e-01     2.724e-01  
   55       22513    1.576772e+01     1.208e-03     1.000e+00     6.645e-01     1.615e-01  
   56       22915    1.576780e+01     4.198e-05     1.000e+00     1.962e-01     1.490e-01  
   57       23317    1.575814e+01     2.921e-04     1.000e+00     4.914e-01     3.527e-01  
   58       23719    1.575052e+01     5.115e-04     1.000e+00     3.049e-01     3.183e-01  
   59       24121    1.573135e+01     2.556e-03     1.000e+00     7.882e-01     2.533e-01  
 Iter  Func-count            Fval   Feasibility   Step Length       Norm of   First-order  
                                                                       step    optimality
   60       24523    1.572900e+01     2.846e-04     1.000e+00     3.908e-01     2.247e-01  
   61       24925    1.572822e+01     1.613e-05     1.000e+00     8.034e-02     2.040e-01  
   62       25327    1.572257e+01     2.239e-04     1.000e+00     3.080e-01     2.237e-01  
   63       25729    1.571749e+01     3.386e-04     1.000e+00     3.408e-01     1.917e-01  
   64       26131    1.570897e+01     1.079e-03     1.000e+00     6.701e-01     1.781e-01  
   65       26533    1.570477e+01     4.987e-04     1.000e+00     6.097e-01     1.111e-01  
   66       26935    1.570270e+01     1.577e-04     1.000e+00     3.697e-01     1.879e-01  
   67       27337    1.569734e+01     4.374e-04     1.000e+00     6.609e-01     2.323e-01  
   68       27739    1.569367e+01     5.410e-04     1.000e+00     6.943e-01     1.479e-01  
   69       28141    1.569385e+01     8.675e-05     1.000e+00     1.602e-01     1.410e-01  
   70       28543    1.568860e+01     9.938e-04     1.000e+00     4.771e-01     2.502e-01  
   71       28945    1.568759e+01     4.111e-04     1.000e+00     2.586e-01     5.868e-02  
   72       29347    1.568581e+01     3.776e-04     1.000e+00     2.306e-01     6.940e-02  
   73       29749    1.568352e+01     7.042e-04     1.000e+00     3.359e-01     7.153e-02  
   74       30151    1.568329e+01     1.288e-04     1.000e+00     1.548e-01     6.584e-02  
   75       30553    1.568262e+01     9.860e-05     1.000e+00     1.259e-01     7.103e-02  
   76       30955    1.568204e+01     6.393e-05     1.000e+00     1.109e-01     7.523e-02  
   77       31357    1.568044e+01     1.995e-04     1.000e+00     2.278e-01     8.887e-02  
   78       31759    1.567895e+01     2.119e-04     1.000e+00     2.859e-01     1.173e-01  
   79       32161    1.567689e+01     3.362e-04     1.000e+00     4.179e-01     1.476e-01  
   80       32563    1.567563e+01     2.498e-04     1.000e+00     3.516e-01     1.393e-01  
   81       32965    1.567425e+01     2.817e-04     1.000e+00     3.175e-01     1.494e-01  
   82       33367    1.567328e+01     2.166e-04     1.000e+00     2.639e-01     1.025e-01  
   83       33769    1.567260e+01     9.650e-05     1.000e+00     1.853e-01     1.071e-01  
   84       34171    1.567097e+01     2.441e-04     1.000e+00     2.783e-01     8.688e-02  
   85       34573    1.567040e+01     1.217e-04     1.000e+00     1.662e-01     6.552e-02  
   86       34975    1.566864e+01     3.004e-04     1.000e+00     2.753e-01     9.395e-02  
   87       35377    1.566761e+01     2.006e-04     1.000e+00     2.656e-01     3.754e-02  
   88       35779    1.566663e+01     1.405e-04     1.000e+00     2.863e-01     3.006e-02  
   89       36181    1.566537e+01     1.946e-04     1.000e+00     3.501e-01     4.474e-02  
 Iter  Func-count            Fval   Feasibility   Step Length       Norm of   First-order  
                                                                       step    optimality
   90       36583    1.566357e+01     3.492e-04     1.000e+00     4.265e-01     4.106e-02  
   91       36985    1.566199e+01     2.572e-04     1.000e+00     2.870e-01     4.563e-02  
   92       37387    1.566038e+01     2.526e-04     1.000e+00     2.474e-01     6.345e-02  
   93       37789    1.565949e+01     2.169e-04     1.000e+00     2.686e-01     3.052e-02  
   94       38191    1.565925e+01     5.616e-05     1.000e+00     1.413e-01     4.128e-02  
   95       38593    1.565767e+01     1.911e-04     1.000e+00     2.693e-01     9.231e-02  
   96       38995    1.565695e+01     5.232e-05     1.000e+00     1.499e-01     7.138e-02  
   97       39397    1.565394e+01     5.203e-04     1.000e+00     4.695e-01     1.311e-01  
   98       39799    1.565203e+01     5.449e-04     1.000e+00     5.043e-01     7.923e-02  
   99       40201    1.565058e+01     4.032e-04     1.000e+00     4.591e-01     9.142e-02  

Solver stopped prematurely.

fmincon stopped because it exceeded the function evaluation limit,
options.MaxFunctionEvaluations = 4.010000e+04.

Elapsed time is 31148.767308 seconds.
No script provided to load.
%}
