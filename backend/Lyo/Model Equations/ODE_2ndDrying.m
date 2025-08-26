function outputs = ODE_2ndDrying(t,y,ip)

% Extract all data
m = ip.nz3;
dz = ip.dz3;
Tb = cal_Tb(t,ip.Tb3);
rho = ip.rhoe;
Cp = ip.Cpe;
q1 = ip.ke/(ip.rhoe*ip.Cpe);
q2 = ip.rhod*ip.dHdes/(ip.rhoe*ip.Cpe);
f = ip.F3;
V = ip.Ac*ip.H3;
Tw = cal_Tw(t,ip.Tc3);
Ta = cal_Tb(t,ip.Ta3);
hrad = ip.eps1*ip.SB*ip.A3;

% States
T = y(1:m);
cs = y(m+1:2*m);

% ODE
dcdt = zeros(m,1);
dTdt = zeros(m,1);

% Desorption
for i = 1:m
    dcdt(i) = -cal_ks(T(i),ip)*cs(i);
    % dcdt(i) = -cal_ks(T(i),ip)*cs(i) + cal_ks(T(i),ip)*0.005;
end

% Heat transfer
for i = 2:m-1
    dTdt(i) = (q1/dz^2)*(T(i-1) - 2*T(i) + T(i+1)) + q2*dcdt(i) - f*hrad*(T(i)^4-Tw^4)/(V*rho*Cp) ;
end
dTdt(1) = 2*((q1/dz^2)*(T(2)-T(1))) + q2*dcdt(1) - 2*ip.ftop3*(ip.eps1*ip.SB/(ip.rhoe*ip.Cpe*dz))*(T(1)^4-Ta^4) - f*hrad*(T(i)^4-Tw^4)/(V*rho*Cp) ;
dTdt(m) = 2*((q1/dz^2)*(T(m-1)-T(m))) + q2*dcdt(m) - 2*(ip.hb3/(ip.rhoe*ip.Cpe*dz))*(T(m)-Tb) - f*hrad*(T(i)^4-Tw^4)/(V*rho*Cp);

% Outputs
outputs = [dTdt;dcdt];

return