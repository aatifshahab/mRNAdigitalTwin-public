function outputs = Sim_2ndDrying(ip)

% Parameters
m = ip.nz3;  % number of nodes
tf = ip.tend;  % final time
dt = ip.dt3;  % data collection frequency from the ODE solver
tspan = (0:dt:tf)';  % define the time span

% Initial conditions
T0 = ip.T03*ones(m,1);
cw0 = ip.cw0.*ones(m,1);

% ODE solver setup
y0 = [T0;cw0];
opts_ode = odeset('Event', @(t,y) event_desorption_complete(t,y,ip),'RelTol',ip.tol,'AbsTol',ip.tol);

% Simulation
[t,y] = ode15s (@(t,y) ODE_2ndDrying(t,y,ip), tspan, y0, opts_ode);

% Export
outputs.Tb = cal_Tb(t,ip.Tb3);
outputs.Tw = cal_Tw(t,ip.Tc3);
outputs.t = t/3600;
outputs.T = y(:,1:m);
outputs.cw = y(:,m+1:end);
outputs.S = ip.H3*100*ones(length(outputs.t),1);
outputs.P  = cal_P(t,ip.Pwc);

return