function [alpha, beta] = VNBtoAlphaBeta(VNB)
% Calculates the pitch and yaw angles (alpha and beta) from Velocity-Normal-Binormal (VNB) coordinates

v = [VNB(1); 0; 0];  % Velocity vector
n = [0; VNB(2); 0];  % Normal vector
b = [0; 0; VNB(3)];  % Binormal vector



% Normalize the input vectors
v = v / norm(v);
n = n / norm(n);
b = b / norm(b);

% Calculate the pitch angle (alpha)
alpha = atan2(dot(v, cross(n, b)), norm(v));

% Calculate the yaw angle (beta)
beta = atan2(dot(v, n), dot(v, b));
end