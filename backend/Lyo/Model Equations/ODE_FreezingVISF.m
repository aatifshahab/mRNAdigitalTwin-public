function outputs = ODE_FreezingVISF(t,y,ip)

% Important parameters and constants
Tw = cal_Tw(t,ip.Tc1);
Ta = cal_Tb(t,ip.Ta1);
Tg = cal_Tg(t,ip.Tg);
m = y(1);
T = y(2);
gm = ip.hm;
dHvap = ip.dHvap(T);
ms = ip.ms;
mw = m-ms;
Cps = ip.Cps;
Cpw = ip.Cpw;
Vl = (ms/ip.rhos) + (mw/ip.rhow);
Hl = Vl/(pi*ip.d^2/4);
A1 = pi*ip.d*Hl;
Ac = ip.Ac;
P = interp1(ip.Ptot(:,2),ip.Ptot(:,1),t);
psat = ip.Psat(T);
pc = 0;  % assume no water in the environment

% Density
rhow_sat = psat*ip.Mw/(ip.R*T);
rhow_c = pc*ip.Mw/(ip.R*T);
rho_sat = psat*ip.Mw/(ip.R*T) + (P - psat)*ip.MN2/(ip.R*T);
rho_c = pc*ip.Mw/(ip.R*T) + (P - pc)*ip.MN2/(ip.R*T);  % assume pure N2

% Mass fraction
xw_sat = rhow_sat/rho_sat;
xw_c = rhow_c/rho_c;

% Mass flux
jm = gm*Ac*(xw_sat-xw_c);

% Heat transfer
Qbot = ip.hs2*Ac*(Tg-T);
Qrad = ip.F1*ip.eps1*ip.SB*A1*(Tw^4-T^4);
Qside = ip.hs3*A1*(Tg-T);
Qtop = ip.hs1*Ac*(Ta-T);
Qevap = dHvap*jm;
Q = -Qevap+Qbot+Qside+Qtop+Qrad;
mCp = ms*Cps + mw*Cpw;

% ODEs
dmdt = -jm;
dTdt = Q/mCp;

% Output
outputs = [dmdt;dTdt];

return