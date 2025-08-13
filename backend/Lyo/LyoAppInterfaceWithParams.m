function [time1, time2, time3, time, massOfIce, boundWater, productTemperature, ...
    operatingPressure, operatingTemperature] = LyoAppInterfaceWithParams(fluidVolume, massFractionmRNA, InitfreezingTemperature, ...
InitprimaryDryingTemperature, InitsecondaryDryingTemperature, TempColdGasfreezing, ...
TempShelfprimaryDrying, TempShelfsecondaryDrying, Pressure,Rp0, Rp1, Rp2, hb2, hb3, fa, Ea)


% Need to change this based on the location
% Add paths using full paths
addpath('C:\Users\moha0095\mRNAdigitalTwin\backend\Lyo\Input Data');
addpath('C:\Users\moha0095\mRNAdigitalTwin\backend\Lyo\Model Equations');
addpath('C:\Users\moha0095\mRNAdigitalTwin\backend\Lyo\Events');
addpath('C:\Users\moha0095\mRNAdigitalTwin\backend\Lyo\Exporting Graphics');
addpath('C:\Users\moha0095\mRNAdigitalTwin\backend\Lyo\Plotting');
addpath('C:\Users\moha0095\mRNAdigitalTwin\backend\Lyo\Validation Data');
addpath('C:\Users\moha0095\mRNAdigitalTwin\backend\Lyo\Simulations');
addpath('C:\Users\moha0095\mRNAdigitalTwin\backend\Lyo\Calculations');


%% Pre-simulation
% Add paths

% Mode of simulation
Lyo = 'on';  % complete simulation for the entire lyo process            
FreezingSto = 'on';  % freezing with stochastic ice nucleation    
FreezingVISF = 'on';  % freezing with controlled nucleation via VISF
PrimDry = 'on';  % primary drying
Choked = 'on';  % primary drying with condenser dynamics
SecDry = 'on';  % secondary drying
%%
switch Lyo
case 'on'

% Parameters
ip0 = get_inputdata;
ip0.Vl = fluidVolume;  % user input from frontend
ip0.xs = massFractionmRNA;  % user input from frontend
ip0.T01 = InitfreezingTemperature;  % user input from forntend
ip0.T02 = InitprimaryDryingTemperature;  % user input from forntend
ip0.T03 = InitsecondaryDryingTemperature;  % user input from forntend
ip0.Tg(:,1) = TempColdGasfreezing;  % user input from forntend
ip0.Tb2 = TempShelfprimaryDrying;  % user input from forntend
ip0.Tb3 = TempShelfsecondaryDrying;  % user input from forntend
ip0.Ptot(:,1) = Pressure*1000;  % user input from forntend (kPa to Pa)
ip0.Rp0 = Rp0;  % cake resistance (m/s)
ip0.Rp1 = Rp1;  % cake resistance (1/s)
ip0.Rp2 = Rp2;  % cake resistance (1/m)
ip0.hb2 = hb2;      % W/m^2-K (example)
ip0.hb3 = hb3;      % W/m^2-K
ip0.fa  = fa;       % 1/s
ip0.Ea  = Ea;       % J/mol


ip = input_processing(ip0); % 

% Simulation and obtain solutions
% sol 1 = freezing, sol 2 = primary drying, sol 3 = secondary drying
tic; [sol1, sol2, sol3] = Sim_Lyo(ip); toc;  


%% Extract separate data
% Extract freezing data
time1 = sol1.t; Temp1 = sol1.T; Tb1 = sol1.Tg;

% Extract primary drying data
time2 = sol2.t; Temp2 = sol2.T; Tp2 = mean(Temp2,2); Tb2 = sol2.Tb;

% Extract secondary drying data
time3 = sol3.t; Temp3 = sol3.T; Tp3 = Temp3(:,end); Tb3 = sol3.Tb; cw = mean(sol3.cw,2);

% Combine
time = [time1;time2;time3];  % combined time
% S = [sol1.S;sol2.S;sol3.S];





% Mass of ice
mi1 = sol1.mi;
mi2 = cal_mi(sol2.S,mi1(end),ip.H2);
mi3 = zeros(length(time3),1);
%% Front end output
mi = [mi1;mi2;mi3]; % Mass of ice 
cw = [sol1.cw;sol2.cw;cw]; % bound water conc. 
Temp = [Temp1;Tp2;Tp3];  % Product temperature

boundWater = cw;
massOfIce     = mi;
productTemperature = Temp;
%% Frontend measured
P = [sol1.P;sol2.P;sol3.P]; % operating pressure
Tb = [Tb1; Tb2;Tb3];  % operating temperature

operatingTemperature = Tb;
operatingPressure = P;
end
end

