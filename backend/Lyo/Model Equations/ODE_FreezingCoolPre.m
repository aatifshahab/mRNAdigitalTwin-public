function outputs = ODE_FreezingCoolPre(t,y,ip)

% Important parameters and constants
Tw = cal_Tw(t,ip.Tc1);
Ta = cal_Tb(t,ip.Ta1);
Tg = cal_Tg(t,ip.Tg);
ms = ip.ms;
mw = ip.mw;
Cps = ip.Cps;
Cpw = ip.Cpw;
Ac = ip.Ac;
A1 = ip.A1l;

Qbot = ip.hs2*Ac*(Tg-y);
Qrad = ip.F1*ip.eps1*ip.SB*A1*(Tw^4-y^4);
Qside = ip.hs3*A1*(Tg-y);
Qtop = ip.hs1*Ac*(Ta-y);
mCp = ms*Cps + mw*Cpw;

dTdt = (Qbot+Qside+Qtop+Qrad)/mCp;

% Output
outputs = dTdt;

return