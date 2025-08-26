function outputs = cal_Nw(T,S,P,ip)

nt = length(T);
Nw = zeros(nt,1);
for i = 1:nt
    Rp = ip.Rp(S(i)*0.01);
    Nw(i) = (ip.PwT(T(i))-P(i))/Rp;
end

outputs = Nw;

end
    