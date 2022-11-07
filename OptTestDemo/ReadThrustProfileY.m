function [number] = ReadThrustProfileY(row)
file='C:/GMAT_Repo/OptTestDemo/ThrustProfile.thrust';
fID=fopen(file,'r');
B=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
Array=cell2mat(B);
fclose(fID);
direction=2;
number = Array(row,direction+1); 
end
