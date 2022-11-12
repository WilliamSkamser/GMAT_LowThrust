function MassUsed=ObjFunc(Thrust)
Headerlines=6;
%READ Thrust File
file='../OptTestMATLAB/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',Headerlines);
ThrustProfile=cell2mat(A);
fclose(fID);

ISP=1500;
g=9.80665;
%mdot= Tmag/(ISP*g0)?
MassUsed=0;

%Converts back to Matrix;
ThrustProfileNew(:,2)=Thrust(1:11);
ThrustProfileNew(:,3)=Thrust(12:22);
ThrustProfileNew(:,4)=Thrust(23:33);
ThrustProfileNew(:,1)=ThrustProfile(:,1);
for i=1:10
    ThrustProfileNew(i,5)=norm(ThrustProfileNew(i,2:4)) / (ISP * g); %mass flow rate 
    
    MassUsed=MassUsed+(ThrustProfileNew(i,5) * (ThrustProfile(i+1,1) - ThrustProfile(i,1)) );
end

%WRITE New Thrust File
%file2='../OptTestMATLAB/ThrustProfile.thrust';
%S = fileread(file2);
%SS = regexp(S, '\r?\n', 'split');
%for i=1:10
%    LineToChange = i+Headerlines; 
%    NewContent = compose("%.1f     \t%.16f %.16f %.16f  %.16f",ThrustProfileNew(i,1),ThrustProfileNew(i,2),ThrustProfileNew(i,3),ThrustProfileNew(i,4),ThrustProfileNew(i,5));
%    SS{LineToChange} = NewContent;
%end
%fid2 = fopen(file2, 'w');
%fprintf(fid2, '%s\n', SS{:});
%fclose(fid2);

%RUN GMAT Script With New Thrust File
%Ans=gmat.gmat.RunScript();
%if Ans == 0
%    fprintf("Fail to run script");
%    FuelMass=NaN;
%    return
%end

%READ Data File
%file1='../OptTestMATLAB/DataReport.txt';
%fID1=fopen(file1,'r');
%B=textscan(fID1, '%f %f %f %f %f %f %f', 'headerlines',1);
%Data=cell2mat(B);
%fclose(fID1);

%TankMass_0=1526; %Mass of full tank
%FuelMass=TankMass_0-Data(6)
%FuelMass2=MassUsed;
end