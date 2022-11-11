clc, clear, format longg;

ISP=1500;
g=9.80665;

TotalTime=10*60*60*24;
NumberOfSteps=100; 
TimeArray=(0:(TotalTime/NumberOfSteps):TotalTime);
ThrustProfile=zeros(NumberOfSteps+1,5);
for i=1:NumberOfSteps
    ThrustProfile(i,1)=TimeArray(i);
    ThrustProfile(i,2)=5;
    ThrustProfile(i,3)=0;
    ThrustProfile(i,4)=0;
    ThrustProfile(i,5)=norm(ThrustProfile(i,2:4)) / (ISP * g);    
end
ThrustProfile(end,1)=TimeArray(end);

%WRITE New Thrust File
Headerlines=6;
file2='../GeostationaryOrbit_LowThrust/ThrustProfileInitalGuess.thrust';
S = fileread(file2);
SS = regexp(S, '\r?\n', 'split');
for i=1:(NumberOfSteps+1)
    LineToChange = i+Headerlines; 
    NewContent = compose("%.1f     \t%.8f %.8f %.8f  %.8f",ThrustProfile(i,1),ThrustProfile(i,2),ThrustProfile(i,3),ThrustProfile(i,4),ThrustProfile(i,5));
    SS{LineToChange} = NewContent;
end
SS{NumberOfSteps+Headerlines+2}="EndThrust {ThrustSegment1}";
fid2 = fopen(file2, 'w');
fprintf(fid2, '%s\n', SS{:});
fclose(fid2);







