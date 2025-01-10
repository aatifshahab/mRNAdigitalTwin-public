%%FUNCTIONS
function [Coutvector, C, Cmatrix,time_points,x] = PDEsolver(q0, c0, L, A, D, tfinal, J, s, Acs,dt)
    %% Constants
    nx = 1000; % Number of spatial points
    a = A / L; % Area per unit length (m^2 / cm)
    x = linspace(0, L, nx); % Spatial grid
    nt = 100; % Number of equally spaced time points
    time_points = linspace(0, tfinal, nt); % Desired time points for storage
    dx = x(2) - x(1);
    

    %% Stability Check
    stab = D * dt / (dx^2);
    if stab > 0.5
        error('Stability criteria not met');
    end

    %% Initial Conditions
    C = ones(1, nx + 1) * c0; % Initial concentration (with ghost cell)
    C(1) = c0; % Boundary condition
    count_final = tfinal / dt; % Total time steps
    Cmatrix = zeros(nt, nx); % Preallocate concentration matrix
    C_ = C; % Temporary variable for updates
    counter = 1; % Index for storing time points
    Coutvector=zeros(1, nt);
    %% Time-stepping loop
    for k = 1:count_final
        % Update concentration using finite difference
        C_(2:nx) = ((D / (dx^2)) * (C(3:nx+1) + C(1:nx-1) - 2 * C(2:nx)) + ...
                   (1 - s) * J * C(2:nx) * a - ...
                   (q0 - J * a * x(2:nx)) .* ((C(2:nx) - C(1:nx-1)) / dx)) * dt / Acs + C(2:nx);
        C_(end) = C_(end-1); % Apply boundary condition for ghost cell
        C = C_; % Update for the next time step

        % Store concentration at specified time points
        if abs(k * dt - time_points(counter)) < 0.01
            Cmatrix(counter, :) = C(1:end-1); % Store profile without ghost cell
            Coutvector(counter)=C(end-1);
            counter = counter + 1;
            if counter > nt
                break; % Stop if all time points are stored
            end
        end
    end

    %% Outputs
    C = C(1:end-1); % Final concentration profile (remove ghost cell)
    Cout = C(end); % Final concentration at the last spatial point
end