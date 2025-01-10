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
    Xactual, ...
    V_final ] = ...
    membraneAPI_new(qF, c0, X, n_stages, D, filterType, tfinal_total)
% membraneAPI
% Simulates Tangential Flow Filtration (TFF) for mRNA purification.
%
% Outputs:
%   time_points          - Array of time points for concentration profiles.
%   x_positions          - Spatial positions along the membrane.
%   Cmatrix_mRNA         - Concentration profiles for mRNA.
%   Cmatrix_protein      - Concentration profiles for protein.
%   Cmatrix_ntps         - Concentration profiles for NTPs.
%   interpolated_times   - Snapshot times for plotting.
%   interpolated_indices - Indices corresponding to snapshot times.
%   td                   - Diafiltration time vector.
%   TFF_protein          - Protein concentration across stages over time.
%   TFF_ntps             - NTPs concentration across stages over time.
%   Jcrit                - Critical flux value.
%   Xactual              - Actual conversion achieved.
%   V_final              - Final volume for chromatography.
%
% Inputs:
%   qF           - Feed flow rate [mL/min].
%   c0           - Initial concentrations [mRNA; protein; NTPs] [mg/mL].
%   X            - Desired conversion (0 < X < 1).
%   n_stages     - Number of TFF stages (>=2).
%   D            - Diafiltration buffer flow rate [mL/min].
%   filterType   - 'HF' for Hollow Fiber or 'VIBRO' for Vibro filters.
%   tfinal_total - Total simulation time [minutes], e.g., 600 for 10 hours.

    %% 1) Membrane geometry and base parameters
    L_all   = [20; 12];          % cm
    A_all   = [0.002; 0.0035];   % m^2
    ID      = [0.5; 0] * 1e-1;   % cm
    W       = 3;                 % cm
    H       = 0.17;              % cm
    Acs_all = [(ID(1)/2)^2*pi; (W*H)];  % Effective cross-sectional area
    
    %% 2) Select filter properties based on filterType
    if strcmpi(filterType, 'HF')
        idx       = 1;  % Hollow Fiber
        dt        = 1e-5;          % Time step [min]
        tfinal    = tfinal_total;  % Total simulation time [min]
        L_HF      = 23.9960;
        K_HF      = 1.3333;
        n_HF      = 16.3122;
        Jcrit_val = (L_HF * (qF^n_HF)) / (K_HF + qF);  % Critical flux for HF
        S         = 0.24; % Retention coefficient
    elseif strcmpi(filterType, 'VIBRO')
        idx       = 2;  % Vibro
        dt        = 1e-3;          % Time step [min]
        tfinal    = tfinal_total;  % Total simulation time [min]
        B         = 18.3417;
        n_v       = 0.8725;
        Jcrit_val = B * (qF^n_v);   % Critical flux for Vibro
        S         = 0.45; 
    else
        error('Invalid filter type. Choose "HF" or "VIBRO".');
    end

    L   = L_all(idx);
    A   = A_all(idx);
    Acs = Acs_all(idx);

    %% 3) Diffusion coefficient [cm^2/min]
    Diff = 1e-12 * 1e4 * 60;  % Adjusted to [cm^2/min]

    %% 4) Retention coefficients for components
    R = ((1 - X)^S - (1 - X)) / X;
    s = [0.01; 1 - R; 0.99];  % Retention factors [mRNA, protein, NTPs]

    %% 5) Adjust X for critical flux
    Jcrit_mLMM = (Jcrit_val * 1e3) / 60;  % mL/(m^2·min)
    Xcrit      = (Jcrit_mLMM * A) / qF;
    if Xcrit > 1
        Xcrit = 0.95;  % Cap Xcrit at 0.95 if it exceeds 1
    end
    if Xcrit < X
        X = Xcrit;  % Adjust X to not exceed critical conversion
    end
    Jactual     = X * (qF / A);  % Actual permeate flux
    Xactual_val = X;             % Actual conversion

    %% 6) Solve PDE for each component over the entire simulation time
    [Cout1, ~, Cmatrix1, time_pts, x_pts] = ...
        PDEsolver(qF, c0(1), L, A, Diff, tfinal, Jactual, s(1), Acs, dt);
    
    [Cout2, ~, Cmatrix2, ~, ~] = ...
        PDEsolver(qF, c0(2), L, A, Diff, tfinal, Jactual, s(2), Acs, dt);
    
    [Cout3, ~, Cmatrix3, ~, ~] = ...
        PDEsolver(qF, c0(3), L, A, Diff, tfinal, Jactual, s(3), Acs, dt);
    
    %% 7) Assign concentration matrices
    Cmatrix_mRNA = Cmatrix1;
    Cmatrix_protein = Cmatrix2;
    Cmatrix_ntps = Cmatrix3;
    
    %% 8) Prepare interpolation data for snapshots across position
    n_interps = 10;
    interpolated_times = linspace(0, time_pts(end), n_interps);
    interpolated_indices = round(interp1(time_pts, 1:length(time_pts), interpolated_times));
    
    %% 9) Diafiltration (CCDF) Stage
    VTFF = 8;  % Total volume (mL)
    R0   = qF * (1 - X);  % Outlet flow rate for concentration step
    c0_ccdf = [Cout1(end); Cout2(end); Cout3(end)];  % Concentrations at membrane end
    P    = D;  % Diafiltration buffer flow rate [mL/min]
    
    % Define Maximum Diafiltration Time (e.g., 600 minutes)
    tmax_diafiltration = 600;  % minutes
    
    % Initialize ODE solver variables
    td_vec   = [];
    n_dia    = n_stages - 1;
    n_sp     = length(c0_ccdf);
    IC       = repmat(c0_ccdf, n_stages, 1);  % Initial conditions for ODE
    
    C1TFF = cell(1, n_stages);  % mRNA concentrations across stages
    C2TFF = cell(1, n_stages);  % Protein concentrations across stages
    C3TFF = cell(1, n_stages);  % NTPs concentrations across stages
    
    % Define ODE function
    fun = @(t, y) CCDF(t, y, R0, P, D, n_dia, c0_ccdf, s, VTFF);
    
    % Define time step and number of iterations
    tstep = 0.5;  % minutes per iteration
    num_iterations = ceil(tmax_diafiltration / tstep);
    
    tprev = 0;
    
    for iter = 1:num_iterations
        tspan = [tprev, tprev + tstep];
        [t_ode, y_ode] = ode15s(fun, tspan, IC);
        td_vec = [td_vec; t_ode];
    
        for stg = 1:n_stages
            base_idx      = 1 + (stg - 1)*n_sp;
            C1TFF{stg}    = [C1TFF{stg}; y_ode(:, base_idx)];
            C2TFF{stg}    = [C2TFF{stg}; y_ode(:, base_idx+1)];
            C3TFF{stg}    = [C3TFF{stg}; y_ode(:, base_idx+2)];
        end
    
        % Update for next iteration
        tprev = tprev + tstep;
        IC    = y_ode(end, :);
    end
    
    %% 10) Extract Diafiltration Data
    td = td_vec;
    for stg = 1:n_stages
        TFF_protein{stg} = C2TFF{stg};
        TFF_ntps{stg} = C3TFF{stg};
    end
    
    %% 11) Calculate Final Volume for Chromatography
    % Mass balance: C_initial * V_initial = C_final * V_final
    % Let's assume 3000 mL (3 L), will change based on IVT
    V_initial = 3000;  % mL
    mass_mRNA_initial = c0(1) * V_initial;  % [mg]
    mass_mRNA_final = Xactual_val * mass_mRNA_initial;  % [mg]
    
  % final mRNA concentration (mg/mL)
    C_final_mRNA = Cmatrix_mRNA(end, end);
    
    % Check if C_final_mRNA is not zero or negative
    if C_final_mRNA <= 0
        error('Final mRNA concentration is zero or negative. Check simulation parameters.');
    end
    
    % Calculate V_final [mL]
    V_final = mass_mRNA_final / C_final_mRNA;
    
    %% 12) Prepare final outputs
    time_points          = time_pts;           % 1×N
    x_positions          = x_pts;             % 1×M
   
    
    Jcrit                = Jcrit_val;         % Critical flux [mL/(m²·min)]
    Xactual              = Xactual_val;       % Actual conversion

end

