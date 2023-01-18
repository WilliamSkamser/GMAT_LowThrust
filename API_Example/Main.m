clc
clear all;
close all;
format longg;
%% Inital State
t1=juliandate(2023,07,20,00,00,00);
[Re_i,Ve_i]= planetEphemeris(t1,'Sun','Earth');
%File
Dir="C:\GMAT_Repo\API_Example";
%FileName = [tempname(Dir),'.script'];
FileName="\GMAT_temp.script";
fid1 = fopen(Dir+FileName,'w');
fid1 = fclose(fid1);

%% GMAT
%Insert inital state
load_gmat();
gmat.gmat.LoadScript(Dir+FileName)

sat = gmat.gmat.Construct("Spacecraft", "Sat");
sat.SetField("DateFormat", "A1ModJulian")           
sat.SetField("Epoch", num2str(t1-2430000.0))
sat.SetField("CoordinateSystem", "SunICRF")
sat.SetField("DisplayStateType", "Cartesian")
sat.SetField('X', Re_i(1));
sat.SetField('Y', Re_i(2));
sat.SetField('Z', Re_i(3));
sat.SetField('VX', Ve_i(1));
sat.SetField('VY', Ve_i(2));
sat.SetField('VZ', Ve_i(3));
sat.SetField("DryMass", 0);

eTank=gmat.gmat.Construct("ElectricTank", "ETank");
eTank.SetField("FuelMass", 1000);

%There seems to be a way to load a force model and proagator to propagate
%by a step size. 

fm = gmat.gmat.Construct("ForceModel", "FM");
fm.SetField("CentralBody", "Sun")
SunG=gmat.gmat.Construct("PointMassForce");
SunG.SetField("BodyName","Sun")
%fm.AddForce(SunG) %THIS SHOULD WORK!!!

%{
psm = gmat.PropagationStateManager();
psm.SetObject(sat)
psm.BuildState()
%fm.SetPropStateManager(psm) %THIS Command Doesn't work either!
%fm.SetState(psm.GetState())
%}

ThePropagator= gmat.gmat.Construct("Propagator", "ThePropagator");
gator = gmat.gmat.Construct("RungeKutta89");
%pdprop.SetReference(gator);
%pdprop.SetReference(fm); % It doesn't Know this command either!
%pdprop.SetField("InitialStepSize", 60.0);
%pdprop.SetField("Accuracy", 1.0e-12);
%pdprop.SetField("MinStep", 0.0);

%fm.SetPropStateManager(psm);
%psm.setSwigOwnership(false());

sunICRF = gmat.gmat.Construct("CoordinateSystem", "SunICRF", "Sun", "ICRF");

thrustHfile = gmat.gmat.Construct("ThrustHistoryFile", "ThrustHistoryFile1");
%Need to be able to add file location
%and add thrust segment

thrustSegment = gmat.gmat.Construct("ThrustSegment", "ThrustSegment1");
%Need to be able to add MassSource

runTime = gmat.gmat.Construct("Variable", "RunTime");
%data = gmat.gmat.Construct("Array","Data[1,6]");
%^  Try to figure out why this doesn't work

%Note it doesn't seem that I can append the mission sequence through api
%commands. However, there might be a way to add text to the file and run
%the modifed script. --> do some testing of finit burns to determined if
%they are any faster than running the script (Take the current solution and
%put it as finit burns-> see if the run speed is simlar or faster. If not
%give up on this approach 


gmat.gmat.SaveScript(Dir+FileName)
gmat.gmat.ShowObjects() %Display current objects
gmat.gmat.Clear()
gmat.gmat.ShowObjects() %Display current objects
