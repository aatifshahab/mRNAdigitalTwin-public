function [objective, termination, direction] = event_desorption_complete(t,T,ip)

objective = T(end)-ip.cfin;  % stop when reaching sublimation temperature
termination = 1;  % terminate ode solvers 
direction = 0;  % both directions

end