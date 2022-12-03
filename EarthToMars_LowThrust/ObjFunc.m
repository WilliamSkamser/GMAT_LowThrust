function MassUsed=ObjFunc(Thrust)
%Read Run Time File
RunTime=Thrust(end);
MassFlowRate = 4.2231e-6; %4.2231e-5 must be a typo becuse it doesn't work???
MassUsed=RunTime*MassFlowRate;


%{
    %Old Method
%Converts back to Matrix;
NumberOfSteps=200;
TimeStep=(4.170266985e+05);
%Thrust=zeros(((NumberOfSteps+1)*3),1);
ThrustProfileNew(:,2)=Thrust(1:(NumberOfSteps+1));
ThrustProfileNew(:,3)=Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) );
ThrustProfileNew(:,4)=Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) );
%Converts Time step into time column

for i=1:NumberOfSteps
    ThrustProfileNew(i+1,1)=ThrustProfileNew(i,1) + Thrust(i+ ((NumberOfSteps+1)*3));
end

for i=1:NumberOfSteps
    ThrustProfileNew(i,5)=4.2231e-6; %4.2231e-5 must be a typo becuse it doesn't work???
    
    MassUsed=MassUsed+(ThrustProfileNew(i,5) * (ThrustProfileNew(i+1,1) - ThrustProfileNew(i,1)) );
end
%}
end