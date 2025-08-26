function [objective, termination, direction] = event_freezing_complete(t,y,ip)

% Tavg = mean(T);
objective = ip.xi*ip.m0 - y(1);  % stop when reaching sublimation temperature
termination = 1;  % terminate ode solvers 
direction = 0;  % both directions

end