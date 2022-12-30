function [time] = ReadThrustTime(A)   
    file='C:/GMAT_Repo/GeostationaryOrbit_LowThrust_SNOPT/ThrustRunTime.txt';
    fID=fopen(file,'r');
    t=textscan(fID, '%f');
    time=cell2mat(t);
    fclose(fID);
end