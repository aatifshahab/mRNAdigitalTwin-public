function outputs = cal_T_rt_cylinder(mode,h,R,k,Cp,rho,t_end,T0,Te,nr,nt,n,Bi0)

if mode == 1
    Bi = Bi0;
    h = Bi*k/R;
else
    Bi = h*R/k;
end

alp = k/(rho*Cp);
r = linspace(0,R,nr);
t = linspace(0,t_end,nt);
Fo = alp*t/R^2;


lmb = zeros(n,1);
obj = zeros(n,1);
An = zeros(n,1);
Bn = zeros(n,1);
fn = zeros(n,nr);


u0 = 0;
for i = 1:n
    [u,fval] = fmincon(@(u) (Bi*besselj(0,u)-u*besselj(1,u))^2, u0, [], [], [], [], u0, u0+3);
    lmb(i) = u;
    obj(i) = fval;
    u0 = u + 2;
end

for i = 1:n
    An(i) = 2*besselj(1,lmb(i))/(lmb(i)*(besselj(0,lmb(i))^2 + besselj(1,lmb(i))^2)); 
    Bn(i) = 2*besselj(1,lmb(i))/lmb(i);
    fn(i,:) = besselj(0,lmb(i)*r/R);
end


T = zeros(nt,nr);
for i = 1:n
    tmp = exp(-lmb(i)^2*Fo);
    T = T + An(i)*tmp'*fn(i,:);
end
T = (T0-Te)*T+Te;

dT = zeros(nt,1);
for i = 1:nt
    dT(i) = max(T(i,:))-min(T(i,:));
end

Tavg = zeros(nt,1);
for i = 1:n
    Tavg = Tavg + An(i).*Bn(i).*exp(-lmb(i)^2*Fo)';
end
Tavg = (T0-Te)*Tavg+Te;

Tlump = (T0-Te)*exp(-2*h*t/(rho*Cp*R)) + Te; Tlump = Tlump';
Q = h*(T(:,end)-Te);
Qlump = h*(Tlump-Te); 

outputs.T = T;
outputs.Tavg = Tavg;
outputs.dT = dT;
outputs.Tlump = Tlump;
outputs.err = abs(Tavg-Tlump);
outputs.t = t;
outputs.r = r;
outputs.Bi = Bi;
outputs.Q = Q;
outputs.Qlump = Qlump;
outputs.eQ = abs(Q-Qlump)*100/Q(1);

return