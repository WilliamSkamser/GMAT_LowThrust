clc
clear all;
close all;
format longg;

global NumberOfSteps
global ThrustAcc_mag
global m0
global mdot
global Vex
global AU
global TU
global my_dir
global headlines

% Load Semi-Analytic Solution
% load('GMAT_data.mat')
% load('GMATdata.mat')
load('EMTG_GMATdata.mat')

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

% Obtain the Time steps
NumberOfSteps = length(GMAT_data.Time);

%% Initial Guess vector for Fmincon (Alpha, Beta, TOF)

% Use for Semi-Analytic Approach
% ThrustAccMag = GMAT_data.ThrustAccMag*1000;    % m/s^2
% x0 = [GMAT_data.Thrustx/ThrustAccMag;GMAT_data.Thrusty/ThrustAccMag;GMAT_data.Thrustz/ThrustAccMag;GMAT_data.TOF/TU];

% Use for EMTG data
% ThrustAccMag = zeros(length(GMAT_data.Thrustx),1);
% for i = 1:length(GMAT_data.Thrustx)
%     ThrustAccMag(i) = norm([GMAT_data.Thrustx(i),GMAT_data.Thrusty(i),GMAT_data.Thrustz(i)]);
% end
% ThrustAccMag(1) = 1; ThrustAccMag(end) = 1;
ThrustAccMag =  Th;
x0 = [GMAT_data.Thrustx/ThrustAccMag;GMAT_data.Thrusty/ThrustAccMag;GMAT_data.Thrustz/ThrustAccMag;GMAT_data.TOF/TU];
ThrustAcc_mag=ThrustAccMag;
% Bounds
lb = [-ones(NumberOfSteps,1);    % Thrust_x 
      -ones(NumberOfSteps,1);    % Thrust_y 
      -ones(NumberOfSteps,1);    % Thrust_z 
      900*86400/TU];             % TOF (TU)
  
ub = [ones(NumberOfSteps,1);     % Thrust_x 
      ones(NumberOfSteps,1);     % Thrust_y 
      ones(NumberOfSteps,1);     % Thrust_z 
      1100*86400/TU];            % TOF (TU)
  
%lower and upper bounds
xlow = lb;
xupp = ub;

%bounds on objective function
Flow=zeros(7, 1);
Fupp=zeros(7, 1);
Flow(1) = 0;
Fupp(1) = 1100*86400/TU;%inf;
%bounds of constraints
Flow(2:7) = 0;
Fupp(2:7) = 0;
%Multiplier and state of design variable x and function F
xmul = zeros(length(lb), 1); %Lagrange multipliers
xstate = zeros(length(lb), 1);
Fmul = zeros(7, 1); %Lagrange multipliers
Fstate = zeros(7, 1);
x=x0;
 
  
  
  
%%  
% Fmincon Options
% fmincon_options = optimoptions('fmincon','Algorithm','interior-point','Display','iter',...
%                      'MaxIterations',5000,'OptimalityTolerance',5e-4,'ObjectiveLimit',2,...
%                      'ConstraintTolerance',5e-4,'StepTolerance',1e-10);%,...
%                      'useParallel','always');

%fmincon_options = optimoptions("fmincon","Algorithm","interior-point",...
%    "MaxFunEvals",10000,"display","iter-detailed","TolX",1e-15,"ObjectiveLimit",6,...
%    "TolCon",1e-5,"UseParallel",true);%...
%     "EnableFeasibilityMode",true,...
%     "SubproblemAlgorithm","cg"); %,'FinDiffType','central');

%% Initialize GMAT and Load Script 
% load_gmat();
% gmat.gmat.LoadScript("../Earth_Mars_Madhu/GMATScriptEarthMars.script");

% Directory Path to create Temp Files
my_dir = 'C:/GMAT_Repo/EarthToMars_LowThrust_SNOPT/myTempFiles';

% Headlines for the Thrust File
headlines = ['BeginThrust{ThrustSegment1}', newline,...
    'Start_Epoch = 20 Jul 2023 00:00:00.000',newline,...
    'Thrust_Vector_Coordinate_System = SunICRF',newline,...  
    'Thrust_Vector_Interpolation_Method  = CubicSpline',newline,...
    'Mass_Flow_Rate_Interpolation_Method = None',newline,...
    'ModelThrustAndMassRate'];              % EMTG
%     'ModelAccelAndMassRate'];             % Semi-Analytic


%% SNOPT Optimization Routine

ObjAdd =0; %Add value to objective Row
ObjRow =1; %Tell the Optimizer which row of F is the objective function

snscreen on;  
snsummary('SNOPt_summary.txt');
%tolerance values, 1e-6 by default 
snsetr('Major feasibility tolerance',1e-6); 
snsetr('Major optimality tolerance',1e-6);
snsetr('Minor feasibility tolerance',1e-6);
snsetr('Minor optimality tolerance',1e-6);

snseti('Time limit',86400) %Sets time limit to 1 day (in seconds)
snseti('Major iteration limit', 100);

load_gmat(); %Having this here tends to cause crashes

tic
[x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
    snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate, 'objFunc_conFunc', ObjAdd, ObjRow);
toc

%% Solution Visualization

%[DataOpt,ThrustAccOpt,TOFOpt] = SolutionVisualization(x_fmincon,NumberOfSteps,ThrustAcc_mag,m0,mdot,Vex,AU,TU);



