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

fm = gmat.gmat.Construct("ForceModel", "FM");
fm.SetField("CentralBody", "Sun")
SunG=gmat.gmat.Construct("PointMassForce");
SunG.SetField("BodyName","Sun")
fm.AddForce(SunG) %THIS SHOULD WORK!!!


%ThePropagator= gmat.gmat.Construct("Propagator", "ThePropagator");



gmat.gmat.SaveScript(Dir+FileName)
gmat.gmat.ShowObjects() %Display current objects
gmat.gmat.Clear()
gmat.gmat.ShowObjects() %Display current objects
