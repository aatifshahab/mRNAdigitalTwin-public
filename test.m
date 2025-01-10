qF = 5; %must be between 1-5 mL/min
c0 = [1; 1; 1];  %input from IVT; concentrations of [mRNA;protein;NTPs]; these can be taken from IVT GUI
X = 0.90; %setpoint user input: Conversion=qp/qF (Flowrate of permeate / Flowrate of Feed); Must be between 0<X<1
D=4.5; %mL/min  ; Flowrate of buffer for washing step
n_stages=3; % larger than 1, maximum is 5

%% Call DT_conc function
[Cout1, C1, Cmatrix1, Cout2, C2, Cmatrix2, Cout3, C3, Cmatrix3, time_points, x, td, C1TFF, C2TFF, C3TFF,Jcrit,Xactual] = membraneAPI(qF, c0, X,n_stages,D, 'VIBRO');

[Cout1, C1, Cmatrix1, ...
          Cout2, C2, Cmatrix2, ...
          Cout3, C3, Cmatrix3, ...
          time_points, x, td, ...
          C1TFF, C2TFF, C3TFF, ...
          Jcrit, Xactual, ...
          plotData] = ...
          membraneAPI(qF, c0, X, n_stages, D, 'VIBRO');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Figure 1: Four Subplots
%  (1) Concentration at Outlet vs. Time
%  (2) Concentration vs. Position for mRNA at selected snapshot times
%  (3) Concentration vs. Position for Protein at selected snapshot times
%  (4) Concentration vs. Position for NTPs at selected snapshot times

figure;

%% Subplot (1): Outlet Concentration vs Time
subplot(2, 2, 1);
hold on;
plot(plotData.OutletVsTime.time, plotData.OutletVsTime.mRNA, ...
     'LineWidth', 1.5, 'DisplayName', 'mRNA');
plot(plotData.OutletVsTime.time, plotData.OutletVsTime.protein, ...
     'LineWidth', 1.5, 'DisplayName', 'Protein');
plot(plotData.OutletVsTime.time, plotData.OutletVsTime.NTPs, ...
     'LineWidth', 1.5, 'DisplayName', 'NTPs');
xlabel('Time (min)');
ylabel('Concentration at Outlet (C_{out})');
title('Concentration at Outlet vs Time');
legend show;
grid on;

%% Subplot (2): Concentration vs Position (x) for mRNA
subplot(2, 2, 2);
hold on;
Snapshots_mRNA = plotData.Snapshots_mRNA;   % array of struct: .time, .x, .C
for i = 1:length(Snapshots_mRNA)
    plot(Snapshots_mRNA(i).x, ...
         Snapshots_mRNA(i).C, ...
         'LineWidth', 1.5, ...
         'DisplayName', sprintf('t = %.4f min', Snapshots_mRNA(i).time));
end
xlabel('Position (x)');
ylabel('Concentration (C)');
title('Concentration vs Position for mRNA');
legend show;
grid on;

%% Subplot (3): Concentration vs Position (x) for Protein
subplot(2, 2, 3);
hold on;
Snapshots_Protein = plotData.Snapshots_Protein;
for i = 1:length(Snapshots_Protein)
    plot(Snapshots_Protein(i).x, ...
         Snapshots_Protein(i).C, ...
         'LineWidth', 1.5, ...
         'DisplayName', sprintf('t = %.4f min', Snapshots_Protein(i).time));
end
xlabel('Position (x)');
ylabel('Concentration (C)');
title('Concentration vs Position for Protein');
legend show;
grid on;

%% Subplot (4): Concentration vs Position (x) for NTPs
subplot(2, 2, 4);
hold on;
Snapshots_NTPs = plotData.Snapshots_NTPs;
for i = 1:length(Snapshots_NTPs)
    plot(Snapshots_NTPs(i).x, ...
         Snapshots_NTPs(i).C, ...
         'LineWidth', 1.5, ...
         'DisplayName', sprintf('t = %.4f min', Snapshots_NTPs(i).time));
end
xlabel('Position (x)');
ylabel('Concentration (C)');
title('Concentration vs Position for NTPs');
legend show;
grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Figure 2: Diafiltration (Protein) in Each Stage vs Time

figure;
hold on;
DiafiltrationProtein = plotData.DiafiltrationProtein;  
% cell array {1 x n_stages}, each entry is a struct with fields:
%   .time   -> time vector for that stage
%   .C      -> concentration vector

for iStage = 1:length(DiafiltrationProtein)
    plot(DiafiltrationProtein{iStage}.time, ...
         DiafiltrationProtein{iStage}.C, ...
         'LineWidth', 1.5, ...
         'DisplayName', ['Stage ' num2str(iStage)]);
end
xlabel('Time (mins)', 'FontWeight', 'bold', 'FontSize', 14);
ylabel('Protein Concentration (mg/mL)', 'FontWeight', 'bold', 'FontSize', 14);
title('Protein Concentration at Each Stage vs Time', 'FontSize', 16);
legend show;
grid on;
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Figure 3: Diafiltration (NTPs) in Each Stage vs Time

figure;
hold on;
DiafiltrationNTPs = plotData.DiafiltrationNTPs;
% cell array {1 x n_stages}, each entry is a struct with fields:
%   .time   -> time vector
%   .C      -> NTPs concentration

for iStage = 1:length(DiafiltrationNTPs)
    plot(DiafiltrationNTPs{iStage}.time, ...
         DiafiltrationNTPs{iStage}.C, ...
         'LineWidth', 1.5, ...
         'DisplayName', ['Stage ' num2str(iStage)]);
end
xlabel('Time (mins)', 'FontWeight', 'bold', 'FontSize', 14);
ylabel('NTPs Concentration (mg/mL)', 'FontWeight', 'bold', 'FontSize', 14);
title('NTPs Concentration at Each Stage vs Time', 'FontSize', 16);
legend show;
grid on;
hold off;
