function outputs = ODE_1stDrying_Lumped(t,y,ip)

rho = ip.rhof;
Cp = ip.Cpf;
Tw = cal_Tw(t,ip.Tc2);
H = ip.H2;
Ac = ip.Ac;
S = y(2);
T = y(1);
Rp = ip.Rp(S);
PwT = ip.PwT(T);
Pwc = ip.Pwc;
if PwT < Pwc
    Nw = 0;
else
    Nw = (PwT-Pwc)/Rp;
end
dHsub = ip.dHsub;
Tb = cal_Tb(t,ip.Tb2);
Ta = cal_Tb(t,ip.Ta2);
hb = ip.hb2;
f = ip.F2;
hrad = ip.eps1*ip.SB*ip.d*pi*(H);
Vf = Ac*(H-S);

qb = -Ac*hb*(T-Tb);
qa = -ip.ftop2*Ac*ip.eps1*ip.SB*(T^4-Ta^4);
qc = -f*hrad*(T^4-Tw^4);
qsub = -Nw*Ac*dHsub;
dSdt = Nw/(rho-ip.rhoe);
dydt = (1/(rho*Cp*Ac*(H-S)))*(qa+qb+qc+qsub);

outputs = [dydt; dSdt];

end