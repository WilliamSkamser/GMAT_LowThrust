%clear
%clc
%clear all
%format longg
function []=TestReadExcelTable(FileName,varargin)
    %arguments
    %    FileName string
    %end
%FileName="\GMAT_LowThrust_Template.xlsx";
narginchk(1, 3);%Check input
if contains(class(FileName),'string') 
    Fname=char(FileName);
    if ~contains(Fname(1),'\')
        fprintf("\nGMAT: Invalid File Name\n");
        return
    end
else
    fprintf("\nGMAT: Invalid File Name\n");
    return   
end
defaultopt = struct( ...
    'LowBound',10,'UpperBound',3500,'MajorFeasibilityTolerance',1e-6,...
    'MajorOptimalityTolerance',1e-6,'OptimizationRunTimeLimit',86400,...
    'MajorIterationLimit',5000);
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
        Opt=defaultopt;
        if nargin>2
            if ~isstruct(varargin{2})
                fprintf("\nGMAT: Third Function Argument Not Struct\n");
                return 
            end
            InputStruct=varargin{2};
            if isfield(InputStruct,'LowBound')
                Opt.LowBound=InputStruct.LowBound;
            end
            if isfield(InputStruct,'UpperBound')
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
end
%% Read Excel Table and check if proper inputs data types 
fileG=pwd+FileName;
InputTable = readtable(fileG,'ReadVariableNames',false);
PlanetsArray={'Sun','Mercury','Venus','Earth','Luna','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto'};
%Array of all possible planets in string arrays
StartDate=table2array(InputTable(1,1)); 
if contains(class(StartDate),'double')~=1
    fprintf("\nGMAT: Invalid Start Date\n");
    return
end
if StartDate>juliandate(1900,00,00,00,00,00) && StartDate<... %Limits
        juliandate(2500,00,00,00,00,00)
else 
    fprintf("\nGMAT: Invalid Start Date\n");
    return
end
CentralBody=table2array(InputTable(1,2));%CentralBodyICRF
if ismember(CentralBody,PlanetsArray)~= 1 || contains(class(CentralBody),'cell')~=1
    fprintf("\nGMAT: Invalid Central Body\n");
    return
end
R_i=table2array(InputTable(1:3,3))';%Sat inital State Vector
V_i=table2array(InputTable(1:3,4))';
if contains(class(R_i),'double')~=1 || contains(class(V_i),'double')~=1 || ...
        any(isnan(R_i)) || any(isnan(V_i))
    fprintf("\nGMAT: Invalid Initial State Vector\n");
    return
end
FinalStateType=table2array(InputTable(1,5));
if contains(class(FinalStateType),'cell')~=1
    fprintf("\nGMAT: Invalid Final State Type\n");
    return
elseif contains(FinalStateType, 'Planetary Rendezvous')
    TargetBody=table2array(InputTable(1,6));
    if contains(class(TargetBody),'cell')~=1 || ismember(TargetBody,PlanetsArray) ~= 1
        fprintf("\nGMAT: Invalid Target Body\n");
        return
    end
elseif contains(FinalStateType, 'State Vector')
    TargetBody='None';
    R_f=table2array(InputTable(1:3,7))';
    V_f=table2array(InputTable(1:3,8))';
    if contains(class(R_f),'double')~=1 || contains(class(V_f),'double')~=1 || ...
        any(isnan(R_f)) || any(isnan(V_f))
        fprintf("\nGMAT: Invalid Final State Vector\n");
        return
    end
else
    fprintf("\nGMAT: Invalid Final State Type\n");
    return
end
FuelM=table2array(InputTable(1,9)); %Fuel Mass
if isnumeric(FuelM)~=1 || FuelM<0 || FuelM> 10^6
    fprintf("\nGMAT: Invalid Fuel Mass\n");
    return
end   
DM=table2array(InputTable(1,10)); %Dry Mass
if isnumeric(DM)~=1 || DM<0 || DM> 10^6
    fprintf("\nGMAT: Invalid Dry Mass\n");
    return
end   
MassFlowOption=table2array(InputTable(1,11)); %Check Mass Flow option
if contains(class(MassFlowOption),'cell')~=1
    fprintf("\nGMAT: Invalid Mass Flow Option\n");
    return
elseif contains(MassFlowOption, 'Off') %No mass flow case
    ISP=0; 
elseif contains(MassFlowOption, 'On') 
    ISP=table2array(InputTable(1,12));
    if contains(class(ISP),'double')~=1 || isnan(ISP) || not(ISP>0)
        fprintf("\nGMAT: Invalid ISP\n");
        return
    end
else
    fprintf("\nGMAT: Invalid Mass Flow Option\n");
    return
end
PointMasses=table2array(InputTable(1:end,13));
if contains(class(PointMasses),'cell')==1 %Check if in PlanetsArray
    PointMasses=PointMasses(~cellfun('isempty', PointMasses));
    for j=1:length(PointMasses)
        if ismember(PointMasses(j),PlanetsArray)~= 1
            fprintf("\nGMAT: Invalid Point Mass Entry\n");
            return
        end  
    end
    PointMasses=unique(PointMasses);
elseif all(isnan(PointMasses)) %Checks if blank
    PointMasses={};
else
    fprintf("\nGMAT: Invalid Point Mass Entry\n");
    return
end
PlanetPlot=table2array(InputTable(1:end,14));
if contains(class(PlanetPlot),'cell')==1 %Check if in PlanetsArray
    PlanetPlot=PlanetPlot(~cellfun('isempty', PlanetPlot));
    for j=1:length(PlanetPlot)
        if ismember(PlanetPlot(j),PlanetsArray)~= 1
            fprintf("GMAT: Invalid Planet Plot Entry");
            return
        end  
    end
    PlanetPlot=unique(PlanetPlot);
elseif all(isnan(PlanetPlot)) %Checks if blank
    PlanetPlot={};
else
    fprintf("\nGMAT: Invalid Planet Plot Entry\n");
    return
end
ThrustSetting=table2array(InputTable(1,15)); %Thrust Setting 
if contains(class(ThrustSetting),'cell')~=1
    fprintf("\nGMAT: Invalid Thrust Setting Type\n");
    return
elseif contains(ThrustSetting, 'Acceleration') || contains(ThrustSetting, 'Force') 
else
    fprintf("\nGMAT: Invalid Thrust Setting Type\n");
    return
end
ThrustMag=table2array(InputTable(1,17));
if isnumeric(ThrustMag)~=1 || isnan(ThrustMag) || ThrustMag<0 || ThrustMag> 1
    fprintf("\nGMAT: Invalid Thrust Magnitude\n");
    return
end 
Time=table2array(InputTable(:,18));
if ~isnumeric(Time) 
    fprintf("\nGMAT: Invalid Time Array\n");
    return
else
    Time=Time(1:find(~isnan(Time), 1, 'last'));
    if any(isnan(Time))
        fprintf("\nGMAT: Invalid Time Array\n");
        return
    end
    EndTime=Time(end);
    for i=2:length(Time)
        if (Time(i)-Time(i-1))<0 %Check if time array is increasing 
            fprintf("\nGMAT: Invalid Time Array\n");
            return
        end
    end
end
%Time(~isnan(Time))
ThrustCoordinateOption=table2array(InputTable(1,16)); %REMOVE THIS PART SOON!
if contains(class(ThrustCoordinateOption),'cell')~=1
    fprintf("\nGMAT: Invalid Thrust Coordinate Type\n");
    return
elseif contains(ThrustCoordinateOption, 'XYZ') 
    ThrustXYZ=table2array(InputTable(:,19:21));
    if contains(class(ThrustXYZ),'double')~=1 || any(any(isnan(ThrustXYZ))) ...
            || not(length(ThrustXYZ)==length(Time))
        fprintf("\nGMAT: Invalid Thrust XYZ Array\n");
        return
    end
elseif contains(ThrustCoordinateOption, 'Thrust Angles') 
    Alpha=table2array(InputTable(:,22));
    Beta=table2array(InputTable(:,23));
    if contains(class(Alpha),'double')~=1 || contains(class(Beta),'double')~=1 ...
            || any(isnan(Alpha)) || any(isnan(Beta)) || not(length(Alpha)==length(Time)) ...
            || not(length(Alpha)==length(Beta))
        fprintf("\nGMAT: Invalid Thrust Angles\n");
        return
    end       
else
    fprintf("\nGMAT: Invalid Thrust Coordinate Type\n");
    return
end
%disable options by default in propagator 
%Can turn on here in code 
RelativisticCorrection= false;%true; %or false
SolarRadiationPressure= false;%true; %or false
end

   

    





