function outputs = cal_freezing_interface(y,ip)

ny = length(y);
z = zeros(ny,1);
r = zeros(ny,1);
H = zeros(ny,1);

for i=1:ny

    % Important parameters and constants
    mi = y(i);  % mass of ice
    ms = ip.ms_new;  % solute does not freeze
    mw = ip.m0 - mi;  % mass of water 
    Ac = ip.Ac;
    
    
    % Density change during freezing
    Vtot = (ms/ip.rhos) + (mw/ip.rhow) + (mi/ip.rhoi);
    Vws = Vtot - (mi/ip.rhoi);
    H1 = Vtot/Ac;
    ratio = 2*H1/ip.d;
    r(i) = (Vws/(ratio*pi))^(1/3);
    z(i) = H1 - r(i)*ratio;
    H(i) = H1;

end

outputs.r = r;
outputs.l = z;
outputs.H = H;

end