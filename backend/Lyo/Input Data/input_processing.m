function outputs = input_processing(ip2)

% Check the input types: volume or height (default = volume)
if isfield(ip2,'H1l')
    ip2.Vl = (pi*ip2.d^2/4)*ip2.H1l;
    ip2 = rmfield(ip2,'H1l');
elseif  isfield(ip2,'H1f')
    H1f = ip2.H1f;
    Vf = (pi*ip2.d^2/4)*H1f;
    rhows = 1/(ip2.xs/ip2.rhos + (1-ip2.xs)/ip2.rhow);
    ip2.Vl = Vf/(ip2.xs*rhows/ip2.rhos + (1-ip2.xs)*rhows*(1-ip2.xi)/ip2.rhow + (1-ip2.xs)*rhows*(ip2.xi)/ip2.rhoi);
    ip2 = rmfield(ip2,'H1f');
elseif  isfield(ip2,'H2')
    H1f = ip2.H2;
    Vf = (pi*ip2.d^2/4)*H1f;
    rhows = 1/(ip2.xs/ip2.rhos + (1-ip2.xs)/ip2.rhow);
    ip2.Vl = Vf/(ip2.xs*rhows/ip2.rhos + (1-ip2.xs)*rhows*(1-ip2.xi)/ip2.rhow + (1-ip2.xs)*rhows*(ip2.xi)/ip2.rhoi);
    ip2 = rmfield(ip2,'H2');
elseif  isfield(ip2,'H3')
    H1f = ip2.H3;
    Vf = (pi*ip2.d^2/4)*H1f;
    rhows = 1/(ip2.xs/ip2.rhos + (1-ip2.xs)/ip2.rhow);
    ip2.Vl = Vf/(ip2.xs*rhows/ip2.rhos + (1-ip2.xs)*rhows*(1-ip2.xi)/ip2.rhow + (1-ip2.xs)*rhows*(ip2.xi)/ip2.rhoi);
    ip2 = rmfield(ip2,'H3');
end

% Properties
ip = ip2;
ip.rhows = 1/(ip2.xs/ip2.rhos + (1-ip2.xs)/ip2.rhow);
ip.Cpws = ip2.xs*ip2.Cps + (1-ip2.xs)*ip2.Cpw;
ip.kws = ip2.xs*ip2.ks + (1-ip2.xs)*ip2.kw;
ip.rhof = 1/(ip2.xs/ip2.rhos + (1-ip2.xs)/ip2.rhoi);
ip.Cpf = ip2.xs*ip2.Cps + (1-ip2.xs)*ip2.Cpi;
ip.kf = ip2.xs*ip2.ks + (1-ip2.xs)*ip2.ki;
ip.mws = ip2.Vl*ip.rhows;
ip.mtot = ip.mws;
ip.ms = ip2.xs*ip.mws;
ip.mw = (1-ip2.xs)*ip.mws;
ip.mi_fin = ip2.xi*ip.mw;
ip.mw_fin = ip.mw - ip.mi_fin;
ip.Vf = ip.mtot/ip.rhof;
% ip.Vf = ip.ms/ip2.rhos + ip.mw_fin/ip2.rhow + ip.mi_fin/ip2.rhoi;
% ip.rhof = ip.mtot/ip.Vf;
% ip.Cpf = ip2.xs*ip2.Cps + (1-ip2.xs)*ip2.xi*ip2.Cpi + (1-ip2.xs)*(1-ip2.xi)*ip2.Cpw;
% ip.kf = ip2.xs*ip2.ks + (1-ip2.xs)*ip2.xi*ip2.ki + (1-ip2.xs)*(1-ip2.xi)*ip2.kw;
ip.alpf = ip.kf/(ip.rhof*ip.Cpf);  % thermal diffusivity (m2/s)
ip.alpe = ip2.ke/(ip2.rhoe*ip2.Cpe);  % thermal diffusivity (m2/s)

% Geometry
ip.H1l = ip2.Vl/(pi*ip2.d^2/4);
ip.H1f = ip.Vf/(pi*ip2.d^2/4);
ip.H2 = ip.H1f;
ip.H3 = ip.H2;
ip.A1l = pi*ip2.d*ip.H1l;
ip.A1f = pi*ip2.d*ip.H1f;
ip.A2 = pi*ip2.d*ip.H2;
ip.A3 = pi*ip2.d*ip.H3;
ip.Ac = pi*ip2.d^2/4;  % cross sectional area (m2)
ip.Avial = pi*ip2.d*ip2.Hgl;  % surface area of the vial (m2)
ip.Vgl = pi*(ip2.d^2-(ip2.d-ip2.tgl)^2)*ip2.Hgl/4; % volume of glass (m3)
ip.mgl = ip2.rhogl*pi*(ip2.d^2-(ip2.d-ip2.tgl)^2)*ip2.Hgl/4; % volume of glass (m3)

% Others
ip.Rp = @(x) ip2.Rp0 + ip2.Rp1*x/(1+ip2.Rp2*x);  % cake resistance, mass transfer resistance (m/s)
ip.Cpgl_total = ip2.rhogl*ip2.Cpgl*ip.Vgl;  % total heat capacity of glass (J/K)
ip.hr = @(x) ip.eps1*ip.SB*4*x^3;

% Numerics and discretization
ip.dz1l = ip.H1l/(ip2.mz1-1);
ip.dz1f = ip.H1f/(ip2.mz1-1);
ip.dr1 = (ip2.d/2)/(ip2.mr1-1);
ip.dz2 = ip.H2/(ip2.nz2-1);
ip.dz3 = ip.H3/(ip2.nz3-1);
ip.dpsi = 1/(ip2.nz2-1);
ip.psi = (0:ip.dpsi:1)';

% Searching for repetitive inputs
ip_fin = ip;
field = fieldnames(ip);
field2 = fieldnames(ip2);
field_same = intersect(field,field2);

if ~isempty(field_same)
    for curr_field = field_same(:)'
        if isa(getfield(ip_fin,curr_field{:}),'function_handle')
            if ~strcmp(func2str(getfield(ip_fin,curr_field{:})),func2str(getfield(ip2,curr_field{:})))
                warning(['Input overwritten: ' curr_field{:}])
                ip_fin = setfield(ip_fin,curr_field{:},getfield(ip2,curr_field{:}));
            end
        elseif isstring(getfield(ip_fin,curr_field{:}))
            if ~isequal(getfield(ip_fin,curr_field{:}),getfield(ip2,curr_field{:}))
                warning(['Input overwritten: ' curr_field{:}])
                ip_fin = setfield(ip_fin,curr_field{:},getfield(ip2,curr_field{:}));
            end
        else
            if ~isequal(round(getfield(ip_fin,curr_field{:}),14),round(getfield(ip2,curr_field{:}),14))
                warning(['Input overwritten: ' curr_field{:}])
                ip_fin = setfield(ip_fin,curr_field{:},getfield(ip2,curr_field{:}));
            end
        end
    end
end

% Export
outputs = ip_fin;

return

