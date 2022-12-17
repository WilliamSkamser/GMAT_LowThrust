function [c,ceq]=nlconsFMC(x)
ceq(1)= x(1)^3 +2*x(2)^2 -x(1)*x(3)+23;
c=x(1)^2 + x(2)^3 + x(3) -10;
end