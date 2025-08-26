function [objective, termination, direction] = event_cooling_complete(t,T,ip)

Tavg = mean(T);
objective = Tavg-ip.Tnuc;  % stop when reaching sublimation temperature
termination = 1;  % terminate ode solvers 
direction = 0;  % both directions

end