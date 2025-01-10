function outputs = Jacobian_1stDrying(input)
%% This function creates the Jacobian matrix for the primary drying model.

% Extract some important input data
m = input.m;
dz = input.dz;
ha = input.ha;
hb = input.hb;
a = input.alpf;
k = input.kf;

% Create a matrix
diagonal = (-2*a/dz^2)*ones(m,1);
offdiag = (1*a/dz^2)*ones(m-1,1);
A = diag(diagonal,0) + diag(offdiag,1) + diag(offdiag,-1);

% Stamp some boundary nodes
A(1,1) = -(2*dz*ha*a/k+2*a)/dz^2;
A(1,2) = 2*a/dz^2;
A(m,m) = -(2*dz*hb*a/k+2*a)/dz^2;
A(m,m-1) = 2*a/dz^2;

% Export
outputs = A;

return