clear
clc
%EtJ50=load('EarthToJupiter50.mat').OutPut_Data;
EtJ300=load('EarthToJupiter300.mat').Op;

%EtM50=load('EarthToMars50.mat').Op;
%EtM200=load('EarthToMars200.mat').OP;
%EtMnTOF=load('EarthToMars50NoTOFObj.mat').Op;

%EtJnTOF=load('EarthToJupiter50NoTOFObj.mat').OutPut_Data;
EtMCS10=load('EtoM10CS.mat').Op;
EtMCS200=load('EtoM200CS.mat').Op;
EtMCS50=load('EtMCS50').Op;

EtJCS50=load('EarthToJupiter50CS.mat').FinalStruct;
EtJCS150=load('EarthToJupiter150CS.mat').SaveData;
EtJCS300=load('EarthToJupiter300CS.mat').OutPut_Data;


%% Jupiter
figure(1)
tiledlayout(2,1)
ax1=nexttile;
plot(EtJCS50.Time,EtJCS50.Alpha,"-D")
hold on
plot(EtJCS150.Time,EtJCS150.Alpha,"-D")
hold on
plot(EtJCS300.Time,EtJCS300.Alpha,"-D")
legend('Earth to Jupiter 50','Earth to Jupiter 150','Earth to Jupiter 300')
ylim([-2*pi 2*pi])
xlim([0 EtJCS50.Time(end)])

ax2=nexttile;
plot(EtJCS50.Time,EtJCS50.Beta,"-D")
hold on
plot(EtJCS150.Time,EtJCS150.Beta,"-D")
hold on
plot(EtJCS300.Time,EtJCS300.Beta,"-D")
legend('Earth to Jupiter 50','Earth to Jupiter 150','Earth to Jupiter 300')
ylim([-2*pi 2*pi])
xlim([0 EtJCS50.Time(end)])

title(ax1,'Earth to Jupiter 50 vs 150 vs 300 steps Alpha angle')
title(ax2,'Earth to Jupiter 50 vs 150 vs 300 steps Beta angle')
ylabel(ax1,'Alpha angle in radians')
ylabel(ax2,'Beta angle in radians')
xlabel(ax1,'Time in seconds')
xlabel(ax2,'Time in seconds')

%% Mars
figure(2)
tiledlayout(2,1)
ax11=nexttile;
plot(EtMCS10.Time,EtMCS10.Alpha,"-D")
hold on
plot(EtMCS50.Time,EtMCS50.Alpha,"-D")
hold on
plot(EtMCS200.Time,EtMCS200.Alpha,"-D")
legend('Earth to Mars 10','Earth to Mars 50','Earth to Mars 200')
ylim([-2*pi 2*pi])
xlim([0 EtMCS10.Time(end)])

ax12=nexttile;
plot(EtMCS10.Time,EtMCS10.Beta,"-D")
hold on
plot(EtMCS50.Time,EtMCS50.Beta,"-D")
hold on
plot(EtMCS200.Time,EtMCS200.Beta,"-D")
legend('Earth to Mars 10','Earth to Mars 50','Earth to Mars 200')
ylim([-2*pi 2*pi])
xlim([0 EtMCS10.Time(end)])

title(ax11,'Earth to Mars 10 vs 50 vs 200 steps Alpha angle')
title(ax12,'Earth to Mars 10 vs 50 vs 200 steps Beta angle')
ylabel(ax11,'Alpha angle in radians')
ylabel(ax12,'Beta angle in radians')
xlabel(ax11,'Time in seconds')
xlabel(ax12,'Time in seconds')

