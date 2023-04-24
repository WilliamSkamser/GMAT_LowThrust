function MassUsed=ObjFunc(Thrust)
RunTime=Thrust(end);
ISP=2800;
g=9.80665;
MassUsed=0;
%Converts back to Matrix;
NumberOfSteps=200;
TimeStep=RunTime/NumberOfSteps;
ThrustProfileNew(:,2)=Thrust(1:(NumberOfSteps+1));
ThrustProfileNew(:,3)=Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) );
ThrustProfileNew(:,4)=Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) );
for i=1:NumberOfSteps
    ThrustProfileNew(i,5)=norm(ThrustProfileNew(i,2:4)) / (ISP * g); %mass flow rate ;
    MassUsed=MassUsed+(ThrustProfileNew(i,5) * TimeStep );
end

end