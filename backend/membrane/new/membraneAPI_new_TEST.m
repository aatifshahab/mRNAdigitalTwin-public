%% membraneAPI_new_TEST
clear; clc;

% Test script for the membraneAPI_new function

% Parameters
qF = 1;  % Feed flow rate [mL/min]
c0 = [1; 0.5; 0.5];  % Initial concentrations [mRNA; Protein; NTPs] [mg/mL]
X = 0.9;  % Desired conversion
n_stages = 5;  % Number of TFF stages
D = 4;  % Diafiltration buffer flow rate [mL/min]
filterType = 'VIBRO';  % Filter type
V_IVT = 1;  % Initial IVT volume [L]

% Call the main function
[time_points, x_positions, Cmatrix_mRNA, Cmatrix_protein, Cmatrix_ntps, ...
 td, TFF_protein, TFF_ntps, t_ss, Reduction, V_final, ...
 avg_conc_pre_ccdf, avg_conc_post_ccdf, ccdf_time,X] = ...
    membraneAPI_new(qF, c0, X, n_stages, D, filterType, V_IVT);

% Display calculated outputs
disp('Actual conversion:');
disp(['X: ', num2str(X)]);

disp('Steady-State Times (t_ss):');
disp(['mRNA: ', num2str(t_ss(1)), ' mins']);
disp(['Protein: ', num2str(t_ss(2)), ' mins']);
disp(['NTPs: ', num2str(t_ss(3)), ' mins']);

disp('CCDF Time to Reach Steady State:');
disp([num2str(ccdf_time), ' mins']);

disp('Reduction Factors after CCDF reaches steady state (outflow):');
disp(['Protein Reduction: ', num2str(Reduction(1)), '%']);
disp(['NTP Reduction: ', num2str(Reduction(2)), '%']);

disp('Final Volume (V_final):');
disp([num2str(V_final), ' mL']);

disp('Average Concentrations after full time:');
disp(['Pre-CCDF: ', num2str(avg_conc_pre_ccdf), ' mg/mL']);
disp(['Post-CCDF: ', num2str(avg_conc_post_ccdf), ' mg/mL']);

% Plot results
figure;

% Subplot 1: Outlet Concentration vs Time (up to 2 * t_ss)
subplot(2, 2, 1);
hold on;
plot(time_points(time_points <= 2 * max(t_ss)), ...
     Cmatrix_mRNA(time_points <= 2 * max(t_ss), end), '-', 'LineWidth', 1.5, 'DisplayName', 'mRNA');
plot(time_points(time_points <= 2 * max(t_ss)), ...
     Cmatrix_protein(time_points <= 2 * max(t_ss), end), '--', 'LineWidth', 1.5, 'DisplayName', 'Protein');
plot(time_points(time_points <= 2 * max(t_ss)), ...
     Cmatrix_ntps(time_points <= 2 * max(t_ss), end), ':', 'LineWidth', 1.5, 'DisplayName', 'NTPs');
hold off;
xlabel('Time (mins)');
ylabel('Concentration (mg/mL)');
title('Outlet Concentration vs Time');
legend('show');
grid on;

% Subplot 2: mRNA Concentration vs Position
subplot(2, 2, 2);
hold on;
time_indices = round(linspace(1, find(time_points >= 2 * max(t_ss), 1), 5));
for i = 1:length(time_indices)
    plot(x_positions, Cmatrix_mRNA(time_indices(i), :), 'LineWidth', 1.5, ...
         'DisplayName', sprintf('t = %.1f mins', time_points(time_indices(i))));
end
hold off;
xlabel('Position along the membrane (cm)');
ylabel('Concentration (mg/mL)');
title('mRNA Concentration vs Position');
legend('show');
grid on;

% Subplot 3: Protein Concentration vs Position
subplot(2, 2, 3);
hold on;
for i = 1:length(time_indices)
    plot(x_positions, Cmatrix_protein(time_indices(i), :), 'LineWidth', 1.5, ...
         'DisplayName', sprintf('t = %.1f mins', time_points(time_indices(i))));
end
hold off;
xlabel('Position along the membrane (cm)');
ylabel('Concentration (mg/mL)');
title('Protein Concentration vs Position');
legend('show');
grid on;

% Subplot 4: NTP Concentration vs Position
subplot(2, 2, 4);
hold on;
for i = 1:length(time_indices)
    plot(x_positions, Cmatrix_ntps(time_indices(i), :), 'LineWidth', 1.5, ...
         'DisplayName', sprintf('t = %.1f mins', time_points(time_indices(i))));
end
hold off;
xlabel('Position along the membrane (cm)');
ylabel('Concentration (mg/mL)');
title('NTP Concentration vs Position');
legend('show');
grid on;

% Diafiltration Plots
figure;

% Protein Diafiltration Plot
subplot(1, 2, 1);
hold on;
for stg = 1:n_stages
    plot(td, TFF_protein{stg}, 'LineWidth', 1.5, 'DisplayName', sprintf('Stage %d', stg));
end
hold off;
xlabel('Time (mins)');
ylabel('Protein Concentration (mg/mL)');
title('Protein Concentration vs Time (Diafiltration)');
legend('show');
grid on;

% NTP Diafiltration Plot
subplot(1, 2, 2);
hold on;
for stg = 1:n_stages
    plot(td, TFF_ntps{stg}, 'LineWidth', 1.5, 'DisplayName', sprintf('Stage %d', stg));
end
hold off;
xlabel('Time (mins)');
ylabel('NTP Concentration (mg/mL)');
title('NTP Concentration vs Time (Diafiltration)');
legend('show');
grid on;
