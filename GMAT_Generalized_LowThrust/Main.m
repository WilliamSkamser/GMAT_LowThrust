clc
clear all;
close all;
format longg;
%% NEXT STEPS TO WORK ON

%Put into SolutionVisulizeOption
%Put in Optimization Option
%If optimize set to yes enter optimization function







%% Inital State (INPUTS)
StartDate=juliandate(2023,07,20,00,00,00);
[R_i,V_i]= planetEphemeris(StartDate,'Sun','Earth');
DM=0; %DryMass
FuelM=1000; %Fuel Mass
PointMasses={};
PlanetPlot={};
%PointMasses={'Mercury','Venus','Earth','Luna','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto'};
%PlanetPlot={'Mercury','Venus','Earth','Luna','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto'};
ThrustSetting={'Thrust'}; %or Acceleration
ThrustCoordinateOption={'ThrustAngles'}; %or ThrustCoordinate
RelativisticCorrection= true; %or false
SolarRadiationPressure= true; %or false
%No NonIdeal Gravity or Drag perturbations

%ThrustInputs
ThrustMag=0.1; %N
ISP=3000; 
ThrustXYZ=0; 
Alpha=zeros(100,1);
Beta=zeros(100,1);
EndTime=1000000; %Sec

%% Julian Date to UTC Gregorian format
StartEpoch=string(datetime(StartDate,'convertfrom','juliandate','Format','dd'' ''MMM'' ''yyyy'' ''HH:mm:ss.SSS'));
%StartEpoch="20 Jul 2023 00:00:00.000"; %Can only be in  UTC Gregorian format
%% Check Inputs of ThrustCoordinate
ThrustAngle=find(contains(ThrustCoordinateOption,'ThrustAngles'));
ThrustCoordinate=find(contains(ThrustCoordinateOption,'ThrustCoordinate'));
if ThrustAngle >= 1
    if length(Alpha) ~= length(Beta)
        fprintf("GMAT: Size of Thrust Direction Angle Don't Match")
        return
    end
    NumberOfSteps=length(Alpha);
    ThrustVec=ThrustMag.*[cos(Beta).*cos(Alpha),cos(Beta).*sin(Alpha),sin(Beta)];
    mdotO= ThrustMag/(ISP *9.807);
    mdot=ones(NumberOfSteps+1,1)*mdotO;
    %MassFlowRate
elseif ThrustCoordinate >= 1
    SizeXYZ=size(ThrustXYZ);
    if SizeXYZ(2) == 3
        ThrustVec=ThrustXYZ;
        NumberOfSteps=length(ThrustVec(:,1));
        ThrustMagnitude=ones(NumberOfSteps,1);
        mdot=ones(NumberOfSteps+1,1);
        for i=1:NumberOfSteps
            ThrustMagnitude(i)=norm([ThrustVec(i,1),ThrustVec(i,2) ,ThrustVec(i,3)]);
            mdot(i)= ThrustMagnitude(i)/(ISP *9.807); %THIS wouldn't Work
            %ThrustXYZ is Acceleration not Force
        end
    else
        fprintf("GMAT: Thrust XYZ does not have 3 columns")
        return   
    end    
elseif ThrustAngle >= 1 && ThrustCoordinate >= 1
    fprintf("GMAT: Thrust Angle and Thrust Coordinate Option Selected")
    return
else
    fprintf("GMAT: No Thrust Coordinate Option Selected")
    return
end
%% Copy Files Over Files
MainDir = pwd;
WorkingDir=MainDir+"\GMAT_RunFolder";
BlanksDir=WorkingDir+"\Blank_scripts";
FileName_blankS="GMAT_BlankScript.script";
FileName_blankT="GMAT_BlankThrustProfile.thrust";
FileName_blankO="OrbitViewPlotCommands.txt";
FileName_runS="\GMAT_RunScript.script";
FileName_runSP="\GMAT_RunScript_Plots.script";
FileName_runT="\GMAT_RunThrustProfile.thrust";
sourceS = fullfile(BlanksDir,FileName_blankS);
destinationS = fullfile(WorkingDir,FileName_runS);
sourceT = fullfile(BlanksDir,FileName_blankT);
destinationT = fullfile(WorkingDir,FileName_runT);
copyfile(sourceS,destinationS);
copyfile(sourceT,destinationT);
%% Configure Thrust History Profile Script
% Headlines for the Thrust File
Accel=find(contains(ThrustSetting,'Acceleration'));
Thrus=find(contains(ThrustSetting,'Thrust'));
if  Thrus >= 1
    ThrustProfileModel="ModelThrustAndMassRate";
elseif Accel >=1
    ThrustProfileModel="ModelAccelAndMassRate";
elseif Thrus >= 1 && Accel >=1
    fprintf("GMAT: Acceleration and Thrust Option Selected")
    return
else
    fprintf("GMAT: No Thrust Profile Option Selected")
    return
end
headlines = ['BeginThrust{ThrustSegment1}', newline,...
    'Start_Epoch = '+StartEpoch,newline,...
    'Thrust_Vector_Coordinate_System = SunICRF',newline,...  
    'Thrust_Vector_Interpolation_Method  = None',newline,...
    'Mass_Flow_Rate_Interpolation_Method = None',newline,...
    ThrustProfileModel]; 
Thrust = zeros(NumberOfSteps+1,3);
Thrust(1:(end-1),:)=ThrustVec;
% Obtain time history
Time = linspace(0,EndTime,NumberOfSteps+1)';  % seconds
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
%% Configure GMAT Script
load_gmat();
gmat.gmat.Clear(); %Clears GMAT API configuration
gmat.gmat.LoadScript(WorkingDir+FileName_runS);
%Spacecraft
sat = gmat.gmat.Construct("Spacecraft", "Sat");
sat.SetField("DateFormat", "A1ModJulian")           
sat.SetField("Epoch", num2str(StartDate-2430000.0)) %modified Julian Date
sat.SetField("CoordinateSystem", "SunICRF")
sat.SetField("DisplayStateType", "Cartesian")
sat.SetField('X', R_i(1));
sat.SetField('Y', R_i(2));
sat.SetField('Z', R_i(3));
sat.SetField('VX', V_i(1));
sat.SetField('VY', V_i(2));
sat.SetField('VZ', V_i(3));
sat.SetField("DryMass", DM);
%FuelSource
eTank=gmat.gmat.Construct("ElectricTank", "ETank");
eTank.SetField("FuelMass", FuelM);
%ForceModel
fm = GMATAPI.Construct("ForceModel", "FM");
fm.SetField("CentralBody", "Sun");
%Additional pointmasses to foce model
%Finds PointMasses in String array
Mercury=find(contains(PointMasses,'Mercury'));
Venus=find(contains(PointMasses,'Venus'));
Earth=find(contains(PointMasses,'Earth'));
Luna=find(contains(PointMasses,'Luna'));
Mars=find(contains(PointMasses,'Mars'));
Jupiter=find(contains(PointMasses,'Jupiter'));
Saturn=find(contains(PointMasses,'Saturn'));
Uranus=find(contains(PointMasses,'Uranus'));
Neptune=find(contains(PointMasses,'Neptune'));
Pluto=find(contains(PointMasses,'Pluto'));
if Mercury >= 1
    Mercurygrav = GMATAPI.Construct("PointMassForce");
    Mercurygrav.SetField("BodyName","Mercury")
    fm.AddForce(Mercurygrav);
    gmat.gmat.Initialize();
end
if Venus >= 1
    Venusgrav = GMATAPI.Construct("PointMassForce");
    Venusgrav.SetField("BodyName","Venus")
    fm.AddForce(Venusgrav);
    gmat.gmat.Initialize();
end
if Earth >= 1
    Earthgrav = GMATAPI.Construct("PointMassForce");
    Earthgrav.SetField("BodyName","Earth")
    fm.AddForce(Earthgrav);
    gmat.gmat.Initialize();
end
if Luna >= 1
    Lunagrav = GMATAPI.Construct("PointMassForce");
    Lunagrav.SetField("BodyName","Luna")
    fm.AddForce(Lunagrav);
    gmat.gmat.Initialize();
end
if Mars >= 1
    Marsgrav = GMATAPI.Construct("PointMassForce");
    Marsgrav.SetField("BodyName","Mars")
    fm.AddForce(Marsgrav);
    gmat.gmat.Initialize();
end
if Jupiter >= 1
    Jupitergrav = GMATAPI.Construct("PointMassForce");
    Jupitergrav.SetField("BodyName","Jupiter")
    fm.AddForce(Jupitergrav);
    gmat.gmat.Initialize();
end
if Saturn >= 1
    Saturngrav = GMATAPI.Construct("PointMassForce");
    Saturngrav.SetField("BodyName","Saturn")
    fm.AddForce(Saturngrav);
    gmat.gmat.Initialize();
end
if Uranus >= 1
    Uranusgrav = GMATAPI.Construct("PointMassForce");
    Uranusgrav.SetField("BodyName","Uranus")
    fm.AddForce(Uranusgrav);
    gmat.gmat.Initialize();
end
if Neptune >= 1
    Neptunegrav = GMATAPI.Construct("PointMassForce");
    Neptunegrav.SetField("BodyName","Neptune")
    fm.AddForce(Neptunegrav);
    gmat.gmat.Initialize();
end
if Pluto >= 1
    Plutograv = GMATAPI.Construct("PointMassForce");
    Plutograv.SetField("BodyName","Pluto")
    fm.AddForce(Plutograv);
    gmat.gmat.Initialize();
end
%{
Create ForceModel FM;
GMAT FM.CentralBody = Sun;
GMAT FM.PointMasses = {Sun};
GMAT FM.Drag = None;
GMAT FM.SRP = On;

GMAT FM.RelativisticCorrection = On;
GMAT FM.ErrorControl = RSSStep;
GMAT FM.SRP.Flux = 1367;
GMAT FM.SRP.SRPModel = Spherical;
GMAT FM.SRP.Nominal_Sun = 149597870.691;
%}
%Propagator
prop= GMATAPI.Construct("Propagator", "ThePropagator");
gator = GMATAPI.Construct("RungeKutta89");
prop.SetReference(gator);
prop.SetReference(fm); 
prop.SetField("InitialStepSize", 86400);
prop.SetField("Accuracy", 1.0e-9);
prop.SetField("MinStep", 86400);
prop.SetField("MaxStep", 86400);
prop.SetField("MaxStepAttempts", 52);
%Save script
gmat.gmat.SaveScript(WorkingDir+FileName_runS);
gmat.gmat.Clear();
%Replace ThrustProfile File Location
ThrustHFFN="GMAT ThrustHistoryFile1.FileName = ";
BlankFPWD="'C:\GMAT_Repo\GMAT_Generalized_LowThrust\GMAT_RunFolder\Blank_scripts\GMAT_BlankThrustProfile.thrust';";
TextToChange1=ThrustHFFN+BlankFPWD;
NewText1=ThrustHFFN+WorkingDir+FileName_runT;
FileRead1 = regexp(fileread(destinationS),'\n','split');
FileRead1New=FileRead1;
LineC1=find(contains(FileRead1,TextToChange1));
FileRead1New{LineC1}=NewText1;
%StopIfAccuracyIsViolated = true -> = false
StopATrue="GMAT ThePropagator.StopIfAccuracyIsViolated = true;";
StopAFalse="GMAT ThePropagator.StopIfAccuracyIsViolated = false;";
LineC2=find(contains(FileRead1,StopATrue));
FileRead1New{LineC2}=StopAFalse;
%RelativisticCorrection
if RelativisticCorrection == true
    LineC6=find(contains(FileRead1,"GMAT FM.RelativisticCorrection "));
    FileRead1New{LineC6}="GMAT FM.RelativisticCorrection = On;";
end
%SolarRadiationPressure
SRP_C=["GMAT FM.SRP.Flux = 1367;";"GMAT FM.SRP.SRPModel = Spherical;";"GMAT FM.SRP.Nominal_Sun = 149597870.691;"];
if SolarRadiationPressure == true
    LineC8=find(contains(FileRead1,"GMAT FM.SRP ="));
    FileRead1New{LineC8}="GMAT FM.SRP = On;";
    LineC7=find(contains(FileRead1,"GMAT FM.ErrorControl = RSSStep;"));
    for i=1:length(SRP_C)
        FileRead1New{LineC7+i}=SRP_C(i);
    end
end
%Rewrite File
fid1 = fopen(destinationS, 'w');
fprintf(fid1, '%s\n', FileRead1New{:});
fclose(fid1);
%% Configure GMAT Plot Script
sourceSP = fullfile(WorkingDir,FileName_runS);
destinationSP = fullfile(WorkingDir,FileName_runSP);
copyfile(sourceSP,destinationSP);
% Insert Plot Commands before Mission sequence 
FileRead2 = regexp(fileread(destinationSP),'\n','split');
LineC3=find(contains(FileRead2,"BeginMissionSequence;"));
CopyMissionSequence=strings(1,20);
for i=1:20    
    CopyMissionSequence{i}=FileRead2{LineC3-4+i};
end
OrbitViewC = regexp(fileread(fullfile(BlanksDir,FileName_blankO)),'\n','split');
LineC5=find(contains(OrbitViewC,"GMAT OrbitView1.Add = {"));
OrbitViewAdd="GMAT OrbitView1.Add = {Sat, Sun";
%Finds PlanetPlot in String array
Mercury2=find(contains(PlanetPlot,'Mercury'));
Venus2=find(contains(PlanetPlot,'Venus'));
Earth2=find(contains(PlanetPlot,'Earth'));
Luna2=find(contains(PlanetPlot,'Luna'));
Mars2=find(contains(PlanetPlot,'Mars'));
Jupiter2=find(contains(PlanetPlot,'Jupiter'));
Saturn2=find(contains(PlanetPlot,'Saturn'));
Uranus2=find(contains(PlanetPlot,'Uranus'));
Neptune2=find(contains(PlanetPlot,'Neptune'));
Pluto2=find(contains(PlanetPlot,'Pluto'));
if Mercury2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Mercury";
end
if Venus2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Venus";
end
if Earth2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Earth";
end
if Luna2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Luna";
end
if Mars2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Mars";
end
if Jupiter2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Jupiter";
end
if Saturn2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Saturn";
end
if Uranus2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Uranus";
end
if Neptune2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Neptune";
end
if Pluto2 >= 1
    OrbitViewAdd=OrbitViewAdd+", Pluto";
end
OrbitViewAdd=OrbitViewAdd+"};"; %end
OrbitViewC{LineC5}=OrbitViewAdd;
FileRead2New=FileRead2;
%UpdateRunTime Variable
LineC4=find(contains(FileRead2New,"Create Variable RunTime;"));
RunTime="GMAT RunTime = "+num2str(EndTime)+";";
FileRead2New{LineC4+1}=RunTime;
%Plot and MissionSequenceCommands
for i=1:(length(OrbitViewC))
    FileRead2New{LineC3-4+i}=OrbitViewC{i};
end
for i=1:(length(CopyMissionSequence))
    FileRead2New{LineC3-4+i+length(OrbitViewC)}=CopyMissionSequence{i};
end
%Rewrite File
fid2 = fopen(destinationSP, 'w');
fprintf(fid2, '%s\n', FileRead2New{:});
fclose(fid2);
%% Run Optimization
Optimize=0;
if Optimize==1
end
%% Run Plot Script with Solution
