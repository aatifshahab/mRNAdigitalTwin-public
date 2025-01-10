function outputs = ParEst_2ndDrying(Data)

x0 = [1e-3;7e3];  % A and Ea
x0_lb = [1e-8; 1e3];
x0_ub = [1e-2; 5e5];

% obj = @(x) cal_obj_2ndDrying(x,Data);
% Optimizer_Ipopt = opti('obj',obj,'lb',x0_lb,'ub',x0_ub,'options',optiset('solver','Ipopt'));
% [x, fval] = solve(Optimizer_Ipopt,x0);

[x, fval] = fmincon(@(x)cal_obj_2ndDrying(x,Data),x0,[],[],[],[],x0_lb,x0_ub);

outputs.x = x;
outputs.fval = fval;

return
