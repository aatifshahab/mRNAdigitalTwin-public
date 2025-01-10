function outputs = cal_P(t,P_profile)

nt = length(t);
P = zeros(nt,1);

if length(P_profile) == 1 && ~isa(P_profile,'function_handle')
    for i = 1:nt
        P(i) = P_profile;
    end
elseif isa(P_profile,'function_handle')
    for i = 1:nt
        P(i) = P_profile(t(i));
    end
else
    for i = 1:nt
        P(i) = interp1(P_profile(:,2),P_profile(:,1),t(i));
    end
end

outputs = P;

return