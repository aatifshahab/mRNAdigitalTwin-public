function [ ...
    time_points, ...
    x_positions, ...
    Cmatrix_mRNA, ...
    Cmatrix_protein, ...
    Cmatrix_ntps, ...
    interpolated_times, ...
    interpolated_indices, ...
    td, ...
    TFF_protein, ...
    TFF_ntps, ...
    Jcrit, ...
    Xactual ] = ...
    membraneAPI(qF, c0, X, n_stages, D, filterType)
% membraneAPI
% Returns arrays needed for plotting:
% (1) time_points and x_positions
% (2) Cmatrix for mRNA, protein, NTPs (N×M)
% (3) interpolated_times and interpolated_indices for snapshot plots
% (4) td (diafiltration time)
% (5) TFF_protein and TFF_ntps across stages vs. td
% (6) Jcrit and Xactual for reporting
%
% SYNTAX:
%   [time_points, x_positions, Cmatrix_mRNA, Cmatrix_protein, Cmatrix_ntps,
%    interpolated_times, interpolated_indices, td, TFF_protein, TFF_ntps,
%    Jcrit, Xactual] = ...
%       membraneAPI(qF, c0, X, n_stages, D, filterType)
%
% INPUTS:
%   qF         : Feed flow rate [mL/min], e.g. 1–5
%   c0         : 3×1 vector [mRNA; protein; NTPs] initial conc.
%   X          : Desired conversion (0 < X < 1)
%   n_stages   : Number of TFF stages (>=2)
%   D          : Diafiltration buffer flow rate [mL/min]
%   filterType : 'HF' or 'VIBRO'
%
% OUTPUTS:
%   time_points          : 1×N array of times for the PDE solution
%   x_positions          : 1×M array of positions along the membrane
%   Cmatrix_mRNA         : N×M PDE solution for mRNA
%   Cmatrix_protein      : N×M PDE solution for protein
%   Cmatrix_ntps         : N×M PDE solution for NTPs
%   interpolated_times   : 1×10 array of snapshot times (for 2D plots)
%   interpolated_indices : indices in time_points that match interpolated_times
%   td                   : Diafiltration time vector
%   TFF_protein          : 1×n_stages cell; each cell is array of protein vs. td
%   TFF_ntps             : 1×n_stages cell; each cell is array of NTPs vs. td
%   Jcrit                : Critical flux
%   Xactual              : Actual conversion (may differ from X if X > Xcrit)

    %% 1) Membrane geometry and base parameters
    L_all   = [20; 12];          % cm
    A_all   = [0.002; 0.0035];   % m^2
    ID      = [0.5; 0] * 1e-1;   % cm
    W       = 3;                 % cm
    H       = 0.17;              % cm
    Acs_all = [(ID(1)/2)^2*pi; (W*H)];

    %% 2) Select filter properties
    if strcmpi(filterType, 'HF')
        idx       = 1;  % Hollow Fiber
        dt        = 1e-5;
        tfinal    = 0.2;  % minutes
        L_HF      = 23.9960;
        K_HF      = 1.3333;
        n_HF      = 16.3122;
        Jcrit_val = (L_HF * (qF^n_HF)) / (K_HF + qF);  % HF flux
        S         = 0.24; % ret. coefficient
    elseif strcmpi(filterType, 'VIBRO')
        idx       = 2;  % Rectangular filter
        dt        = 1e-3;
        tfinal    = 24;  % minutes
        B         = 18.3417;
        n_v       = 0.8725;
        Jcrit_val = B * (qF^n_v);   % Vibro flux
        S         = 0.45; 
    else
        error('Invalid filter type. Choose "HF" or "VIBRO".');
    end

    L   = L_all(idx);
    A   = A_all(idx);
    Acs = Acs_all(idx);

    %% 3) Diffusion coefficient [cm^2/min]
    Diff = 1e-12 * 1e4 * 60;

    %% 4) Retention coefficient for protein
    R = ((1 - X)^S - (1 - X)) / X;
    s = [0.01; 1 - R; 0.99];  % ret. factors [mRNA, protein, NTPs]

    %% 5) Adjust X for critical flux
    Jcrit_mLMM = (Jcrit_val * 1e3) / 60;  % mL/(m^2·min)
    Xcrit      = (Jcrit_mLMM * A) / qF;
    if Xcrit > 1
        Xcrit = 0.95;
    end
    if Xcrit < X
        X = Xcrit;
    end
    Jactual     = X * (qF / A);
    Xactual_val = X;

    %% 6) Solve PDE for each component
    [Cout1, ~, Cmatrix1, time_pts, x_pts] = ...
        PDEsolver(qF, c0(1), L, A, Diff, tfinal, Jactual, s(1), Acs, dt);

    [Cout2, ~, Cmatrix2, ~, ~] = ...
        PDEsolver(qF, c0(2), L, A, Diff, tfinal, Jactual, s(2), Acs, dt);

    [Cout3, ~, Cmatrix3, ~, ~] = ...
        PDEsolver(qF, c0(3), L, A, Diff, tfinal, Jactual, s(3), Acs, dt);

    % time_pts: 1×N, x_pts: 1×M
    % Cmatrix1,2,3: N×M
    % Cout1,2,3: 1×N, but not strictly needed for plotting if using Cmatrix(:, end)

    %% 7) Prepare interpolation data for snapshots across position
    n_interps = 10;
    interp_times = linspace(0, time_pts(end), n_interps);
    interp_indices = round( interp1(time_pts, 1:length(time_pts), interp_times) );

    %% 8) Diafiltration (CCDF)
    VTFF = 8;  % total TFF volume
    R0   = qF * (1 - X);
    c0_ccdf = [Cout1(end); Cout2(end); Cout3(end)];
    P    = D;

    td_vec   = [];
    n_dia    = n_stages - 1;
    n_sp     = length(c0_ccdf);
    IC       = repmat(c0_ccdf, n_stages, 1);

    C1TFF = cell(1, n_stages);  % mRNA
    C2TFF = cell(1, n_stages);  % Protein
    C3TFF = cell(1, n_stages);  % NTPs
    dC2dt = 100;

    tprev = 0;
    tnext = 0.5;
    fun   = @(t, y) CCDF(t, y, R0, P, D, n_dia, c0_ccdf, s, VTFF);

    while abs(dC2dt) > 1e-4
        tspan = [tprev, tnext];
        [t_ode, y_ode] = ode15s(fun, tspan, IC);
        td_vec = [td_vec; t_ode];

        for stg = 1:n_stages
            base_idx      = 1 + (stg - 1)*n_sp;
            C1TFF{stg}    = [C1TFF{stg}; y_ode(:, base_idx)];
            C2TFF{stg}    = [C2TFF{stg}; y_ode(:, base_idx+1)];
            C3TFF{stg}    = [C3TFF{stg}; y_ode(:, base_idx+2)];
        end

        if length(C2TFF{1}) >= 3
            dt_ode = (t_ode(end) - t_ode(end-1));
            cA     = C2TFF{1}(end);
            cB     = C2TFF{1}(end-1);
            cC     = C2TFF{1}(end-2);
            dC2dt  = (1.5*cA - 2*cB + 0.5*cC) / dt_ode;
        end

        tprev = tnext;
        tnext = tnext + 0.5;
        IC    = y_ode(end, :);
    end

    %% 9) Extract only the protein and NTPs TFF data
    %   The user is specifically plotting protein and NTPs vs. td.
    %   mRNA TFF data not shown in the original code snippet, but can be added if needed.

    % td_vec is appended each iteration, so it is monotonic. Flatten, unique, etc.
    % or keep as-is if a fully appended vector is acceptable.

    % For consistency, gather final arrays:
    td_out = td_vec;

    %% 10) Prepare final outputs
    time_points          = time_pts;           % 1×N
    x_positions          = x_pts;             % 1×M
    Cmatrix_mRNA         = Cmatrix1;          % N×M
    Cmatrix_protein      = Cmatrix2;          % N×M
    Cmatrix_ntps         = Cmatrix3;          % N×M

    % Interpolated snapshots
    interpolated_times   = interp_times;       % 1×10
    interpolated_indices = interp_indices;     % 1×10

    % Diafiltration
    td                   = td_out;            % appended vector
    TFF_protein          = C2TFF;             % 1×n_stages cell
    TFF_ntps             = C3TFF;             % 1×n_stages cell

    Jcrit                = Jcrit_val;
    Xactual              = Xactual_val;
end




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

function [dY] = CCDF(t, y, R0, P, D, n, c0, s, VTFF)

    n_species = length(c0);     % Number of species
    n_stages = n + 1;           % Total stages (n intermediate + 1 final)
    CTFF = y(1:(n_species * n_stages)); % Extract concentrations

    dCTFF = zeros(n_species * n_stages, 1); % Initialize derivatives

    % First stage
    dCTFF(1:n_species) = (c0 .* R0 + s .* CTFF((n_species + 1):(2 * n_species)) * P ...
        - R0 .* CTFF(1:n_species) - P .* s .* CTFF(1:n_species)) / VTFF;

    % Intermediate stages (2 to n)
    for i = 2:n
        prev_idx = ((i - 2) * n_species + 1):((i - 1) * n_species);  % Indices of previous stage
        curr_idx = ((i - 1) * n_species + 1):(i * n_species);        % Indices of current stage
        next_idx = (i * n_species + 1):((i + 1) * n_species);        % Indices of next stage

        dCTFF(curr_idx) = (CTFF(prev_idx) .* R0 + s .* P .* CTFF(next_idx) ...
            - CTFF(curr_idx) .* (R0 + s .* P)) / VTFF;
    end

    % Final stage
    prev_idx = ((n - 1) * n_species + 1):(n * n_species);  % Indices of previous stage
    final_idx = (n * n_species + 1):((n + 1) * n_species); % Indices of final stage

    dCTFF(final_idx) = (CTFF(prev_idx) .* R0 ...
        - CTFF(final_idx) .* (R0 + s .* P)) / VTFF;

    dY = dCTFF; % Return derivatives
end
