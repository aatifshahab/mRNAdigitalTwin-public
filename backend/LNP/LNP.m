function [Diameter, PSD] =  LNP(Residential_time, FRR, pH, Ion, TF)




global delta2
global M
global grid

M       = 200;              % Number of bins        [-]

L_min   = 1e-9;
L_max   = 10e-7;

grid = linspace(log(L_min), log(L_max), M+1);
grid = exp(grid);
grid = linspace(L_min, L_max, M+1);


delta = grid(2:end)-grid(1:end-1);
grid = grid(2:end);


delta2 = 1e-9;
grid2 = delta2*linspace(L_min, L_max, 1000)*1000000000;
X = grid;
Length = X;

%%

init = zeros(1, M)+eps*2;


duration = [0:Residential_time];%    [s]
duration = linspace(0, Residential_time, 1001)

crystal_factor = 1;


Alpha = Alpha_calc(pH, Ion, FRR)*0.00005;
FRR = FRR/(FRR+1);
[t,n] = ode15s(@( t , n )fun(t, n, Alpha, delta, grid, crystal_factor, FRR), duration, init );

n = n(:, 1:M);
%%
clearvars lipid

for i =1:length(duration)
    lipid(i) = 2.5 - sum(n(i, :).*delta.*Length.*Length.*Length)*pi/6*1052;
end

lipid = lipid';

sigma   = 0.035;                                                  % Surface energy            [J/m2]
Vm      = 6.1e-28;                                              % Molar volume              [m3/mol]
kB      = 1.380E-23;                                            % Bolzmann constant         [J/K]


x_esti = exp( (1-FRR)*log(0.0035)+FRR*log(0.00000002));         % Mole fraction solubility  [-]
S_esti = x_esti*386/(FRR*18 + (1-FRR)*46/0.789)*1000;           % Density solubility        [kg/m3]

Supersaturation = max(1, lipid/S_esti);    

L_c     = crystal_factor*sigma*Vm/kB/294./log(Supersaturation);

S = exp(crystal_factor*sigma*Vm/kB/294./Length');

%%

n = max(0, n);
DLS = ((n.*X.*X.*X.*X.*X.*X)');
inter_DLS=interp1(grid*1000000000, DLS, grid2*1000000000, 'makima');

Sum = max(inter_DLS)';
Normalized = inter_DLS'./repmat(Sum, 1, 1000);


hold on

for i = 2:length(duration)


    mean_d(i-1) =  sum(grid2.*Normalized(i, :))/sum(Normalized(i, :))*1000000000;
 
end

Diameter = [duration', [0, mean_d]'];
PSD = [grid2'*1000000000, Normalized(end, :)'];


end
