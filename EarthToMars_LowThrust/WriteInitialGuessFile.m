clc, clear, format longg;
%READ File
file='../EarthToMars_LowThrust/GMAT_initialGuess.txt';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f', 'headerlines',1);
ThrustProfile=cell2mat(A);
fclose(fID);

ISP=2800;
g=9.80665;

NumberOfSteps=size(ThrustProfile(:,1));

for i=1:NumberOfSteps(1)      
    ThrustProfile(i,5)=norm(ThrustProfile(i,2:4)) / (ISP * g);
    %ThrustProfile(i,5)=4.2231e-6;
end

%WRITE New Thrust File
Headerlines=6;
file2='../EarthToMars_LowThrust/InitialGuessThrustProfile.thrust';
S = fileread(file2);
SS = regexp(S, '\r?\n', 'split');
for i=1:(NumberOfSteps(1))
    LineToChange = i+Headerlines; 
    NewContent = compose("%8.4f\t\t\t\t%.10f %.10f %.10f  %.10f",ThrustProfile(i,1),ThrustProfile(i,2),ThrustProfile(i,3),ThrustProfile(i,4),ThrustProfile(i,5));
    %e       		w       2w       		e
    SS{LineToChange} = NewContent;
end
SS{NumberOfSteps(1)+Headerlines+1}="EndThrust {ThrustSegment1}";
fid2 = fopen(file2, 'w');
fprintf(fid2, '%s\n', SS{:});
fclose(fid2);