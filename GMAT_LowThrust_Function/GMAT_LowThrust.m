function [OutPut_DataStruct]=GMAT_LowThrust(FileName,varargin)
%% README (Instructions)
%   GMAT_LowThrust writes GMAT script files to propagate and optimize
%   low-thrust trajectory problems
%   
%   Low_Thrust problems may be propagated as is or optimized.
%   The bin folder of GMAT must be within your path variable for the API
%   commands used in this function to work.
%   Optimization is done using SNOPT 7.6 Matlab interface (Other versions
%   may work).
%   SNOPT Guide Link: 
%   https://ccom.ucsd.edu/~optimizers/docs/snopt/interfaces.html#matlab
%   https://ccom.ucsd.edu/~optimizers/static/pdfs/sndoc7.pdf
%   SNOPT Matlab folder must be within the path variable for optimization to work 
%   The constraint / objective function is called using objFunc_conFunc
%
%   Optimization Notes and Limitations:
%
%   1) Optimization assumes that thrust/acceleration magnitude remains
%   constant, and if fuel mass is decremented, it's constant for all time steps.
%   2) Optimization works by updating a GMAT thrust history file and rerunning a
%   GMAT script. This process is computationally inefficient as files must be
%   saved to the hard drive. -> Long run times
%   3) Optimization performance depends on how the design variable, constraint,
%   and objective bounds are defined. You may want to adjust these parameters
%   to improve the performance of your problem. 
%   4) Problems with more than 200 steps tend to take more than 10 hours to
%   optimize for optimal time of flight. 
%
%   Function inputs and outputs:
%   
%   [OutPut_DataStruct]=GMAT_LowThrust(FileName,varargin)
%   1) OutPut_DataStruct includes the time step array, ICRF coordinates thrust
%   array, Alpha (in-plane), and Beta (out-plane) thrust angles. X is the design
% variable array from the last optimization iteration. 
%   2) FileName is the name of the Excel file that includes the set-up
%   information about your problem. Example input: "\EarthToMarsProblem.xlsx"
%   3) varargin includes the optional inputs
%       i) 'Optimize' option tells the function that you want to optimize your
%       low-thrust problem. This will launch the SNOPT optimization
%       sequence and run 'objFunc_conFunc' (objective/constraint function)
%       ii) By default, the optimizer will run with default settings. To
%       change settings, you need to pass in a struct after 'Optimize' that
%       includes your optimization settings. Example:
%   opt = struct( ...
%    'TOF_LowBound',200,'TOF_UpperBound',1000,'MajorFeasibilityTolerance',1e-6,...
%    'MajorOptimalityTolerance',1e-6,'OptimizationRunTimeLimit',86400,...
%    'MajorIterationLimit',5000,'Obj','Cons');
%       a) TOF_LowBound and TOF_UpperBound, are the lower and upper bound
%       time of flight used in the optimization sequence. Values in days
%       b) MajorFeasibilityTolerance and MajorOptimalityTolerance are the feasibility 
%       and optimality tolerance SNOPT settings 
%       c) OptimizationRunTimeLimit is how long the SNOPT optimization
%       sequence will run. In seconds
%       d) MajorIterationLimit is the limit on the number of major
%       iterations that will be run during optimization
%       e) Obj is the objective function setting option. The two settings are
%       'Cons' and 'TOF'
%           'Cons' is used to minimize the state vector constraints without
%           defining the Time of Flight as the objective to minimize 
%           'TOF' is used to optimize the Time of Flight as the
%           objective function
%   4) The function will also generate the files GMAT_RunScript_Plots.script and 
%   GMAT_ThrustProfileSolution.thrust in the GMAT_RunFolder. GMAT_RunScript_Plots is a GMAT file
%   that can be used to plot the orbital trajectory (for visualization) and 
%   GMAT_ThrustProfileSolution is the thrust history file used to propagate
%   the trajectory. During optimization, the files GMAT_RunScript and
%   GMAT_RunThrustProfile will also be created. GMAT_RunThrustProfile will 
%   have the most up-to-date iteration in the optimization sequence.
%   If you need to end the optimization sequence before GMAT_RunScript_Plots 
%   and GMAT_ThrustProfileSolution.thrust are generated, you can modify the
%   existing GMAT_RunScript_Plots to run the last iteration of GMAT_RunThrustProfile.
%   5) The file SNOPT_summary.txt will also be created during the
%   optimization sequence. This file includes a summary of the SNOPT optimization.
%
%   Example Input:
%
%   Propgating trajectory without optimization:
%   OutPut_DataStruct=GMAT_LowThrust("\EarthToMarsProblem.xlsx")
%
%   Optimizing using default settings:
%   OutPut_DataStruct=GMAT_LowThrust("\EarthToMarsProblem.xlsx",'Optimize')
%
%   Optimizing using own settings struct:
%   OutPut_DataStruct=GMAT_LowThrust("\EarthToMarsProblem.xlsx",'Optimize',Opt)
%   
%   Supporting Functions:
%
%   X_interpreter-> can be used to generate output struct if optimization
%   sequence is paused/terminated before completion. 
%   GMAT_LowThrustDataInterolator-> can be used to increase or decrease the
%   number of time steps of a problem.
%   LowThrustOutputStructToExcel-> can be used to regenerate the Excel set-up
%   sheet using output struct. 
%
%   Known Errors:   'Minor iteration limit' is stuck at 10000
%   
%   Future Work:
%   Replacing/Providing the option to optimize with GMAT's CSALT plugin
%   Improve run time of optimization



%Global variables passed to SNOPT Objective/Constraint function
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
global TargetSetting
global TargetSV
global MassFOn
global UpperBoundTOF
global OptObj
narginchk(1, 3);%Check input
if contains(class(FileName),'string') 
    Fname=char(FileName);
    if ~contains(Fname(1),'\')
        fprintf("\nGMAT: Invalid File Name\n");
        dbstack()
        return
    end
else
    fprintf("\nGMAT: Invalid File Name\n");
    dbstack()
    return   
end
defaultopt = struct( ...
    'TOF_LowBound',200,'TOF_UpperBound',1000,'MajorFeasibilityTolerance',1e-6,...
    'MajorOptimalityTolerance',1e-6,'OptimizationRunTimeLimit',86400,...
    'MajorIterationLimit',5000,'Obj','Cons');%'TOF');
    Opt=defaultopt;
    %Optimize=0;
    %LowBound =10; %in days
    %UpperBound= 3500; %in days
    %MajorFeasibilityTolerance=1e-6;
    %MajorOptimalityTolerance=1e-6;
    %OptimizationRunTimeLimit= 86400; %Seconds 
    %MajorIterationLimit=5000; 
    %'Obj' Objective Function is Time Of Flight (TOF) or Minimize
    %Constraints (Cons)
if nargin>1
    Optimize=varargin{1};
    if (contains(class(Optimize),'string') || contains(class(Optimize),'char')) ...
            && contains(Optimize,'Optimize')
        fprintf("\n SNOPT Optimizer On\n")
        Optimize=1;%Turns SNOPT on for other parts of code
        if nargin>2
            if ~isstruct(varargin{2})
                fprintf("\nGMAT: Third Function Argument Not Struct\n");
                dbstack()
                return 
            end
            InputStruct=varargin{2};
            if isfield(InputStruct,'TOF_LowBound')
                Opt.TOF_LowBound=InputStruct.TOF_LowBound;
            end
            if isfield(InputStruct,'TOF_UpperBound')
                Opt.TOF_UpperBound=InputStruct.TOF_UpperBound;
            end
            if isfield(InputStruct,'MajorFeasibilityTolerance')
                Opt.MajorFeasibilityTolerance=InputStruct.MajorFeasibilityTolerance;
            end
            if isfield(InputStruct,'MajorOptimalityTolerance')
                Opt.MajorOptimalityTolerance=InputStruct.MajorOptimalityTolerance;
            end
            if isfield(InputStruct,'OptimizationRunTimeLimit')
                Opt.OptimizationRunTimeLimit=InputStruct.OptimizationRunTimeLimit;
            end
            if isfield(InputStruct,'MajorIterationLimit')
                Opt.MajorIterationLimit=InputStruct.MajorIterationLimit;
            end
            if isfield(InputStruct,'Obj')
                Opt.Obj=InputStruct.Obj;
            end
        end
        if contains(class(Opt.Obj),'char')==1
            if contains(Opt.Obj,'Cons')==1
                OptObj=2;
            else
                OptObj=1;
            end       
        end        
        fprintf("\n SNOPT Optimizer Options Set To\n")
        disp(Opt)
    end
else
    Optimize=0;
end
%% Read Excel Table and check if proper inputs 
fileG=pwd+FileName;
InputTable = readtable(fileG,'ReadVariableNames',false);
PlanetsArray={'Sun','Mercury','Venus','Earth','Luna','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto'};
%^Array of all possible planets in string arrays
%Start Date Input
StartDate=table2array(InputTable(1,1));
if contains(class(StartDate),'double')~=1
    fprintf("\nGMAT: Invalid Start Date\n");
    dbstack()
    return
end
if StartDate>juliandate(1900,00,00,00,00,00) && StartDate<... %Limits
        juliandate(2500,00,00,00,00,00)
else 
    fprintf("\nGMAT: Invalid Start Date\n");
    dbstack()
    return
end
%Central Body Input
CentralBody=table2array(InputTable(1,2));%CentralBodyICRF
if ismember(CentralBody,PlanetsArray)~= 1 || contains(class(CentralBody),'cell')~=1
    fprintf("\nGMAT: Invalid Central Body\n");
    dbstack()
    return
end
%Initial Position & Velocity Input
R_i=table2array(InputTable(1:3,3))';%Sat inital State Vector
V_i=table2array(InputTable(1:3,4))';
if contains(class(R_i),'double')~=1 || contains(class(V_i),'double')~=1 || ...
        any(isnan(R_i)) || any(isnan(V_i))
    fprintf("\nGMAT: Invalid Initial State Vector\n");
    dbstack()
    return
end
%Final State Type Input, Only needed for optimization
if Optimize==1
    FinalStateType=table2array(InputTable(1,5));
    if contains(class(FinalStateType),'cell')~=1
        fprintf("\nGMAT: Invalid Final State Type\n");
        dbstack()
        return
    elseif contains(FinalStateType, 'Planetary Rendezvous') 
        TargetBody=table2array(InputTable(1,6));
        if contains(class(TargetBody),'cell')~=1 || ismember(TargetBody,PlanetsArray) ~= 1
            fprintf("\nGMAT: Invalid Target Body\n");
            dbstack()
            return
        end
        TargetSetting=1;
    elseif contains(FinalStateType, 'State Vector') 
        TargetBody={'None'};
        TargetSetting=0;
        R_f=table2array(InputTable(1:3,7))';
        V_f=table2array(InputTable(1:3,8))';
        if contains(class(R_f),'double')~=1 || contains(class(V_f),'double')~=1 || ...
            any(isnan(R_f)) || any(isnan(V_f))
            fprintf("\nGMAT: Invalid Final State Vector\n");
            dbstack()
            return
        end
        TargetSV(1:3)=R_f;
        TargetSV(4:6)=V_f;
    else
        fprintf("\nGMAT: Invalid Final State Type\n");
        dbstack()
        return
    end
else %For when Optimize==0
end
%Initial Fuel Mass input
FuelM=table2array(InputTable(1,9)); %Fuel Mass
if isnumeric(FuelM)~=1 || FuelM<0 || FuelM> 10^6
    fprintf("\nGMAT: Invalid Fuel Mass\n");
    dbstack()
    return
end
%Dry Mass input, can be zero
DM=table2array(InputTable(1,10)); %Dry Mass
if isnumeric(DM)~=1 || DM<0 || DM> 10^6
    fprintf("\nGMAT: Invalid Dry Mass\n");
    dbstack()
    return
end  
%Mass Flow Option, Checks if you want to decrement Fuel Mass every time
%step
MassFlowOption=table2array(InputTable(1,11)); %Check Mass Flow option
if contains(class(MassFlowOption),'cell')~=1
    fprintf("\nGMAT: Invalid Mass Flow Option\n");
    dbstack()
    return
elseif contains(MassFlowOption, 'Off') %No mass flow case
    ISP=0; 
elseif contains(MassFlowOption, 'On') 
    ISP=table2array(InputTable(1,12));
    if contains(class(ISP),'double')~=1 || isnan(ISP) || not(ISP>0)
        fprintf("\nGMAT: Invalid ISP\n");
        dbstack()
        return
    end
else
    fprintf("\nGMAT: Invalid Mass Flow Option\n");
    dbstack()
    return
end
%Gravitational Point Masses, GMAT will default to just Sun for 2-body
%problems
PointMasses=table2array(InputTable(1:end,13));
if contains(class(PointMasses),'cell')==1 %Check if in PlanetsArray
    PointMasses=PointMasses(~cellfun('isempty', PointMasses));
    for j=1:length(PointMasses)
        if ismember(PointMasses(j),PlanetsArray)~= 1
            fprintf("\nGMAT: Invalid Point Mass Entry\n");
            dbstack()
            return
        end  
    end
    PointMasses=unique(PointMasses);
elseif all(isnan(PointMasses)) %Checks if blank
    PointMasses={};
else
    fprintf("\nGMAT: Invalid Point Mass Entry\n");
    dbstack()
    return
end
%Planets to Plot input, only for visualization on final solution orbit plot
PlanetPlot=table2array(InputTable(1:end,14));
if contains(class(PlanetPlot),'cell')==1 %Check if in PlanetsArray
    PlanetPlot=PlanetPlot(~cellfun('isempty', PlanetPlot));
    for j=1:length(PlanetPlot)
        if ismember(PlanetPlot(j),PlanetsArray)~= 1
            fprintf("\nGMAT: Invalid Planet Plot Entry\n");
            dbstack()
            return
        end  
    end
    PlanetPlot=unique(PlanetPlot);
elseif all(isnan(PlanetPlot)) %Checks if blank
    PlanetPlot={};
else
    fprintf("\nGMAT: Invalid Planet Plot Entry\n");
    dbstack()
    return
end
%Thrust Setting Input, tells function if magnitude/XYZ are acceleration
%(m/s^2) values or Thust Forces (Newtons)
ThrustSetting=table2array(InputTable(1,15)); %Thrust Setting 
if contains(class(ThrustSetting),'cell')~=1
    fprintf("\nGMAT: Invalid Thrust Setting Type\n");
    dbstack()
    return
elseif contains(ThrustSetting, 'Acceleration') || contains(ThrustSetting, 'Force') 
else
    fprintf("\nGMAT: Invalid Thrust Setting Type\n");
    dbstack()
    return
end
ThrustMag=table2array(InputTable(1,17));
if isnumeric(ThrustMag)~=1 || isnan(ThrustMag) || ThrustMag<0 || ThrustMag> 1
    fprintf("\nGMAT: Invalid Thrust Magnitude\n");
    dbstack()
    return
end 
%Time vector array input
Time=table2array(InputTable(:,18));
if ~isnumeric(Time) 
    fprintf("\nGMAT: Invalid Time Array\n");
    dbstack()
    return
else
    Time=Time(1:find(~isnan(Time), 1, 'last'));
    if any(isnan(Time))
        fprintf("\nGMAT: Invalid Time Array\n");
        dbstack()
        return
    end
    EndTime=Time(end);
    for i=2:length(Time)
        if (Time(i)-Time(i-1))<0 %Check if time array is increasing 
            fprintf("\nGMAT: Invalid Time Array\n");
            dbstack()
            return
        end
    end
end
%Check for "thrust coordinate type", if providing angles (Alpha, Beta) or just XYZ
%vector component form
ThrustCoordinateOption=table2array(InputTable(1,16)); 
if contains(class(ThrustCoordinateOption),'cell')~=1
    fprintf("\nGMAT: Invalid Thrust Coordinate Type\n");
    dbstack()
    return
elseif contains(ThrustCoordinateOption, 'XYZ') 
    ThrustXYZ=table2array(InputTable(:,19:21));
    if contains(class(ThrustXYZ),'double')~=1 || any(any(isnan(ThrustXYZ))) ...
            || not(length(ThrustXYZ)==length(Time))
        fprintf("\nGMAT: Invalid Thrust XYZ Array\n");
        dbstack()
        return
    end
elseif contains(ThrustCoordinateOption, 'Thrust Angles') 
    Alpha=table2array(InputTable(:,22));
    Beta=table2array(InputTable(:,23));
    if contains(class(Alpha),'double')~=1 || contains(class(Beta),'double')~=1 ...
            || any(isnan(Alpha)) || any(isnan(Beta)) || not(length(Alpha)==length(Time)) ...
            || not(length(Alpha)==length(Beta))
        fprintf("\nGMAT: Invalid Thrust Angles\n");
        dbstack()
        return
    end       
else
    fprintf("\nGMAT: Invalid Thrust Coordinate Type\n");
    dbstack()
    return
end
%Disable options by default in propagator 
%Can turn on here in code, may add to excel sheet later 
RelativisticCorrection= false;%true; %or false
SolarRadiationPressure= false;%true; %or false
%% Julian Date to UTC Gregorian format
StartEpoch=string(datetime(StartDate,'convertfrom','juliandate','Format',...
    'dd'' ''MMM'' ''yyyy'' ''HH:mm:ss.SSS'));
%StartEpoch="20 Jul 2023 00:00:00.000"; %Can only be in  UTC Gregorian format
%% Check Inputs of ThrustCoordinate and ThrustSetting
ThrustAngle=find(contains(ThrustCoordinateOption,'Thrust Angles'));
ThrustCoordinate=find(contains(ThrustCoordinateOption,'XYZ'));
Accel=find(contains(ThrustSetting,'Acceleration'));
Thrus=find(contains(ThrustSetting,'Force'));
MassFOn=find(contains(MassFlowOption,'On'));
if isempty(MassFOn)
    MassFOn=0;
end
NumberOfSteps=length(Time);
if ThrustAngle >= 1 %For Alpha, Beta Angles
    %This assumes that magnitude is constant for all time steps
    %Mass flow rate is constant for Thrust (newtons) case
    if length(Alpha) ~= length(Beta)
        fprintf("\nGMAT: Size of Thrust Direction Angles Don't Match\n")
        dbstack()
        return
    end
    ThrustVec=ThrustMag.*[cos(Beta).*cos(Alpha),cos(Beta).*sin(Alpha),sin(Beta)];
    if  Thrus >= 1 %ThrustForce
        mdotO= ThrustMag/(ISP *9.807);
        mdot=ones(NumberOfSteps,1)*mdotO;
    elseif Accel >=1 && MassFOn==1 %Acceleration MassFOn
        mdot=ones(NumberOfSteps,1);
        PropellantMass=FuelM;
        Mtotal=DM+PropellantMass;
        TimeStep=Time(2); %Uniform Time Step
        ThrustMagnitude=ones(NumberOfSteps,1)*ThrustMag;
        for i=1:NumberOfSteps %MassFlow Rate interpolation
            mdot(i)= (ThrustMagnitude(i)*Mtotal)/(ISP *9.807); 
            PropellantMass=PropellantMass-(mdot(i)*TimeStep);
            Mtotal=DM+PropellantMass;
        end
     end 
elseif ThrustCoordinate >= 1 %For XYZ thrust vector componets 
    SizeXYZ=size(ThrustXYZ);
    if SizeXYZ(2) == 3
        ThrustVec=ThrustXYZ;
        ThrustMagnitude=ones(NumberOfSteps,1);
        Alpha=ones(NumberOfSteps,1);
        Beta=ones(NumberOfSteps,1);
        mdot=ones(NumberOfSteps,1);
        PropellantMass=FuelM;
        Mtotal=DM+PropellantMass;
        TimeStep=Time(2);
        for i=1:NumberOfSteps
            ThrustMagnitude(i)=norm(ThrustVec(i,1:3));
            %if Optimize==1%Solve for alpha,beta angles 
            Beta(i)=asin(ThrustVec(i,3)/ThrustMagnitude(i));
            Alpha(i)=atan(ThrustVec(i,2)/ThrustVec(i,1));
            %end
            %Mass Flow Rate Calculation
            if  Thrus >= 1
                mdot(i)= ThrustMagnitude(i)/(ISP *9.807);
            elseif Accel >=1
                mdot(i)= (ThrustMagnitude(i)*Mtotal)/(ISP *9.807);
                PropellantMass=PropellantMass-(mdot(i)*TimeStep);
                Mtotal=DM+PropellantMass;
            end 
        end
    else
        fprintf("\nGMAT: Thrust XYZ does not have 3 columns\n")
        dbstack()
        return   
    end    
elseif ThrustAngle >= 1 && ThrustCoordinate >= 1
    fprintf("\nGMAT: Thrust Angle and Thrust Coordinate Option Selected\n")
    dbstack()
    return
else
    fprintf("\nGMAT: No Thrust Coordinate Option Selected\n")
    dbstack()
    return
end
%% Copy Files Over To Working Directory
MainDir = pwd;
WorkingDir=MainDir+"\GMAT_RunFolder";
%BlanksDir=WorkingDir+"\Blank_scripts";
%FileName_blankS="GMAT_BlankScript.script";
%FileName_blankT="GMAT_BlankThrustProfile.thrust";
%FileName_blankO="OrbitViewPlotCommands.txt";
FileName_runS="\GMAT_RunScript.script";
FileName_runSP="\GMAT_RunScript_Plots.script";
FileName_runT="\GMAT_RunThrustProfile.thrust";
%sourceS = fullfile(BlanksDir,FileName_blankS);
destinationS = fullfile(WorkingDir,FileName_runS);
%sourceT = fullfile(BlanksDir,FileName_blankT);
destinationT = fullfile(WorkingDir,FileName_runT);
mkdir(WorkingDir);
%GMAT Script Template
ScriptTemp =...
    {'%General Mission Analysis Tool(GMAT) Script',...
'%Created: 2023-02-28 19:34:12',...
'',...
'%----------------------------------------',...
'%---------- Spacecraft',...
'%----------------------------------------',...
'Create Spacecraft Sat;',...
'GMAT Sat.DateFormat = UTCGregorian;',...
"GMAT Sat.Epoch = '20 Jul 2023 00:00:00.000';",...
'GMAT Sat.CoordinateSystem = CentralBodyICRF;',...
'GMAT Sat.DisplayStateType = Cartesian;',...
'GMAT Sat.X = 68405277.7525657;',...
'GMAT Sat.Y = -124569338.82142;',...
'GMAT Sat.Z = -54000478.8230257;',...
'GMAT Sat.VX = 26.12608398815661;',...
'GMAT Sat.VY = 12.20163451293511;',...
'GMAT Sat.VZ = 5.289560433755932;',...
'GMAT Sat.DryMass = 0;',...
'GMAT Sat.Cd = 0;',...
'GMAT Sat.Cr = 0;',...
'GMAT Sat.DragArea = 0;',...
'GMAT Sat.SRPArea = 0;',...
'GMAT Sat.SPADDragScaleFactor = 1;',...
'GMAT Sat.SPADSRPScaleFactor = 1;',...
'GMAT Sat.Tanks = {ETank};',...
'GMAT Sat.NAIFId = -10000001;',...
'GMAT Sat.NAIFIdReferenceFrame = -9000001;',...
'GMAT Sat.OrbitColor = Red;',...
'GMAT Sat.TargetColor = Teal;',...
'GMAT Sat.OrbitErrorCovariance = [ 1e+70 0 0 0 0 0 ; 0 1e+70 0 0 0 0 ; 0 0 1e+70 0 0 0 ; 0 0 0 1e+70 0 0 ; 0 0 0 0 1e+70 0 ; 0 0 0 0 0 1e+70 ];',...
'GMAT Sat.CdSigma = 1e+70;',...
'GMAT Sat.CrSigma = 1e+70;',...
"GMAT Sat.Id = 'SatId';",...
'GMAT Sat.Attitude = CoordinateSystemFixed;',...
'GMAT Sat.SPADSRPInterpolationMethod = Bilinear;',...
'GMAT Sat.SPADSRPScaleFactorSigma = 1e+70;',...
'GMAT Sat.SPADDragInterpolationMethod = Bilinear;',...
'GMAT Sat.SPADDragScaleFactorSigma = 1e+70;',...
"GMAT Sat.ModelFile = 'aura.3ds';",...
'GMAT Sat.ModelOffsetX = 0;',...
'GMAT Sat.ModelOffsetY = 0;',...
'GMAT Sat.ModelOffsetZ = 0;',...
'GMAT Sat.ModelRotationX = 0;',...
'GMAT Sat.ModelRotationY = 0;',...
'GMAT Sat.ModelRotationZ = 0;',...
'GMAT Sat.ModelScale = 1;',...
"GMAT Sat.AttitudeDisplayStateType = 'Quaternion';",...
"GMAT Sat.AttitudeRateDisplayStateType = 'AngularVelocity';",...
'GMAT Sat.AttitudeCoordinateSystem = EarthMJ2000Eq;',...
"GMAT Sat.EulerAngleSequence = '321';",...
'%----------------------------------------',...
'%---------- Hardware Components',...
'%----------------------------------------',...
'Create ElectricTank ETank;',...
'GMAT ETank.AllowNegativeFuelMass = false;',...
'GMAT ETank.FuelMass = 1000;',...
'',...
'',...
'',...
'',...
'',...
'',...
'',...
'%----------------------------------------',...
'%---------- ForceModels',...
'%----------------------------------------',...
'Create ForceModel FM;',...
'GMAT FM.CentralBody = Sun;',...
'GMAT FM.PointMasses = {Sun};',...
'GMAT FM.Drag = None;',...
'GMAT FM.SRP = Off;',...
'GMAT FM.RelativisticCorrection = Off;',...
'GMAT FM.ErrorControl = RSSStep;',...
'',...
'',...
'',...
'',...
'',...
'',...
'',...
'',...
'',...
'%----------------------------------------',...
'%---------- Propagators',...
'%----------------------------------------',...
'Create Propagator ThePropagator;',...
'GMAT ThePropagator.FM = FM;',...
'GMAT ThePropagator.Type = RungeKutta89;',...
'GMAT ThePropagator.InitialStepSize = 86400;',...
'GMAT ThePropagator.Accuracy = 1e-09;',...
'GMAT ThePropagator.MinStep = 86400;',...
'GMAT ThePropagator.MaxStep = 86400;',...
'GMAT ThePropagator.MaxStepAttempts = 50;',...
'GMAT ThePropagator.StopIfAccuracyIsViolated = false;',...
'',...
'%----------------------------------------',...
'%---------- Coordinate Systems',...
'%----------------------------------------',...
'Create CoordinateSystem CentralBodyICRF;',...
'GMAT CentralBodyICRF.Origin = Sun;',...
'GMAT CentralBodyICRF.Axes = ICRF;',...
'',...
'%----------------------------------------',...
'%---------- Thrust History File',...
'%----------------------------------------',...
'Create ThrustHistoryFile ThrustHistoryFile1;',...
"GMAT ThrustHistoryFile1.FileName = 'C:\GMAT_Repo\GMAT_Generalized_LowThrust\GMAT_RunFolder\Blank_scripts\GMAT_BlankThrustProfile.thrust';",...
"GMAT ThrustHistoryFile1.AddThrustSegment = {'ThrustSegment1'};",...
'',...
'Create ThrustSegment ThrustSegment1;',...
'GMAT ThrustSegment1.ThrustScaleFactor = 1;',...
'GMAT ThrustSegment1.ThrustScaleFactorSigma = 1e+70;',...
'GMAT ThrustSegment1.ApplyThrustScaleToMassFlow = false;',...
'GMAT ThrustSegment1.MassFlowScaleFactor = 1;',...
"GMAT ThrustSegment1.MassSource = {'ETank'};",...
'',...
'%----------------------------------------',...
'%---------- Arrays, Variables, Strings',...
'%----------------------------------------',...
'',...
'Create Array Data[1,6];',...
'Create Variable RunTime;',...
'',...
'',...
'',...
'',...
'',...
'',...
'',...
'%----------------------------------------',...
'%---------- Mission Sequence',...
'%----------------------------------------',...
'BeginMissionSequence;',...
"BeginScript 'Step1'",...
'   BeginFileThrust ThrustHistoryFile1(Sat);',...
'   Propagate ThePropagator(Sat) {Sat.ElapsedSecs = RunTime};',...
'   EndFileThrust ThrustHistoryFile1(Sat);',...
'EndScript;',...
'',...
'GMAT Data(1) = Sat.CentralBodyICRF.VX;',...
'GMAT Data(2) = Sat.CentralBodyICRF.VY;',...
'GMAT Data(3) = Sat.CentralBodyICRF.VZ;',...
'GMAT Data(4) = Sat.CentralBodyICRF.X;',...
'GMAT Data(5) = Sat.CentralBodyICRF.Y;',...
'GMAT Data(6) = Sat.CentralBodyICRF.Z;',...
'',...
'',...
''};
fileID01 = fopen(destinationS, 'w');
for i = 1:length(ScriptTemp)
    fprintf(fileID01, '%s\n', ScriptTemp{i});
end
fclose(fileID01);
ThrustTemp=...
{'BeginThrust{ThrustSegment1}',...
'Start_Epoch = 20 Jul 2023 00:00:00.000',...
'Thrust_Vector_Coordinate_System = CentralBodyICRF',...
'Thrust_Vector_Interpolation_Method  = None',...
'Mass_Flow_Rate_Interpolation_Method = None',...
'ModelThrustAndMassRate',...
'0.0	 	 0.0 0.0 0.0 0.0',...
'1000000.0 	 0.0 0.0 0.0 0.0',...
'EndThrust{ThrustSegment1}'};
fileID02 = fopen(destinationT, 'w');
for i = 1:length(ThrustTemp)
    fprintf(fileID02, '%s\n', ThrustTemp{i});
end
fclose(fileID02);
%copyfile(sourceS,destinationS);
%copyfile(sourceT,destinationT);
%% Configure Thrust History Profile Script
% Headlines for the Thrust File
if  Thrus >= 1
    if MassFOn==1 
        ThrustProfileModel="ModelThrustAndMassRate";
    elseif MassFOn==0
        ThrustProfileModel="ModelThrustOnly";
    else
        fprintf("\nGMAT: MassFlow Error\n")
        dbstack()
        return
    end
elseif Accel >=1
    if MassFOn==1
        ThrustProfileModel="ModelAccelAndMassRate";
    elseif MassFOn==0
        ThrustProfileModel="ModelAccelOnly";
    else
        fprintf("\nGMAT: MassFlow Error\n")
        dbstack()
        return
    end    
elseif Thrus >= 1 && Accel >=1
    fprintf("\nGMAT: Acceleration and Thrust Option Selected\n")
    dbstack()
    return
else
    fprintf("\nGMAT: No Thrust Profile Option Selected\n")
    dbstack()
    return
end
headlines = ['BeginThrust{ThrustSegment1}', newline,...
    'Start_Epoch = '+StartEpoch,newline,...
    'Thrust_Vector_Coordinate_System = CentralBodyICRF',newline,...  
    'Thrust_Vector_Interpolation_Method  = None',newline,...
    'Mass_Flow_Rate_Interpolation_Method = None',newline,...
    ThrustProfileModel]; 
%Thrust = zeros(NumberOfSteps,3);
%Thrust(1:(end-1),:)=ThrustVec;
Thrust=ThrustVec;
% Obtain time history
if MassFOn==1
    for i=1:(NumberOfSteps)
        LineToChange = i+1;         % first 6 lines ae used for headers
        NewContent = compose("%.16f \t %.16f %.16f %.16f %.16f",Time(i),Thrust(i,1),...
            Thrust(i,2),Thrust(i,3),mdot(i));
        SS{LineToChange} = NewContent;
    end
elseif MassFOn==0
    for i=1:(NumberOfSteps)
        LineToChange = i+1;         % first 6 lines ae used for headers
        NewContent = compose("%.16f \t %.16f %.16f %.16f",Time(i),Thrust(i,1),...
            Thrust(i,2),Thrust(i,3));
        SS{LineToChange} = NewContent;
    end
else
    fprintf("\nGMAT: Mass Flow Rate in Thrust History File Error\n")
    dbstack()
    return
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
sat.SetField("Epoch", num2str(StartDate-2430000.0, '%.8f')) %modified Julian Date
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
%The part below use to work. GMAT's API is terrible 
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
    fprintf("\nGMAT: Failed to Run GMAT Run Script\n")
    dbstack()
    return
end
%% Run SNOPT Optimization
%This Optimization assumes that magnitude remains constant and if fuel mass
%is decremented it's constants for all time steps.
%The design varibles are the Alpha and Beta angle array and TOF
%Time of Flight Bounds
UpperBoundTOF=Opt.TOF_UpperBound*86400;
LowBoundTOF=Opt.TOF_LowBound*86400;
x=[Alpha/(2*pi);Beta/(2*pi);EndTime/UpperBoundTOF];
%Check Target body array
if Optimize==1 && any(size(TargetBody) ~= 1)
    fprintf("\nGMAT: Target Body Size Error\n")
    dbstack()
    return
end
%Run SNOPT
if Optimize==1
    %Constants
    muS = 1.32712440018e+11;   % Km^3/sec^2 
    AU  = 149598000;            % km
    TU  = sqrt(AU^3/muS);       % sec
    Th = ThrustMag;               % kg m/s^2
    t1 = StartDate;   
    %Initial Guess vector (Alpha, Beta, TOF)
 
    lb = [-ones(NumberOfSteps,1);    % Alpha
          -ones(NumberOfSteps,1);    % Beta  
            LowBoundTOF/UpperBoundTOF];             % TOF (TU) %900

    ub = [ones(NumberOfSteps,1);     % Alpha 
          ones(NumberOfSteps,1);    % Beta 
          UpperBoundTOF/UpperBoundTOF];            % UpperBoundTOF/UpperBoundTOF
    %lower and upper bounds
    xlow = lb;
    xupp = ub;
    %Multiplier and state of design variable x
    xmul = zeros(length(lb), 1); %Lagrange multipliers
    xstate = zeros(length(lb), 1);
    if OptObj==1
        %bounds on objective function
        Flow=zeros(7, 1);
        Fupp=zeros(7, 1);
        Flow(1) = 0;
        Fupp(1) = ub(end);%inf;
        %bounds of constraints
        Flow(2:7) = 0;
        Fupp(2:7) = 0;
        %Multiplier and state of function F
        Fmul = zeros(7, 1); %Lagrange multipliers
        Fstate = zeros(7, 1);
    elseif OptObj==2
        %bounds on objective function
        Flow(1) = 0;
        Fupp(1) = 0;%ub(end);%inf;
        %Multiplier and state of function F
        Fmul = 0; %Lagrange multipliers
        Fstate = 0;
    end
    %SNOPT Optimization Routine
    ObjAdd =0; %Add value to objective Row
    ObjRow =1; %Tell the Optimizer which row of F is the objective function
    snscreen on;  
    snsummary('SNOPT_summary.txt');
    %tolerance values, 1e-6 by default 
    snsetr('Major feasibility tolerance',Opt.MajorFeasibilityTolerance); 
    snsetr('Major optimality tolerance',Opt.MajorOptimalityTolerance);
    snsetr('Minor feasibility tolerance',1e-6);
    snsetr('Minor optimality tolerance',1e-6);
    snseti('Time limit',Opt.OptimizationRunTimeLimit);% (in seconds)
    snseti('Major iteration limit',Opt.MajorIterationLimit);
    snseti('Minor iteration limit',Opt.MajorIterationLimit*1000000);
    snseti('Line search algorithm', 3)%More-Thuente line search, Seems to be faster than default line search
    load_gmat();
    tic
    [x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
        snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate,...
        'objFunc_conFunc', ObjAdd, ObjRow);
    toc
    % Extract Design Variables
    Thrust_alpha = x(1:NumberOfSteps)*(2*pi);                   % rads
    Thrust_beta = x(NumberOfSteps+1:2*NumberOfSteps)*(2*pi);   % rads
    EndTime     = x(end)*UpperBoundTOF;                                           % s
    ThrustVec=Th.*[cos(Thrust_beta).*cos(Thrust_alpha),cos(Thrust_beta).*sin(Thrust_alpha), ...
        sin(Thrust_beta)];
    Thrust = zeros(NumberOfSteps+1,3);
    Thrust(1:(end-1),:)=ThrustVec;
    Time = linspace(0,EndTime,NumberOfSteps)';  % seconds
    Alpha=Thrust_alpha;
    Beta=Thrust_beta;
end
%% Solution Thrust Profile
ThrustProfileSolution='\GMAT_ThrustProfileSolution.thrust'; 
destinationSolution = fullfile(WorkingDir,ThrustProfileSolution);
copyfile(destinationT,destinationSolution);
% Write the contents of the Thrust File
if MassFOn==1
    for i=1:(NumberOfSteps)
        LineToChange = i+1;         % first 6 lines ae used for headers
        NewContent = compose("%.16f \t %.16f %.16f %.16f %.16f",Time(i),Thrust(i,1),...
            Thrust(i,2),Thrust(i,3),mdot(i));
        SS{LineToChange} = NewContent;
    end
else
    for i=1:(NumberOfSteps)
        LineToChange = i+1;         % first 6 lines ae used for headers
        NewContent = compose("%.16f \t %.16f %.16f %.16f",Time(i),Thrust(i,1),...
            Thrust(i,2),Thrust(i,3));
        SS{LineToChange} = NewContent;
    end
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
%OrbitViewC = regexp(fileread(fullfile(BlanksDir,FileName_blankO)),'\n','split');
OrbitViewC =...
{'%----------------------------------------',...
'%---------- Subscribers',...
'%----------------------------------------',...
'',...
'Create OrbitView OrbitView1;',...
'GMAT OrbitView1.SolverIterations = Current;',...
'GMAT OrbitView1.UpperLeft = [ 0.003971405877680699 0 ];',...
'GMAT OrbitView1.Size = [ 0.7998411437648928 0.8501228501228502 ];',...
'GMAT OrbitView1.RelativeZOrder = 63;',...
'GMAT OrbitView1.Maximized = false;',...
'GMAT OrbitView1.Add = {Sat, Earth, Jupiter, Luna, Mars, Mercury, Neptune, Pluto, Saturn, Sun, Uranus, Venus};',...
'GMAT OrbitView1.CoordinateSystem = CentralBodyICRF;',...
'GMAT OrbitView1.DrawObject = [ true true true true true true true true true true true true ];',...
'GMAT OrbitView1.DataCollectFrequency = 1;',...
'GMAT OrbitView1.UpdatePlotFrequency = 50;',...
'GMAT OrbitView1.NumPointsToRedraw = 0;',...
'GMAT OrbitView1.ShowPlot = true;',...
'GMAT OrbitView1.MaxPlotPoints = 200000;',...
'GMAT OrbitView1.ShowLabels = true;',...
'GMAT OrbitView1.ViewPointReference = Sun;',...
'GMAT OrbitView1.ViewPointVector = [ 0 0 700000000 ];',...
'GMAT OrbitView1.ViewDirection = Sun;',...
'GMAT OrbitView1.ViewScaleFactor = 1;',...
'GMAT OrbitView1.ViewUpCoordinateSystem = CentralBodyICRF;',...
'GMAT OrbitView1.ViewUpAxis = Z;',...
'GMAT OrbitView1.EclipticPlane = Off;',...
'GMAT OrbitView1.XYPlane = Off;',...
'GMAT OrbitView1.WireFrame = Off;',...
'GMAT OrbitView1.Axes = Off;',...
'GMAT OrbitView1.Grid = Off;',...
'GMAT OrbitView1.SunLine = Off;',...
'GMAT OrbitView1.UseInitialView = On;',...
'GMAT OrbitView1.StarCount = 7000;',...
'GMAT OrbitView1.EnableStars = Off;',...
'GMAT OrbitView1.EnableConstellations = On;',...
''}; 
 
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
    fprintf("\nGMAT: Failed to Run GMAT Plot Script\n")
    dbstack()
    return
else %Remove Optimizer Run files
    delete(destinationS);
    delete(destinationT); 
    OutPut_DataStruct=struct('Time',Time,'ThrustXYZ',ThrustVec,'Alpha',Alpha,'Beta',Beta,'X',x);
end
end%END
