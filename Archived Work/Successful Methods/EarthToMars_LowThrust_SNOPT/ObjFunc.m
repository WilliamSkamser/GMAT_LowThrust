function TOF=ObjFunc(x)
[F, G] = objFunc_conFunc(x);
TOF=F(1);
end