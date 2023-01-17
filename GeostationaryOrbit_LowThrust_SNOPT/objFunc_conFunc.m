function [F, G] = objFunc_conFunc(x)
global NumberOfSteps
global Th
global mdot
global GEO_R
global L
global TU
global headlines

% Extract Design Variables
Thrust_alpha = x(1:NumberOfSteps);                   % rads
Thrust_beta = x(NumberOfSteps+1:2*NumberOfSteps);   % rads
TOF     = x(end)*TU;                                           % s
ThrustVec=Th.*[cos(Thrust_beta).*cos(Thrust_alpha),cos(Thrust_beta).*sin(Thrust_alpha),sin(Thrust_beta)];
%% Create Thrust History 
Thrust = zeros(NumberOfSteps+1,3);
Thrust(1:(end-1),:)=ThrustVec;

% Obtain time History
Time = linspace(0,TOF,NumberOfSteps+1)';  % seconds


%% Write Thrust History File
file2='C:/GMAT_Repo/GeostationaryOrbit_LowThrust_SNOPT/ThrustProfile.thrust';

% Write the contents of the Thrust File
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

%{
%WRITE Thrust Run Time
file3='../EarthToMars_LowThrust_SNOPT/ThrustRunTime.txt';
fid3 = fopen(file3, 'w');
fprintf(fid3, '%.16d', TOF);
fclose(fid3);
%}

%% RUN GMAT and Read the Results

% Load GMAT
%load_gmat();

% Load GMAT SCRIPT
gmat.gmat.LoadScript("C:\GMAT_Repo\GeostationaryOrbit_LowThrust_SNOPT\LEOtoGEO_plots.script");

% Input the TOF as RunTime
PropTime = gmat.gmat.GetObject('RunTime'); %This part seems to work
PropTime.SetField('Value', TOF);

% Run GMAT Script
Ans = gmat.gmat.RunScript();
if Ans == 0
    con(1:6)= 1e10;
    Obj = 1e10;
elseif Ans ==1

Sat_RMAG = gmat.gmat.GetRuntimeObject("Sat.Earth.RMAG");
Radius = Sat_RMAG.GetNumber("Value");
Sat_ECC = gmat.gmat.GetRuntimeObject("Sat.Earth.ECC");
Eccentricity = Sat_ECC.GetNumber("Value");
Sat_INC = gmat.gmat.GetRuntimeObject("Sat.EarthMJ2000Eq.INC");
Inclination = Sat_INC.GetNumber("Value");
Sat_Longitude = gmat.gmat.GetRuntimeObject("Sat.Earth.Longitude");
Longitude = Sat_Longitude.GetNumber("Value");



%READ Data File 2

file1='../GeostationaryOrbit_LowThrust_SNOPT/DataOut2.txt';
fID2=fopen(file1,'r');
B2=textscan(fID2, '%f %f', 'headerlines',1);
Data2=cell2mat(B2);
fclose(fID2);
UR=50000; LR=6900;
MinRadius=min(Data2(:,2));
MaxRadius=max(Data2(:,2));
ConRadius=[((MinRadius-LR)/LR); ((UR-MaxRadius)/UR)]; %Max and min Radius 

%MinRadius=7000 - min(Data2(:,2));
%MaxRadius=50000 - max(Data2(:,2));

%% Construct the Constraints and Objective Function

con = [((Radius-GEO_R)/GEO_R);
       Eccentricity;
       Inclination;
       ((Longitude+L)/L);
       ConRadius(1); ConRadius(2)];
   
Obj = TOF/TU;
end
F(1) = Obj;
F(2:7)=con;
G=[];
end