"""
    ivt_batch!(du,u,param,t,stoich,constantspecies)

Timestep of DAE showing time evolution of vector u by infinetesimal du.

"""
function ivt_batch!(du,u,param,t,stoich,constantspecies;kwargs...)
    species = vcat(u,constantspecies)
    N_all = sum(stoich)
    #Reaction Dynamics
    (rates,balances) = ratesmodel(param,stoich,species;kwargs...)
    (V_seq,V_deg,V_tr,V_ds,CapFraction,V_precip,V_PPiase,V_nuc) = rates
    (Chargebalance,Mgbalance,Nabalance) = balances
    N_A, N_U, N_C, N_G = stoich
    #Differential Equations
    #DNAtot
    du[1] =  - V_seq
    #T7RNAPtot
    du[2] = - V_deg
    #capRNAtot 
    du[3] =  CapFraction*V_tr
    #uncapRNAtot 
    du[4] =  (1-CapFraction)*V_tr
    #dsRNAtot 
    du[5] =  V_ds
    #PPitot
    du[6] =  (N_all - 1)*(V_tr) - V_precip - V_PPiase
    #ATPtot
    du[7] =  -N_A*(V_tr)
    #UTPtot
    du[8] =  -N_U*(V_tr)
    #CTPtot
    du[9] =  -N_C*(V_tr)
    #GTPtot
    du[10] =  -N_G*(V_tr)
    #Captot
    du[11] =  -CapFraction*(V_tr)
    #Mgtot
    du[12] =  -2*V_precip
    #Nuctot
    du[13] = V_nuc
    #Pitot
    du[14] = 2*V_PPiase
    
    #Algebraic Equations
    # Chargebalance
    du[15] = Chargebalance
    # Mg mass balance
    du[16] = Mgbalance
    # Na mass balance
    du[17] = Nabalance
    nothing
end

"""
    runDAE_batch(params::AbstractArray{T1}, inputs; saveevery = true, stoich = SVector(231, 246, 189, 202), PPi = 1e-18, PPiase = 0.0, Cap = 0, Pi = 1e-18, Nuc = 0, RNA = 0, tol = 1e-5, init_time = 0.0) where {T1<:Number}

Take parameters and reaction inputs and run DAE model of IVT. Returns solution object.
"""
function runDAE_batch(params::AbstractArray{T1}, inputs; 
    saveevery = true, 
    stoich = SVector(231, 246, 189, 202), 
    PPi = 1e-18, 
    Na4PPi = 0.0, 
    PPiase = 0.0, 
    Cap = 0,
    Pi = 1e-18, 
    Nuc = 0, 
    RNA = 0, 
    Naanion = 0,
    tol = 1e-6, 
    init_time = 0.0,
    immobilized = false,
    seperateDNA = false,
    precip = true,
    observed = false,
    discreteobserved = false,
    OAccounterion = true,
    BufferperNTP = 0.0,
    NaperNTP = 3.96,
    bufferpKa = 8.1) where {T1<:Number}

    #Generate initialization
    nstatevars = 14
    nalgebraicvars = 3
    ntotalvars =  nstatevars+nalgebraicvars

    NTPnoncap = inputs.ATP + inputs.UTP + inputs.CTP + inputs.GTP
    NTPtot = NTPnoncap

    Buffer = inputs.Buffer

    #Na = 3.07*PPi+0.52*NTPnoncap+4*Cap#Arranta
    #Na = 3.07*PPi+0.001*NTPnoncap
    Na = 4*Na4PPi+3.07*PPi+NaperNTP*NTPtot+Naanion #Akama
    PPi = PPi+Na4PPi
    if OAccounterion
        OAc = 2*inputs.Mg+Naanion
        Cl = Buffer*((1e-8*10^bufferpKa)/(1e-8*10^bufferpKa+1)) #Cl from HCl in Buffer - remove if using HEPES   note: removed 1e-8 -1e-6
    else
        OAc = 0
        Cl = 2*inputs.Mg+Naanion+Buffer*((1e-8*10^bufferpKa)/(1e-8*10^bufferpKa+1)) #Cl from HCl in Buffer - remove if using HEPES   note: removed 1e-8 -1e-6
    end

    Buffer = Buffer+BufferperNTP*NTPtot#Akama

    initial = zeros(T1,ntotalvars)
    initial[1:nstatevars] = [inputs.DNA,inputs.T7RNAP,RNA,0,0,PPi,inputs.ATP,inputs.UTP,inputs.CTP,inputs.GTP,Cap,inputs.Mg,Nuc,Pi]
    initial[(nstatevars+1):ntotalvars] = getfreeconcentrations(params, NTPtot, inputs.Mg, Buffer, PPi, Pi, Na, Cl, OAc)
    constantspecies = [Buffer, PPiase, Na, Cl, OAc]

    #Run DAE and get solution object
    M = zeros(ntotalvars,ntotalvars)
    M[1:nstatevars,1:nstatevars] = I(nstatevars)
    f = ODEFunction(((du,u,param,t) -> ivt_batch!(du,u,param,t,stoich,constantspecies;immobilized=immobilized, seperateDNA = seperateDNA, precip = precip, bufferpKa = bufferpKa)),mass_matrix=M)
    prob_mm = ODEProblem(f,initial,(init_time,inputs.final_time),params)
    sol = solve(prob_mm,Rodas4(),abstol=tol,reltol=tol,save_everystep=saveevery)

    #If solution fails, rerun at a higher tolerance
    if (sol.retcode == ReturnCode.DtLessThanMin || sol.retcode == ReturnCode.Unstable)
        if tol>1e-12
            sol = runDAE_batch(params, inputs; saveevery = saveevery, stoich = stoich, PPi = PPi, PPiase = PPiase, Cap = Cap, Pi = Pi, Nuc = Nuc, RNA = RNA, tol = 0.1*tol, init_time = init_time, OAccounterion= OAccounterion)
       end
   end
   return sol
end  

###################################################
###################################################
###################################################
###################################################
###################################################
# Modified by Aatif for CSTR model


function ivt_CSTR!(du, u, param, t, stoich, constantspecies, C_in, τ; kwargs...)
    species = vcat(u, constantspecies)
    N_all = sum(stoich)
    # Reaction Dynamics
    (rates, balances) = ratesmodel(param, stoich, species; kwargs...)
    (V_seq, V_deg, V_tr, V_ds, CapFraction, V_precip, V_PPiase, V_nuc) = rates
    (Chargebalance, Mgbalance, Nabalance) = balances
    N_A, N_U, N_C, N_G = stoich

    # Flow term factor
    flow_factor = 1 / τ  # τ = V / Q

    # Differential Equations with Flow Terms
    # DNAtot
    du[1] = flow_factor * (C_in[1] - u[1]) - V_seq
    # T7RNAPtot
    du[2] = flow_factor * (C_in[2] - u[2]) - V_deg
    # capRNAtot
    du[3] = flow_factor * (C_in[3] - u[3]) + CapFraction * V_tr
    # uncapRNAtot
    du[4] = flow_factor * (C_in[4] - u[4]) + (1 - CapFraction) * V_tr
    # dsRNAtot
    du[5] = flow_factor * (C_in[5] - u[5]) + V_ds
    # PPitot
    du[6] = flow_factor * (C_in[6] - u[6]) + (N_all - 1) * V_tr - V_precip - V_PPiase
    # ATPtot
    du[7] = flow_factor * (C_in[7] - u[7]) - N_A * V_tr
    # UTPtot
    du[8] = flow_factor * (C_in[8] - u[8]) - N_U * V_tr
    # CTPtot
    du[9] = flow_factor * (C_in[9] - u[9]) - N_C * V_tr
    # GTPtot
    du[10] = flow_factor * (C_in[10] - u[10]) - N_G * V_tr
    # Captot
    du[11] = flow_factor * (C_in[11] - u[11]) - CapFraction * V_tr
    # Mgtot
    du[12] = flow_factor * (C_in[12] - u[12]) - 2 * V_precip
    # Nuctot
    du[13] = flow_factor * (C_in[13] - u[13]) + V_nuc
    # Pitot
    du[14] = flow_factor * (C_in[14] - u[14]) + 2 * V_PPiase

    # Algebraic Equations (No flow terms for algebraic variables)
    # Chargebalance
    du[15] = Chargebalance
    # Mg mass balance
    du[16] = Mgbalance
    # Na mass balance
    du[17] = Nabalance
    nothing
end

# runDAE_CSTR similar to batch but with flow terms 
function runDAE_CSTR(params::AbstractArray{T1}, inputs, Q, V; 
    saveevery = true, 
    stoich = SVector(231, 246, 189, 202), 
    PPi = 1e-18, 
    Na4PPi = 0.0, 
    PPiase = 0.0, 
    Cap = 0,
    Pi = 1e-18, 
    Nuc = 0, 
    RNA = 0, 
    Naanion = 0,
    tol = 1e-6, 
    init_time = 0.0,
    immobilized = false,
    seperateDNA = false,
    precip = true,
    observed = false,
    discreteobserved = false,
    OAccounterion = true,
    BufferperNTP = 0.0,
    NaperNTP = 3.96,
    bufferpKa = 8.1,
    saveat = nothing) where {T1<:Number}

    # Calculate residence time
    τ = V / Q

    # Generate initialization
    nstatevars = 14
    nalgebraicvars = 3
    ntotalvars = nstatevars + nalgebraicvars

    NTPnoncap = inputs.ATP + inputs.UTP + inputs.CTP + inputs.GTP
    NTPtot = NTPnoncap

    Buffer = inputs.Buffer

    Na = 4 * Na4PPi + 3.07 * PPi + NaperNTP * NTPtot + Naanion
    PPi = PPi + Na4PPi
    if OAccounterion
        OAc = 2 * inputs.Mg + Naanion
        Cl = Buffer * ((1e-8 * 10^bufferpKa) / (1e-8 * 10^bufferpKa + 1))
    else
        OAc = 0
        Cl = 2 * inputs.Mg + Naanion + Buffer * ((1e-8 * 10^bufferpKa) / (1e-8 * 10^bufferpKa + 1))
    end

    Buffer = Buffer + BufferperNTP * NTPtot

    initial = zeros(T1, ntotalvars)
    initial[1:nstatevars] = [inputs.DNA, inputs.T7RNAP, RNA, 0, 0, PPi, inputs.ATP, inputs.UTP, inputs.CTP, inputs.GTP, Cap, inputs.Mg, Nuc, Pi]
    initial[(nstatevars + 1):ntotalvars] = getfreeconcentrations(params, NTPtot, inputs.Mg, Buffer, PPi, Pi, Na, Cl, OAc)

    constantspecies = [Buffer, PPiase, Na, Cl, OAc]

    # Set up inlet concentrations (C_in)
    C_in = initial[1:14]  # Assuming inlet concentrations are the same as initial concentrations

    # Run DAE and get solution object
    M = zeros(ntotalvars, ntotalvars)
    M[1:nstatevars, 1:nstatevars] = I(nstatevars)
    f = ODEFunction(((du, u, param, t) -> ivt_CSTR!(du, u, param, t, stoich, constantspecies, C_in, τ; 
        immobilized = immobilized, seperateDNA = seperateDNA, precip = precip, bufferpKa = bufferpKa)), 
        mass_matrix = M)
    prob_mm = ODEProblem(f, initial, (init_time, inputs.final_time), params)

        # Solver call with 'saveat' if it's provided
    if saveat !== nothing
        sol = solve(prob_mm, Rodas4(), abstol = tol, reltol = tol, saveat = saveat)
    else
        sol = solve(prob_mm, Rodas4(), abstol = tol, reltol = tol)
    end


    # Solver call with 'saveat'
    # sol = solve(prob_mm, Rodas4(), abstol = tol, reltol = tol, saveat = saveat)


   # sol = solve(prob_mm, Rodas4(), abstol = tol, reltol = tol, save_everystep = saveevery)


    return sol
end

