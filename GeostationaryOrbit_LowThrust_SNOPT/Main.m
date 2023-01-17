clc
clear all;
close all;
format longg;

global NumberOfSteps
global Th
global mdot
global GEO_R
global L
global TU
global headlines

%READ initial guess with 200 steps
%fileG='../EarthToMars_LowThrust_SNOPT/GMAT_thrust.txt';
%fIDG=fopen(fileG,'r');
%AG=textscan(fIDG, '%f %f %f %f', 'headerlines',1);
%InitialGuess_Data2=cell2mat(AG);
%fclose(fIDG);
%NumberOfSteps_i=size(InitialGuess_Data2(:,1));
%Alpha_i=InitialGuess_Data2(:,2);
%Beta_i=InitialGuess_Data2(:,3);
%Time_i=InitialGuess_Data2(end,1);

NumberOfSteps=30;
InitialGuess=ones(NumberOfSteps,2) * pi;
Alpha_i=InitialGuess(:,1);
Beta_i=InitialGuess(:,1);
Time_i=510*86400; %50 Days
%For 0.1 Newtons it takes about 51 days
%For 1 Newtons it takes about 5.1 days 

%% Constants

muS = 1.32712440018e+11;   % Km^3/sec^2 
g   = 9.81;                 % m/s^2
AU  = 149598000;            % km
TU  = sqrt(AU^3/muS);       % sec
VU  = AU/TU;                % km/sec

L=93.6465; %Target Longitude
GEO_R=42164; %GEO Radius

Th = 0.1;               % kg m/s^2
Isp = 2800;             % s^-1
Vex = Isp*g;            % m/s
m0  = 90;             % kg
mdot  = Th / Vex;
t1=juliandate(2023,07,20,00,00,00);


% Obtain the Time steps
%NumberOfSteps = length(GMAT_data.Time)-2;%Cut-off ends %100 steps
%NumberOfSteps=NumberOfSteps_i(1);   %200 steps
%% Initial Guess vector (Alpha, Beta, TOF)
%x=[GMAT_data.Alpha;GMAT_data.Beta;GMAT_data.TOF/TU]; %100 Steps

x=[Alpha_i;Beta_i;Time_i/TU];  %200 Steps
% Bounds
lb = [-ones(NumberOfSteps,1)*pi;    % Alpha
      -ones(NumberOfSteps,1)*pi;    % Beta  
      10*86400/TU];             % TOF (TU)
  
ub = [ones(NumberOfSteps,1)*pi;     % Alpha 
      ones(NumberOfSteps,1)*pi;     % Beta 
      1000*86400/TU];            % TOF (TU) 

%lower and upper bounds
xlow = lb;
xupp = ub;
%bounds on objective function
Flow=zeros(7, 1);
Fupp=zeros(7, 1);
Flow(1) = lb(end);
Fupp(1) = ub(end);%inf;
%bounds of constraints
Flow(2:5) = 0;
Fupp(2:5) = 0;
Flow(6:7) = 0;
Fupp(6:7) = inf;
%Multiplier and state of design variable x and function F
xmul = zeros(length(lb), 1); %Lagrange multipliers
xstate = zeros(length(lb), 1);
Fmul = zeros(7, 1); %Lagrange multipliers
Fstate = zeros(7, 1);

% Directory Path to create Temp Files
my_dir = 'C:\GMAT_Repo\GeostationaryOrbit_LowThrust_SNOPT';

% Headlines for the Thrust File
headlines = ['BeginThrust{ThrustSegment1}', newline,...
    'Start_Epoch = 20 Jul 2023 00:00:00.000',newline,...
    'Thrust_Vector_Coordinate_System = VNB',newline,...  
    'Thrust_Vector_Interpolation_Method  = None',newline,... %%CubicSpline
    'Mass_Flow_Rate_Interpolation_Method = None',newline,...
    'ModelThrustAndMassRate'];              

%% SNOPT Optimization Routine

ObjAdd =0; %Add value to objective Row
ObjRow =1; %Tell the Optimizer which row of F is the objective function

snscreen on;  
snsummary('SNOPt_summary.txt');
snsetr('Major feasibility tolerance',1e-6); 
snsetr('Major optimality tolerance',1e-6);
snsetr('Minor feasibility tolerance',1e-6);
snsetr('Minor optimality tolerance',1e-6);

snseti('Time limit',345600);%86400) %Sets time limit to 1 day (in seconds)
snseti('Major iteration limit', 500);%250);%5000);
snseti('Line search algorithm', 3)%More-Thuente line search


load_gmat(); %Load GMAT here tends to cause higher likelihood of SNOPT crashing MATLAB

tic
%[x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
    %snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate, 'objFunc_conFunc', ObjAdd, ObjRow);
toc

%% Write Solution Files

%WRITE Thrust Run Time
file3='../GeostationaryOrbit_LowThrust_SNOPT/ThrustRunTime.txt';
fid3 = fopen(file3, 'w');
fprintf(fid3, '%.16d', x(end)*TU);
fclose(fid3);

% Extract Design Variables
Thrust_alpha = x(1:NumberOfSteps);                   % rads
Thrust_beta = x(NumberOfSteps+1:2*NumberOfSteps);   % rads
TOF     = x(end)*TU;                                           % s
ThrustVec=Th.*[cos(Thrust_beta).*cos(Thrust_alpha),cos(Thrust_beta).*sin(Thrust_alpha),sin(Thrust_beta)];
% Create Thrust History 
Thrust = zeros(NumberOfSteps+1,3);
Thrust(1:(end-1),:)=ThrustVec;

% Obtain time History
Time = linspace(0,TOF,NumberOfSteps+1)';  % seconds
%Write the contents of the Thrust File
file2='C:/GMAT_Repo/GeostationaryOrbit_LowThrust_SNOPT/ThrustProfileSolution.thrust';
for i=1:(NumberOfSteps+1)
    LineToChange = i+1;         % first 6 lines ae used for headers
    NewContent = compose("%.16f \t %.16f %.16f %.16f %.16f",Time(i),Thrust(i,1),Thrust(i,2),Thrust(i,3),mdot);
    SS{LineToChange} = NewContent;
end
fid2 = fopen(file2, 'w');
fprintf(fid2,'%s',headlines);
fprintf(fid2, '%s\n', SS{:});
fprintf(fid2,'%s','EndThrust{ThrustSegment1}');
fclose(fid2);
