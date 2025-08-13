
function Alpha = VDW(i, j, potential, Ion, FRR)

global delta2
global grid
global M

T       = 293;             % Temperature           [K]
kB      = 1.380E-23;        % Bolzmann constant     [J/K]
A=1.7e-20*0.01;


Length      = grid;      % Length range of each bin                  [m]


a = [1:1:M*10]*delta2;

phi_VDW = -A/6*(2*Length(i)/2*Length(j)/2 ./ ( a.^2 + 2*a*(Length(i)/2+Length(j)/2) )...
    +2*Length(i)/2*Length(j)/2 ./ (  a.^2 + 2*a*(Length(i)/2+Length(j)/2) + 4*Length(i)/2*Length(j)/2 )...
    +log(   (a.^2 + 2*a*(Length(i)/2+Length(j)/2))  ./  (a.^2 + 2*a*(Length(i)/2+Length(j)/2+4*Length(i)/2*Length(j)/2)) )   );

%phi_VDW = -A/6*(2*Length(i)*Length(j) ./ ( a.^2 + 2*a*(Length(i)+Length(j)) )...
%    +2*Length(i)*Length(j) ./ (  a.^2 + 2*a*(Length(i)+Length(j)) + Length(i)*Length(j) )...
%    +log(   (a.^2 + 2*a*(Length(i)+Length(j)))  ./  (a.^2 + 2*a*(Length(i)+Length(j)+Length(i)*Length(j))) )  );

e = 1.6e-19;
e_0 = 8.854e-12;
e_rel = (78.3*FRR+24.3*(1-FRR));

% Ethanol : 24.3 
% Water : 78.3


ion_conc = Ion; 

kappa = sqrt(2*e^2*6.02e23*ion_conc/(e_0*e_rel*kB*T));

phi_elec = 128/kappa/kappa*pi*ion_conc*6.02e23*kB*T*(tanh(e*potential/4/kB/T)).^2*(Length(i)/2*Length(j)/2)./(  Length(i)/2+Length(j)/2+a ).*exp(-kappa*a);
phi_total = phi_VDW + phi_elec;

W = sum(  exp(phi_total/kB/T).*( Length(i)/2 + Length(j)/2 + a ).^(-2)*delta2 )*(Length(i)/2 + Length(j)/2);
Alpha = 1/W;

end
