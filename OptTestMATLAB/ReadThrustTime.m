function [time] = ReadThrustTime(N)   
    file='C:/GMAT_Repo/OptTestMATLAB/ThrustRunTime.txt';
    fID=fopen(file,'r');
    t=textscan(fID, '%f');
    time=cell2mat(t);
    fclose(fID);
end


%function [number] = ReadThrustProfileX(row)
%file='C:/GMAT_Repo/OptTestDemo/ThrustProfile.thrust';
%fID=fopen(file,'r');
%B=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
%Array=cell2mat(B);
%fclose(fID);
%direction=1;
%number = Array(row,direction+1); 