% Define the VNB vectors for a moving object
v = [1; 0; 0];  % Velocity vector
n = [0; 1; 0];  % Normal vector
b = [0; 0; 1];  % Binormal vector

% Convert the VNB coordinates to alpha and beta angles
[alpha, beta] = VNBtoAlphaBeta(v, n, b);

% Display the results
disp(['Pitch angle (alpha): ', num2str(alpha * 180 / pi), ' degrees']);
