function [ ...
    time_points, ...
    x_positions, ...
    Cmatrix_mRNA, ...
    Cmatrix_protein, ...
    Cmatrix_ntps, ...
    td, ...
    TFF_protein, ...
    TFF_ntps, ...
    t_ss, ...
    Reduction, ...
    V_final, ...
    avg_conc_pre_ccdf, ...
    avg_conc_post_ccdf, ...
    ccdf_time, ...
    X,...
    interpolated_times, ...        % Added Output
    interpolated_indices] = ...
    membraneAPI_new(qF, c0, X, n_stages, D, filterType, V_IVT)

    %% 1) Membrane geometry and base parameters
    L = 12; % cm
    A = 0.0035; % m^2
    W = 3; % cm
    H = 0.17; % cm
    Acs = W * H; % Effective cross-sectional area
    tfinal_conc = V_IVT / qF * 10^3; % min

    %% 2) Select filter properties based on filterType
    if strcmpi(filterType, 'NOVIBRO')
        dt = 1e-3; % Time step [min]
        tfinal = tfinal_conc; % Total simulation time [min]
        L_HF = 23.9960;
        K_HF = 1.3333;
        n_HF = 16.3122;
        Jcrit_val = (L_HF * (qF^n_HF)) / (K_HF + qF^n_HF); % Critical flux for HF
        S = 0.24; % Retention coefficient
    elseif strcmpi(filterType, 'VIBRO')
        dt = 1e-3; % Time step [min]
        tfinal = tfinal_conc; % Total simulation time [min]
        B = 18.3417;
        n_v = 0.8725;
        Jcrit_val = B * (qF^n_v); % Critical flux for Vibro
        S = 0.45;
    else
        error('Invalid filter type. Choose "NOVIBRO" or "VIBRO".');
    end

    %% 3) Diffusion coefficient [cm^2/min]
    Diff = 1e-12 * 1e4 * 60; % Adjusted to [cm^2/min]

    %% 4) Retention coefficients for components
    R = ((1 - X)^S - (1 - X)) / X;
    s = [0.005; 1 - R; 0.99]; % Retention factors [mRNA, protein, NTPs]

    %% 5) Adjust X for critical flux
    Jcrit_mLMM = (Jcrit_val * 1e3) / 60; % mL/(m^2·min)
    Xcrit = (Jcrit_mLMM * A) / qF;
    if Xcrit > 1
        Xcrit = 0.95; % Cap Xcrit at 0.95 if it exceeds 1
    end
    if Xcrit < X
        X = Xcrit; % Adjust X to not exceed critical conversion
    end
    Jactual = X * (qF / A); % Actual permeate flux
    Xactual_val = X; % Actual conversion

    %% 6) Solve PDE for each component over the entire simulation time
    [Cout1, ~, Cmatrix1, time_pts_mRNA, x_pts, t_ss_mRNA] = ...
        PDEsolver(qF, c0(1), L, A, Diff, tfinal, Jactual, s(1), Acs, dt);
  
    [Cout2, ~, Cmatrix2, time_pts_protein, ~, t_ss_protein] = ...
        PDEsolver(qF, c0(2), L, A, Diff, tfinal, Jactual, s(2), Acs, dt);

    [Cout3, ~, Cmatrix3, time_pts_ntps, ~, t_ss_ntps] = ...
        PDEsolver(qF, c0(3), L, A, Diff, tfinal, Jactual, s(3), Acs, dt);

  %% 7) Combine Time Points and Interpolate Concentrations
t_ss = [t_ss_mRNA, t_ss_protein, t_ss_ntps];
shared_time_points = time_pts_mRNA; % Use mRNA time points as the reference

% Interpolate protein and NTP concentrations onto the shared time points
Cmatrix_protein_interp = interp1(time_pts_protein, Cmatrix2, shared_time_points, 'linear', 'extrap');
Cmatrix_ntps_interp = interp1(time_pts_ntps, Cmatrix3, shared_time_points, 'linear', 'extrap');

% Assign final time points and concentration matrices
time_points = shared_time_points;
Cmatrix_mRNA = Cmatrix1; % mRNA does not need interpolation since it's the reference
Cmatrix_protein = Cmatrix_protein_interp;
Cmatrix_ntps = Cmatrix_ntps_interp;


    %% Added Section -Aatif: Compute interpolated_times and interpolated_indices for Plotting
    % -------------------------------------------------------------------------------
    % Purpose: To select specific time points and their corresponding indices for plotting
    % Similar to how 'time_indices' were determined in the plotting code

    num_snapshots = 5; % Number of snapshots to select
    max_ss_time = max(t_ss); % Maximum steady-state time among components
    snapshot_time_range = linspace(0, 2 * max_ss_time, num_snapshots); % Define snapshot times up to twice the max steady-state time

    % Ensure snapshot times do not exceed the simulation time
    snapshot_time_range = snapshot_time_range(snapshot_time_range <= max(time_points));

    % Initialize interpolated_indices
    interpolated_indices = zeros(1, length(snapshot_time_range));

    % Find the closest indices in time_points to the snapshot times
    for i = 1:length(snapshot_time_range)
        [~, idx] = min(abs(time_points - snapshot_time_range(i)));
        interpolated_indices(i) = idx;
    end

    % Extract the interpolated_times based on the indices
    interpolated_times = time_points(interpolated_indices);
    % --------------------------------------------------------------------------
    %% 8) Diafiltration (CCDF) Stage
    VTFF = 8; % Total volume (mL)
    R0 = qF * (1 - X); % Outlet flow rate for concentration step
    avg_conc_pre_ccdf = [trapz(time_pts_mRNA, Cmatrix1(:, end)) / tfinal_conc, ...
                              trapz(time_pts_protein, Cmatrix2(:, end)) / tfinal_conc, ...
                              trapz(time_pts_ntps, Cmatrix3(:, end)) / tfinal_conc] % Avg Pre-CCDF
    c0_ccdf = [avg_conc_pre_ccdf(1); avg_conc_pre_ccdf(2); avg_conc_pre_ccdf(3)];

   P = D; % Diafiltration buffer flow rate

td = []; % Time tracking for CCDF
n = n_stages - 1; % Number of stages minus 1
n_species = length(c0_ccdf); % Number of components
IC = repmat(c0_ccdf, n_stages, 1); % Initial conditions for CCDF

% Storage for concentrations at each stage
C1TFF = cell(1, n_stages); % Storage for mRNA concentrations
C2TFF = cell(1, n_stages); % Storage for Protein concentrations
C3TFF = cell(1, n_stages); % Storage for NTPs concentrations

dC2TFF1dt = 100; % Convergence criterion for Protein

% Initialize time variables
tprev = 0;
tnext = tprev + 0.5;

% Define ODE function
fun = @(t, y) CCDF(t, y, R0, P, D, n, c0_ccdf, s, VTFF);

% Loop until steady state is reached
while abs(dC2TFF1dt) > 10^-6
    tspan = [tprev, tnext];
    [t, y] = ode15s(fun, tspan, IC); % Solve ODE system
    td = [td; t]; % Append time points

    for i = 1:n_stages
        base_idx = 1 + (i - 1) * n_species;
        C1TFF{i} = [C1TFF{i}; y(:, base_idx)];       % mRNA concentration
        C2TFF{i} = [C2TFF{i}; y(:, base_idx + 1)];   % Protein concentration
        C3TFF{i} = [C3TFF{i}; y(:, base_idx + 2)];   % NTPs concentration
    end

    % Check convergence for Protein concentration (C2TFF1)
    if length(C2TFF{1}) >= 3
        dC2TFF1dt = (3/2 * C2TFF{1}(end) - 2 * C2TFF{1}(end-1) + 1/2 * C2TFF{1}(end-2)) / (t(end) - t(end-1));
    end

    % Update for next iteration
    tprev = tnext;
    tnext = tnext + 0.5;
    IC = y(end, :);
end

% CCDF time to steady state
ccdf_time = t(end); % Total CCDF time

  %% 9) Reduction Factor Calculation
% Use the final concentration values from the diafiltration stages
Reduction_Protein = (1 - (c0(2) / C2TFF{1}(end))^-1) * 100;
Reduction_NTPs = (1 - (c0(3) / C3TFF{1}(end))^-1) * 100;
Reduction = [Reduction_Protein; Reduction_NTPs];

%% 10) Final Volume Calculation
% Based on the conversion achieved during the process
V_final = V_IVT * (1 - Xactual_val);

%% 11) Average Concentrations Post-CCDF
% Stretch outputs and times to match the actual CCDF duration
ccdf_totaltime = V_final / R0 * 1000; % Total CCDF duration in minutes

% Extend the time vector to include steady-state time
extra_time_points = (td(end) + 0.5):0.5:ccdf_totaltime; % Additional time points
extended_td = [td; extra_time_points']; % New extended time vector

% Extend the concentrations to match the extended time vector
steady_state_C1 = C1TFF{end}(end); % Steady-state mRNA concentration
steady_state_C2 = C2TFF{end}(end); % Steady-state protein concentration
steady_state_C3 = C3TFF{end}(end); % Steady-state NTPs concentration

% Append steady-state concentrations for the extended time
extended_C1 = [C1TFF{end}; repmat(steady_state_C1, length(extra_time_points), 1)];
extended_C2 = [C2TFF{end}; repmat(steady_state_C2, length(extra_time_points), 1)];
extended_C3 = [C3TFF{end}; repmat(steady_state_C3, length(extra_time_points), 1)];

% Perform integration to compute average concentrations of protein and NTPs post-CCDF
avg_conc_post_ccdf = [
    trapz(extended_td, extended_C1) / ccdf_totaltime, ... % Average mRNA concentration
    trapz(extended_td, extended_C2) / ccdf_totaltime, ... % Average protein concentration
    trapz(extended_td, extended_C3) / ccdf_totaltime  % Average NTPs concentration
];
%% Final Outputs
% x_positions and other values remain unchanged
x_positions = x_pts;

TFF_protein=C2TFF;
TFF_ntps=C3TFF;
end
