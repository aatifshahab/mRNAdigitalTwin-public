function outputs = ODE_FreezingCoolPost_2D(t,y,ip)

% Important parameters and constants
nr = ip.mr1;
nz = ip.mz1;
dr = ip.dr1;
dz = ip.dz1f;
rho = ip.rhofs;
Cp = ip.Cpfs ;
k = ip.kfs;
Tw = cal_Tw(t,ip.Tc1);
Ta = cal_Tw(t,ip.Ta1);
Tg = cal_Tg(t,ip.Tg);
alp = k/(rho*Cp);
ha = ip.hs1;
hb = ip.hs2;
hs = ip.hs3;
f = ip.F1;
T = reshape(y,nz,nr);
dTdt = zeros(nz,nr);

for i = 2:nz-1
    for j = 2:nr-1
        r = (j-1)*dr;
        dTdt(i,j) = (alp/r)*(T(i,j+1)-T(i,j-1))/(2*dr) + (alp/dr^2)*(T(i,j+1)-2*T(i,j)+T(i,j-1)) + (alp/dz^2)*(T(i+1,j)-2*T(i,j)+T(i-1,j)); 
    end
end

% Top surface
for i = 1
    for j = 2:nr-1
        r = (j-1)*dr;
        Tghost = T(i+1,j)+2*dz*ha*(Ta-T(i,j))/k;
        % Tghost = T(i+1,j)+2*dz*(ip.eps1*ip.SB*(Tw_top^4-T(i,j)^4))/k;
        dTdt(i,j) = (alp/r)*(T(i,j+1)-T(i,j-1))/(2*dr) + (alp/dr^2)*(T(i,j+1)-2*T(i,j)+T(i,j-1)) + (alp/dz^2)*(T(i+1,j)-2*T(i,j)+Tghost); 
    end
end

% Bottom surface
for i = nz
    for j = 2:nr-1
        r = (j-1)*dr;
        Tghost = T(i-1,j)-2*dz*hb*(T(i,j)-Tg)/k;
        % Tghost = T(i-1,j)-(2*dz/k)*(hb*(T(i,j)-Tg) + ip.eps1*ip.SB*(T(i,j)^4-Tg^4));
        dTdt(i,j) = (alp/r)*(T(i,j+1)-T(i,j-1))/(2*dr) + (alp/dr^2)*(T(i,j+1)-2*T(i,j)+T(i,j-1)) + (alp/dz^2)*(Tghost-2*T(i,j)+T(i-1,j)); 
    end
end

% Center 
for i = 2:nz-1
    for j = 1
        dTdt(i,j) = (4*alp/dr^2)*(T(i,j+1)-T(i,j)) + (alp/dz^2)*(T(i+1,j)-2*T(i,j)+T(i-1,j)); 
    end
end

% Outer
for i = 2:nz-1
    for j = nr
        r = (j-1)*dr;
        Tghost = (-2*dr/k)*(hs*(T(i,j)-Tg)+f*ip.eps1*ip.SB*(T(i,j)^4-Tw^4)) + T(i,j-1);
        dTdt(i,j) = (alp/r)*(Tghost -T(i,j-1))/(2*dr) + (alp/dr^2)*(Tghost -2*T(i,j)+T(i,j-1)) + (alp/dz^2)*(T(i+1,j)-2*T(i,j)+T(i-1,j)); 
    end
end

% Top + Center
for i = 1
    for j = 1
        Tghost = T(i+1,j)+2*dz*ha*(Ta-T(i,j))/k;
        % Tghost = T(i+1,j)+2*dz*(ip.eps1*ip.SB*(Tw_top^4-T(i,j)^4))/k;
        dTdt(i,j) = (4*alp/dr^2)*(T(i,j+1)-T(i,j)) + (alp/dz^2)*(T(i+1,j)-2*T(i,j)+Tghost); 
    end
end

% Top + Outer
for i = 1
    for j = nr
        r = (j-1)*dr;
        Tghostj = (-2*dr/k)*(hs*(T(i,j)-Tg)+f*ip.eps1*ip.SB*(T(i,j)^4-Tw^4)) + T(i,j-1);
        Tghosti = T(i+1,j)+2*dz*ha*(Ta-T(i,j))/k;
        % Tghosti = T(i+1,j)+2*dz*(ip.eps1*ip.SB*(Tw_top^4-T(i,j)^4))/k;
        dTdt(i,j) = (alp/r)*(Tghostj -T(i,j-1))/(2*dr) + (alp/dr^2)*(Tghostj-2*T(i,j)+T(i,j-1)) + (alp/dz^2)*(T(i+1,j)-2*T(i,j)+Tghosti); 
    end
end

% Bottom + Center
for i = nz
    for j = 1
        % Tghost = T(i-1,j)-(2*dz/k)*(hb*(T(i,j)-Tg) + ip.eps1*ip.SB*(T(i,j)^4-Tg^4));
        Tghost = T(i-1,j)-2*dz*hb*(T(i,j)-Tg)/k;
        dTdt(i,j) = (4*alp/dr^2)*(T(i,j+1)-T(i,j)) + (alp/dz^2)*(Tghost-2*T(i,j)+T(i-1,j)); 
    end
end

% Bottom + Outer
for i = nz
    for j = nr
        r = (j-1)*dr;
        Tghostj = (-2*dr/k)*(hs*(T(i,j)-Tg)+f*ip.eps1*ip.SB*(T(i,j)^4-Tw^4)) + T(i,j-1);
        % Tghosti = T(i-1,j)-(2*dz/k)*(hb*(T(i,j)-Tg) + ip.eps1*ip.SB*(T(i,j)^4-Tg^4));
        Tghosti = T(i-1,j)-2*dz*hb*(T(i,j)-Tg)/k;
        dTdt(i,j) = (alp/r)*(Tghostj -T(i,j-1))/(2*dr) + (alp/dr^2)*(Tghostj-2*T(i,j)+T(i,j-1)) + (alp/dz^2)*(Tghosti-2*T(i,j)+T(i-1,j)); 
    end
end

% Output
outputs = reshape(dTdt,nr*nz,1);

return