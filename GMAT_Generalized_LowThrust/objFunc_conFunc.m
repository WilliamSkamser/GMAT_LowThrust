function [F, G] = objFunc_conFunc(x)
global NumberOfSteps
global Th
global mdot
global AU
global TU
global headlines
global t1
global destinationT
global destinationS
global ISP
% Extract Design Variables
Thrust_alpha = x(1:NumberOfSteps);                   % rads
Thrust_beta = x(NumberOfSteps+1:2*NumberOfSteps);   % rads
TOF     = x(end)*TU;                                           % s
ThrustVec=Th.*[cos(Thrust_beta).*cos(Thrust_alpha),cos(Thrust_beta).*sin(Thrust_alpha),sin(Thrust_beta)];
%% Create Thrust History 
Thrust = zeros(NumberOfSteps+1,3);
Thrust(1:(end-1),:)=ThrustVec;
Time = linspace(0,TOF,NumberOfSteps+1)';  % seconds
mdotO= Th/(ISP *9.807);
mdot=ones(NumberOfSteps+1,1)*mdotO;
for i=1:(NumberOfSteps+1)
    LineToChange = i+1;         % first 6 lines ae used for headers
    NewContent = compose("%.16f \t %.16f %.16f %.16f %.16f",Time(i),Thrust(i,1),Thrust(i,2),Thrust(i,3),mdot(i));
    SS{LineToChange} = NewContent;
end
fid0 = fopen(destinationT, 'w');
fprintf(fid0,'%s',headlines);
fprintf(fid0, '%s\n', SS{:});
fprintf(fid0,'%s','EndThrust{ThrustSegment1}');
fclose(fid0);
%% RUN GMAT and Read the Results
% Load GMAT SCRIPT
gmat.gmat.LoadScript(destinationS);
% Input the TOF as RunTime
PropTime = gmat.gmat.GetObject('RunTime'); %This part seems to work
PropTime.SetField('Value', TOF);
% Run GMAT Script
Ans = gmat.gmat.RunScript();
if Ans == 0
    con(1:6)= 1e10;
    Obj = 1e10;
elseif Ans ==1
% Extract Final States of Satellite 
Sat_X = gmat.gmat.GetRuntimeObject("Sat.SunICRF.X");  Sat_X = Sat_X.GetNumber("Value");
Sat_Y = gmat.gmat.GetRuntimeObject("Sat.SunICRF.Y");  Sat_Y = Sat_Y.GetNumber("Value");
Sat_Z = gmat.gmat.GetRuntimeObject("Sat.SunICRF.Z");  Sat_Z = Sat_Z.GetNumber("Value");
Sat_VX = gmat.gmat.GetRuntimeObject("Sat.SunICRF.VX");  Sat_VX = Sat_VX.GetNumber("Value");
Sat_VY = gmat.gmat.GetRuntimeObject("Sat.SunICRF.VY");  Sat_VY = Sat_VY.GetNumber("Value");
Sat_VZ = gmat.gmat.GetRuntimeObject("Sat.SunICRF.VZ");  Sat_VZ = Sat_VZ.GetNumber("Value");
t2=t1+(TOF/86400);
[Rm,Vm]= planetEphemeris(t2,'Sun','Mars');
Mars_VX=Vm(1);
Mars_VY=Vm(2);
Mars_VZ=Vm(3);
Mars_X=Rm(1);
Mars_Y=Rm(2);
Mars_Z=Rm(3);
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
