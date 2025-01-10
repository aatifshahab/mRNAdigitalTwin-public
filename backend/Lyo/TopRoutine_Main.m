% ==============================================================================
% This is a top-level routine for running general simulations.
% Mechanistic modeling of continuous lyophilization via suspended vials.
%
% Created by Prakitr Srisuma, 
% PhD, Braatz Group, MIT.
% ==============================================================================
close all; clear; clc;

%% Pre-simulation
% Add paths
addpath('Input Data', 'Model Equations', 'Events','Exporting Graphics','Plotting', ...
    'Validation Data','Simulations','Calculations');

% Mode of simulation
Lyo = 'on';  % complete simulation for the entire lyo process            
FreezingSto = 'on';  % freezing with stochastic ice nucleation    
FreezingVISF = 'on';  % freezing with controlled nucleation via VISF
PrimDry = 'on';  % primary drying
Choked = 'on';  % primary drying with condenser dynamics
SecDry = 'on';  % secondary drying


%% Complete continuous lyophilization
switch Lyo
case 'on'

% Parameters
ip0 = get_inputdata;
% ip0.Vl = 3e-6;  % modify any inputs here
ip = input_processing(ip0);

% Simulation and obtain solutions
% sol 1 = freezing, sol 2 = primary drying, sol 3 = secondary drying
tic; [sol1, sol2, sol3] = Sim_Lyo(ip); toc;  

% Plotting
fig_all = figure; 
plot_all(sol1,sol2,sol3,ip)

end


%% Freezing with stochastic ice nucleation
switch FreezingSto
case 'on'
ip0 = get_inputdata;
ip = overwrite_inputdata(ip0,'stochastic_freezing');
ip = input_processing(ip);

fig_freeze = figure; 
for i = 1:5
    rng(i+3)
    sol = Sim_Freezing_Sto(ip);
    time = sol.t; Temp = sol.T; Tg = sol.Tg;
    
    plot(time,Temp,'linewidth',1.5); hold on; 
    ylabel({'Product temperature (K)'}); xlabel('Time (hours)')

end

end


%% Freezing with VISF
switch FreezingVISF
case 'on'

% Parameters
ip0 = get_inputdata;
ip = input_processing(ip0);

% Simulation and obtain solutions
sol = Sim_Freezing_VISF(ip);
time = sol.t; Temp = sol.T; Tg = sol.Tg;

% Plotting
fig_VISF = figure; 
plot_Tavg(time,Temp); 

end


%% Primary Drying 
switch PrimDry
case 'on'

% Parameters
ip0 = get_inputdata;
ip = input_processing(ip0);

% Simulation and obtain solutions
sol = Sim_1stDrying(ip);
time = sol.t; Temp = sol.T; S = sol.S; 
Tp = mean(Temp,2); Tb = sol.Tb;

% Plotting
figure; plot_Tp(time,Tp);
figure; plot_S(time,S);

end


%% Primary Drying with Choked Flow 
switch Choked
case 'on'

% Parameters
ip0 = get_inputdata;
ip = input_processing(ip0);

% Simulation and obtain solutions
sol = Sim_1stDrying_Choked(ip);
time = sol.t; Temp = sol.T;
Tp = mean(Temp,2); Tb = sol.Tb;

% Plotting
fig_ch = figure;
tiledlayout(1,3,"TileSpacing","loose","Padding","compact")
nexttile(1); plot(time,sol.P,'linewidth',2); hold on
ylabel({'Pressure (Pa)'}); xlabel('Time (h)')
ylim([0 25]); xticks(0:2:10); text(.83,.1,'(A)','Units','normalized','FontSize', 10,'fontweight', 'bold');
graphics_setup('1by3s')
nexttile(2); plot(time,sol.S,'linewidth',2); hold on
ylabel({'Sublimation front position (cm)'}); xlabel('Time (h)'); xticks(0:2:10);
text(.83,.1,'(B)','Units','normalized','FontSize', 10,'fontweight', 'bold');
graphics_setup('1by3s')
nexttile(3); plot(time,Tp,'linewidth',2); hold on
ylabel({'Product temperature (K)'}); xlabel('Time (h)'); xticks(0:2:10);
text(.83,.1,'(C)','Units','normalized','FontSize', 10,'fontweight', 'bold');
graphics_setup('1by3s')

end


%% Secondary Drying
switch SecDry
case 'on'

% Parameters
ip0 = get_inputdata;
ip = input_processing(ip0);

% Simulation and obtain solutions
sol = Sim_2ndDrying(ip);
time = sol.t;
cw = sol.cw; cw_avg = mean(cw,2);
Temp = sol.T; Tp = Temp(:,end); Tb = sol.Tb;

% Plotting
fig_sec = figure;
plot_cw(time,cw_avg)

end


