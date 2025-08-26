function bound_final = run_cctc_model_with_params(states0_last, qmax_val, K_ad_L_val, k_ad_val, phi_val)
    % run_cctc_model_params: Compute final bound mRNA given key CCTC parameters
    % Inputs:
    %   states0_last   - inlet mRNA concentration (g/mL)
    %   qmax_val       - resin capacity (g/L resin)
    %   K_ad_L_val     - adsorption equilibrium constant (L/g)
    %   k_ad_val       - adsorption rate constant (1/s)
    %   phi_val        - bed packing fraction (solid/total)
    
    % Load baseline states0 vector and params struct
    data = load('func_input.mat');
    states0 = data.states0;    % vector of initial state values
    params = data.params;      % struct with default fields

    data.params.qmax  = 2.32;
    data.params.Vbin_frac  = [0.15 0.15 0.15];

    % Overwrite key parameters
    params.qmax   = qmax_val;
    params.K_ad_L = K_ad_L_val;
    params.k_ad   = k_ad_val;
    params.phi    = phi_val;

    % Overwrite inlet mRNA in last position of states0
    states0(end) = states0_last;

    % Time discretization (seconds)
    t_vec = (0:60:500)';

    % Solve ODE using original CCTC_main
    [tSol_sec, states_mat] = ode15s(@(t,st) CCTC_main(st, params), t_vec, states0);

    % Post-process: compute bound_mRNA (g/L resin) at each time step
    nTime = numel(tSol_sec);
    bound_mRNA = zeros(nTime,1);
    n = params.n;
    nbin = params.nbin;
    epsilonp = params.epsilonp;
    V = params.V;           % [n x nbin]

    for iTime = 1:nTime
        % extract q(i,k)
        q_range = states_mat(iTime, n*nbin+1 : 2*n*nbin);
        q_now   = reshape(q_range, [n, nbin]);
        totalBoundMass = 0;
        totalResinVol  = 0;
        for kR = 1:nbin
            for i = 1:n
                resinVol = (1 - epsilonp)*V(i,kR);
                totalBoundMass = totalBoundMass + q_now(i,kR)*resinVol;
                totalResinVol  = totalResinVol  + resinVol;
            end
        end
        bound_mRNA(iTime) = (totalResinVol>0) * (totalBoundMass/totalResinVol);
    end

    % Return only the final value
    bound_final = bound_mRNA(end);
end

function deriv = CCTC_main(states, params)
    
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
    q = states(n*nbin+1 : 2*n*nbin);
    q = reshape(q, [n, nbin]);
    cs = states(2*n*nbin+1);

    % Initialize
    pqpt = nan(size(q));
    pcpt = nan(size(c));
    pcspt = nan(nbin, 1);
    j = nan(n+1, nbin);
    jA = nan(n+1, nbin);

    % Loop through resin size fractions
    for k_R = 1:nbin
        pqpt(:, k_R) = k_ad * ( c(:, k_R).*(qmax - q(:, k_R)) - q(:, k_R) / K_ad_L );

        j(:, k_R) = [
            0;
            D_p * (c(2:end, k_R) - c(1:end-1, k_R)) / deltar(k_R);
            k_f * (cs - c(end, k_R))
        ];
        jA(:, k_R) = j(:, k_R) .* A(:, k_R);

        pcpt(:, k_R) = ...
            ( (jA(2:end, k_R) - jA(1:end-1, k_R)) ./ V(:, k_R) - pqpt(:, k_R) ) / epsilonp;

        pcspt(k_R) = - jA(end, k_R) / sum(V(:, k_R)) * phi / (1 - phi) * Vbin_frac(k_R);
    end

    pcspt_total = sum(pcspt);

    deriv = [
        pcpt(:);
        pqpt(:);
        pcspt_total
    ];
end