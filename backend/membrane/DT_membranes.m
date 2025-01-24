%% Can remove as needed
clear
clc
%% SCRIPT EXAMPLE
%% Inputs
qF = 5; %must be between 1-5 mL/min
c0 = [1; 1; 1];  %input from IVT; concentrations of [mRNA;protein;NTPs]; these can be taken from IVT GUI
X = 0.90; %setpoint user input: Conversion=qp/qF (Flowrate of permeate / Flowrate of Feed); Must be between 0<X<1
D=4.5; %mL/min  ; Flowrate of buffer for washing step
n_stages=3; % larger than 1, maximum is 5




%% Call DT_conc function
[Cout1, C1, Cmatrix1, Cout2, C2, Cmatrix2, Cout3, C3, Cmatrix3, time_points, x, td, C1TFF, C2TFF, C3TFF,Jcrit,Xactual] = DT_conc(qF, c0, X,n_stages,D, 'VIBRO');
% The output of this function contain all the information you need to plot
%Cout and C are for concentration, C1TFF, C2TFF, C3TFF are the
%concentration of mRNA protein and NTPS for each stage ==> structure is a
%1Xn_stages cell 

%% Display Critical Flux and Actual Conversion
% Examples of displays in the UGI
fprintf('Critical Flux (Jcrit): %.4f mL/m^2/min\n', Jcrit);
fprintf('Actual Conversion (Xactual): %.4f\n', Xactual);

%% Example outputs PLOTS
%% Plot 1: Concentration at Outlet vs Time
figure;
subplot(2, 2, 1);
plot(time_points, Cmatrix1(:, end), '-', 'LineWidth', 1.5, 'DisplayName', 'mRNA');
hold on;
plot(time_points, Cmatrix2(:, end), '-', 'LineWidth', 1.5, 'DisplayName', 'Protein');
plot(time_points, Cmatrix3(:, end), '-', 'LineWidth', 1.5, 'DisplayName', 'NTPs');
xlabel('Time (min)');
ylabel('Concentration at Outlet (C_{out})');
title('Concentration at Outlet vs Time');
legend show;
grid on;

%% Plot 2: Concentration vs Position (x) for mRNA
subplot(2, 2, 2);
interpolated_times = linspace(0, time_points(end), 10);
interpolated_indices = round(interp1(time_points, 1:length(time_points), interpolated_times));

for i = 1:length(interpolated_indices)
    idx = interpolated_indices(i);
    plot(x, Cmatrix1(idx, :), '-', 'LineWidth', 1.5, 'DisplayName', sprintf('t = %.4f min', time_points(idx)));
    hold on;
end
xlabel('Position (x)');
ylabel('Concentration (C)');
title('Concentration vs Position for mRNA');
legend show;
grid on;

%% Plot 3: Concentration vs Position (x) for Protein
subplot(2, 2, 3);
for i = 1:length(interpolated_indices)
    idx = interpolated_indices(i);
    plot(x, Cmatrix2(idx, :), '-', 'LineWidth', 1.5, 'DisplayName', sprintf('t = %.4f min', time_points(idx)));
    hold on;
end
xlabel('Position (x)');
ylabel('Concentration (C)');
title('Concentration vs Position for Protein');
legend show;
grid on;

%% Plot 4: Concentration vs Position (x) for NTPs
subplot(2, 2, 4);
for i = 1:length(interpolated_indices)
    idx = interpolated_indices(i);
    plot(x, Cmatrix3(idx, :), '-', 'LineWidth', 1.5, 'DisplayName', sprintf('t = %.4f min', time_points(idx)));
    hold on;
end
xlabel('Position (x)');
ylabel('Concentration (C)');
title('Concentration vs Position for NTPs');
legend show;
grid on;

%% Diafiltration
% Plot Protein (C2TFF) concentration at each stage vs time
figure;
for i = 1:length(C2TFF)
    plot(td, C2TFF{i}, 'LineWidth', 1.5, 'DisplayName', ['Stage ', num2str(i)]);
    hold on;
end
xlabel('Time (mins)', 'FontWeight', 'bold', 'FontSize', 14);
ylabel('Protein Concentration (mg/mL)', 'FontWeight', 'bold', 'FontSize', 14);
title('Protein Concentration at Each Stage vs Time', 'FontSize', 16);
legend show;
grid on;
hold off;

% Plot NTPs (C3TFF) concentration at each stage vs time
figure;
for i = 1:length(C3TFF)
    plot(td, C3TFF{i}, 'LineWidth', 1.5, 'DisplayName', ['Stage ', num2str(i)]);
    hold on;
end
xlabel('Time (mins)', 'FontWeight', 'bold', 'FontSize', 14);
ylabel('NTPs Concentration (mg/mL)', 'FontWeight', 'bold', 'FontSize', 14);
title('NTPs Concentration at Each Stage vs Time', 'FontSize', 16);
legend show;
grid on;
hold off;

%% FUNCTIONS

function [Cout1, C1, Cmatrix1, Cout2, C2, Cmatrix2, Cout3, C3, Cmatrix3, time_points, x, td, C1TFF, C2TFF, C3TFF,Jcrit,Xactual] = DT_conc(qF, c0, X,n_stages,D, filterType)
% INPUTS: last input takes in 'VIBRO' or 'HF' (2 geometrics/different
% devices)
    % Membrane dimensions and properties
    L = [20; 12]; % cm
    A = [0.002; 0.0035]; % m^2
    ID = [0.5; 0] * 10^-1; % cm
    W = 3; % cm width
    H = 0.17; % cm height
    Acs = [(ID(1) / 2)^2 * pi; H * W];

    % Select filter properties based on user input
    if strcmpi(filterType, 'HF')
        idx = 1; % Hollow Fiber
        dt = 10^-5;
        tfinal = 0.2; % mins
        L_HF = 23.9960;
        K_HF = 1.3333;
        n_HF = 16.3122;
        Jcrit = (L_HF * qF^n_HF) / (K_HF + qF); % HF flux model
        S = 0.24; % Retention coefficient for HF
    elseif strcmpi(filterType, 'VIBRO')
        idx = 2; % Rectangular Filter
        dt = 10^-3;
        tfinal = 24; % mins
        B = 18.3417;
        n = 0.8725;
        Jcrit = B * qF^n; % Power law model for VIBRO
        S = 0.45; % Retention coefficient for VIBRO
    else
        error('Invalid filter type. Choose either "HF" or "VIBRO".');
    end

    % Assign selected dimensions
    L = L(idx);
    A = A(idx);
    Acs = Acs(idx);

    % Diffusion coefficient
    Diff = 10^-12 * 10^4 * 60; % cm^2/min

    % Retention coefficient for protein
    R = ((1 - X)^S - (1 - X)) / X;

    % Define s values
    s = [0.01; 1 - R; 0.99];

    %% Adjust X for critical flux
    Jcrit_mLMM = Jcrit * 10^3 / 60; % mL/m^2/min
    Xcrit = Jcrit_mLMM * A / qF;

    if Xcrit > 1
        Xcrit = 0.95;
    end

    if Xcrit < X
        X = Xcrit;
    end

    Jactual = X * qF / A;
    Xactual = X;

    %% Solve PDEs for each component

    % mRNA
    [Cout1, C1, Cmatrix1, time_points, x] = PDEsolver(qF, c0(1), L, A, Diff, tfinal, Jactual, s(1), Acs, dt);

    % Protein
    [Cout2, C2, Cmatrix2, time_points, x] = PDEsolver(qF, c0(2), L, A, Diff, tfinal, Jactual, s(2), Acs, dt);

    % NTPs
    [Cout3, C3, Cmatrix3, time_points, x] = PDEsolver(qF, c0(3), L, A, Diff, tfinal, Jactual, s(3), Acs, dt);

    %% Counter-Current Diafiltration (CCDF)
    VTFF = 8; % Total volume (mL)
    R0 = qF * (1 - X); % Outlet flow rate for concentration step
    c0_ccdf = [Cout1(end); Cout2(end); Cout3(end)]; % Outlet concentration as new input
    P = D;

    td = []; % Time tracking for CCDF
    n = n_stages - 1;
    n_species = length(c0_ccdf);
    IC = repmat(c0_ccdf, n_stages, 1); % Initial conditions for CCDF
    
    C1TFF = cell(1, n_stages); % Storage for mRNA concentrations
    C2TFF = cell(1, n_stages); % Storage for Protein concentrations
    C3TFF = cell(1, n_stages); % Storage for NTPs concentrations
    dC2TFF1dt = 100; % Convergence criterion for Protein

    tprev = 0;
    tnext = tprev + 0.5;
    fun = @(t, y) CCDF(t, y, R0, P, D, n, c0_ccdf, s, VTFF); % ODE solver function

    while abs(dC2TFF1dt) > 10^-4
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

        tprev = tnext;
        tnext = tnext + 0.5;
        IC = y(end, :);
    end
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
