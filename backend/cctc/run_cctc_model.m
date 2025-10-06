function [tSol, unbound_mRNA, bound_mRNA] = run_cctc_model(states0_last_value, overrides)
    % This version extends original function to also compute
    % the bound mRNA concentration (g/L of resin) at each time point.
    if nargin < 2, overrides = struct(); end
    % --------------------- Load initial states & params ---------------------
    states0 = [];
    params  = [];
    if isempty(states0)
        load('func_input.mat'); 
    end

    % params.qmax  = 2.32;
    % params.Vbin_frac  = [0.15 0.15 0.15];
    % Overwrite the last entry of 'states0' with the provided external mRNA
    % concentration (from previous units)

    % === Safe defaults (keeps current behavior) ===
    if ~isfield(params,'qmax'),      params.qmax = 2.32;     end
    if ~isfield(params,'K_ad_L'),    params.K_ad_L = 1.0;    end
    if ~isfield(params,'k_ad'),      params.k_ad = 0.1;      end
    if ~isfield(params,'D_p'),       params.D_p = 1e-10;     end
    if ~isfield(params,'k_f'),       params.k_f = 1e-5;      end
    if ~isfield(params,'epsilonp'),  params.epsilonp = 0.35; end
    if ~isfield(params,'phi'),       params.phi = 0.40;      end
    if ~isfield(params,'Vbin_frac'), params.Vbin_frac = [0.15 0.15 0.15]; end

    % === Apply user overrides ===
    fn = fieldnames(overrides);
    for i = 1:numel(fn)
        params.(fn{i}) = overrides.(fn{i});
    end
    % optional: map Vbin_frac_1..3 into vector if user provided scalars
    for k = 1:3
        f = sprintf('Vbin_frac_%d', k);
        if isfield(params, f)
            params.Vbin_frac(k) = params.(f);
        end
    end


    states0(end) = states0_last_value; 

    
    % === Time control (optional overrides t_vec) ===
    t_final_s = 500; dt_s = 60;
    if isfield(overrides,'t_final_s'), t_final_s = overrides.t_final_s; end
    if isfield(overrides,'dt_s'),      dt_s      = overrides.dt_s;      end
    t_vec = (0:dt_s:t_final_s)';
    % t_vec = (0:60:500)'; 


    % --------------------------- Solve the ODE ------------------------------
    [tSol_seconds, states_matrix] = ode15s(@(t, st) CCTC_main(st, params), t_vec, states0);

    % Convert time to hours
    tSol = tSol_seconds / 3600;

    % ------------------------- Extract "unbound mRNA" -----------------------
    
    % last state in the vector = states_matrix(:, end).
    unbound_mRNA = states_matrix(:, end);

    % ----------------- Post-process to find "bound_mRNA" in g/L ------------
    % "bound_mRNA(iTime)" as the *volume-weighted average* of q
    % across all resin shells, i.e. total bound mass / total resin volume.
    % Here:
    %   q(i,k_R) [g / L resin],
    %   Resin volume for shell (i,k_R) = (1 - epsilonp)*V(i, k_R).

    % Pre-allocate
    nTime = length(tSol);
    bound_mRNA = zeros(nTime, 1);

    % parameters
    n         = params.n;
    nbin      = params.nbin;
    epsilonp  = params.epsilonp;
    V         = params.V;          % size [n, nbin]

    for iTime = 1:nTime
        % At time iTime, the state vector is: c(1..n*nbin), q(1..n*nbin), cs
        % Extract q:
        q_range = states_matrix(iTime, n*nbin+1 : 2*n*nbin);
        q_now   = reshape(q_range, [n, nbin]);

        % Sum total bound mass and total resin volume
        totalBoundMass_g  = 0;
        totalResinVolumeL = 0;
        for k_R = 1:nbin
            for i = 1:n
                % "Solid" resin volume in shell i,k_R
                resinVol_L = (1 - epsilonp) * V(i, k_R);

                % local bound mass = q(i,k_R) [g/L resin] * resinVol_L [L]
                totalBoundMass_g  = totalBoundMass_g + q_now(i, k_R) * resinVol_L;
                totalResinVolumeL = totalResinVolumeL + resinVol_L;
            end
        end

        % Average bound concentration (g/L of total resin)
        if totalResinVolumeL > 0
            bound_mRNA(iTime) = totalBoundMass_g / totalResinVolumeL; 
        else
            bound_mRNA(iTime) = 0;
        end
    end
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
