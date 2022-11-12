clear, clc, format longg, close all
load_gmat();
gmat.gmat.LoadScript("/C/GMAT_Repo/LowThrustProfile2/LowThrustProfile2.script");
gmat.gmat.RunScript();

