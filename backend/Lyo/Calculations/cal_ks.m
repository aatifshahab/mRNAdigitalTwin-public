function outputs = cal_ks(T,ip)

nt = length(T);
ks = zeros(nt,1);
for i = 1:nt
    ks(i) = ip.fa*exp(-ip.Ea/(ip.R*T(i)));
end

outputs = ks;

end
    