function [objective, termination, direction] = event_sublimation_start(t,T,ip)

objective = T(1)-ip.Tm;  % stop when reaching sublimation temperature
termination = 1;  % terminate ode solvers 
direction = 0;  % both directions

end