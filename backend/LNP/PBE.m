function dndt = PBE(t, n, Alpha, delta, grid, crystal_factor, FRR, C_lipid)

global M

n           = n(1:M);               % Number density function                               [m^-4]
dndt        = n(1:M)*0;             % Change rate of number density function                [m^-4 s^-1]
Length      = grid;                 % Length bins               [m]
T           = 293;                  % Temperature               [K] 
kB          = 1.380E-23;            % Bolzmann constant         [J/K]
mu          = 0.001;                % Viscosity of water        [Pa s]

Birth       = zeros(M,1);           % Birth rate                [m^-4 s^-1]
Death       = zeros(M,1);           % Death rate                [m^-4 s^-1]
Growth      = zeros(M,1);           % Growth rate               [m^-4 s^-1]
Nuc         = zeros(M,1);           % Nucleation rate           [m^-4 s^-1]

B           = zeros(M,1);           % Birth rate due to Coalescence     [m^-4 s^-1]
D           = zeros(M,1);           % Death rate due to Coalescence     [m^-4 s^-1]

%% Properties and Constant

Rho_cholesterol = 1052 ;            % Density of cholesterol    [kg/m3]
sigma   = 0.001;                    % Surface energy            [J/m2]
Vm      = 6.1e-28;                  % Molar volume              [m3/mol]
kB      = 1.380E-23;                % Bolzmann constant         [J/K]
k_g     = 0.008*1.1*1.5;            % Growth rate constant      [m/s] 

%% State variables

lipid = C_lipid/(FRR/(1-FRR)+1) - sum(n.*delta'.*Length'.*Length'.*Length')*pi/6*Rho_cholesterol;%              [kg/m3]
lipid = max(lipid, 0.001);

x_solu = exp( (1-FRR)*log(0.0035)+FRR*log(0.00000002));         % Mole fraction solubility  [-]
S_solu = x_solu*386*(FRR*1000/18 + (1-FRR)*789/46);             % Bulk solubility           [kg/m3]

Supersaturation = max(1, lipid/S_solu);                         % Supersaturation           [kg/m3 / kg/m3]
L_c = crystal_factor*sigma*Vm/kB/294./log(Supersaturation);     % Critial size              [m]

%% Kinetics

Smooth = max(0, 1-2 ./ (1 + exp((Supersaturation - 1.05) / 0.1)));
S_star = exp(crystal_factor*sigma*Vm/kB/294./Length');               % Equilibrium supersaturation  [-]

% Nucleation rate

J  = Smooth*1.1*1.5*(80000000)*10000000000*exp(-2400000/T/T/T*log(Supersaturation)^(-2));%     [##/ m3 s1]




for i = 1:M

    if i ==1

        dn_dx(i) = -( S_solu*(Supersaturation-S_star(i+1))  .*Length(i+1).*n(i+1)   -  S_solu*(Supersaturation-S_star(i))  .*Length(i).*n(i)) / (delta(1));
        Growth(i) = Growth(i) + k_g.*dn_dx(i);% [##/m4 s]


    elseif i ==M

    else

        dn_dx(i) = -( S_solu*(Supersaturation-S_star(i+1))  .*Length(i+1).*n(i+1)   -  S_solu*(Supersaturation-S_star(i-1))  .*Length(i-1).*n(i-1)) / (grid(i+1) - grid(i-1));
        Growth(i) = Growth(i) + k_g.*dn_dx(i);% [##/m4 s]

    end

end


if t>1
for i = 1:M

    for j = 1:M
                Collision   = Alpha(i, j)*2*kB*T/(3*mu)*(Length(i)+Length(j))...
                              *(1/Length(i)+1/Length(j))*n(i)*n(j)*delta(j)*delta(i);       % Collision rate        [m^-3 s^-1]
                
                Death(i)    = Death(i) + Collision'/delta(i);%...
                              
                k           =  (Length(i)^3+Length(j)^3)^(1/3);                             % Death rate            [m^-4 s^-1]

                    if k<=Length(1) 

                        Birth(1)    = Birth(1) + 0.5 * Collision / delta(1);                % Birth in first bin    [m^-4 s^-1]
        
                    elseif k>Length(M)

                        Birth(M)    = Birth(M) + 0.5 * Collision / delta(M);                % Birth in last bin     [m^-4 s^-1]

                    else

                        p = 1;

                        while (k > Length(p))

                            if k <=Length(p+1)

                                w1          = (1 - (k/Length(p+1))^3) /...
                                              (1 - (Length(p)/Length(p+1))^3);  % Weight 1                  [-]
                                w2          = 1 - w1;                           % Weight 2                  [-]

                                Birth(p)    = Birth(p)   + w1/2 * Collision / delta(p);     % Birth rate    [m^-4 s^-1]
                                Birth(p+1)  = Birth(p+1) + w2/2 * Collision / delta(p+1);   % Birth rate    [m^-4 s^-1]
                                
                            end

                            p = p+1;

                        end 

                    end
                   

    end    

end
end
sigma = 0.9;
%unnormalized_W = (1 ./ (Length * sigma * sqrt(2 * pi))) .* exp(-((log(Length) - log(L_c)).^2) ./ (2 * sigma^2));

unnormalized_W = exp(-0.5 * ((Length - L_c) / 0.00000001).^2);  % Distribution factor   [-]
W = unnormalized_W ./ sum(unnormalized_W .* delta);             % Normalzied factor     [/m]
B_n = J * W;                                                    % Nucleation rate       [#/m4]            



Check = (sum(Death'.*Length.*Length.*Length.*delta) - sum(Birth'.*Length.*Length.*Length.*delta))/sum(Death'.*Length.*Length.*Length.*delta);
dndt = dndt + B_n'*(L_c<8e-7)*1000*(t<1);%   [##/m4 s]  
dndt = dndt + Growth*900*(t<1);%  [##/m4 s]
dndt = dndt + Birth* (1/(1+exp(-t+1)));
dndt = dndt - Death* (1/(1+exp(-t+1)));
dndt = dndt.*(n>eps);
end

