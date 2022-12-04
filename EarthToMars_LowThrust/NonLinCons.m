function [Cons,Cons_eq]=NonLinCons(Thrust)
Headerlines=6;
%Converts back to Matrix;
NumberOfSteps=200; 

%Thrust=zeros(((NumberOfSteps+1)*3),1);
ThrustProfileNew(:,2)=Thrust(1:(NumberOfSteps+1));
ThrustProfileNew(:,3)=Thrust( ((NumberOfSteps+1)+1) : ((NumberOfSteps+1)*2) );
ThrustProfileNew(:,4)=Thrust( (((NumberOfSteps+1)*2)+1) : ((NumberOfSteps+1)*3) );
RunTime=Thrust(end);
TimeStep=RunTime/NumberOfSteps;
for i=1:NumberOfSteps
ThrustProfileNew(i+1,1)=ThrustProfileNew(i,1) +TimeStep;
% Old Method
%ThrustProfileNew(i,1) + Thrust(i+ ((NumberOfSteps+1)*3));
end

for i=1:NumberOfSteps
    ThrustProfileNew(i,5)=4.2231e-6; %mass flow rate 
end

%WRITE New Thrust File
file2='../EarthToMars_LowThrust/ThrustProfile.thrust';
S = fileread(file2);
SS = regexp(S, '\r?\n', 'split');
for i=1:NumberOfSteps
    LineToChange = i+Headerlines; 
    NewContent = compose("%.16f     \t%.16f %.16f %.16f  %.16f",ThrustProfileNew(i,1),ThrustProfileNew(i,2),ThrustProfileNew(i,3),ThrustProfileNew(i,4),ThrustProfileNew(i,5));
    SS{LineToChange} = NewContent;
end
fid2 = fopen(file2, 'w');
fprintf(fid2, '%s\n', SS{:});
fclose(fid2);

%WRITE Thrust Run Time
file3='../EarthToMars_LowThrust/ThrustRunTime.txt';
fid3 = fopen(file3, 'w');
fprintf(fid3, '%d', RunTime);
fclose(fid3);



%RUN GMAT Script With New Thrust File
Ans=gmat.gmat.RunScript();
if Ans == 0
    fprintf("Fail to run script");
    Cons=NaN;
    Cons_eq=NaN;
    return
end

%READ Data File
file1='../EarthToMars_LowThrust/DataOutput.txt';
fID1=fopen(file1,'r');
B=textscan(fID1, '%f %f %f %f %f %f %f', 'headerlines',1);
Data=cell2mat(B);
fclose(fID1);

Cons=[];
%Equality constants
%In sunICR (S/C-Mars)
Vx=Data(2)-Data(8);
Vy=Data(3)-Data(9);
Vz=Data(4)-Data(10);
X=Data(5)-Data(11);
Y=Data(6)-Data(12);
Z=Data(7)-Data(13);
Cons_eq=[Vx Vy Vz X Y Z];

M=zeros(NumberOfSteps,1);
for i=1:NumberOfSteps
    M(i) =0.1 - norm([ThrustProfileNew(i,2) ThrustProfileNew(i,3) ThrustProfileNew(i,4)]);
end
CN=size(Cons_eq,2);
%Fill Cons_eq with Magnitude
for i=1:NumberOfSteps
    Cons_eq(i+CN)= M(i);
end

end 