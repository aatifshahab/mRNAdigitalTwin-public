function outputs = Sim_1stDrying(ip)

% Parameters
m = ip.nz2;  % number of nodes
tf = ip.tend;  % final time
dt = ip.dt2;  % data collection frequency from the ODE solver
Tini = [ip.T02*ones(m,1); ip.S0];  % initial condition, shelf temperaute at the last position
tspan = (0:dt:tf)';  % define the time span

% Simulation of the heating stage
options_ode = odeset('Event', @(t,y) event_sublimation_complete(t,y,ip), 'RelTol', ip.tol, 'AbsTol', ip.tol);
[t,y] = ode15s(@(t,y) ODE_1stDrying(t,y,ip), tspan, Tini, options_ode);

% Export
outputs.Tb = cal_Tb(t,ip.Tb2);
outputs.Tw = cal_Tw(t,ip.Tc2);
outputs.t = t/3600;
outputs.T = y(:,1:end-1);
outputs.S = y(:,end)*100;
outputs.cw = ip.cw0*ones(length(outputs.t),1);
outputs.P  = cal_P(t,ip.Pwc);

return