function Alpha = Alpha_calc(pH, Ion, FRR)


global delta
global M
clc

T       = 293;             % Temperature           [K]
kB      = 1.380E-23;        % Bolzmann constant     [J/K]

load('pH_list.mat')
load('Zeta_list.mat')
potential = interp1(pH_list, Zeta_list, pH, 'makima')*0.001;

Alpha = zeros(M, M);

for i =1:M

    
    for j = 1:M
        
        Alpha(i, j)  = VDW(i, j, potential, Ion, FRR);

    end


end


end

