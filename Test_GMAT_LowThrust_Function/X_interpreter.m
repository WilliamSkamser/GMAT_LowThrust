function [OutPut_Data]=X_interpreter(x,Th,UpperBoundTOF)
NumberOfSteps=(length(x)-1)/2;
Thrust_alpha = x(1:NumberOfSteps)*(2*pi);                   % rads
Thrust_beta = x(NumberOfSteps+1:2*NumberOfSteps)*(2*pi);   % rads
TOF     = x(end)*UpperBoundTOF;                                           % s
ThrustVec=Th.*[cos(Thrust_beta).*cos(Thrust_alpha),cos(Thrust_beta).*sin(Thrust_alpha),sin(Thrust_beta)];
Time = linspace(0,TOF,NumberOfSteps)';
OutPut_Data=struct('Time',Time,'ThrustXYZ',ThrustVec,'Alpha',Thrust_alpha,'Beta',Thrust_beta,'X',x);
end
% Example: OutPut_Data=X_interpreter(SAVE_Data.X,0.00015,3500*86400)
%
% To save work when pausing SNOPT optimization 
%   1) Save X with x_interpreter
%   OutPut_Data=X_interpreter(x,ThrustMag,UpperBoundTOF)
%   2) Write to Excel
%   []=LowThrustOutputStructToExcel(OutPut_Data,FileName)
%   3) Rerun GMAT_LowThrust with new excel file
%





