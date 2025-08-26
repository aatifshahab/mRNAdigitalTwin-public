function [objective, termination, direction] = event_freezing_nucleation(t,y,ip)

objective = y(end) - ip.Tnuc;  % stop when reaching sublimation temperature
termination = 1;  % terminate ode solvers 
direction = 0;  % both directions

end