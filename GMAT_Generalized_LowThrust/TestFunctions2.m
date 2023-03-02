clc
clear all;
close all;
format longg;

MainDir = pwd;
WorkingDir=MainDir+"\GMAT_RunFolder";
BlanksDir=WorkingDir+"\Blank_scripts";
FileName_blank="GMAT_BlankScript.script";
FileName_run="\GMAT_temp2.script";
source = fullfile(BlanksDir,FileName_blank);
destination = fullfile(WorkingDir,FileName_run);
copyfile(source,destination);
FileName_runT="\GMAT_RunThrustProfile.thrust";

ThrustHFFN="GMAT ThrustHistoryFile1.FileName = ";
BlankFPWD="'C:\GMAT_Repo\GMAT_Generalized_LowThrust\GMAT_RunFolder\Blank_scripts\GMAT_BlankThrustProfile.thrust';";
TextToChange=ThrustHFFN+BlankFPWD;
NewText=ThrustHFFN+WorkingDir+FileName_runT;
FileRead = regexp(fileread(destination),'\n','split');
Line = find(contains(FileRead,TextToChange));
FileRead{Line}=NewText;
fid = fopen(destination, 'w');
fprintf(fid, '%s\n', FileRead{:});
fclose(fid);


