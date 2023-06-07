# Example problem (Earth to Mars) 20 minutes

1) Use EarthToMars_10Steps.xlsx low-thrust setup file to propagate an Earth to Mars trajectory. 
2) Use this command in this directory:
``` 
Output=GMAT_LowThrust(“\EarthToMars_10Steps.xlsx”)
```
3) Open GMAT and run “GMAT_RunScript_Plots”
It should produce a trajectory that looks like this:

![image](https://github.com/WilliamSkamser/GMAT_LowThrust/assets/82694780/8f5b1771-bdca-42ac-bb5d-b696afa9fb25)
 
4) To improve the initial guess, we can use the command:
```
Output=GMAT_LowThrust(“\EarthToMars_10Steps.xlsx”,’Optimize’,OP_Options) 
```
Where OP_Options is a struct defined as: 
```
OP_Options= struct('TOF_LowBound',200,'TOF_UpperBound',1000,'MajorFeasibilityTolerance',1e-6,…
	'MajorOptimalityTolerance',1e-6,'OptimizationRunTimeLimit',3600,'MajorIterationLimit',…
	5000,'Obj','Cons');
```

Using these commands will launch the SNOPT optimization loop with the objective function of minimizing the constraints (the difference in final state vector between the satellite and Mars). This process should take 10 minutes. Once completed,reloading and running “GMAT_RunScript_Plots” in GMAT should produce a trajectory that looks like this:

![image](https://github.com/WilliamSkamser/GMAT_LowThrust/assets/82694780/35439559-5243-4afe-9641-58103b1562d2)
 
5) Although the trajectory reached Mars, the time of flight can be improved. Use this command to save the previous solution to an Excel setup file to rerun the Optimization:
 ```
LowThrustOutputStructToExcel(Output,“\EarthToMars_10Steps.xlsx”)
```
This will generate an excel file called \EarthToMars_10Steps_SolutionData.xlsx
6) Now rerun GMAT_LowThrust with the new excel setup file to optimize for time of flight
Output=GMAT_LowThrust(“\EarthToMars_10Steps_SolutionData.xlsx”,’Optimize’,OP_Options)

Where OP_Options is a struct defined as:
 ```
OP_Options= struct('TOF_LowBound',200,'TOF_UpperBound',1000,'MajorFeasibilityTolerance',1e-6,…
'MajorOptimalityTolerance',1e-6,'OptimizationRunTimeLimit',3600,'MajorIterationLimit',…
5000,'Obj','TOF');
```
"'Obj', 'TOF'" is used to specify TOF as the objective function. SNOPT should run for another 10 minutes. The final trajectory should look like this:
	
 ![image](https://github.com/WilliamSkamser/GMAT_LowThrust/assets/82694780/87cf0dfd-9b8b-4465-b153-0e1de583301f)
 





