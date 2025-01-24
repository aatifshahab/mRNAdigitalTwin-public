function [Coutvector, C, Cmatrix, time_points, x, t_ss] = PDEsolver(q0, c0, L, A, D, tfinal, J, s, Acs, dt)
    %% Constants
    nx = 1000; % Number of spatial points
    a = A / L; % Area per unit length (m^2 / cm)
    x = linspace(0, L, nx); % Spatial grid
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
    C_ = C; % Temporary variable for updates
    Coutvector = [];
    Cmatrix = [];
    time_points = [];

    %% Time-stepping loop
    t_ss = 0; % Initialize steady-state time
    sampling_interval = 0.05; % Fine sampling interval

    for k = 1:count_final
        % Update concentration using finite difference
        C_(2:nx) = ((D / (dx^2)) * (C(3:nx+1) + C(1:nx-1) - 2 * C(2:nx)) + ...
                   (1 - s) * J * C(2:nx) * a - ...
                   (q0 - J * a * x(2:nx)) .* ((C(2:nx) - C(1:nx-1)) / dx)) * dt / Acs + C(2:nx);
        C_(end) = C_(end-1); % Apply boundary condition for ghost cell

        % Check for steady state
        if norm(C_ - C) < 1e-8
            t_ss = k * dt;
            disp('Reached steady state');
            break;
        end

        C = C_; % Update for the next time step

        % Store concentration and time at fine intervals
        if mod(k * dt, sampling_interval) < dt
            Cmatrix = [Cmatrix; C(1:end-1)]; % Store profile without ghost cell
            Coutvector = [Coutvector, C(end-1)];
            time_points = [time_points, k * dt]; % Store time points
        end
    end

    %% Handle steady-state extension
    if t_ss < tfinal
        steady_state_sampling_interval = 5; % Coarse interval for steady-state
        extended_time_points = t_ss:steady_state_sampling_interval:tfinal;
        num_extra_points = length(extended_time_points) - 1;

        % Replicate steady-state values
        steady_state_values = repmat(Cmatrix(end, :), num_extra_points, 1);
        Cmatrix = [Cmatrix; steady_state_values];

        steady_state_Cout = repmat(Coutvector(end), 1, num_extra_points);
        Coutvector = [Coutvector, steady_state_Cout];

        time_points = [time_points, extended_time_points(2:end)]; % Extend time points
    end

    %% Outputs
    C = C(1:end-1); % Final concentration profile (remove ghost cell)
end
