t1= juliandate(2004,06,05,01,52,21);

%20 Jul 2023 00:00:00.000

t1=juliandate(2023,07,20,00,00,00);
t2=t1+(TOF/86400);
[Rm,Vm]= planetEphemeris(t2,'Sun','Mars');

%READ File
fileG='../EarthToMars_LowThrust_SNOPT/GMAT_thrust.txt';
fIDG=fopen(fileG,'r');
AG=textscan(fIDG, '%f %f %f %f', 'headerlines',1);
InitialGuess_Data2=cell2mat(AG);
fclose(fIDG);
NumberOfSteps=size(InitialGuess_Data2(:,1));
Alpha_i=InitialGuess_Data2(:,2);
Beta_i=InitialGuess_Data2(:,3);
Time_i=InitialGuess_Data2(end,1);