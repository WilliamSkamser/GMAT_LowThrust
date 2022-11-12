clc, clear, format longg;
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

%Sat = gmat.gmat.GetRuntimeObject("Sat");
%Days=str2num(Sat.GetField());

%READ Thrust File
file='C:/GMAT_Repo/OptTestMATLAB/ThrustProfile.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);

%READ Data File
file1='C:/GMAT_Repo/OptTestMATLAB/DataReport.txt';
fID1=fopen(file1,'r');
B=textscan(fID1, '%f %f %f %f', 'headerlines',1);
Data=cell2mat(B);
fclose(fID1);

WriteThrustProfile(ThrustProfile);

%Equality constraints 
%Aeq=[1 2 0];
%beq=5;
%Inequality constraints 
%A=[1,-2,3; 0,2,3;3 -1 0];
%b=[3;5;2];  
%Inital guess 
%x0= [2;2;2];
%fmincon
%ptions=optimoptions('fmincon','Algorithm', 'sqp','Display','iter');
%[xOpt, fOpt, exitflag, output, lambda]=fmincon("objFunc",x0, A,b, Aeq, beq, [],[],"nlcons",options);




function WriteThrustProfile(ThrustProfileNew)
Headerlines=6;
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
end



%Sat.GetField("ElapsedDays")


%Days=str2num(Sat.GetField("ElapsedDays"));




%TOI = gmat.gmat.GetRuntimeObject("TOI");
%MCC = gmat.gmat.GetRuntimeObject("MCC");
%MOI = gmat.gmat.GetRuntimeObject("MOI");
%toidv = str2num(TOI.GetField("Element1"));
%mccdv = sqrt(str2num(MCC.GetField("Element1"))^2+str2num(MCC.GetField("Element2"))^2);
%moidv = str2num(MOI.GetField("Element1"));
%DeltaV = abs(toidv)+mccdv+abs(moidv)
