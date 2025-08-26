function outputs = ODE_1stDrying(t,T,ip)

% Extract all data
m = ip.nz2;
dpsi = ip.dpsi;
psi = ip.psi;
H = ip.H2;

alp = ip.alpf;
rho = ip.rhof;
Cp = ip.Cpf;
k = ip.kf;

dHsub = ip.dHsub;
hb = ip.hb2;
f = ip.F2;

Tb = cal_Tb(t,ip.Tb2);
Ta = cal_Tb(t,ip.Ta2);
Tw = cal_Tw(t,ip.Tc2);

% States
Ti = T(1);
S = T(end);
Rp = ip.Rp(S);
PwT = ip.PwT(Ti);
Pwc = ip.Pwc;
if PwT < Pwc
    Nw = 0;
else
    Nw = (PwT-Pwc)/Rp;
end

hrad = ip.eps1*ip.SB*ip.A2;
Vf = ip.Ac*(H-S);

% ODEs
dSdt = Nw/(rho-ip.rhoe);  % interface
dTdt = zeros(m,1);  % temperature
for i = 2:m-1
    dTdt(i) = alp*(1/(H-S)^2)*(1/dpsi^2)*(T(i-1)-2*T(i)+T(i+1)) - ((psi(i)-1)*dSdt/(H-S))*(T(i+1)-T(i-1))/(2*dpsi) - f*hrad*(T(i)^4-Tw^4)/(Vf*rho*Cp);
end
dTdt(1) = alp*(1/(H-S)^2)*(1/dpsi^2)*(2*T(2)-2*T(1)-2*Nw*dpsi*dHsub*(H-S)/k - ip.ftop2*ip.eps1*ip.SB*(T(1)^4-Ta^4)*2*dpsi*(H-S)/k)...
        -((psi(1)-1)*dSdt/(H-S))*((H-S)*Nw*dHsub/k + ip.ftop2*ip.eps1*ip.SB*(T(1)^4-Ta^4)*(H-S)/k) - f*hrad*(T(1)^4-Tw^4)/(Vf*rho*Cp);
dTdt(m) = alp*(1/(H-S)^2)*(1/dpsi^2)*(2*T(m-1)-2*T(m)+2*(S-H)*hb*dpsi*(T(m)-Tb)/k)-((psi(m)-1)*dSdt/(H-S))*((S-H)*hb*(T(m)-Tb)/k) - f*hrad*(T(m)^4-Tw^4)/(Vf*rho*Cp);

% Outputs
outputs = [dTdt; dSdt];


end