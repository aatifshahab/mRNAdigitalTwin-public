function outputs = cal_Tb(t,Tb_profile)

nt = length(t);
Tb = zeros(nt,1);

if length(Tb_profile) == 1 && ~isa(Tb_profile,'function_handle')
    for i = 1:nt
        Tb(i) = Tb_profile;
    end
elseif isa(Tb_profile,'function_handle')
    for i = 1:nt
        Tb(i) = Tb_profile(t(i));
    end
else
    for i = 1:nt
        Tb(i) = interp1(Tb_profile(:,2),Tb_profile(:,1),t(i));
    end
end

outputs = Tb;

return