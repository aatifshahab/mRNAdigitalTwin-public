close all; clear all; clc;
load('func_input.mat')

%states0 = zeros( (n*nbin*2)+1, 1);
%states0(end,1) = initial feed concentration of mRNA g/L =cs0

t_vec    = (0:5:10800)';
[tSol,states] = ode15s(@(t,states) CCTC_to_aatif(states,params),t_vec,states0);
unbound_mRNA = states(:,end);
plot(tSol,unbound_mRNA)

function deriv=CCTC_to_aatif(states,params)

n         = params.n; %number of discretization points for each variable, default = 100
nbin      = params.nbin; %number of bins in each discretized point, default = 3
k_ad      = params.k_ad; %adsorption rate constant_1
qmax      = params.qmax; %maximum binding capacity
K_ad_L    = params.K_ad_L; %Langmuir adsorption isotherm
D_p       = params.D_p; %diffusion coefficient of mRNA in the resin pores
deltar    = params.deltar; %default values = [1.78987839380294e-07	2.18792304297425e-07	2.58601326108078e-07];
k_f       = params.k_f; %mass transfer coefficient
epsilonp  = params.epsilonp; %resin particle porosite
phi       = params.phi; %settled resin void fraction
Vbin_frac = params.Vbin_frac; %default values = [0.33 0.33 0.33];
A         = params.A; %resin particles cross section
V         = params.V; % resin particles volume


% unroll states
c =states(1:n*nbin);
c = reshape(c,[n,nbin]);
q =states((n*nbin)+1:2*n*nbin);
q = reshape(q,[n,nbin]);
cs = states((n*nbin)*2+1);

pqpt = nan(size(q,1),1);
pcpt = nan(size(c,1),1);
pcspt = nan(nbin,1);
j = nan(size(c,1)+1,1);
jA = nan(size(c,1)+1,1);

% loop through resin size fractions
for k_R = 1:nbin
    pqpt(:,k_R) = k_ad*(c(:,k_R).*(qmax-q(:,k_R))-q(:,k_R)./K_ad_L); %local langmuir binding

    j(:,k_R)=[0;D_p.*(c(2:end,k_R)-c(1:end-1,k_R))./deltar(k_R);k_f.*(cs-c(end,k_R))];
    jA(:,k_R)=j(:,k_R).*A(:,k_R); %finite volume fluxes

    pcpt(:,k_R)=((jA(2:end,k_R)-jA(1:end-1,k_R))./V(:,k_R)-pqpt(:,k_R))./epsilonp; %interstitial balance
    pcspt(k_R)=sum(-jA(end,k_R)./sum(V(:,k_R)).*phi./(1-phi).*Vbin_frac(k_R)); %solution balance
end
pcspt = sum(pcspt);
deriv=[pcpt(:);pqpt(:);pcspt]; %roll states
end