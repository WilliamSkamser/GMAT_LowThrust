function [Rmag,Rmag_eq]=NonLinCons(Thrust)
Headerlines=6;
%READ Thrust File
file='C:/GMAT_Repo/OptTestMATLAB/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',Headerlines);
ThrustProfile=cell2mat(A);
fclose(fID);

%Converts back to Matrix;
ThrustProfileNew(:,2)=Thrust(1:11);
ThrustProfileNew(:,3)=Thrust(12:22);
ThrustProfileNew(:,4)=Thrust(23:33);
ThrustProfileNew(:,1)=ThrustProfile(:,1);
ThrustProfileNew(:,5)=ThrustProfile(:,5);

%WRITE New Thrust File
file2='C:/GMAT_Repo/OptTestMATLAB/ThrustProfile.thrust';
S = fileread(file2);
SS = regexp(S, '\r?\n', 'split');
for i=1:10
    LineToChange = i+Headerlines; 
    NewContent = compose("%.1f     \t%.3f %.3f %.3f  0.001",ThrustProfileNew(i,1),ThrustProfileNew(i,2),ThrustProfileNew(i,3),ThrustProfileNew(i,4));
    SS{LineToChange} = NewContent;
end
fid2 = fopen(file2, 'w');
fprintf(fid2, '%s\n', SS{:});
fclose(fid2);

%RUN GMAT Script With New Thrust File
load_gmat();
Ans1=gmat.gmat.LoadScript("../OptTestMATLAB/OptTestMatlab.script");
if Ans1 == 1
    Ans2=gmat.gmat.RunScript();
    if Ans2 == 0
        fprintf("Fail to run script");
    end
else
    fprintf("Fail to load script\n");
end

%READ Data File
file1='C:/GMAT_Repo/OptTestMATLAB/DataReport.txt';
fID1=fopen(file1,'r');
B=textscan(fID1, '%f %f %f %f', 'headerlines',1);
Data=cell2mat(B);
fclose(fID1);

%42164km for GEO
%Inequality constants
%Rmag(1)=42163-Data(2); 
%Rmag(2)=42165-Data(2);
Rmag=[];
%Equality constants
Rmag_eq=42164-Data(2);
%Rmag_eq=[];

%function [c,ceq]=nlcons(x)
%c(1) = x(1)^3 +2*x(2)^2 -x(1)*x(3);
%ceq=[]; %no none linear Equality constraints 
%end
end 