clc, clear, format longg;
%READ Thrust File
file='../SNOPT/ThrustProfileInitalGuess.thrust';
fID=fopen(file,'r');
A=textscan(fID, '%f %f %f %f %f', 'headerlines',6);
ThrustProfile=cell2mat(A);
fclose(fID);

%Read Time Step from initial guess
steps=10;
TimeStep=zeros(steps,1);
for i=1:steps
TimeStep(i)=ThrustProfile(i+1,1) - ThrustProfile(i,1);
end

%Converts to vector
Thrust=zeros(43,1);
Thrust(1:11)=ThrustProfile(:,2);
Thrust(12:22)=ThrustProfile(:,3);
Thrust(23:33)=ThrustProfile(:,4);
Thrust(34:43)=TimeStep;%Time
                       
%Bounds
lb=zeros(1,length(Thrust)); ub=lb;
lb(1:length(Thrust)-steps)=-11.75;
ub(1:length(Thrust)-steps)=11.75;
lb(length(Thrust)-steps+1:end)=8640;
ub(length(Thrust)-steps+1:end)=86400*3;

%lower and upper bounds
xlow = lb.';
xupp = ub.';

%Objective Function
%bounds on objective function
Flow=zeros(7, 1);
Fupp=zeros(7, 1);
Flow(1) = 0;
Fupp(1) = +Inf;

%bounds of inequality constraints
Flow(2) = 0;
Fupp(2) = inf;
Flow(3) = 0;
Fupp(3) = inf;
%bounds on equality constraints
Flow(4) = 0.0;
Fupp(4) = 0.0;
Flow(5) = 0.0;
Fupp(5) = 0.0;
Flow(6) = 0.0;
Fupp(6) = 0.0;
Flow(7) = 0.0;
Fupp(7) = 0.0;
%Multiplier and state of design variable x and function F
xmul = zeros(43, 1);
xstate = zeros(43, 1);
Fmul = zeros(7, 1);
Fstate = zeros(7, 1);

x=Thrust;

%% SNOPT
ObjAdd =0; %Add value to objective Row
ObjRow =1; %Tell the Optimizer which row of F is the objective function

snscreen on;  
%snset("Minimize")
%create summary file
snsummary('SNOPt_summary.txt');
snsetr("Time limit",43200) %Sets time limit to 1/2 day (in seconds)
snseti("Iteration limit", 500);
snseti("Line search algorithm", 0)%Backtracking line search

load_gmat();
Ans1=gmat.gmat.LoadScript("../SNOPT/OptTestMatlab.script");
if Ans1 == 1
    tic
[x,F,inform,xmul,Fmul,xstate,Fstate,output]= ...
    snopt( x, xlow, xupp, xmul, xstate, Flow, Fupp, Fmul, Fstate, 'objFuncSNOPT', ObjAdd, ObjRow);
    toc
else
    fprintf("Fail to load script\n");
end
%{

 ==============================
 S N O P T  7.6.0    (Jan 2017)
 ==============================
  XXX  Keyword not recognized:          XXX  Keyword not recognized:         No script provided to load.
Warning: User is not providing SNOPT derivatives structures 
> In snopt (line 334)
  In Optimization_SNOPT (line 74) 
Warning: Derivatives provided but not structures: estimating structure via snJac. 
> In snopt (line 347)
  In Optimization_SNOPT (line 74) 
 
 SNMEMA EXIT 100 -- finished successfully
 SNMEMA INFO 104 -- memory requirements estimated

 Nonzero derivs  Jij       243
 Non-constant    Jij's     243     Constant Jij's           0
 
 SNJAC  EXIT 100 -- finished successfully
 SNJAC  INFO 102 -- Jacobian structure estimated

 
 ===>  WARNING - Column     11 of the Jacobian is empty.
 ===>  WARNING - Column     22 of the Jacobian is empty.
 ===>  WARNING - Column     33 of the Jacobian is empty.
 
 Scale option  0
 

 Nonlinear constraints       6     Linear constraints       1
 Nonlinear variables        40     Linear variables         3
 Jacobian  variables        40     Objective variables     40
 Total constraints           7     Total variables         43
 
 Itn      0: Feasible linear rows
 Itn      0: PP1.  Minimizing  Norm(x-x0)

 Itn      0: PP1.  Norm(x-x0) approximately minimized  (0.00E+00)

 
 The user has defined       0   out of     243   first  derivatives
 
 Itn      0: Hessian set to a scaled identity matrix

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
     0     28               1  9.0E-03  1.9E-03  3.6185358E+02     15           r
 Itn     28: Hessian set to a scaled identity matrix
     1      7  8.5E-02      2  8.2E-03  1.6E-03  2.3746079E+03     17 7.1E-03   rl
     2      9  9.3E-02      3  7.3E-03  2.2E-03  4.6218989E+03     15 1.7E-02 s  l
     3      8  1.0E+00      4  2.4E-03  1.6E-02  1.2847094E+03     16 1.7E-02
     4      8  4.3E-01      5  5.7E-04  1.1E-02  6.9839582E+02     19 1.7E-02
     5      5  1.8E-01      6  2.9E-04  1.0E-02  6.4937832E+02     19 1.7E-02
     6     11  7.1E-02      7  2.3E-04  5.4E-03  6.4097219E+02     15 1.8E-02
     7      1  3.7E-03      8  2.3E-04  6.2E-03  1.0376855E+03     15 1.4E+00
     8      5  3.3E-03      9  2.3E-04  6.6E-03  1.0369613E+03     17 1.4E+00
     9      4  5.5E-03     10  2.3E-04  6.4E-03  1.0346320E+03     14 1.4E+00

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    10      1  1.8E-03     11  2.3E-04  6.5E-03  1.0343519E+03     14 1.4E+00
    11      1  5.3E-05     13  2.3E-04  6.5E-03  1.0671050E+03     14 1.6E+00
    12      4  5.2E-05     15  2.3E-04  6.6E-03  1.0688150E+03     13 1.6E+00  m
    13     10  7.8E-04     16  2.3E-04  6.5E-03  1.0687299E+03     19 1.6E+00
    14      2  3.7E-03     17  2.3E-04  6.7E-03  1.0668979E+03     18 1.6E+00
    15      9  1.9E-03     18  2.3E-04  6.6E-03  1.0664208E+03     18 1.6E+00
    16      6  2.5E-05     20  2.3E-04  6.6E-03  1.1802825E+03     20 2.0E+00  M
    17      4  6.4E-05     21  2.3E-04  6.0E-03  1.1802712E+03     21 2.0E+00
    18      4  5.4E-03     22  2.3E-04  6.5E-03  1.1766382E+03     18 2.0E+00
    19      4  2.1E-03     23  2.3E-04  6.2E-03  1.1760848E+03     20 2.0E+00

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    20     17  2.0E-03     25  2.3E-04  2.2E-03  1.1756039E+03     12 2.0E+00 sM
    21     17  3.1E-03     26  2.3E-04  4.0E-03  1.1733622E+03     13 2.0E+00
    22     29  2.0E-04     27  2.3E-04  4.6E-03  1.1731283E+03     14 2.0E+00
    23     25  2.0E-03     29  2.3E-04  4.4E-03  1.1720712E+03     13 2.0E+00  M
    24     85  2.9E-03     30  2.3E-04  4.5E-03  1.1700364E+03     15 2.0E+00
    25     25  2.8E-03     32  2.3E-04  9.5E-03  1.1680003E+03      9 2.0E+00 sM
    26     12  3.5E-05     33  2.3E-04  9.0E-03  1.1678906E+03     10 2.0E+00
    27     46  1.8E-02     34  2.2E-04  5.8E-03  1.1446335E+03      2 2.0E+00
    28     67  1.2E-05     35  2.2E-04  6.1E-03  7.7666380E+03     11 2.8E+01
    29      3  1.7E-03     36  2.2E-04  6.9E-03  2.2399703E+03     12 6.3E+00

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    30     20  1.9E-03     37  2.2E-04  9.0E-03  2.2365875E+03     11 6.3E+00
    31     11  6.2E-05     39  2.2E-04  9.1E-03  2.2364086E+03     11 6.3E+00  M
    32     20  7.5E-05     40  2.2E-04  8.7E-03  2.2361970E+03     11 6.3E+00
    33     21  1.9E-05     41  2.2E-04  5.9E-03  2.2361434E+03     11 6.3E+00
    34     94  1.6E-05     42  2.2E-04  6.4E-03  2.2360999E+03     12 6.3E+00
    35     25  2.6E-05     43  2.2E-04  7.2E-03  2.2360285E+03     12 6.3E+00
    36     93  2.9E-05     44  2.2E-04  1.1E-02  2.2359396E+03     12 6.3E+00
    37     75  1.9E-03     45  2.2E-04  1.1E-02  2.2299964E+03     13 6.3E+00
    38      3  9.0E-05     46  2.2E-04  1.2E-02  2.2297618E+03     14 6.3E+00

        Minor NonOpt  QP mult  QP step   rgNorm   QP objective     nS
          100      4  1.9E+01  1.0E+00  3.5E-07  4.2157616E+03     11

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    39    192  4.1E-02     47  2.1E-04  9.7E-03  1.7867984E+03     14 6.3E+00

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    40     54  9.9E-03     48  2.1E-04  1.1E-02  1.7397834E+03     14 6.3E+00
    41     60  7.9E-04     49  2.1E-04  9.6E-03  1.7379740E+03     14 6.3E+00
    42      5  1.2E-05     50  2.1E-04  1.1E-02  1.7379507E+03     14 6.3E+00
    43     31  9.0E-06     51  2.1E-04  1.1E-02  1.7379336E+03     15 6.3E+00
    44     54  1.5E-02     52  2.1E-04  8.9E-03  1.6941021E+03     15 6.3E+00
    45     61  2.1E-03     53  2.1E-04  9.9E-03  1.6913183E+03     16 6.3E+00
    46      1  1.6E-04     55  2.1E-04  9.9E-03  1.6910000E+03     16 6.3E+00
    47     20  1.6E-04     56  2.1E-04  9.1E-03  1.6906769E+03     16 6.3E+00
    48     30  2.5E-03     57  2.1E-04  8.3E-03  1.6864080E+03     17 6.3E+00
    49     23  3.7E-03     59  2.1E-04  9.5E-03  1.6813162E+03     17 6.3E+00  M

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    50     43  9.9E-05     60  2.1E-04  1.0E-02  1.6811074E+03     17 6.3E+00
    51     19  3.7E-05     61  2.1E-04  8.6E-03  1.6810423E+03     17 6.3E+00
    52     48  3.7E-05     62  2.1E-04  2.0E-03  1.6809732E+03     17 6.3E+00

        Minor NonOpt  QP mult  QP step   rgNorm   QP objective     nS
          100      9           1.0E+00  2.1E-05  2.4965561E+03     15

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    53    120  1.7E-02     63  2.1E-04  7.9E-03  1.6498107E+03     19 6.3E+00
    54     20  3.6E-03     65  2.1E-04  6.2E-03  1.6448255E+03     10 6.3E+00 sM
    55     41  2.5E-02     66  2.0E-04  4.3E-03  1.4839751E+03      9 6.3E+00
    56     31  1.0E-03     67  2.0E-04  2.2E-03  1.4820987E+03      8 6.3E+00
    57     49  1.3E-03     68  2.0E-04  4.4E-03  1.4800106E+03     11 6.3E+00
    58      1  1.2E-05     70  2.0E-04  4.7E-03  1.4800047E+03     11 6.3E+00  M
    59     18  1.1E-05     71  2.0E-04  5.6E-03  1.4799943E+03      9 6.3E+00

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    60      9  1.1E-03     72  2.0E-04  5.6E-03  1.4784026E+03      7 6.3E+00
    61      5  1.3E-03     73  2.0E-04  5.9E-03  1.4768541E+03      7 6.3E+00
    62      7  1.2E-03     74  2.0E-04  7.3E-03  1.4753695E+03      8 6.3E+00
    63      9  1.5E-03     75  2.0E-04  7.3E-03  1.4737781E+03      8 6.3E+00
    64      6  1.5E-03     76  2.0E-04  7.0E-03  1.4719811E+03      9 6.3E+00
    65     12  1.9E-03     77  2.0E-04  5.8E-03  2.3523065E+03      6 1.1E+01
    66     36  6.0E-05     78  2.0E-04  3.4E-03  3.9082631E+03     13 1.9E+01
    67     14  2.1E-03     79  2.0E-04  5.1E-03  2.1912684E+03     12 9.7E+00
    68      3  1.9E-03     80  2.0E-04  2.4E-03  2.1861761E+03     12 9.7E+00
    69      1  2.2E-03     82  2.0E-04  2.4E-03  2.1807169E+03     12 9.7E+00  M

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    70      8  2.2E-03     84  2.0E-04  2.9E-03  2.1749503E+03     11 9.7E+00  M
    71     78  1.9E-03     85  2.0E-04  4.0E-03  2.1703936E+03     13 9.7E+00
    72      1  2.2E-03     87  2.0E-04  4.0E-03  2.1645688E+03     13 9.7E+00  M
    73      3  2.2E-03     89  2.0E-04  4.1E-03  2.1588679E+03     13 9.7E+00  M
    74     27  2.4E-03     90  2.0E-04  3.8E-03  2.1526629E+03     13 9.7E+00
    75      5  2.3E-03     92  2.0E-04  1.8E-03  2.1467062E+03     13 9.7E+00  m
 Itn   1964 -- Central differences invoked.  Small reduced gradient.
    75      7  2.3E-03     92  2.0E-04  1.9E-03  2.1467062E+03     12 9.7E+00  m    c
    76     19  1.8E-03     94  2.0E-04  8.2E-04  2.1419119E+03     12 9.7E+00  M    c
    77     35  4.0E-03     95  2.0E-04  8.0E-04  2.1352222E+03     13 9.7E+00       c
    78     24  3.3E-03     96  2.0E-04  1.3E-03  2.1278541E+03     12 9.7E+00       c
    79     16  2.7E-03     97  2.0E-04  8.1E-04  2.1212429E+03     15 9.7E+00       c

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    80     78  3.4E-03     98  2.0E-04  5.4E-03  2.1131687E+03     16 9.7E+00       c
    81     12  2.1E-03    100  2.0E-04  6.4E-03  2.1081765E+03     15 9.7E+00  m    c
    82     18  2.3E-03    101  2.0E-04  4.2E-03  2.1021345E+03     16 9.7E+00       c
    83     32  2.3E-03    102  2.0E-04  2.1E-03  2.0955830E+03     17 9.7E+00       c
    84     29  2.7E-03    104  1.9E-04  8.5E-04  2.0894499E+03     17 9.7E+00  m    c
    85     15  2.2E-03    105  1.9E-04  1.5E-03  2.0839854E+03     16 9.7E+00       c
    86     21  6.5E-05    106  1.9E-04  9.9E-04  2.0838336E+03     17 9.7E+00       c
    87     24  2.3E-03    108  1.9E-04  1.4E-03  2.0784060E+03     18 9.7E+00  m    c
    88     13  3.3E-03    109  1.9E-04  3.9E-03  2.0705739E+03     18 9.7E+00       c
    89     25  2.8E-03    111  1.9E-04  1.2E-03  2.0638775E+03     18 9.7E+00  m    c

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
    90     20  3.0E-03    112  1.9E-04  6.1E-04  2.0569221E+03     17 9.7E+00       c
    91     31  2.8E-03    113  1.9E-04  4.6E-03  2.0504255E+03     19 9.7E+00       c
    92      7  3.1E-03    115  1.9E-04  5.8E-03  2.0435028E+03     19 9.7E+00  m    c
    93     17  4.6E-03    117  1.9E-04  5.7E-03  2.0360720E+03     19 9.7E+00  m    c
    94     12  2.9E-03    119  1.9E-04  5.9E-03  2.0299341E+03     18 9.7E+00  M    c
    95      6  3.2E-03    121  1.9E-04  6.2E-03  2.0231232E+03     19 9.7E+00  m    c
    96     27  3.2E-03    123  1.9E-04  2.0E-03  2.0162642E+03     19 9.7E+00  m    c
    97     17  3.4E-03    124  1.9E-04  9.4E-04  2.0087419E+03     19 9.7E+00       c
    98     19  1.9E-03    126  1.9E-04  1.0E-03  2.0044541E+03     19 9.7E+00  M    c
    99     43  2.4E-03    128  1.9E-04  4.9E-04  1.9992037E+03     19 9.7E+00  m    c

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
   100     18  2.3E-03    130  1.9E-04  4.8E-03  1.9942736E+03     19 9.7E+00  m    c
   101     22  2.1E-03    131  1.9E-04  7.0E-04  1.9895118E+03     20 9.7E+00       c
   102     29  2.1E-03    133  1.9E-04  7.0E-04  1.9847102E+03     18 9.7E+00  M    c
   103     21  2.5E-03    135  1.9E-04  6.1E-04  1.9793072E+03     20 9.7E+00  m    c
   104     10  2.8E-03    137  1.9E-04  4.7E-03  1.9733852E+03     19 9.7E+00  m    c
   105      6  2.2E-03    139  1.9E-04  5.5E-03  1.9684143E+03     20 9.7E+00  m    c
   106      8  2.3E-03    141  1.8E-04  4.6E-03  1.9635383E+03     19 9.7E+00  m    c
   107      9  3.0E-03    142  1.8E-04  4.7E-03  1.9573794E+03     19 9.7E+00       c
   108      8  2.2E-03    144  1.8E-04  1.2E-03  1.9528303E+03     20 9.7E+00  m    c
   109      9  2.3E-03    145  1.8E-04  5.5E-04  1.9480670E+03     20 9.7E+00       c

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
   110     51  6.1E-05    147  1.8E-04  1.1E-03  1.9479560E+03     20 9.7E+00  m    c
   111     37  3.8E-03    149  1.8E-04  3.8E-03  1.9421926E+03     20 9.7E+00  m    c
   112      5  2.8E-03    150  1.8E-04  5.2E-04  1.9365902E+03     20 9.7E+00       c
   113     12  2.6E-03    152  1.8E-04  2.6E-03  1.9312726E+03     21 9.7E+00  m    c
   114     17  3.4E-03    154  1.8E-04  4.9E-04  1.9241853E+03     21 9.7E+00  M    c
   115     11  3.8E-03    156  1.8E-04  2.9E-03  1.9169551E+03     21 9.7E+00  m    c
 Itn   2821: Indefinite QP reduced Hessian
 Itn   2821: Hessian off-diagonals discarded
   116     34  3.0E-03    158  1.8E-04  2.6E-03  1.9110523E+03     30 9.7E+00  mR   c
   117      3  1.5E-01    159  1.5E-04  3.4E-03  2.3020199E+03     30 1.3E+01 s     c
   118      3  7.5E-02    160  1.4E-04  1.1E-03  2.0564528E+03     30 1.3E+01       c
   119      4  6.7E-03    162  1.4E-04  7.9E-04  2.0403663E+03     29 1.3E+01  m    c

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
   120      2  6.5E-03    164  1.4E-04  9.7E-04  2.0252559E+03     28 1.3E+01  m    c
   121      3  4.3E-04    166  1.4E-04  1.4E-03  2.0239142E+03     28 1.3E+01  M    c
   122      1  7.0E-03    168  1.4E-04  2.6E-03  2.0076535E+03     28 1.3E+01  m    c
   123      6  6.9E-03    170  1.4E-04  1.6E-03  1.9918354E+03     29 1.3E+01  m    c
   124      4  7.1E-03    172  1.4E-04  1.1E-03  1.9742640E+03     30 1.3E+01  m    c
   125      4  7.2E-03    173  1.4E-04  1.5E-03  1.9577451E+03     29 1.3E+01       c
   126      8  7.1E-03    174  1.4E-04  5.0E-04  1.9418678E+03     28 1.3E+01       c
   127      2  5.5E-03    176  1.4E-04  9.1E-04  1.9313423E+03     29 1.3E+01  m    c
   128      4  3.8E-04    178  1.4E-04  2.0E-03  1.9302398E+03     28 1.3E+01  M    c
   129      5  6.0E-03    180  1.3E-04  2.0E-03  1.9196174E+03     26 1.3E+01  M    c

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
   130      4  5.4E-03    182  1.3E-04  2.2E-03  1.9097652E+03     29 1.3E+01  M    c
   131      4  5.7E-03    184  1.3E-04  5.4E-04  1.8991310E+03     30 1.3E+01  m    c
   132      2  7.0E-03    185  1.3E-04  5.0E-04  1.8842595E+03     29 1.3E+01       c
   133      5  5.9E-03    187  1.3E-04  4.5E-04  1.8735773E+03     29 1.3E+01  m    c
   134      6  4.4E-03    189  1.3E-04  4.8E-04  1.8651944E+03     28 1.3E+01  M    c
   135      1  3.4E-04    190  1.3E-04  2.3E-03  1.8642641E+03     28 1.3E+01       c
   136      4  5.8E-03    192  1.3E-04  2.5E-03  1.8538126E+03     29 1.3E+01  M    c
   137      4  5.6E-03    194  1.3E-04  8.4E-04  1.8428000E+03     30 1.3E+01  m    c
   138      2  6.5E-03    196  1.3E-04  2.0E-03  1.8283421E+03     29 1.3E+01  m    c
   139      1  7.1E-03    198  1.3E-04  3.2E-03  1.8126071E+03     29 1.3E+01  m    c

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
   140      1  2.0E-03    200  1.3E-04  3.6E-03  1.8076621E+03     29 1.3E+01  m    c
   141      3  7.2E-03    202  1.3E-04  3.7E-03  1.7918427E+03     29 1.3E+01  m    c
   142      1  1.9E-04    203  1.3E-04  4.8E-04  1.7913728E+03     29 1.3E+01       c
   143      3  6.4E-03    205  1.3E-04  7.9E-04  1.7787396E+03     28 1.3E+01  m    c
   144      6  5.8E-03    207  1.3E-04  4.8E-04  1.7666806E+03     29 1.3E+01  m    c
   145      1  7.8E-03    209  1.2E-04  4.4E-04  1.7502835E+03     29 1.3E+01  m    c
   146      3  8.2E-03    211  1.2E-04  3.3E-03  1.7333321E+03     29 1.3E+01  M    c
   147      3  7.5E-03    212  1.2E-04  5.0E-04  1.7197363E+03     29 1.3E+01       c
   148      2  9.7E-03    214  1.2E-04  1.6E-03  1.7001774E+03     30 1.3E+01  M    c
   149      3  1.4E-02    215  1.2E-04  3.1E-03  1.6733338E+03     30 1.3E+01       c

 Major Minors     Step   nCon Feasible  Optimal  MeritFunction     nS Penalty
   150      3  5.5E-03    217  1.2E-04  2.5E-03  1.6639751E+03     29 1.3E+01  m    c
   151      2  9.5E-03    218  1.2E-04  9.7E-04  1.6454710E+03     30 1.3E+01       c
   152      5  9.2E-03    220  1.2E-04  2.1E-03  1.6280588E+03     26 1.3E+01  m    c
   153     15  2.0E-04    221  1.2E-04  8.1E-04  1.6276259E+03     30 1.3E+01       c
   154      5  7.8E-03    223  1.2E-04  1.0E-03  1.6131669E+03     28 1.3E+01  m    c
   155      4  4.7E-03    225  1.2E-04  2.4E-03  1.6064046E+03     29 1.3E+01  m    c
   156      8  2.4E-04    226  1.2E-04  2.1E-03  1.6058640E+03     27 1.3E+01       c
   157      5  3.8E-04    227  1.2E-04  7.5E-04  1.6049749E+03     29 1.3E+01       c
   158      4  4.0E-03    229  1.2E-04  1.2E-03  1.5965556E+03     28 1.3E+01  M    c
   159      3  5.2E-03    231  1.2E-04  8.2E-04  1.5872939E+03     28 1.3E+01  m    c
%}
