function outputs = ODE_FreezingCoolPost(t,y,ip)

% Important parameters and constants
Tw = cal_Tw(t,ip.Tc1);
Ta = cal_Tb(t,ip.Ta1);
Tg = cal_Tg(t,ip.Tg);
ms = ip.ms_new;
mw = ip.mw - ip.mi_fin;
mi = ip.mi_fin;
Cps = ip.Cps;
Cpw = ip.Cpw;
Cpi = ip.Cpi;
Ac = ip.Ac;
A1 = ip.A1f;

% Heat transfer
Qbot = ip.hs2*Ac*(Tg-y);
Qrad = ip.F1*ip.eps1*ip.SB*A1*(Tw^4-y^4);
Qside = ip.hs3*A1*(Tg-y);
Qtop = ip.hs1*Ac*(Ta-y);
mCp = ms*Cps + mw*Cpw + mi*Cpi;

% ODEs
dTdt = (Qbot+Qside+Qtop+Qrad)/mCp;

% Output
outputs = dTdt;

return