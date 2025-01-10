function outputs = Sim_Freezing_Sto(ip)

% Correct the gas temperature profile
if length(ip.Tg) > 1
    if ip.Tg(end,2) < ip.tpost1
        Tg_add = [ip.Tg(end,1), ip.tpost1];
        ip.Tg = [ip.Tg; Tg_add];
    end
end

% Parameters
prob_nuc = rand;  % probability for nucleation
tf = ip.tpost1;
dt = ip.dt1;  % data collection frequency from the ODE solver

% Initial conditions
T0 = ip.T01;

% ODE solver setup
y0 = T0;
opts_ode = odeset('RelTol',ip.tol,'AbsTol',ip.tol);
t = 0;
T = T0;

% Simulation
prob = 0;
tspan = [0 dt];

while prob<prob_nuc
tic; [t1,y1] = ode15s (@(t1,y1) ODE_FreezingCoolPre(t1,y1,ip), tspan, y0, opts_ode); toc;
Tend = y1(end);

if Tend < ip.Tf
    J = ip.bn*(ip.Tf-y1(end))^ip.kn;
    prob = prob + J*ip.Vl*dt;
end
t = [t;t1(end)];
T = [T;Tend];
tspan = [t1(end); t1(end)+dt];
y0 = Tend;

end
m_ice = zeros(length(T),1);

% No VISF
mloss = 0;
ip.mws_new = ip.mws - mloss;
ip.ms_new = ip.xs*ip.mws_new;  % mass of solute after evaporation via VISF
ip.mw_new = ip.mws_new-ip.ms_new;  % mass of water after evaporation via VISF
ip.m0 = ip.mw_new;  % total mass after evaporation via VISF

% Nucleation
K1 = 1;
K2 = -ip.Tf-ip.Tnuc-ip.dHfus*ip.mw/(ip.Cpws*ip.mws);
K3 = ip.dHfus*ip.mw*ip.Tf/(ip.Cpws*ip.mws) - ip.ms*(ip.Kf/ip.Ms)*ip.dHfus/(ip.Cpws*ip.mws) + ip.Tf*ip.Tnuc;
Teq_ini = 0.5*(-K2-sqrt(K2^2-4*K1*K3));  % new equilibrium temperature
mi = ip.mw - ip.ms*(ip.Kf/ip.Ms)/(ip.Tf-Teq_ini);  % mass of ice after first nucleation
m_ice = [m_ice;mi];

% Append new temperature data
t = [t;t(end)];
T = [T;Teq_ini];
tspan = (t(end):dt:tf)';
opts_ode2 = odeset('Event', @(t,y) event_freezing_complete(t,y,ip),'RelTol',ip.tol,'AbsTol',ip.tol);
tic; [t2,y2] = ode15s (@(t,y) ODE_FreezingNucl(t,y,ip), tspan, mi, opts_ode2); toc;
Teq = ip.Tf - ((ip.Kf/ip.Ms)*(ip.ms_new./(ip.m0-y2)));
ip.mi_fin = y2(end);
t = [t;t2];
T = [T;Teq];
m_ice = [m_ice;y2];

% Cooling
opts_ode3 = odeset('RelTol',1e-10,'AbsTol',1e-10);
y0 = T(end);
tspan = (t(end):dt:tf)';
tic; [t3,y3] = ode15s (@(t,y) ODE_FreezingCoolPost(t,y,ip), tspan, y0, opts_ode3); toc; 
t = [t;t3];
T = [T;y3];
m_ice = [m_ice; m_ice(end)*ones(length(t3),1)];

if t(end) < ip.tpost1
    t = [t; ip.tpost1];
    T = [T; T(end)];
    m_ice = [m_ice; m_ice(end)];
end

% Export
outputs.Tg = cal_Tg(t,ip.Tg);
outputs.Tw = cal_Tw(t,ip.Tc1);
outputs.t = t/3600;
outputs.T = T;
outputs.S = ip.S0*100*ones(length(outputs.t),1);
outputs.cw = ip.cw0*ones(length(outputs.t),1);
outputs.mi = m_ice;


return