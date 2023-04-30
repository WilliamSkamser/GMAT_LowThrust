function [Cons,Cons_eq]=NonLinCons(x)
[F, G] = objFunc_conFunc(x);
Cons_eq=F(2:7);
Cons=[];
end