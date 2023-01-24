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
gmat.gmat.Clear(); %Clears GMAT API configuration
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
sat.SetField("DryMass", 1); %0

eTank=gmat.gmat.Construct("ElectricTank", "ETank");
eTank.SetField("FuelMass", 1000);
 
fm = GMATAPI.Construct("ForceModel", "FM");
fm.SetField("CentralBody", "Sun");

sungrav = GMATAPI.Construct("PointMassForce");
sungrav.SetField("BodyName","Sun")
fm.AddForce(sungrav);
gmat.gmat.Initialize();
%{
psm = gmat.PropagationStateManager();
psm.SetObject(sat);
psm.BuildState();
fm.SetPropStateManager(psm);
fm.SetState(psm.GetState());
gmat.gmat.Initialize();
%  Map the spacecraft state into the model
fm.BuildModelFromMap();
% Load the physical parameters needed for the forces
fm.UpdateInitialData();
% Now access the state and get the derivative data
pstate = sat.GetState().GetState();
fm.GetDerivatives(pstate);
dv = fm.GetDerivativeArray()
vec = fm.GetDerivativesForSpacecraft(sat)
%}

prop= GMATAPI.Construct("Propagator", "ThePropagator");
gator = GMATAPI.Construct("RungeKutta89");
prop.SetReference(gator);
prop.SetReference(fm); % It doesn't Know this command either!
prop.SetField("InitialStepSize", 86400);
prop.SetField("Accuracy", 1.0e-9);
prop.SetField("MinStep", 86400);
prop.SetField("MaxStep", 86400);
%Propagate steps
%{
gmat.gmat.Initialize();
prop.AddPropObject(sat);
prop.PrepareInternals();
gator = prop.GetPropagator();
pstate=gator.GetState()
%fm.GetDerivativeArray()
%fm.GetDerivatives(pstate, 0.0)
for i = 1 : 144
   gator.Step(60);
   gator.GetState()
end
%}

sunICRF = gmat.gmat.Construct("CoordinateSystem", "SunICRF", "Sun", "ICRF");

thrustHfile = gmat.gmat.Construct("ThrustHistoryFile", "ThrustHistoryFile1");
%Need to be able to add file location
%and add thrust segment

thrustSegment = gmat.gmat.Construct("ThrustSegment", "ThrustSegment1");
%Need to be able to add MassSource

runTime = gmat.gmat.Construct("Variable", "RunTime");
data = gmat.gmat.Construct("Array","Data");


gmat.gmat.SaveScript(Dir+FileName)
gmat.gmat.ShowObjects() %Display current objects
gmat.gmat.Clear()
gmat.gmat.ShowObjects() %Display current objects
