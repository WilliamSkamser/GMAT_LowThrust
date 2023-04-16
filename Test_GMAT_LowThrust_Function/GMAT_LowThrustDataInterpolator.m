function [OutPut_Data]=GMAT_LowThrustDataInterpolator(NumberOfSteps,Op)
xq=linspace(0,Op.Time(end),NumberOfSteps)';
ThrustVec(:,1)=interp1(Op.Time,Op.ThrustXYZ(:,1),xq,'spline');
ThrustVec(:,2)=interp1(Op.Time,Op.ThrustXYZ(:,2),xq,'spline');
ThrustVec(:,3)=interp1(Op.Time,Op.ThrustXYZ(:,3),xq,'spline');
Alpha=interp1(Op.Time,Op.Alpha,xq,'spline');
Beta=interp1(Op.Time,Op.Beta,xq,'spline');
OutPut_Data=struct('Time',xq,'ThrustXYZ',ThrustVec,'Alpha',Alpha,'Beta',Beta,'X',Op.X);
end