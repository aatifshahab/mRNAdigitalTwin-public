"""
    ivt_batch!(du,u,param,t,stoich,constantspecies)

Timestep of DAE showing time evolution of vector u by infinetesimal du.

"""
function ivt_fedbatch!(du,u,param,t,stoich,constantspecies,speciesaddition;kwargs...)
    V = u[19]
    species = vcat(u[1:14]/V,u[20:22],u[15]/V,constantspecies[1]/V,u[16:18]/V) #Get species concentrations in mol/L
    N_all = sum(stoich)
    #Reaction Dynamics
    (rates,balances) = ratesmodel(param,stoich,species;kwargs...)
    (V_seq,V_deg,V_tr,V_ds,CapFraction,V_precip,V_PPiase,V_nuc) = rates #Rates in mol/(L hr)
    (Chargebalance,Mgbalance,Nabalance) = balances
    N_A, N_U, N_C, N_G = stoich

    du[1:19] = speciesaddition(t) #Addition of species in mol/hr (addition of volume is in L/hr)

    #Effect of rates on state variables (adding on top of species addition)
    #V*DNAtot
    du[1] +=  - V_seq*V
    #V*T7RNAPtot
    du[2] += - V_deg*V
    #V*capRNAtot 
    du[3] +=  CapFraction*V_tr*V
    #V*uncapRNAtot 
    du[4] +=  (1-CapFraction)*V_tr*V
    #V*dsRNAtot 
    du[5] +=  V_ds*V
    #V*PPitot
    du[6] +=  ((N_all - 1)*(V_tr) - V_precip - V_PPiase)*V
    #V*ATPtot
    du[7] +=  -N_A*(V_tr)*V
    #V*UTPtot
    du[8] +=  -N_U*(V_tr)*V
    #V*CTPtot
    du[9] +=  -N_C*(V_tr)*V
    #V*GTPtot
    du[10] +=  -N_G*(V_tr)*V
    #V*Captot
    du[11] +=  -CapFraction*(V_tr)*V
    #V*Mgtot
    du[12] +=  -2*V_precip*V
    #V*Nuctot
    du[13] += V_nuc*V
    #V*Pitot
    du[14] += 2*V_PPiase*V
    # #V*Buffer
    # du[15] += 0
    # #V*Na
    # du[16] += 0
    # #V*Cl
    # du[17] += 0
    # #V*OAc
    # du[18] += 0
    # #V (L)
    # du[19] += 0
    #Algebraic Equations
    # Chargebalance
    du[20] = Chargebalance
    # Mg mass balance
    du[21] = Mgbalance
    # Na mass balance
    du[22] = Nabalance
    nothing
end

"""
    runDAE_batch(params::AbstractArray{T1}, inputs; saveevery = true, stoich = SVector(231, 246, 189, 202), PPi = 1e-18, PPiase = 0.0, Cap = 0, Pi = 1e-18, Nuc = 0, RNA = 0, tol = 1e-5, init_time = 0.0) where {T1<:Number}

Take parameters and reaction inputs and run DAE model of IVT. Returns solution object.
"""
function runfedbatch(params::AbstractArray{T1}, inputs; 
    continuousspeciesaddition = t -> zeros(19),
    discretespeciesaddition = reshape([Inf, 0.0, 0.0, 0.0], (1,4)),
    saveevery = true, 
    stoich = SVector(231, 246, 189, 202), 
    Na4PPi = 0.0, 
    PPiase = 0.0, 
    Cap = 0,
    Naanion = 0,
    tol = 1e-6, 
    inittime = 0.0,
    immobilized = false,
    seperateDNA = false,
    precip = true,
    OAccounterion = true,
    BufferperNTP = 0.0,
    NaperNTP = 3.96,
    bufferpKa = 8.1) where {T1<:Number}

    #Generate initialization
    nstatevars = 19
    nalgebraicvars = 3
    ntotalvars =  nstatevars+nalgebraicvars

    NTPnoncap = inputs.ATP + inputs.UTP + inputs.CTP + inputs.GTP
    NTPtot = NTPnoncap + Cap

    Buffer = inputs.Buffer


    Na = 4*Na4PPi+NaperNTP*NTPtot+Naanion #Akama
    PPi = 1e-9+Na4PPi
    if OAccounterion
        OAc = 2*inputs.Mg+Naanion
        Cl = Buffer*((1e-8*10^bufferpKa)/(1e-8*10^bufferpKa+1)) #Cl from HCl in Buffer - remove if using HEPES   note: removed 1e-8 -1e-6
    else
        OAc = 0
        Cl = 2*inputs.Mg+Naanion+Buffer*((1e-8*10^bufferpKa)/(1e-8*10^bufferpKa+1)) #Cl from HCl in Buffer - remove if using HEPES   note: removed 1e-8 -1e-6
    end

    Buffer = Buffer+BufferperNTP*NTPtot#Akama
    (DNA,T7RNAP,ATP,UTP,CTP,GTP,Mg) = (inputs.DNA,inputs.T7RNAP,inputs.ATP,inputs.UTP,inputs.CTP,inputs.GTP,inputs.Mg)
    capRNA = uncapRNA = dsRNA = Nuc = 0
    Pi = 1e-9
    V = 1#Volume in L
    sollist = []
    for (ind,(t_add,Mg_add,ATP_add,UTP_add,CTP_add,GTP_add,Na_add,vol_add)) in enumerate(eachrow(discretespeciesaddition))
        finaltime = min(inputs.final_time,t_add)
        initial = zeros(T1,ntotalvars)
        initial[1:nstatevars] = [DNA,T7RNAP,capRNA,uncapRNA,dsRNA,PPi,ATP,UTP,CTP,GTP,Cap,Mg,Nuc,Pi,Buffer, Na, Cl, OAc, V]#state variables in mol
        initial[(nstatevars+1):ntotalvars] = getfreeconcentrations(params, NTPtot/V, Mg/V, Buffer/V, PPi/V, Pi/V, Na/V, Cl/V, OAc/V)#We still pass these variables in mol/L
        constantspecies = [PPiase]

        #Run DAE and get solution object
        M = zeros(ntotalvars,ntotalvars)
        M[1:nstatevars,1:nstatevars] = I(nstatevars)
        f = ODEFunction(((du,u,param,t) -> ivt_fedbatch!(du,u,param,t,stoich,constantspecies,continuousspeciesaddition,immobilized=immobilized, seperateDNA = seperateDNA, precip = precip, bufferpKa = bufferpKa)),mass_matrix=M)
        prob_mm = ODEProblem(f,initial,(inittime,finaltime),params)
        sol = solve(prob_mm,Rodas4(),abstol=tol,reltol=tol,save_everystep=saveevery)
        append!(sollist,[sol])

        if inputs.final_time>t_add
            inittime = t_add
            (DNA,T7RNAP,capRNA,uncapRNA,dsRNA,PPi,ATP,UTP,CTP,GTP,Cap,Mg,Nuc,Pi,Buffer, Na, Cl, OAc, V, H, Mgfree, Nafree) = sol[:,end]
            #Addition
            NTP_add = ATP_add+UTP_add+CTP_add+GTP_add
            V += vol_add
            Mg += Mg_add
            Cl += 2*Mg_add*!OAccounterion
            OAc += 2*Mg_add*OAccounterion
            ATP += ATP_add
            UTP += UTP_add
            CTP += CTP_add
            GTP += GTP_add
            Na += NTP_add*NaperNTP+Na_add
            Buffer += NTP_add*BufferperNTP
            NTPtot = ATP + UTP + CTP + GTP + Cap
        end
    end

   return sollist
end  