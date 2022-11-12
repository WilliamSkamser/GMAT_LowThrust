load_gmat();
Ans1=gmat.gmat.LoadScript("../GMAT_Repo/LowThrustProfile1.script");
Ans2=gmat.gmat.RunScript();



%TOI = gmat.gmat.GetRuntimeObject("TOI");
%MCC = gmat.gmat.GetRuntimeObject("MCC");
%MOI = gmat.gmat.GetRuntimeObject("MOI");
%toidv = str2num(TOI.GetField("Element1"));
%mccdv = sqrt(str2num(MCC.GetField("Element1"))^2+str2num(MCC.GetField("Element2"))^2);
%moidv = str2num(MOI.GetField("Element1"));
%DeltaV = abs(toidv)+mccdv+abs(moidv)
