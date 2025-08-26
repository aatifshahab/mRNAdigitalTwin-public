function [objective, termination, direction] = event_sublimation_complete(t,s,ip)

objective = s(end)-ip.H2;  % stop when reaching sublimation temperature
termination = 1;  % terminate ode solvers 
direction = 0;  % both directions

end