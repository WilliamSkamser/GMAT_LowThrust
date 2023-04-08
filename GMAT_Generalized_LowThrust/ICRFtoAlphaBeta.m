clear
clc
		

Table=readtable(pwd+"\Earth_Mars_data.xlsx",'ReadVariableNames',false);
thrustVec=table2array(Table(:,9:11));
for i=1:length(thrustVec(:,1))
    Beta2(i)=asin(thrustVec(i,3)/norm(thrustVec(i,:)));
    Alpha2(i)=atan(thrustVec(i,2)/thrustVec(i,1));
    %Alpha2(i)=atan(thrustVec(i,1)/thrustVec(i,2));
end
Beta2=Beta2';
Alpha2=Alpha2';
thrustMag=table2array(Table(:,12));
Alpha=table2array(Table(:,13));
Beta=table2array(Table(:,14));
thrustVec2=norm(thrustMag).*[cos(Beta).*cos(Alpha),cos(Beta).*sin(Alpha),sin(Beta)];
%thrustVec2=norm(thrustMag).*[cos(Beta).*sin(Alpha),cos(Beta).*cos(Alpha),sin(Beta)]; 
