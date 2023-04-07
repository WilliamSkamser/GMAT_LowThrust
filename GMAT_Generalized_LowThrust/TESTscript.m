% Define the VNB vectors for a moving object
VNB=[0.000104356000729457;	-0.0000908648826200433;	-0.000052764358951092];

%VNB=[1;1;1];
% Convert the VNB coordinates to alpha and beta angles
[alpha, beta] = VNBtoAlphaBeta(VNB);

% Display the results
disp(['Pitch angle (alpha): ', num2str(alpha)]);
disp(['Yaw angle (beta): ', num2str(beta)]);
