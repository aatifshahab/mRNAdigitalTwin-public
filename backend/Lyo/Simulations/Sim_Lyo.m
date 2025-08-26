function [sol1, sol2, sol3] = Sim_Lyo(ip)

% Freezing
switch ip.freezing
case 'suspended'
sol1 = Sim_Freezing(ip);
case 'VISF'
sol1 = Sim_Freezing_VISF(ip);
case '2D'
sol1 = Sim_Freezing_2D(ip);
case 'stochastic'
sol1 = Sim_Freezing_sto(ip);
end

% Primary drying
ip.T02 = sol1.T(end);
ip = input_processing(ip);
sol2 = Sim_1stDrying(ip);
sol2.t = sol2.t + sol1.t(end);

% Post Primary Drying
if ip.tpost2 > 0
    tspan = [3600*sol2.t(end) 3600*sol2.t(end)+ip.tpost2];  % final time
    Tini = sol2.T(end,:);  % initial condition, shelf temperaute at the last position

    % Solve the ODEs
    options_ode = odeset('RelTol', ip.tol, 'AbsTol', ip.tol);
    [t,y] = ode15s(@(t,y) ODE_Post1D(t,y,ip), tspan, Tini, options_ode);

    % Colelct data
    sol2.t = [sol2.t;t/3600];
    sol2.T = [sol2.T;y];
    sol2.Tb = [sol2.Tb;cal_Tb(t,ip.Tb2)];
    sol2.S = [sol2.S; ip.H2*100*ones(length(t),1)];
    sol2.Tw = [sol2.Tw; cal_Tw(t,ip.Tc2)];
    sol2.P = [sol2.P; cal_P(t,ip.Pwc)];
end
sol2.cw = ip.cw0*ones(length(sol2.t),1);

% Secondary drying
% ip.tend = 6*3600;  % to change the final time
% ip.cfin = .001;
ip.T03 = sol2.T(end);
ip = input_processing(ip);
% ip.Tb3 = @(x) min(sol2.Tb(end)+(.2/60)*x,313);
sol3 = Sim_2ndDrying(ip);
sol3.t = sol3.t + sol2.t(end);

return