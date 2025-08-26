function outputs = ODE_PressureBalance(jin,jout,T,ip)
    jout = min(jout,ip.jmax);
    dpdt = (jin-jout)*ip.R*T/(ip.Vc*ip.Mw*1e-3);
    outputs = dpdt;
end