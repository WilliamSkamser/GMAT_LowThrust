function [Cons,Cons_eq]=NonLinCons(Thrust)

Headerlines=6;
%{
%READ Thrust File
file='../OptTestMATLAB/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',Headerlines);
ThrustProfile=cell2mat(A);
fclose(fID);
%}
ISP=2800;
g=9.80665;
%mdot= Tmag/(ISP*g0)
steps=10;
%Converts back to Matrix;
ThrustProfileNew(:,2)=Thrust(1:11);
ThrustProfileNew(:,3)=Thrust(12:22);
ThrustProfileNew(:,4)=Thrust(23:33);
%Converts Time step into time column
for i=1:steps
ThrustProfileNew(i+1,1)=ThrustProfileNew(i,1) + Thrust(i+33);
end

for i=1:10
    ThrustProfileNew(i,5)=norm(ThrustProfileNew(i,2:4)) / (ISP * g); %mass flow rate 
end


%WRITE New Thrust File
file2='../Fmincon/ThrustProfile.thrust';
S = fileread(file2);
SS = regexp(S, '\r?\n', 'split');
for i=1:11 %increase to 11
    LineToChange = i+Headerlines; 
    NewContent = compose("%.16f     \t%.16f %.16f %.16f  %.16f",ThrustProfileNew(i,1),ThrustProfileNew(i,2),ThrustProfileNew(i,3),ThrustProfileNew(i,4),ThrustProfileNew(i,5));
    SS{LineToChange} = NewContent;
end
fid2 = fopen(file2, 'w');
fprintf(fid2, '%s\n', SS{:});
fclose(fid2);

ThrustTime=ThrustProfileNew(end,1); 
%WRITE Thrust Run Time
file3='../Fmincon/ThrustRunTime.txt';
fid3 = fopen(file3, 'w');
fprintf(fid3, '%d', ThrustTime);
fclose(fid3);

%RUN GMAT Script With New Thrust File
Ans=gmat.gmat.RunScript();
if Ans == 0
    fprintf("Fail to run script");
    Cons=NaN;
    Cons_eq=NaN;
    return
end

%READ Data File 1
file1='../Fmincon/DataReport.txt';
fID1=fopen(file1,'r');
B=textscan(fID1, '%f %f %f %f %f %f %f', 'headerlines',1);
Data=cell2mat(B);
fclose(fID1);

%READ Data File 2
file1='../Fmincon/DataReport2.txt';
fID2=fopen(file1,'r');
B2=textscan(fID2, '%f %f', 'headerlines',1);
Data2=cell2mat(B2);
fclose(fID2);
MinRadius=7000 - min(Data2(:,2));
MaxRadius=50000 - max(Data2(:,2));
Cons=[MinRadius MaxRadius]; %Max and min Radius 

%Equality constants
e=Data(1); %eccentricity 
Rmag_eq=42164-Data(3);
Inc_eq=Data(2);  %target inclination
Longitude=93.6465+Data(4);
%Latitude=Data(5);
Cons_eq=[e Rmag_eq Inc_eq Longitude];
end 