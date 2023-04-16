function [x]=GMAT_LowThrust(FileName,varargin)
%GMAT_LowThrust writes GMAT script files to propagate and optimize
%low-thrust trajectory problems
%   
%   Low_Thrust problems may be propagated as is or optimized.
%   Optimization is done using SNOPT 7.7 Matlab interface (Other versions
%   may work). 
%   Snopt Matlab foulder must be within path varible for optimization to work 
%   The constaint / objective function is called objFunc_conFunc
%
%Optimization limitations:
%
%
%   [x]=GMAT_LowThrust(FileName,varargin)
%   The FileName varible is a 
%
%   Example function call: 
%   GMAT_LowThrust("\MarsAccelerationProblem.xlsx",'Optimize',Opt)
%
% ....
%Future Work:
%   Replacing/Providing option to optimize with GMAT's CSALT plugin
%   Improve run time of optimization




%2461912.5
%May 21 2028
%









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
    'TOF_LowBound',50,'TOF_UpperBound',3500,'MajorFeasibilityTolerance',1e-6,...
    'MajorOptimalityTolerance',1e-6,'OptimizationRunTimeLimit',86400,...
    'MajorIterationLimit',5000);
    Opt=defaultopt;
    %Optimize=0;
    %LowBound =10; %in days
    %UpperBound= 3500; %in days
    %MajorFeasibilityTolerance=1e-6;
    %MajorOptimalityTolerance=1e-6;
    %OptimizationRunTimeLimit= 86400; %Seconds 
    %MajorIterationLimit=5000; 
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
                Opt.LowBound=InputStruct.LowBound;
            end
            if isfield(InputStruct,'TOF_UpperBound')
                Opt.UpperBound=InputStruct.UpperBound;
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
   % g   = 9.807;                 % m/s^2
    AU  = 149598000;            % km
    TU  = sqrt(AU^3/muS);       % sec
    %VU  = AU/TU;                % km/sec
    Th = ThrustMag;               % kg m/s^2
    %Isp = ISP;             % s^-1
    %Vex = Isp*g;            % m/s
    %m0  = FuelM;             % kg
    t1 = StartDate;   
    %Initial Guess vector (Alpha, Beta, TOF)
   % x=[Alpha/(2*pi);Beta/(2*pi);EndTime/UpperBoundTOF];
    % Bounds
    %[F, G] = objFunc_conFunc(x)
    lb = [-ones(NumberOfSteps,1);    % Alpha
          -ones(NumberOfSteps,1);    % Beta  
          LowBoundTOF/UpperBoundTOF];             % TOF (TU) %900

    ub = [ones(NumberOfSteps,1);     % Alpha 
          ones(NumberOfSteps,1);     % Beta 
         1];            % UpperBoundTOF/UpperBoundTOF
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
    snsetr('Major feasibility tolerance',Opt.MajorFeasibilityTolerance); 
    snsetr('Major optimality tolerance',Opt.MajorOptimalityTolerance);
    snsetr('Minor feasibility tolerance',1e-6);
    snsetr('Minor optimality tolerance',1e-6);
    snseti('Time limit',Opt.OptimizationRunTimeLimit);%345600); %Sets time limit to 1 day (in seconds)
    snseti('Major iteration limit',Opt.MajorIterationLimit);
    snseti('Minor iteration limit',Opt.MajorIterationLimit*10000);
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
    fprintf("\nGMAT: Failed to Run GMAT Plot Script\n")
    dbstack()
    return
end
end%END