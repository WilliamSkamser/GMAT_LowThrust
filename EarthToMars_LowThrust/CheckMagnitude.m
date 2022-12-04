clc, clear, format longg
file='../EarthToMars_LowThrust/ThrustProfile.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);
NumberOfSteps=200;
TimeStep=zeros(NumberOfSteps,1);
for i=1:NumberOfSteps
TimeStep(i)=ThrustProfile(i+1,1) - ThrustProfile(i,1);
end

Thrust=zeros(((NumberOfSteps+1)*3 + NumberOfSteps),1);
Thrust(1:(NumberOfSteps+1))=ThrustProfile(:,2);
Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) )=ThrustProfile(:,3);
Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) )=ThrustProfile(:,4);
Thrust( ((NumberOfSteps+1)*3 + 1) : ((NumberOfSteps+1)*3 + NumberOfSteps) )=TimeStep;

Magnitude=zeros(NumberOfSteps+1,1);
for i=1:NumberOfSteps+1
Magnitude(i)=norm([ThrustProfile(i,2) ThrustProfile(i,3) ThrustProfile(i,4)]);
end
disp(Magnitude)