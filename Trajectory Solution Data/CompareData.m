clear
clc
EtJ50=load('EarthToJupiter50.mat').OutPut_Data;
EtJ300=load('EarthToJupiter300.mat').Op;
EtM50=load('EarthToMars50.mat').Op;
EtM200=load('EarthToMars200.mat').OP;
EtMnTOF=load('EarthToMars50NoTOFObj.mat').Op;
EtJnTOF=load('EarthToJupiter50NoTOFObj.mat').OutPut_Data;

%% Jupiter
figure(1)
tiledlayout(2,1)
ax1=nexttile;
plot(EtJ50.Time,EtJ50.Alpha,"-D")
hold on
plot(EtJ300.Time,EtJ300.Alpha,"-D")
hold on
plot(EtJnTOF.Time,EtJnTOF.Alpha,"-D")
legend('Earth to Jupiter 50','Earth to Jupiter 300','Earth to Jupiter 50 No TOF Obj')
ylim([-2*pi 2*pi])
xlim([0 EtJ50.Time(end)])

ax2=nexttile;
plot(EtJ50.Time,EtJ50.Beta,"-D")
hold on
plot(EtJ300.Time,EtJ300.Beta,"-D")
hold on
plot(EtJnTOF.Time,EtJnTOF.Beta,"-D")
legend('Earth to Jupiter 50','Earth to Jupiter 300','Earth to Jupiter 50 No TOF Obj')
ylim([-2*pi 2*pi])
xlim([0 EtJ50.Time(end)])

title(ax1,'Earth to Jupiter 50 vs 300 steps Alpha angle')
title(ax2,'Earth to Jupiter 50 vs 300 steps Beta angle')
ylabel(ax1,'Alpha angle in radians')
ylabel(ax2,'Beta angle in radians')
xlabel(ax1,'Time in seconds')
xlabel(ax2,'Time in seconds')

%% Mars
figure(2)
tiledlayout(2,1)
ax11=nexttile;
plot(EtM50.Time,EtM50.Alpha,"-D")
hold on
plot(EtM200.Time,EtM200.Alpha,"-D")
hold on
plot(EtMnTOF.Time,EtMnTOF.Alpha,"-D")
legend('Earth to Mars 50','Earth to Mars 200','Earth to Mars 50 No TOF Obj')
ylim([-2*pi 2*pi])
xlim([0 EtMnTOF.Time(end)])

ax12=nexttile;
plot(EtM50.Time,EtM50.Beta,"-D")
hold on
plot(EtM200.Time,EtM200.Beta,"-D")
hold on
plot(EtMnTOF.Time,EtMnTOF.Beta,"-D")
legend('Earth to Mars 50','Earth to Mars 200','Earth to Mars 50 No TOF Obj')
ylim([-2*pi 2*pi])
xlim([0 EtMnTOF.Time(end)])

title(ax11,'Earth to Mars 50 vs 200 steps Alpha angle')
title(ax12,'Earth to Mars 50 vs 200 steps Beta angle')
ylabel(ax11,'Alpha angle in radians')
ylabel(ax12,'Beta angle in radians')
xlabel(ax11,'Time in seconds')
xlabel(ax12,'Time in seconds')

