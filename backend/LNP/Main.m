

% Residential_time = 1;%     Residential time    [s]
% FRR = 3;%                   Flow rate ratio     [Water/Ethanol] (1~5)
% pH = 5.5;%                  pH                  [-] (4~6)
% Ion = 0.1;%                 Ionic concentration [M] (0.01~1)
% TF = 5;%                    Total flowrate      [ml/min]
% C_lipid = 10;%              Lipid concentration [mg/ml]
% mRNA_in = 10;%              mRNA                [mg/ml] (Example)
% 
% [Diameter, PSD, EE, mRNA_out, Fraction] = LNP(Residential_time, FRR, pH, Ion, TF, C_lipid, mRNA_in);

%% 

function [Diameter, PSD, EE, mRNA_out, Fraction, PDI_val, Dstats] =  LNP(Residential_time, FRR, pH, Ion, TF, C_lipid, mRNA_in)


global delta2
global M
global grid

M       = 200;              % Number of bins        [-]
L_min   =1e-9;
L_max   = 10e-7;

grid = linspace(log(L_min), log(L_max), M);
grid = exp(grid);
delta = grid - [0, grid(1:M-1)];
delta2 = 1e-9;

grid2 = delta2*linspace(L_min, L_max, 1000)*1000000000;
X = grid;
Length = X;

T       = 293;              % Temperature           [K]
kB      = 1.380E-23;        % Bolzmann constant     [J/K]
mu      = 0.001;            % Viscosity of water    [Pa s]

K_p     = 57;               % Partition coefficient [-]
EE=1./((1 + 1./K_p.*FRR));
mRNA_out = EE*mRNA_in;
%%

init = zeros(1, M)+eps*2;
duration = [0:Residential_time/1000:Residential_time];%                 [s]
crystal_factor = 2;%Fitting parameter               [-]
FRR = FRR/(FRR+1);%                                 [fraction]
Alpha = Alpha_calc(pH, Ion, FRR)*6.5e-6;% Agglomeration effeicney [-]
  % ————————————
    % % Use custom solver tolerances
    opts = odeset( ...
        'RelTol', 1e-4, ...    % tighten relative tolerance (default 1e-3)
        'AbsTol', 1e-6, ...    % tighten absolute tolerance (default 1e-6)
        'MaxStep', 10 ...      % prevent steps >10 s
    );

    % Solve the PBE with these options
    [t,n] = ode15s( ...
        @(t,n) PBE(t, n, Alpha, delta, grid, crystal_factor, FRR, C_lipid), ...
        duration, init, opts ...
    );
    % ————————————


% [t,n] = ode15s(@( t , n )PBE(t, n, Alpha,  delta, grid, crystal_factor, FRR, C_lipid), duration, init );
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


x_solu = exp( (1-FRR).*log(0.0035)+FRR*log(0.00000002));         % Mole fraction solubility  [-]
S_solu = x_solu*386*(FRR*1000/18 + (1-FRR)*789/46);             % Bulk solubility           [kg/m3]

Supersaturation = max(1, lipid./S_solu);    

L_c     = crystal_factor.*sigma.*Vm./kB/294./log(Supersaturation);

S = exp(crystal_factor*sigma*Vm/kB/294./Length');

%%

n = max(0, n);
DLS = ((n.*X.*X.*X.*X.*X.*X)');
inter_DLS=interp1(grid*1000000000, DLS, grid2*1000000000, 'makima');

Sum = max(inter_DLS)';
Normalized = inter_DLS'./repmat(Sum, 1, 1000);


for i = 2:length(duration)



    mean_d(i-1) =  sum(grid2.*Normalized(i, :))/sum(Normalized(i, :))*1000000000;
 
end

Diameter = [duration', [0, mean_d]'];
PSD = [grid2'*1000000000, Normalized(end, :)'];


Mean_density = FRR*1000 + (1-FRR)*789;%   [mg/ml]


Fraction = (mRNA_out + C_lipid*(1-FRR) )/ (Mean_density);%             [-]

%% Add more CQQs after reviewer comments
% ---------- PDI (from intensity-weighted distribution at final time) ----------
d_nm   = grid*1e9;                                % bin centers in nm (from grid in m)
I_final = (n(end,:).*(X.^6));                     % intensity ~ d^6
I_final = max(I_final,0);
wI = I_final / (trapz(d_nm, I_final) + eps);      % area-normalize by integral

Dz_nm = Diameter(end,2);                          % use existing Z-average (nm)
varI  = trapz(d_nm, ((d_nm - Dz_nm).^2) .* wI);   % intensity-weighted variance
PDI   = varI / (Dz_nm^2);                         % DLS-style relative variance

% ---------- D10/D50/D90 (and D25/D75) from number-weighted PSD ----------
N_final = max(n(end,:),0);                        % number-weighted spectrum
wN   = N_final / (trapz(d_nm, N_final) + eps);    % area-normalize
cdfN = cumtrapz(d_nm(:), wN(:));
tot  = cdfN(end);
if ~isfinite(tot) || tot <= 0
    D10_nm = NaN; D25_nm = NaN; D50_nm = NaN; D75_nm = NaN; D90_nm = NaN;
else
    cdfN = cdfN ./ tot;
    pick = @(p) d_nm( find(cdfN >= p, 1, 'first') );
    D10_nm = pick(0.10); D25_nm = pick(0.25); D50_nm = pick(0.50);
    D75_nm = pick(0.75); D90_nm = pick(0.90);
end 

PDI_val = PDI;
Dstats  = [D10_nm, D50_nm, D90_nm, D25_nm, D75_nm];

end
%%
