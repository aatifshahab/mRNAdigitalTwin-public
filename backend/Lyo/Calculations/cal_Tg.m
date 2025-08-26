function outputs = cal_Tg(t,Tg_profile)

nt = length(t);
Tg = zeros(nt,1);

if length(Tg_profile) == 1
    for i = 1:nt
        Tg(i) = Tg_profile;
    end
else
    for i = 1:nt
        Tg(i) = interp1(Tg_profile(:,2),Tg_profile(:,1),t(i));
    end
end
outputs = Tg;

return