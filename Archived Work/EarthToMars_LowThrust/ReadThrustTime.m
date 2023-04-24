function [time] = ReadThrustTime(N)   
    file='C:/GMAT_Repo/EarthToMars_LowThrust/ThrustRunTime.txt';
    fID=fopen(file,'r');
    t=textscan(fID, '%f');
    time=cell2mat(t);
    fclose(fID);
end