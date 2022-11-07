function [test] = WriteThrustProfile(input)
%Thrust File
Headerlines=6;
file='C:/GMAT_Repo/OptTestDemo/ThrustProfile.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',Headerlines);
ThrustProfile=cell2mat(A);
fclose(fID);

%Output File
file1='C:/GMAT_Repo/OptTestDemo/ThrustProfileOUT.txt';
fID1=fopen(file1,'r');
B=textscan(fID1, '%f %f %f %f', 'headerlines',1);
Array=cell2mat(B);
fclose(fID1);

%Write To File
file2='C:/GMAT_Repo/OptTestDemo/ThrustProfile.thrust';
S = fileread(file2);
SS = regexp(S, '\r?\n', 'split');
for i=1:10
    LineToChange = i+Headerlines; 
    NewContent = compose("%.1f     \t%.3f %.3f %.3f  0.0001",ThrustProfile(i,1),Array(i,2),Array(i,3),Array(i,4));
    SS{LineToChange} = NewContent;
end
fid2 = fopen(file2, 'w');
fprintf(fid2, '%s\n', SS{:});
fclose(fid2);
test=input;
end