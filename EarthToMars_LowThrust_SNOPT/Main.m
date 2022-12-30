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

% Load Semi-Analytic Solution
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
NumberOfSteps = length(GMAT_data.Time)-2;%Cut-off ends
%% Initial Guess vector (Alpha, Beta, TOF)

x=[GMAT_data.Alpha;GMAT_data.Beta;GMAT_data.TOF/TU];

% Bounds
lb = [-ones(NumberOfSteps,1)*pi;    % Alpha
      -ones(NumberOfSteps,1)*pi;    % Beta  
      900*86400/TU];             % TOF (TU)
  
ub = [ones(NumberOfSteps,1)*pi;     % Alpha 
      ones(NumberOfSteps,1)*pi;     % Beta 
      1100*86400/TU];            % TOF (TU)
  
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

% Directory Path to create Temp Files
my_dir = 'C:/GMAT_Repo/EarthToMars_LowThrust_SNOPT';

% Headlines for the Thrust File
headlines = ['BeginThrust{ThrustSegment1}', newline,...
    'Start_Epoch = 20 Jul 2023 00:00:00.000',newline,...
    'Thrust_Vector_Coordinate_System = SunICRF',newline,...  
    'Thrust_Vector_Interpolation_Method  = CubicSpline',newline,...
    'Mass_Flow_Rate_Interpolation_Method = None',newline,...
    'ModelThrustAndMassRate'];              % EMTG

%% SNOPT Optimization Routine

ObjAdd =0; %Add value to objective Row
ObjRow =1; %Tell the Optimizer which row of F is the objective function

snscreen on;  
snsummary('SNOPt_summary.txt');
%tolerance values, 1e-6 by default 
snsetr('Major feasibility tolerance',1e-7); 
snsetr('Major optimality tolerance',1e-7);
snsetr('Minor feasibility tolerance',1e-7);
snsetr('Minor optimality tolerance',1e-7);

snseti('Time limit',345600);%86400) %Sets time limit to 1 day (in seconds)
snseti('Major iteration limit', 5000);

snseti('Line search algorithm', 3)%More-Thuente line search
%Around 7% faster than default ,0) Backtracking line search

load_gmat(); %Having this here tends to cause crashes

tic
[x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
    snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate, 'objFunc_conFunc', ObjAdd, ObjRow);
toc

%% Solution Visualization
[DataOpt,ThrustAccOpt,TOFOpt] = SolutionVisualization(x);
