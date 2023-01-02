t1= juliandate(2004,06,05,01,52,21);

20 Jul 2023 00:00:00.000

t1=juliandate(2023,07,20,00,00,00);
t2=t1+(TOF/86400);
[Rm,Vm]= planetEphemeris(t2,'Sun','Mars');