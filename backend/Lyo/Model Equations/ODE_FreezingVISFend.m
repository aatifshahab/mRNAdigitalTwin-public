function outputs = ODE_FreezingVISFend(t,y,ip)

% Important parameters and constants
m = y(1);
T = y(2);
gm = ip.hm;
dHvap = ip.dHvap(T);
ms = ip.ms;
mw = m-ms;
Cps = ip.Cps;
Cpw = ip.Cpw;
Ac = ip.Ac;
P = interp1(ip.Ptot(:,2),ip.Ptot(:,1),t);
psat = ip.Psat(T);
pc = 0;  % assume no water in the environment

rhow_sat = psat*ip.Mw/(ip.R*T);
rhow_c = pc*ip.Mw/(ip.R*T);
rho_sat = psat*ip.Mw/(ip.R*T) + (P - psat)*ip.MN2/(ip.R*T);
rho_c = pc*ip.Mw/(ip.R*T) + (P - pc)*ip.MN2/(ip.R*T);  % assume pure N2

xw_sat = rhow_sat/rho_sat;
xw_c = rhow_c/rho_c;

jm = gm*Ac*(xw_sat-xw_c);

Qbot = 0;
Qrad = 0;
Qside = 0;
Qtop = 0;
Qevap = dHvap*jm;
Q = -Qevap+Qbot+Qside+Qtop+Qrad;
% Q = -Qevap;
mCp = ms*Cps + mw*Cpw;


dmdt = -jm;
dTdt = Q/mCp;

% Output
outputs = [dmdt;dTdt];

return