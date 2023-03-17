function []=GMAT_LowThrust(TestSet)
%Note: 
%Sometimes GMAT API will crash MATLAB. Use breakpoints at failure point
%and copy load_gmat() into Command window.
%gmat.gmat.ShowObjects()

%clear
%clc
%clear all
%format longg

%Global variables passed to SNOPT Objective/Constraint  function
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
global TargetBody
%% NEXT STEPS TO WORK ON
%Problems to work on
% Write comments explaning code (do this today)
%1) Input Format Standardization
    %Thrust vs Acceleration
    %XYZ vs Alpha/Beta
    %Read full TimeSteps vs Just EndTime
    %Thrust Magnitude/Acceleration Magnitude
    %Massflow Rate -> provided or interpolated
    %StartDate
    %Start position, Velocity
    %Target Body -> uses Ephemeris in optimization
    %N-bodies, SolarRadiation, Relativistic Correction
    %N-bodies to plot
    %CenterBody
%2) Alpha, Beta angle interpolation for only thrust coordinate provided
%3) Acceleration Massflow Rate
%4) Function Input and Output


%% Initial State (INPUTS)
%Test data
%TestSet=1;
if TestSet==0 %BlankTestSet
    Alpha=zeros(100,1);
    Beta=zeros(100,1);
    EndTime=1000000; %Sec
    ISP=3000;
    StartDate=juliandate(2002,12,23,20,39,01);
    [R_i,V_i]= planetEphemeris(StartDate,'Sun','Mars');
    DM=23; %DryMass
    FuelM=1300; %Fuel Mass
    PointMasses={'Mercury','Venus','Earth','Luna','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto'};
    PlanetPlot={'Mercury','Venus','Earth','Luna','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto'};
    ThrustSetting={'Thrust'}; %or Acceleration
    ThrustCoordinateOption={'ThrustAngles'}; %or ThrustCoordinate
    RelativisticCorrection= true;%true; %or false
    SolarRadiationPressure= true;%true; %or false
    CentralBody={'Mars'};%CentralBodyICRF
    %ThrustInputs
    ThrustMag=0.1; %N
    ThrustXYZ=0; 
    
    %SNOPT Optimization options 
    Optimize=0;
    TargetBody={'Venus'};
    LowBound =10; %in days
    UpperBound= 3500; %in days
    MajorFeasibilityTolerance=1e-6;
    MajorOptimalityTolerance=1e-6;
    OptimizationRunTimeLimit= 86400; %Seconds 
    MajorIterationLimit=5000; 
end

if TestSet==1 %EathToMars(ThrustAngles) 1
    fileG=pwd+"\GMAT_thrust.txt";
    fIDG=fopen(fileG,'r');
    AG=textscan(fIDG, '%f %f %f %f', 'headerlines',1);
    InitialGuess_Data2=cell2mat(AG);
    fclose(fIDG);
    Alpha=InitialGuess_Data2(:,2);
    Beta=InitialGuess_Data2(:,3);
    EndTime=InitialGuess_Data2(end,1);
    ISP=2800;
    StartDate=juliandate(2023,07,20,00,00,00);
    [R_i,V_i]= planetEphemeris(StartDate,'Sun','Earth');
    DM=0; %DryMass
    FuelM=1000; %Fuel Mass
    PointMasses={};
    PlanetPlot={'Earth','Mars'};
    ThrustSetting={'Thrust'}; %or Acceleration
    ThrustCoordinateOption={'ThrustAngles'}; %or ThrustCoordinate
    RelativisticCorrection= false;%true; %or false
    SolarRadiationPressure= false;%true; %or false
    CentralBody={'Sun'};%CentralBodyICRF
    %ThrustInputs
    ThrustMag=0.1; %N
    ThrustXYZ=0; 
    
    %SNOPT Optimization options 
    Optimize=0;%1;
    TargetBody={'Mars'};
    LowBound =10; %in days
    UpperBound= 3500; %in days
    MajorFeasibilityTolerance=1e-6;
    MajorOptimalityTolerance=1e-6;
    OptimizationRunTimeLimit=86400; %Seconds 
    MajorIterationLimit=5000*10; 
    
end

if TestSet==2 %EathToMars(Acceleration+Coordinate) 2
    fileG=pwd+"\Earth_Mars_data.xlsx";
    Table = readtable(fileG);
    R_i=table2array(Table(1:3,1))';
    V_i=table2array(Table(1:3,2))';
    DM=0; %DryMass
    FuelM=table2array(Table(1,5)); %Fuel Mass
    ISP=table2array(Table(1,6));
    PointMasses={};
    PlanetPlot={'Earth','Mars'};
    ThrustSetting={'Acceleration'}; %or Acceleration
    ThrustCoordinateOption={'ThrustCoordinate'}; %or ThrustCoordinate
    RelativisticCorrection= false;%true; %or false
    SolarRadiationPressure= false;%true; %or false
    CentralBody={'Sun'};%CentralBodyICRF
    ThrustMag=table2array(Table(1,7));
    Time=table2array(Table(:,8));
    EndTime=Time(end);
    ThrustXYZ=table2array(Table(:,9:11));
    
    %Assume values
    StartDate=juliandate(2023,07,20,00,00,00);
    
    
    
    %SNOPT Optimization options 
    Optimize=0;
    TargetBody={'Mars'};
    LowBound =10; %in days
    UpperBound= 3500; %in days
    MajorFeasibilityTolerance=1e-6;
    MajorOptimalityTolerance=1e-6;
    OptimizationRunTimeLimit= 86400; %Seconds 
    MajorIterationLimit=5000;
    
end
%}




%% Julian Date to UTC Gregorian format
StartEpoch=string(datetime(StartDate,'convertfrom','juliandate','Format',...
    'dd'' ''MMM'' ''yyyy'' ''HH:mm:ss.SSS'));
%StartEpoch="20 Jul 2023 00:00:00.000"; %Can only be in  UTC Gregorian format
%% Check Inputs of ThrustCoordinate and ThrustSetting
ThrustAngle=find(contains(ThrustCoordinateOption,'ThrustAngles'));
ThrustCoordinate=find(contains(ThrustCoordinateOption,'ThrustCoordinate'));
Accel=find(contains(ThrustSetting,'Acceleration'));
Thrus=find(contains(ThrustSetting,'Thrust'));
if ThrustAngle >= 1 %For Alpha, Beta Angles
    if length(Alpha) ~= length(Beta)
        fprintf("GMAT: Size of Thrust Direction Angles Don't Match")
        return
    end
    NumberOfSteps=length(Alpha);
    Time = linspace(0,EndTime,NumberOfSteps+1)';  % seconds
    ThrustVec=ThrustMag.*[cos(Beta).*cos(Alpha),cos(Beta).*sin(Alpha),sin(Beta)];
    if  Thrus >= 1 %ThrustForce
        mdotO= ThrustMag/(ISP *9.807);
        mdot=ones(NumberOfSteps+1,1)*mdotO;
    elseif Accel >=1 %Acceleration
        mdot=ones(NumberOfSteps+1,1);
        PropellantMass=FuelM;
        Mtotal=DM+PropellantMass;
        TimeStep=Time(2);
        for i=1:NumberOfSteps %MassFlow Rate interpolation
            mdot(i)= (ThrustMagnitude(i)*Mtotal)/(ISP *9.807); %This may be wrong
            PropellantMass=PropellantMass-(mdot(i)*TimeStep);
            Mtotal=DM+PropellantMass;
        end
     end 
elseif ThrustCoordinate >= 1
    SizeXYZ=size(ThrustXYZ);
    if SizeXYZ(2) == 3
        ThrustVec=ThrustXYZ;
        NumberOfSteps=length(ThrustVec(:,1));
        Time = linspace(0,EndTime,NumberOfSteps+1)';  % seconds
        ThrustMagnitude=ones(NumberOfSteps,1);
        Alpha=ones(NumberOfSteps,1);
        Beta=ones(NumberOfSteps,1);
        mdot=ones(NumberOfSteps+1,1);
        PropellantMass=FuelM;
        Mtotal=DM+PropellantMass;
        TimeStep=Time(2);
        for i=1:NumberOfSteps
            ThrustMagnitude(i)=norm(ThrustVec(i,1:3));
            if Optimize==1%Solve for alpha,beta angles 
                %SEEMS to be broken
                Beta(i)=asin(ThrustVec(i,3)/ThrustMagnitude(i));
                Alpha(i)=acos((ThrustVec(i,1)/ThrustMagnitude(i)) / cos(Beta(i)));
                ThrustVecNew=ThrustMagnitude(i).*[cos(Beta(i))*cos(Alpha(i)),...
                    cos(Beta(i))*sin(Alpha(i)),sin(Beta(i))];
                if (Alpha(i) ~= (asin((ThrustVec(i,2)/ThrustMagnitude(i)) / ...
                        cos(Beta(i))))) || any(ThrustVecNew ~= ThrustVec(i,1:3)) 
                    fprintf("GMAT: Thrust Angle Interpolation error");
                    return
                end
            end
            if  Thrus >= 1
                mdot(i)= ThrustMagnitude(i)/(ISP *9.807);
            elseif Accel >=1
                mdot(i)= (ThrustMagnitude(i)*Mtotal)/(ISP *9.807); %This may be wrong
                PropellantMass=PropellantMass-(mdot(i)*TimeStep);
                Mtotal=DM+PropellantMass;
            end 
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
%% Copy Files Over To Working Directory
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
    'Thrust_Vector_Coordinate_System = CentralBodyICRF',newline,...  
    'Thrust_Vector_Interpolation_Method  = None',newline,...
    'Mass_Flow_Rate_Interpolation_Method = None',newline,...
    ThrustProfileModel]; 
Thrust = zeros(NumberOfSteps+1,3);
Thrust(1:(end-1),:)=ThrustVec;
% Obtain time history
for i=1:(NumberOfSteps+1)
    LineToChange = i+1;         % first 6 lines ae used for headers
    NewContent = compose("%.16f \t %.16f %.16f %.16f %.16f",Time(i),Thrust(i,1),...
        Thrust(i,2),Thrust(i,3),mdot(i));
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
%Spacecraft Configuration
sat = gmat.gmat.Construct("Spacecraft", "Sat");
sat.SetField("DateFormat", "A1ModJulian")           
sat.SetField("Epoch", num2str(StartDate-2430000.0)) %modified Julian Date
sat.SetField("CoordinateSystem", "CentralBodyICRF")
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
fm.SetField("CentralBody", string(CentralBody)); %set to central body
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
%Propagator
prop= GMATAPI.Construct("Propagator", "ThePropagator");
gator = GMATAPI.Construct("RungeKutta89");
prop.SetReference(gator);
prop.SetReference(fm); 
prop.SetField("InitialStepSize", 86400);
prop.SetField("Accuracy", 1.0e-9);
prop.SetField("MinStep", 86400);
prop.SetField("MaxStep", 86400);
prop.SetField("MaxStepAttempts", 50);
%CoordinateSystem
%CentralBodyICRF = gmat.gmat.Construct("CoordinateSystem", "CentralBodyICRF", string(CentralBody), "ICRF");
%GMAT API CRASH POINT! Use breakpoint, load_gmat() in command window, or
%use gmat.gmat.LoadScript(WorkingDir+FileName_runS);
gmat.gmat.SaveScript(WorkingDir+FileName_runS);
gmat.gmat.Clear();
%Replace ThrustProfile File Location
ThrustHFFN="GMAT ThrustHistoryFile1.FileName = ";
BlankFPWD="'C:\GMAT_Repo\GMAT_Generalized_LowThrust\GMAT_RunFolder\Blank_scripts\GMAT_BlankThrustProfile.thrust';";
TextToChange1=ThrustHFFN+BlankFPWD;
NewText1=ThrustHFFN+"'"+WorkingDir+FileName_runT+"';";
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
SRP_C=["GMAT FM.SRP.Flux = 1367;";"GMAT FM.SRP.SRPModel = Spherical;";...
    "GMAT FM.SRP.Nominal_Sun = 149597870.691;"];
if SolarRadiationPressure == true
    LineC8=find(contains(FileRead1,"GMAT FM.SRP ="));
    FileRead1New{LineC8}="GMAT FM.SRP = On;";
    LineC7=find(contains(FileRead1,"GMAT FM.ErrorControl = RSSStep;"));
    for i=1:length(SRP_C)
        FileRead1New{LineC7+i}=SRP_C(i);
    end
end
%CoordinateSystem
%CentralBodyICRF = gmat.gmat.Construct("CoordinateSystem", "CentralBodyICRF", string(CentralBody), "ICRF");
LineC0=find(contains(FileRead1,"GMAT CentralBodyICRF.Origin = Sun;"));
FileRead1New{LineC0}="GMAT CentralBodyICRF.Origin = "+string(CentralBody)+";"; 
%Rewrite File
fid1 = fopen(destinationS, 'w');
fprintf(fid1, '%s\n', FileRead1New{:});
fclose(fid1);
%RunScript
load_gmat();
gmat.gmat.Clear(); %Clears GMAT API configuration
gmat.gmat.LoadScript(destinationS);
Ans1 = gmat.gmat.RunScript();
if Ans1 ~= 1
    fprintf("GMAT: Failed to Run GMAT Run Script")
    return
end
%% Run SNOPT Optimization
if Optimize==1 && any(size(TargetBody) ~= 1)
    fprintf("Gmat: Target Body error")
    return
end
if Optimize==1
    %Constants
    muS = 1.32712440018e+11;   % Km^3/sec^2 
    g   = 9.807;                 % m/s^2
    AU  = 149598000;            % km
    TU  = sqrt(AU^3/muS);       % sec
    VU  = AU/TU;                % km/sec
    Th = ThrustMag;               % kg m/s^2
    Isp = ISP;             % s^-1
    Vex = Isp*g;            % m/s
    m0  = FuelM;             % kg
    t1 = StartDate;
    %Initial Guess vector (Alpha, Beta, TOF)
    x=[Alpha;Beta;EndTime/TU];
    % Bounds
    lb = [-ones(NumberOfSteps,1)*pi;    % Alpha
          -ones(NumberOfSteps,1)*pi;    % Beta  
          LowBound*86400/TU];             % TOF (TU) %900

    ub = [ones(NumberOfSteps,1)*pi;     % Alpha 
          ones(NumberOfSteps,1)*pi;     % Beta 
          UpperBound*86400/TU];            % TOF (TU) %1100
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
    %SNOPT Optimization Routine
    ObjAdd =0; %Add value to objective Row
    ObjRow =1; %Tell the Optimizer which row of F is the objective function
    snscreen on;  
    snsummary('SNOPt_summary.txt');
    %tolerance values, 1e-6 by default 
    snsetr('Major feasibility tolerance',MajorFeasibilityTolerance); 
    snsetr('Major optimality tolerance',MajorOptimalityTolerance);
    snsetr('Minor feasibility tolerance',1e-6);
    snsetr('Minor optimality tolerance',1e-6);
    snseti('Time limit',OptimizationRunTimeLimit);%345600); %Sets time limit to 1 day (in seconds)
    snseti('Major iteration limit',MajorIterationLimit);
    snseti('Minor iteration limit',MajorIterationLimit*500)
    snseti('Line search algorithm', 3)%More-Thuente line search
    load_gmat();
    tic
    [x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
        snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate,...
        'objFunc_conFunc', ObjAdd, ObjRow);
    toc
    % Extract Design Variables
    Thrust_alpha = x(1:NumberOfSteps);                   % rads
    Thrust_beta = x(NumberOfSteps+1:2*NumberOfSteps);   % rads
    EndTime     = x(end)*TU;                                           % s
    ThrustVec=Th.*[cos(Thrust_beta).*cos(Thrust_alpha),cos(Thrust_beta).*sin(Thrust_alpha), ...
        sin(Thrust_beta)];
    Thrust = zeros(NumberOfSteps+1,3);
    Thrust(1:(end-1),:)=ThrustVec;
    Time = linspace(0,EndTime,NumberOfSteps+1)';  % seconds    
end
%% Solution Thrust Profile
ThrustProfileSolution='\GMAT_ThrustProfileSolution.thrust'; 
destinationSolution = fullfile(WorkingDir,ThrustProfileSolution);
copyfile(destinationT,destinationSolution);
% Write the contents of the Thrust File
for i=1:NumberOfSteps+1
    LineToChange = i+1;         % first 6 lines are used for header
    NewContent = compose("%.16f \t %.16f %.16f %.16f %.16f",Time(i),Thrust(i,1),...
        Thrust(i,2),Thrust(i,3),mdot(i));
    SS{LineToChange} = NewContent;
end
fid3 = fopen(destinationSolution, 'w');
fprintf(fid3,'%s',headlines);
fprintf(fid3, '%s\n', SS{:});
fprintf(fid3,'%s','EndThrust{ThrustSegment1}');
fclose(fid3); 
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
%Update view Direction/Reference
LineC7=find(contains(OrbitViewC,"GMAT OrbitView1.ViewPointReference = Sun;"));
NewText3="GMAT OrbitView1.ViewPointReference = "+string(CentralBody)+";";
LineC8=find(contains(OrbitViewC,"GMAT OrbitView1.ViewDirection"));
NewText4="GMAT OrbitView1.ViewDirection = "+string(CentralBody)+";";
OrbitViewAdd=OrbitViewAdd+"};"; 
OrbitViewC{LineC5}=OrbitViewAdd;
OrbitViewC{LineC7}=NewText3;
OrbitViewC{LineC8}=NewText4;
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
%Replace ThrustProfile with Solution Profile
LineC6=find(contains(FileRead2,NewText1));
NewText2=ThrustHFFN+"'"+destinationSolution+"';";
FileRead2New{LineC6}=NewText2;
%Rewrite File
fid2 = fopen(destinationSP, 'w');
fprintf(fid2, '%s\n', FileRead2New{:});
fclose(fid2);
%RunPlotScript
load_gmat();
gmat.gmat.Clear(); %Clears GMAT API configuration
gmat.gmat.LoadScript(destinationSP);
Ans2 = gmat.gmat.RunScript();
if Ans2 ~= 1
    fprintf("GMAT: Failed to Run GMAT Plot Script")
    return
end
end%END
