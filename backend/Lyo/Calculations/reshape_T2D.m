function outputs = reshape_T2D(T,ip)

nt = height(T);

sol = cell(nt,1);
for i = 1:nt
    sol{i} = reshape(T(i,:),ip.mz1,ip.nr1);
end

outputs = sol;

return