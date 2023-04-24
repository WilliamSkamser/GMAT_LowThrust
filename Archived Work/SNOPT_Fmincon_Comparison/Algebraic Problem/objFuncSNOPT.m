function [F, G] = objFuncSNOPT(x)
%Objective Function
F(1)=4*x(1)^2 +2*x(2)^2 +x(3)^2 -x(1)*x(3) -2*x(1)*x(2)+x(1)-12*x(2)+901;
%Constaints
F(2) = x(1)^3 +2*x(2)^2 -x(1)*x(3)+23;
F(3)=x(1)^2 + x(2)^3 + x(3) -10;
%No Derivatives
G=[];
end
