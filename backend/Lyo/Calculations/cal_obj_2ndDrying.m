function outputs = cal_obj_2ndDrying(x,Data)

input = get_inputdata_expcon1;
input.A = x(1);
input.Ea = x(2);
ip = input_processing(input);
sol2 = Sim_2ndDrying(ip);


time2 = sol2.t;
cs = sol2.cs; cs_avg = mean(sol2.cs,2);
Temp2 = sol2.T; Tp2 = Temp2(:,end); Tb2 = sol2.Tb;

Tsim = interp1(time2, cs_avg, Data(:,1));
Texp = Data(:,2);

error = (Texp-Tsim).^2;
outputs = 1e5*sum(error);

return