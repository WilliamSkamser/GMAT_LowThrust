function [F, G] = objFunc_conFunc(x)

global NumberOfSteps
global Th
global mdot
global AU
global TU
%lobal my_dir
global headlines
global t1

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

% % Obtain Mass History
% mass = zeros(length(Time),1);    mass(1)= m0;
% for i=2:length(Time)
%     mass(i) = mass(i-1)*exp(-1/Vex*abs(trapz(Time(i-1:i),[norm(ThrustAcc(i-1,:));norm(ThrustAcc(i,:))]*1000)));
% end
% 
% % Create Thrust Profile
% Thrust = mass.*ThrustAcc*1000; % N or kg m/s^2
% Thrust = ThrustAcc*1000;

%% Write Thrust History File
% task = getCurrentTask;
% 
% if isempty(task)
%     task.ID = 99999;
% end
% 
% % Obtain the Iter number and append it with the Thrust File
% file2  = ['ThrustProfile' num2str(task.ID) '.thrust']; 

% % Create the file in the folder as specified
% file2 = fullfile(my_dir,file2); 

% Temporary File

file2='C:/GMAT_Repo/EarthToMars_LowThrust_SNOPT/ThrustProfile.thrust';
%file2 = tempname('C:\GMAT_Repo\EarthToMars_LowThrust_SNOPT\ThrustProfileTemp');
%file2 = [file2,'.thrust'];


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
gmat.gmat.LoadScript("C:/GMAT_Repo/EarthToMars_LowThrust_SNOPT/GMATScriptEarthMars.script");

% Input the TOF as RunTime
PropTime = gmat.gmat.GetObject('RunTime'); %This part seems to work
PropTime.SetField('Value', TOF);

% Input the Location of the Corresponding Thrust File
%Thrust_File = gmat.gmat.GetObject('ThrustHistoryFile1');
%Thrust_File.SetField('FileName',file2);

% Run GMAT Script
Ans = gmat.gmat.RunScript();
if Ans == 0
    %fprintf("Fail to run script");
    con(1:6)= 1e10;
    Obj = 1e10;
    %return
elseif Ans ==1

% Extract Final States of Satellite 
Sat_X = gmat.gmat.GetRuntimeObject("Sat.SunICRF.X");  Sat_X = Sat_X.GetNumber("Value");
Sat_Y = gmat.gmat.GetRuntimeObject("Sat.SunICRF.Y");  Sat_Y = Sat_Y.GetNumber("Value");
Sat_Z = gmat.gmat.GetRuntimeObject("Sat.SunICRF.Z");  Sat_Z = Sat_Z.GetNumber("Value");
Sat_VX = gmat.gmat.GetRuntimeObject("Sat.SunICRF.VX");  Sat_VX = Sat_VX.GetNumber("Value");
Sat_VY = gmat.gmat.GetRuntimeObject("Sat.SunICRF.VY");  Sat_VY = Sat_VY.GetNumber("Value");
Sat_VZ = gmat.gmat.GetRuntimeObject("Sat.SunICRF.VZ");  Sat_VZ = Sat_VZ.GetNumber("Value");
%{
% Extract Final States of Mars %NOTE THAT MARS is not propgating! 
Mars_X = gmat.gmat.GetRuntimeObject("Mars.SunICRF.X");  Mars_X = Mars_X.GetNumber("Value");
Mars_Y = gmat.gmat.GetRuntimeObject("Mars.SunICRF.Y");  Mars_Y = Mars_Y.GetNumber("Value");
Mars_Z = gmat.gmat.GetRuntimeObject("Mars.SunICRF.Z");  Mars_Z = Mars_Z.GetNumber("Value");
Mars_VX = gmat.gmat.GetRuntimeObject("Mars.SunICRF.VX");  Mars_VX = Mars_VX.GetNumber("Value");
Mars_VY = gmat.gmat.GetRuntimeObject("Mars.SunICRF.VY");  Mars_VY = Mars_VY.GetNumber("Value");
Mars_VZ = gmat.gmat.GetRuntimeObject("Mars.SunICRF.VZ");  Mars_VZ = Mars_VZ.GetNumber("Value");
%}
t2=t1+(TOF/86400);
[Rm,Vm]= planetEphemeris(t2,'Sun','Mars');

Mars_VX=Vm(1);
Mars_VY=Vm(2);
Mars_VZ=Vm(3);
Mars_X=Rm(1);
Mars_Y=Rm(2);
Mars_Z=Rm(3);

%{
%READ Data File
%file1='../EarthToMars_LowThrust_SNOPT/DataOutput.txt';
%fID1=fopen(file1,'r');
%B=textscan(fID1, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'headerlines',1);
%Data=cell2mat(B);
%fclose(fID1);

Sat_VX=Data(1);
Sat_VY=Data(2);
Sat_VZ=Data(3);
Sat_X=Data(4);
Sat_Y=Data(5);
Sat_Z=Data(6);
Mars_VX=Data(9);
Mars_VY=Data(10);
Mars_VZ=Data(11);
Mars_X=Data(12);
Mars_Y=Data(13);
Mars_Z=Data(14);
%}
%% Construct the Constraints and Objective Function
X = Mars_X - Sat_X;
Y = Mars_Y - Sat_Y;
Z = Mars_Z - Sat_Z;
Vx = Mars_VX - Sat_VX;
Vy = Mars_VY - Sat_VY;
Vz = Mars_VZ - Sat_VZ;

con = [Vx/(AU/TU);
       Vy/(AU/TU);
       Vz/(AU/TU);
       X/AU;
       Y/AU;
       Z/AU]; 
Obj = TOF/TU;
end


F(1) = Obj;
F(2:7)=con;
G=[];
end