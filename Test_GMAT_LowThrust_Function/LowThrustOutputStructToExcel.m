function []=LowThrustOutputStructToExcel(O_Struct,FileName)
NewExcelTable=insertAfter(pwd+FileName,strlength(pwd+FileName)-5,'_SolutionData');
copyfile(pwd+FileName,NewExcelTable);
xlswrite(NewExcelTable,O_Struct.Time,1,'R2')
xlswrite(NewExcelTable,O_Struct.ThrustXYZ,1,'S2')
xlswrite(NewExcelTable,O_Struct.Alpha,1,'V2')
xlswrite(NewExcelTable,O_Struct.Beta,1,'W2')
end
%LowThrustOutputStructToExcel(O_Struct,"\JupiterAccelerationFFSProblem2.xlsx")