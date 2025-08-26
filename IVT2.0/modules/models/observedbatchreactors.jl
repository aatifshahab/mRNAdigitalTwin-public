"""
    ivt_batchLobserver!!(du,u,param,t,stoich,constantspecies)

Timestep of DAE showing time evolution of vector u by infinetesimal du using Luenburger observer.

"""
function ivt_batchLobserver!(du,u,param,t,stoich,constantspecies,L,continuousdata; seperateDNA, NaperNTP)
    species = vcat(u,constantspecies)
    species = vcat(u[1:14],u[17:19],constantspecies[1],constantspecies[2],u[15:16])
    N_all = sum(stoich)
    #Reaction Dynamics
    (rates,balances) = ratesmodel(param,stoich,species; seperateDNA)
    (V_seq,V_deg,V_tr,V_ds,CapFraction,V_precip,V_PPiase,V_nuc) = rates
    (Chargebalance,Mgbalance,Nabalance) = balances
    N_A, N_U, N_C, N_G = stoich
    NTPstoich = [stoich...]
    minthreshold = 1e-6
    #Luenburger observer: RNA influence on data
    #NTPupdate = NTPstoich * L[1] * (continuousdata(t)[1]-1e6*(u[3] .+ u[4]))
    NTPupdate = (NTPstoich * L[1:2]' * [continuousdata(t)[1]-1e6*(u[3] .+ u[4]),continuousdata(t)[6]-(-log10(u[17]))])
    NTPupdate = NTPupdate*(u[3]+u[4]>minthreshold || sum(NTPupdate)>0)
    NTPupdate = [(u[6+i]>minthreshold || NTPupdate[i]<0)*NTPupdate[i] for i in 1:length(NTPupdate)]
    Vtrupdate = sum(NTPupdate)/sum(NTPstoich)
    
    extraNTPupdate = -L[4] .* (continuousdata(t)[2:5] -1e3*(u[7:10]))
    NTPupdate += extraNTPupdate

    pHupdate = L[3] * (continuousdata(t)[6]-(-log10(u[17]))) - sum(extraNTPupdate)*NaperNTP
    if u[15]<minthreshold && pHupdate<0
        Clupdate = -pHupdate
        pHupdate = 0
    else
        Clupdate = 0
    end

    #Differential Equations
    #DNAtot
    du[1] =  - V_seq
    #T7RNAPtot
    du[2] = - V_deg
    #capRNAtot 
    du[3] =  CapFraction*(V_tr + Vtrupdate)
    #uncapRNAtot 
    du[4] =  (1-CapFraction)*(V_tr + Vtrupdate)
    #dsRNAtot 
    du[5] =  V_ds
    #PPitot
    du[6] =  (N_all - 1)*(V_tr) - V_precip - V_PPiase
    #ATPtot
    du[7] =  -N_A*V_tr - NTPupdate[1]
    #UTPtot
    du[8] =  -N_U*V_tr - NTPupdate[2]
    #CTPtot
    du[9] =  -N_C*V_tr - NTPupdate[3]
    #GTPtot
    du[10] =  -N_G*V_tr - NTPupdate[4]
    #Captot
    du[11] =  -CapFraction*V_tr#  - NTPupdate[5]
    #Mgtot
    du[12] =  -2*V_precip
    #Nuctot
    du[13] = V_nuc
    #Pitot
    du[14] = 2*V_PPiase + (N_all - 1)*2*Vtrupdate
    #Natot
    du[15] = pHupdate
    #Cltot
    du[16] = Clupdate
    #Algebraic Equations
    # Chargebalance
    du[17] = Chargebalance
    # Mg mass balance
    du[18] = Mgbalance
    # Na mass balance
    du[19] = Nabalance
    nothing
end

"""
    runDAE_batch(params::AbstractArray{T1}, inputs; saveevery = true, stoich = SVector(231, 246, 189, 202), PPi = 1e-18, PPiase = 0.0, Cap = 0, Pi = 1e-18, Nuc = 0, RNA = 0, tol = 1e-5, init_time = 0.0) where {T1<:Number}

Take parameters and reaction inputs and run DAE model of IVT. Returns solution object.
"""
function runobservedbatch(params::AbstractArray{T1}, inputs,L,continuousdata; 
    saveevery = true, 
    stoich = SVector(231, 246, 189, 202), 
    PPi = 1e-18, 
    PPiase = 0.0, 
    Cap = 0, 
    Pi = 1e-18, 
    Nuc = 0, 
    RNA = 0, 
    tol = 1e-6, 
    init_time = 0.0, 
    seperateDNA = false,
    Na = nothing,
    BufferperNTP = 0.0,
    NaperNTP = 3.96) where {T1<:Number}

    #Generate initialization
    nstatevars = 16
    nalgebraicvars = 3
    ntotalvars =  nstatevars+nalgebraicvars

    NTPnoncap = inputs.ATP + inputs.UTP + inputs.CTP + inputs.GTP
    NTPtot = NTPnoncap + Cap

    if isnothing(Na)
        Na = 3.07*PPi+NaperNTP*NTPnoncap
    end

    Buffer = inputs.Buffer
    buffer_pka = 8.1
    Cl = 2*inputs.Mg+Buffer*((1e-8*10^buffer_pka)/(1e-8*10^buffer_pka+1)) #Cl from HCl in Buffer - remove if using HEPES   note: removed 1e-8 -1e-6
    Buffer = Buffer+BufferperNTP*NTPnoncap

    initial = zeros(T1,ntotalvars)
    initial[1:nstatevars] = [inputs.DNA,inputs.T7RNAP,RNA,0,0,PPi,inputs.ATP,inputs.UTP,inputs.CTP,inputs.GTP,Cap,inputs.Mg,Nuc,Pi,Na,Cl]
    initial[(nstatevars+1):ntotalvars] = getfreeconcentrations(params, NTPtot, inputs.Mg, Buffer, PPi, Pi, Na, Cl)
    constantspecies = [Buffer, PPiase]

    #Run DAE and get solution object
    M = zeros(ntotalvars,ntotalvars)
    M[1:nstatevars,1:nstatevars] = I(nstatevars)
    f = ODEFunction(((du,u,param,t) -> ivt_batchLobserver!(du,u,param,t,stoich,constantspecies,L,continuousdata; seperateDNA, NaperNTP)),mass_matrix=M)
    prob_mm = ODEProblem(f,initial,(init_time,inputs.final_time),params)
    sol = solve(prob_mm,Rodas4(),abstol=tol,reltol=tol,save_everystep=saveevery)

    #If solution fails, rerun at a higher tolerance
    if (sol.retcode == ReturnCode.DtLessThanMin || sol.retcode == ReturnCode.Unstable)
        if tol>1e-12
            sol = runDAE_batch(params, inputs; saveevery = saveevery, stoich = stoich, PPi = PPi, PPiase = PPiase, Cap = Cap, Pi = Pi, Nuc = Nuc, RNA = RNA, tol = 0.1*tol, init_time = init_time)
       end
   end
   return ("continuousobserved",sol)
end  