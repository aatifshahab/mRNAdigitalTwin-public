function outputs = ODE_Desorption(t,y,T,ip)

% Desorption
dcdt = -cal_ks(T,ip)*y;

outputs = dcdt;

return