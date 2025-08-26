
"""
    initialconcentrationresidual!(F, x, ptot, param)

Generate residual for nonlinear solving of free ion concentrations. Only used for initialization of DAE.

"""
function initialconcentrationresidual!(F, x, ptot, param;buffer_pka = 8.1, RNAtotalbases = 0)
    H = exp(x[1])
    Mg = exp(x[2])
    Na = exp(x[3])
    (ions,(Chargebalance,Mgbalance,Nabalance)) = speciationmodel(param, RNAtotalbases, ptot.NTPtot, ptot.Mgtot, ptot.Buffertot, ptot.PPitot, ptot.Pitot, ptot.Natot, H, Mg, Na, ptot.Cltot, ptot.OActot,buffer_pka = buffer_pka)
    #Algebraic Equations
    # H mass balance
    F[1] = Chargebalance
    # Mg mass balance
    F[2] = Mgbalance
    #Na mass balance
    F[3] = Nabalance
    nothing
end

"""
    getfreeconcentrations(params::AbstractArray{T}, NTPtot, Mgtot, Buffertot, PPitot, Pitot)  where {T<:Real}

Take parameters and total concentration of ions, return free concentrations of H and Mg. Performs solving of nonlinear system of equations in log space. Only used for initialization of DAE.

"""
function getfreeconcentrations(params::AbstractArray{T}, NTPtot, Mgtot, Buffertot, PPitot, Pitot, Natot, Cltot, OActot; buffer_pka = 8.1, RNAtotalbases = 0, init = log.([1e-7,0.0001,Natot]))  where {T<:Real}
    #Defining Parameters
    initialtotalconcentrations = (NTPtot=NTPtot, Mgtot=Mgtot, Buffertot=Buffertot, PPitot = PPitot, Pitot = Pitot, Natot = Natot, Cltot = Cltot, OActot = OActot)
    guessfreeconcentrations = zeros(T,3)
    guessfreeconcentrations += init
    logsolvedfreeconcentrations = nlsolve((F,x)->initialconcentrationresidual!(F, x, initialtotalconcentrations, params,buffer_pka = buffer_pka, RNAtotalbases = RNAtotalbases), guessfreeconcentrations,ftol = 1e-8)
    solvedfreeconcentrations = [exp(x) for x in logsolvedfreeconcentrations.zero]
    return solvedfreeconcentrations
end


function getfreeconcentrations(params::AbstractArray{Float64}, NTPtot, Mgtot, Buffertot, PPitot, Pitot, Natot::Float64, Cltot, OActot; buffer_pka = 8.1, RNAtotalbases = 0, init = log.([1e-7,0.0001,Natot]))
    #Defining Parameters
    initialtotalconcentrations = (NTPtot=NTPtot, Mgtot=Mgtot, Buffertot=Buffertot, PPitot = PPitot, Pitot = Pitot, Natot = Natot, Cltot = Cltot, OActot = OActot)
    guessfreeconcentrations = zeros(3)
    guessfreeconcentrations += init
    logsolvedfreeconcentrations = nlsolve((F,x)->initialconcentrationresidual!(F, x, initialtotalconcentrations, params,buffer_pka = buffer_pka, RNAtotalbases = RNAtotalbases), guessfreeconcentrations,ftol = 1e-8)
    solvedfreeconcentrations = [exp(x) for x in logsolvedfreeconcentrations.zero]
    return solvedfreeconcentrations
end

"""
    speciationmodel(param, NTPtot, Mgtot, Buffertot, PPitot, Pitot, H, Mg)

Take parameters and total concentration of ions, return concentrations of ionic species and ion equilibrium residuals for use in rate calculations and DAE solving.

"""
function speciationmodel(param, RNAtotalbases, NTPtot, Mgtot, Buffertot, PPitot, Pitot, Natot, H, Mg, Na, Cl, OAc;buffer_pka = 8.1)

    #Dimensionless concentrations for NTP
    HNTP_dimless = H*param.K_HNTP
    HMgNTP_dimless = HNTP_dimless*Mg*param.K_HMgNTP
    MgNTP_dimless = Mg*param.K_MgNTP
    Mg2NTP_dimless = MgNTP_dimless*Mg*param.K_Mg2NTP
    NaNTP_dimless = Na*param.K_NaNTP

    #Dimensionless concentrations for PPi
    HPPi_dimless = H*param.K_HPPi
    HMgPPi_dimless = HPPi_dimless*Mg*param.K_HMgPPi
    H2PPi_dimless = HPPi_dimless*H*param.K_H2PPi
    H2MgPPi_dimless = H2PPi_dimless*Mg*param.K_H2MgPPi
    MgPPi_dimless = Mg*param.K_MgPPi
    Mg2PPi_dimless = MgPPi_dimless*Mg*param.K_Mg2PPi

    #Dimensionless concentrations for Buffer
    HBuffer_dimless = H*10^buffer_pka
    
    #Dimensionless concentrations for Pi
    MgPi_dimless = Mg*param.K_MgPi
    HPi_dimless = H*param.K_HPi
    NaPi_dimless = Na*param.K_NaPi

    #Solve for Anion Concentrations
    NTP = NTPtot/(1 + HNTP_dimless + HMgNTP_dimless + MgNTP_dimless + Mg2NTP_dimless + NaNTP_dimless)
    PPi = PPitot/(1 + MgPPi_dimless + Mg2PPi_dimless + HPPi_dimless + HMgPPi_dimless + H2PPi_dimless + H2MgPPi_dimless)
    Buffer = Buffertot/(1+HBuffer_dimless)
    Pi = Pitot/(1+MgPi_dimless+HPi_dimless+NaPi_dimless)
    OH = 10^-14/H

    #Redimensionalizing concentrations for NTP
    HNTP = HNTP_dimless*NTP
    HMgNTP = HMgNTP_dimless*NTP
    MgNTP = MgNTP_dimless*NTP
    Mg2NTP = Mg2NTP_dimless*NTP
    NaNTP = NaNTP_dimless*NTP

    #Redimensionalizing concentrations for PPi
    HPPi = HPPi_dimless*PPi
    HMgPPi = HMgPPi_dimless*PPi
    H2PPi = H2PPi_dimless*PPi
    H2MgPPi = H2MgPPi_dimless*PPi
    MgPPi = MgPPi_dimless*PPi
    Mg2PPi = Mg2PPi_dimless*PPi

    #Redimensionalizing concentrations for Buffer
    HBuffer = HBuffer_dimless*Buffer
    
    #Redimensionalizing concentrations for Pi
    MgPi = MgPi_dimless*Pi
    HPi = HPi_dimless*Pi
    NaPi = NaPi_dimless*Pi

    #Algebraic Equations
    #Change balance
    #total charge equations (correct but slower)
    negativecharge = OAc+Cl+OH+4*NTP+4*PPi+2*Pi+3*HNTP+HMgNTP+2*MgNTP+3*NaNTP+3*HPPi+HMgPPi+2*H2PPi+2*MgPPi+HPi+NaPi+RNAtotalbases
    positivecharge = H+HBuffer+Na+2*Mg

    ionicstrength = 0.5*(OAc+Cl+OH+4^2*NTP+4^2*PPi+2^2*Pi+3^2*HNTP+HMgNTP+2^2*MgNTP+3^2*NaNTP+3^2*HPPi+HMgPPi+2^2*H2PPi+2^2*MgPPi+HPi+NaPi+RNAtotalbases+H+HBuffer+Na+2^2*Mg)

    #totalfreeions = Cl+OH+NTP+PPi+Pi+HNTP+HMgNTP+MgNTP+NaNTP+HPPi+HMgPPi+H2PPi+MgPPi+HPi+NaPi+H+HBuffer+Na+Mg
    totalcation = 4*Mg

    #PPi only (good for pyrophosphate solutions)
    # negativecharge = Cl+OH+4*PPi+3*HPPi+2*H2PPi
    # positivecharge = H+HBuffer+Na

    #NTP only (good for NTP solutions)
    # negativecharge = Cl+OH+4*NTP+3*HNTP+3*NaNTP
    # positivecharge = H+HBuffer+Na

    #Basic (good for strongly buffered solutions where pH doesn't matter much)
    # negativecharge = Cl+OH
    # positivecharge = H+HBuffer

    Chargebalance  = 1-(negativecharge)/(positivecharge)
    # Mg mass balance
    Mgbalance = 1 - (1/(Mgtot)) * (Mg + MgPPi + HMgPPi + MgNTP + 2*Mg2NTP + 2*Mg2PPi + HMgNTP + H2MgPPi + MgPi)
    # Na mass balance
    Nabalance = 1 - (1/(Natot)) * (Na + NaPi + NaNTP)

    ionspecies = (Mg,MgNTP,MgPPi,Mg2PPi,H,ionicstrength,totalcation)
    balances = (Chargebalance,Mgbalance,Nabalance)
    return (ionspecies,balances)
end

"""
    pHfactor(params,H)

Effect of pH on reaction rate.

"""
function pHfactor(params,H)
    denom = 1+H/params.K_a+params.K_b/H
    return params.k_pH/denom
end

"""
    dimensionlesspHfactor(params,H)

Effect of pH on reaction rate.

"""
function dimensionlesspHfactor(params,H)
    denom = 1+H/params.K_a+params.K_b/H
    return 1/denom
end

# function empiricalISeffect(IS)#IS in mM
#     return 1-1/(1+(0.2/IS)^6)
# end

"""
    ratesmodel(param,stoich,species)

Take parameters and concentration of all species (total and free ions), return rates of processes and balances for use in DAE.

"""
function ratesmodel(param,stoich,species; immobilized = false, seperateDNA = false, precip = true, bufferpKa = 8.1)
    #Species common to all reactors
    (DNAtot, RNAPtot, capRNAtot, uncapRNAtot, dsRNAtot, PPitot, ATPtot, UTPtot, CTPtot, GTPtot, Captot, Mgtot, Nuctot, Pitot, H, Mg, Na, Buffertot, PPiasetot, Natot, Cl, OAc) = species
    RNAtot = capRNAtot+uncapRNAtot
    NTPtot = ATPtot + UTPtot + CTPtot + GTPtot# + Captot

    #Using speciation model to calculate complex concentrations
    (ions,balances) = speciationmodel(param, RNAtot*(sum(stoich)+2), NTPtot, Mgtot, Buffertot, PPitot, Pitot, Natot, H, Mg, Na, Cl, OAc; buffer_pka = bufferpKa)
    (Mg,MgNTP,MgPPi,Mg2PPi,H,ionicstrength,totalcation) = ions
    MgNTPs = (MgNTP/NTPtot) .*[ATPtot, UTPtot, CTPtot, GTPtot] #Concentrations of MgATP, MgUTP, MgCTP, MgGTP
    MgCap = Captot#MgNTP*Captot/NTPtot

    #Calculating Capping Fraction
    #CapFraction = MgCap/(MgCap+(param.gamma/(param.theta+MgNTPs[4]))*MgNTPs[1]*MgNTPs[4])#Trinucleoside
    CapFraction = MgCap/(MgCap+param.gamma*GTPtot)#Binucleoside
    
    #Calculating T7RNAP degredation rate
    V_deg = param.k_dT7*RNAPtot

    #Calculating Transcription Rate
    if all(MgNTPs .>0)
        #k_Ns = param.k_e .* Mg.* MgNTPs ./(param.K_1*param.K_2+param.K_1*Mg+MgNTP*Mg)
        #k_Ns = param.k_e .* Mg.* MgNTPs ./(MgNTPs .*Mg .+param.K_1 .*Mg .+param.K_2 .+param.Ki_PPi .*MgPPi)
        #competitiveNTP = NTPtot .- MgNTPs
        K_2 = param.K_2*exp(param.nMg*sqrt(abs(ionicstrength)))
        K_1 = param.K_1
        if seperateDNA
            k_i = param.k_i_guo
            k_e = param.k_e_guo
        else
            k_i = param.k_i
            k_e = param.k_e
        end
        #     #k_Ns =  empiricalISeffect(ionicstrength)* param.k_e_seperateDNA .* ((MgNTPs ./(MgNTPs .+param.K_1*(1 .+ MgPPi ./param.Ki_PPi))) .*abs(Mg)^param.nMg/((param.K_2^param.nMg+abs(Mg)^param.nMg)))
        #     #k_Ns = param.k_e_seperateDNA .* Mg.* MgNTPs ./(param.K_1*param.K_2+param.K_1*Mg+MgNTP*Mg)
        #     k_Ns =  param.k_e_seperateDNA .* ((MgNTPs ./(MgNTPs .+K_1*(1 .+ (MgPPi) ./param.Ki_PPi))) .*Mg/((K_2+Mg)))
        #     #k_Ns =  param.k_e_seperateDNA .* ((MgNTPs ./(MgNTPs .+K_1)) .*Mg/((K_2+Mg)))
        # else
        #     #k_Ns =  param.k_e .* ((MgNTPs ./(MgNTPs .+K_1*(1 .+ Mg ./param.Ki_PPi))) .*Mg/((K_2+Mg)))
        #     k_Ns = param.k_e .* ((MgNTPs ./(MgNTPs .+K_1*(1 .+ (MgPPi) ./param.Ki_PPi))) .*Mg/((K_2+Mg)))
        #     #k_Ns =  param.k_e .* ((MgNTPs ./(MgNTPs .+K_1)) .*Mg/((K_2+Mg)))
        # end
        k_Ns = k_e .* ((MgNTPs ./(MgNTPs .+K_1*(1 .+ (MgPPi) ./param.Ki_PPi))) .*Mg/((K_2+Mg)))

        #k_Ns = param.k_e .* ((MgNTPs ./(MgNTPs .+param.K_1)) .*Mg/((param.K_2+Mg)))

        k_E = sum(stoich)/sum(stoich ./ k_Ns)
        k_I = k_i*k_E/k_e
        #k_I = sum(stoich)* param.k_i
        #k_I = sum(stoich)* param.k_i / sum(stoich ./(MgNTPs ./(MgNTPs .+param.K_1*(1+MgPPi/param.Ki_PPi))) .*Mg/((param.K_2+Mg)))
        #k_Ns = (param.k_e .*MgNTPs ./(MgNTPs .+param.K_1)) .*Mg/((param.K_2+Mg))
        #alpha = 1+param.k_i*sum(stoich ./ k_Ns)
        #alpha = 1+k_I*sum(stoich ./ k_Ns)
        alpha = 1+k_i*sum(stoich)/k_e
        #K_MD = (param.k_off+param.k_i)/param.k_on
        #K_MD = (param.k_off+k_I)/param.k_on
        #log_k_off = log(1e9*param.k_on) - (20.25 - 2.75*(log(Cl)-log(14e-3)))
        #k_off = exp(log_k_off)
        K_MD = (((1+(Cl*param.K_u0)^4)*(1+(Mg*param.K_Mg)^4))*param.k_off+k_i)/(param.k_on)
        RNAnM = RNAPtot*1e9 # RNA in nm
        IC = ((K_MD+RNAnM+DNAtot*alpha) - sqrt((K_MD+RNAnM+DNAtot*alpha)^2-4*RNAnM*DNAtot*alpha))/(2*alpha) #Initiation Complex concentration
        if immobilized
            #K_MD = (param.k_off+k_I)/(param.k_on)

            #K_MD = (param.k_off+param.omega*k_I)/(param.k_on)
            #V_tr = param.omega*1e-9*param.k_i*RNAnM*DNAtot/(K_MD+RNAnM)
            #V_tr = param.omega*1e-9*k_I*RNAnM*DNAtot/(K_MD+RNAnM)
            V_tr = dimensionlesspHfactor(param,H)*1e-9*k_I*RNAnM*DNAtot/(K_MD+RNAnM)

        else
            #V_tr = 1e-9*param.k_i*IC
            V_tr = dimensionlesspHfactor(param,H)*1e-9*k_I*IC
            #V_tr = 1e-9*k_I*IC
        end
        V_ds = IC/(DNAtot+IC+1e-6)*param.K_ds*RNAtot#
    else 
        V_tr = 0
        V_ds = 0
    end

    #Calculating rate of nucleation and crystal growth
    S = Mg2PPi/param.Mg2PPi_eq
    if (S>1) && precip
        B = param.B
        V_nuc = exp(-(B)/log(S)^2)
        V_precip = param.k_precip*Nuctot*log(S)
    else
        V_nuc = 0
        V_precip = 0
    end
    
    #Calculating rate of degradation of PPi by PPiase 
    if MgPPi > 0
        V_PPiase = 60*param.kPPiase*PPiasetot*MgPPi/(MgPPi+param.KMPPiase)
    else
        V_PPiase = 0
    end
    
    #Calculating rate of sequestration of DNA by nuclei
    if DNAtot > 0
        V_seq = param.k_d*(Nuctot)*DNAtot
    else
        V_seq = 0
    end

    rates = (V_seq,V_deg,V_tr,V_ds,CapFraction,V_precip,V_PPiase,V_nuc)
    return (rates,balances)
end




