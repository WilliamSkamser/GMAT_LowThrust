function  time = ReadThrustTime(N)
if N ==1    
    file='../OptTestMATLAB/ThrustRunTime.txt';
    fID=fopen(file,'r');
    t=textscan(fID, '%f');
    time=cell2mat(t);
    fclose(fID);
end
end