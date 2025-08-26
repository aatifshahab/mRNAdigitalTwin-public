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
