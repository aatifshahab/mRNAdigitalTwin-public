function outputs = Sim_Freezing_2D(ip)

% Correct the gas temperature profile
if length(ip.Tg) > 1
    if ip.Tg(end,2) < ip.tpost1
        Tg_add = [ip.Tg(end,1), ip.tpost1];
        ip.Tg = [ip.Tg; Tg_add];
    end
end

% Parameters
mz = ip.mz1;
mr = ip.mr1;
tf = ip.tpost1;
dt = ip.dt1;  % data collection frequency from the ODE solver
tspan = (0:dt:tf)';  % define the time span

% Initial conditions
T0 = ip.T01;

% ODE solver setup
y0 = T0*ones(mz,mr,1);
opts_ode = odeset('Event', @(t,y) event_cooling_complete(t,y,ip),'RelTol',ip.tol,'AbsTol',ip.tol);
%opts_ode = odeset('RelTol',1e-6,'AbsTol',1e-6);

% Simulation
tic; [t1,y1] = ode15s (@(t1,y1) ODE_FreezingCoolPre_2D(t1,y1,ip), tspan, y0, opts_ode); toc;
t = t1;
T = y1;

mloss = 0;
ip.mws_new = ip.mws - mloss;
ip.ms_new = ip.xs*ip.mws_new;
ip.mw_new = ip.mws_new-ip.ms_new;
ip.m0 = ip.mw_new;

K1 = 1;
K2 = -ip.Tf-ip.Tnuc-ip.dHfus*ip.mw/(ip.Cpws*ip.mws);
K3 = ip.dHfus*ip.mw*ip.Tf/(ip.Cpws*ip.mws) - ip.ms*(ip.Kf/ip.Ms)*ip.dHfus/(ip.Cpws*ip.mws) + ip.Tf*ip.Tnuc;
Teq_ini = 0.5*(-K2-sqrt(K2^2-4*K1*K3)); 
mi = ip.mw - ip.ms*(ip.Kf/ip.Ms)/(ip.Tf-Teq_ini);
t = [t;t(end)];
T = [T;Teq_ini*ones(1,mz*mr)];

% Append new temperature data
tspan = (t(end):dt:tf)';
opts_ode2 = odeset('Event', @(t,y) event_freezing_complete(t,y,ip),'RelTol',ip.tol,'AbsTol',ip.tol);
tic; [t2,y2] = ode15s (@(t,y) ODE_FreezingNucl(t,y,ip), tspan, mi, opts_ode2); toc;
Teq = ip.Tf - ((ip.Kf/ip.Ms)*(ip.ms_new./(ip.m0-y2)));

t = [t;t2];
T = [T;Teq*ones(1,mz*mr)];


% Cooling
opts_ode3 = odeset('RelTol',ip.tol,'AbsTol',ip.tol);
y0 = T(end,:);
tspan = (t(end):dt:tf)';
tic; [t3,y3] = ode15s (@(t,y) ODE_FreezingCoolPost_2D(t,y,ip), tspan, y0, opts_ode3); toc;
% 
t = [t;t3];
T = [T;y3];


% Export
outputs.Tg = cal_Tg(t,ip.Tg);
outputs.Tw = cal_Tw(t,ip.Tc1);
outputs.t = t/3600;
outputs.T = mean(T,2);
outputs.Tspatial = T;
outputs.S = ip.S0*100*ones(length(outputs.t),1);
outputs.cw = ip.cw0*ones(length(outputs.t),1);

return