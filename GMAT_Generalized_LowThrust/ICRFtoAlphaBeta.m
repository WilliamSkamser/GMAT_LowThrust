clear
clc
		
% Define the position and velocity vectors in ICRF
%r = [x;y;z];
r =[1;1;1];
v= [1;1;1];

%v = [vx;vy;vz];

% Define the thrust vector in ICRF
T_icrf =[1;1;1];% [Tx;Ty;Tz];

% Compute the unit vectors in the radial and in-track directions
e_r = r/norm(r);
e_t = cross(r,v)/norm(cross(r,v));

% Compute the unit vector in the thrust direction
e_T = T_icrf/norm(T_icrf);

% Compute the projection of the thrust vector onto the in-track direction
T_t = dot(T_icrf,e_t)*e_t;

% Compute the projection of the thrust vector onto the radial direction
T_r = dot(T_icrf,e_r)*e_r;

% Compute the projection of the thrust vector onto the cross-track direction
T_c = T_icrf - T_t - T_r;

% Compute the magnitude of the cross-track component of the thrust vector
T_c_mag = norm(T_c);

% Compute the angle alpha between the thrust vector and the in-track direction
alpha = atan2(T_c_mag,dot(T_icrf,e_r));

% Compute the angle beta between the thrust vector and the radial direction
beta = atan2(T_c_mag,dot(T_icrf,e_t));

% Compute the unit vectors in the radial and in-track directions
e_r = r/norm(r);
e_t = cross(r,v)/norm(cross(r,v));

% Compute the unit vector in the thrust direction
e_T = cos(alpha)*cos(beta)*e_r + cos(alpha)*sin(beta)*e_t + sin(alpha)*e_T;

% Compute the magnitude of the thrust vector
T_mag = T; % assign the magnitude of the thrust vector as a known value

% Compute the thrust vector in ICRF
T_icrf = T_mag*e_T;
