function [number] = ThrustProfile(row,column)
file='C:\GMAT_Repo\LowThrustProfile2\InitialThrustProfile.thrust';
%row=2;
%column=2;
fID=fopen(file,'r');
B=textscan(fID, '%f %f %f %f', 'headerlines',6);
Array=cell2mat(B);
fclose(fID);
%number=Array;

number = Array(row,column); 
end
%if ReadWrite == 'w' || 'W'
    
%elseif ReadWrite == 'r' || 'R'
        
%else
%    number=null; %Return 
    
%end