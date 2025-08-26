function outputs = cal_Tw(t,Tw_profile)

nt = length(t);
Tw = zeros(nt,1);

if length(Tw_profile) == 1 && ~isa(Tw_profile,'function_handle')
    for i = 1:nt
        Tw(i) = Tw_profile;
    end
elseif isa(Tw_profile,'function_handle')
    for i = 1:nt
        Tw(i) = Tw_profile(t(i));
    end
else
    for i = 1:nt
        Tw(i) = interp1(Tw_profile(:,2),Tw_profile(:,1),t(i));
    end
end

outputs = Tw;

return