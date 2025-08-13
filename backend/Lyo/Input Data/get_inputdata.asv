function outputs = get_inputdata

% ** Some symbols used in this code are different from those appearing in the
% manuscript. Please refer to the description of each symbol. **

%% Properties
ip.dHvap = @(x) 2257000*((1-x/647.1)/(1-373.15/647.1))^0.38;  % heat of vaporization (J/kg) 
ip.dHfus = 334000;  % heat of fusion (J/kg) 
ip.dHdes = 2.68e6;  % heat of desoprtion (J/kg) 
ip.dHsub = 2.84e6;  % heat of sublimation (J/kg)
ip.Cpw = 4187;  % heat capacity liquid water (J/kg-K)
ip.Cpi = 2108;  % heat capacity ice (J/kg-K)
ip.Cps = 1240;  % heat capacity solute (J/kg-K)
ip.Cpe = 2590;  % effective heat capacity of the dried region (J/kgK)
ip.xs = 0.05;  % mass fraction of solute in solution
ip.rhos = 1587.9;  % density of solute (kg/m3)
ip.rhow = 1000;  % density of water (kg/m3)
ip.rhoi = 917;  % density of ice (kg/m3)
ip.rhoe = 215;  % effective density of the dried region (kg/m3)
ip.rhod = 212.21;  % density of dried material (kg/m3)
ip.ks = 0.126;  % thermal conductivity of sucrose (W/mK) 
ip.kw = 0.598;  % thermal conductivity of water (W/mK)
ip.ki = 2.25;  % thermal conductivity of ice (W/mK)
ip.ke = 0.217;  % effective thermal conductivity of the dry region (W/mK)
ip.Ms = 0.3423;  % molecular weight of solute
ip.Kf = 1.86;  % colligative constant (kg-K/mol)

% Vials
ip.kgl = 1;  % glass vial thermal conductivity (W/mK)
ip.tgl = 1e-3;  % thickness of glass vial (m)
ip.Hgl = 0.045;  % vial height (m)
ip.rhogl = 2300;  % density of glass (kg/m3)
ip.Cpgl = 840;  % heat capacity of glass (J/kgK)
ip.d = 0.024;  % vial diameter (m)
ip.eps1 = 0.8;  % emissivity of glass
ip.eps2 = 0.3;  % emissivity of stainless steel
ip.SB = 5.67e-8;  % Stefan-Boltzmann constant (W/m2K)

%% Freezing 
% usually denoted with 1

ip.freezing = "VISF";  % suspended, VISF, or 2D
ip.Vl = 3e-6;  % volume of frozen material (m3)
ip.hs1 = 5;  % heat transfer coefficient at the top (w/m2-K)
ip.hs2 = 10;  % heat transfer coefficient at the bottom (w/m2-K)
ip.hs3 = 8;  % heat transfer coefficient on the side (w/m2-K)
ip.T01 = 298.15;  % initial temperature (K)
% ip.Tc1 = 280;  % constant wall temperature (K)
ip.Tc1 = [273, 273, 240, 240; 0, 2*3600+200, 2*3600+300, 4*3600]';  % time profile wall temperature (K)
ip.Ta1 = [273, 273, 240, 240; 0, 2*3600+200, 2*3600+300, 4*3600]';  % top surface temperature, assumed equal to Tw (K)
ip.Tf = 273.15;  % equilibrium freezing temperature (K)
ip.Tnuc = 268;  % nucleation temperature (K)
ip.Tg = [268, 268, 230, 230; 0, 2*3600+200, 2*3600+300, 4*3600]';  % gas temperature time profile for VISF (K)
ip.xi = 0.95;  % mass fraction for complete freezing
ip.tini1 = 0;  % initial time (s)
ip.tpre1 = 2*3600;  % pre-conditioning time, used for VISF only (s)
ip.tpost1 = 4*3600;  % final time (s)
ip.F1 = .78;  % fraction of radiative energy going to the product (assumed a vial between 2 vials)
ip.bn = 1e-9;
ip.kn = 12;

% VISF freezing
ip.Mw = 18e-2;  % molecular weight of water
ip.MN2 = 28e-2;  % molecular weight of nitrogen, inert
ip.hm = 6.34e-3;  % mass transfer coefficient (kg/m2-s)
ip.tVISF = 200;  % time for VISF
ip.Psat = @(x) 1e3*exp(16.3872-3885.7/(x-273.15 + 230.17));  % saturated pressure (Pa)
ip.Ptot = [1e5, 1e4, 1e4, 1e5; 0, 60, 60+ip.tVISF, 2*60+ip.tVISF]';  % pressure profile (Pa)

%% Primary drying
% usually denoted with 2

ip.hb2 = 15;  % heat transfer coefficient at the bottom surface (w/m2K)
ip.T02 = 228;  % initial temperature (K)
ip.Tb2 = 270;  % constant shelf temperature (K)
% ip.Tb2 = [280,280,280;0,3600,1e7]';  % shelf temperature profile (K)
% ip.Tb2 = @(x) min(263+(1/60)*x,263);  % shelf temperature profile (K)
ip.Tc2 = 265;  % constant wall temperature (K)
% ip.Tc2 = [270, 270; 0, 1e7]';  % time profile wall temperature (K)
ip.Ta2 = 265;  % top surface temperature (K)
% ip.Ta2 = [270, 270; 0, 1e7]';  % top surface temperature profile (K)
ip.S0 = 0;  % initial position of sublimation front (m)
ip.PwT = @(x) exp(-6139.9/x + 28.8912);  % saturated pressure (Pa)
ip.Pwc = 3;  % water vapor pressure in chamber (Pa)
ip.Rp0 = 1.5e4;  % cake resistance (m/s)
ip.Rp1 = 3e7;  % cake resistance (1/s)
ip.Rp2 = 1e1;  % cake resistance (1/m)
ip.tpost2 = 1*3600;  % period after primary drying (s)
ip.F2 = .78;  % fraction of radiative energy going to the product (assumed a vial between 2 vials)
ip.ftop2 = 1;  % fraction of heat from the top surface

% Condensor failure
ip.Vc = .118;
ip.Te = 260;
ip.jmax = 1.8e-5;  % maximum condenser flow (choked)
ip.nvial = 200;

%% Secondary Drying
% usually denoted with 3

ip.hb3 = ip.hb2;  % heat transfer coefficient at the bottom surface (w/m2K)
ip.Tb3 = 295;  % shelf temperature profile (K)
% ip.Tb3 = [280,313,313;0,1000,1e7]';  % shelf temperature time profile
% ip.Tb3 = @(x) min(273+(.2/60)*x,313);  % shelf temperature time profile
ip.T03 = 273;  % initial temperature (K)
ip.Tc3 = 290;  % constant wall temperature (K)
ip.Ta3 = 290;  % top surface temperature (K)
ip.cw0 = 0.088;  % initial bound water concentration (kg water/kg solid)
ip.cw0_min = 0.0314;  % minimun bound water concentration (kg water/kg solid)
ip.cw0_max = 0.6415;  % maximum bound water concentration (kg water/kg solid)
ip.cfin = .01;  % target bound water concentration (kg water/kg solid)
ip.Ea = 6500;  % activation energy (J/mol)
ip.fa = 1.5e-3;  % frequency factor (1/s)
ip.R = 8.314;  % gas constant (J/mol-K)
ip.F3 = .78;  % fraction of radiative energy going to the product (assumed a vial between 2 vials)
ip.ftop3 = 1;  % fraction of heat from the top surface

%% Numerics and Discretization
ip.tend = 1e7;  % final time (s)
ip.tol = 1e-9;  % tolerance
ip.mr1 = 20;  % number of nodes (freezing, 2D)
ip.mz1 = 20;  % number of nodes (freezing, 2D)
ip.nz2 = 20;  % number of nodes (primary drying)
ip.nz3 = 20;  % number of nodes (secondary drying)
ip.dt1 = 50;  % time discretization; freezing (s)
ip.dt2 = 50;  % time discretization; primary drying (s)
ip.dt3 = 50;  % time discretization; secondary drying (s)

%% Export
outputs = ip;

return