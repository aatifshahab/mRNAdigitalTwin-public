function [tSol, unbound_mRNA] = run_cctc_model(states0_last_value)
    states0 =[];
    params=[];
    if isempty(states0)
        % Initialize states0 and params
        load('func_input.mat'); % Load parameters and initial states
        % load('states0.mat');
        % states0 = func_input.states0_initial;  % Initial state
        % params = func_input.params;
    end

    % Update the last value of 'states0' with the provided value
    states0(end) = states0_last_value;

    % Time vector for the current time step
    t_vec = (0:60:10800)';  % Modify TIME_STEP as needed

    % Solve the ODE
    [tSol, states] = ode15s(@(t, states) CCTC_to_aatif(states, params), t_vec, states0);

    % Extract unbound mRNA (cs over time)
    unbound_mRNA = states(:, end);  % Take the last value for continuity

   
    states0 = states(end, :);

    % time in hrs
    tSol = tSol/3600;
end


function deriv = CCTC_to_aatif(states, params)
    

    % Extract parameters from 'params'
    n = params.n;
    nbin = params.nbin;
    k_ad = params.k_ad;
    qmax = params.qmax;
    K_ad_L = params.K_ad_L;
    D_p = params.D_p;
    deltar = params.deltar;
    k_f = params.k_f;
    epsilonp = params.epsilonp;
    phi = params.phi;
    Vbin_frac = params.Vbin_frac;
    A = params.A;
    V = params.V;

    % Unroll states
    c = states(1:n*nbin);
    c = reshape(c, [n, nbin]);
    q = states(n*nbin+1:2*n*nbin);
    q = reshape(q, [n, nbin]);
    cs = states(2*n*nbin+1);

    % Initialize variables
    pqpt = nan(size(q));
    pcpt = nan(size(c));
    pcspt = nan(nbin, 1);
    j = nan(n+1, nbin);
    jA = nan(n+1, nbin);

    % Loop through resin size fractions
    for k_R = 1:nbin
        pqpt(:, k_R) = k_ad * (c(:, k_R) .* (qmax - q(:, k_R)) - q(:, k_R) / K_ad_L);

        j(:, k_R) = [0; D_p * (c(2:end, k_R) - c(1:end-1, k_R)) / deltar(k_R); k_f * (cs - c(end, k_R))];
        jA(:, k_R) = j(:, k_R) .* A(:, k_R);

        pcpt(:, k_R) = ((jA(2:end, k_R) - jA(1:end-1, k_R)) ./ V(:, k_R) - pqpt(:, k_R)) / epsilonp;
        pcspt(k_R) = -jA(end, k_R) / sum(V(:, k_R)) * phi / (1 - phi) * Vbin_frac(k_R);
    end

    % Total change in cs
    pcspt_total = sum(pcspt);

    % Assemble derivatives
    deriv = [pcpt(:); pqpt(:); pcspt_total];
end
