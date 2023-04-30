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


t1=juliandate(2023,07,20,00,00,00);
[Re_i,Ve_i]= planetEphemeris(t1,'Sun','Earth');
load_gmat();
%timeConverter = gmat.gmat.theTimeSystemConverter
%t1_G=timeConverter.ConvertMjdToGregorian(t1)
gmat.gmat.LoadScript("C:/GMAT_Repo/EarthToMars_LowThrust_SNOPT/GMATScriptEarthMars.script");
sat = gmat.gmat.Construct("Spacecraft", "Sat");
sat.SetField("DateFormat", "A1ModJulian")           %"UTCGregorian")
sat.SetField("Epoch", num2str(t1-2430000.0))                %"20 Jul 2023 00:00:00.000")
sat.SetField("CoordinateSystem", "SunICRF")
sat.SetField("DisplayStateType", "Cartesian")
sat.SetField('X', Re_i(1));
sat.SetField('Y', Re_i(2));
sat.SetField('Z', Re_i(3));
sat.SetField('VX', Ve_i(1));
sat.SetField('VY', Ve_i(2));
sat.SetField('VZ', Ve_i(3));




