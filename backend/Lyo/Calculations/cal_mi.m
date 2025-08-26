function outputs = cal_mi(S,mf,Hf)

nt = length(S);
mi = zeros(nt,1);
for i = 1:nt
    mi(i) = (Hf-S(i)*1e-2)*mf/Hf;
end

outputs = mi;

end
    