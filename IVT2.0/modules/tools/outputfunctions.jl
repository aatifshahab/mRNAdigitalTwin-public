function dodecamer(sol,p)
    return 0.45*totalrna(sol,p)
end

function thirtyeightmer(sol,p)
    return 0.65*totalrna(sol,p)
end

function totalrna(sol,p)#Total RNA concentration in mM
    if sol[1]=="fedbatch"
        sol = sol[2]
        return 1e6*(sol[3,:] .+ sol[4,:]) ./sol[19,:]
    elseif sol[1]=="continuousobserved"
        sol = sol[2]
        return 1e6*(sol[3,:] .+ sol[4,:])    
    else
        return 1e6*(sol[3,:] .+ sol[4,:])    
    end
end                                                
cappedrna(sol,p) = 1e6*sol[3,:]                                                                 #capped RNA concentration in mM
uncappedrna(sol,p) = 1e6*sol[4,:]    #uncapped RNA concentration in mM


function cappingfraction(sol,p)   
    if sol[1]=="fedbatch"
        sol = sol[2]
    end
    cappingfractions = zeros(length(sol[3,:]))
    for (ind,i) in enumerate(sol[2,:])
        if (sol[3,ind] + sol[4,ind]) > 0
            cappingfractions[ind] = (sol[3,ind]) ./ (sol[3,ind] .+ sol[4,ind]) 
        end
    end
    if sol.t[1] == 0.0
        cappingfractions[1] = cappingfractions[2]
    end
    return cappingfractions
end


dsrna(sol,p) = 1e9*sol[5,:]                                                                    #dsRNA concentration in nM
dsrnapercent(sol,p) = 1e2 .* dsrnafraction(sol,p)                                              #dsRNA percent

function dsrnafraction(sol,p)                                                                  #dsRNA fraction
    dsrnafractions = []
    for (ind,i) in enumerate(sol[5,:])
        if (sol[3,ind] .+ sol[4,ind]) > 0
            dsrnafraction = (sol[5,ind]) ./ (sol[3,ind] .+ sol[4,ind]) 
            append!(dsrnafractions,dsrnafraction)
        else
            append!(dsrnafractions,0.0)
        end
    end
    if sol.t[1] == 0.0
        dsrnafractions[1] = dsrnafractions[2]
    end
    return dsrnafractions
end


totalMg(sol,p) = 1e3*sol[12,:]                                                                  #total Mg concentration in mM
freeMg(sol,p) = 1e3*sol[16,:]                                                                   #free Mg concentration in mM

totalPPi(sol,p) = 1e3*sol[6,:]                                                                  #PPi concentration in mM

function atp(sol,p)      
    if sol[1]=="fedbatch"
        sol = sol[2]
        return 1e3*(sol[7,:]) ./sol[19,:]                                                                       #ATP concentration in mM
    elseif sol[1]=="continuousobserved"
        sol = sol[2]
        return 1e3*sol[7,:]
    else
        return 1e3*sol[7,:]
    end
end  

function utp(sol,p)      
    if sol[1]=="fedbatch"
        sol = sol[2]
        return 1e3*(sol[8,:]) ./sol[19,:]                                                                       #ATP concentration in mM
    elseif sol[1]=="continuousobserved"
        sol = sol[2]
        return 1e3*sol[8,:]
    else
        return 1e3*sol[8,:]
    end
end    

function ctp(sol,p)      
    if sol[1]=="fedbatch"
        sol = sol[2]
        return 1e3*(sol[9,:]) ./sol[19,:]                                                                       #ATP concentration in mM
    elseif sol[1]=="continuousobserved"
        sol = sol[2]
        return 1e3*sol[9,:]
    else
        return 1e3*sol[9,:]
    end
end    

function gtp(sol,p)      
    if sol[1]=="fedbatch"
        sol = sol[2]
        return 1e3*(sol[10,:]) ./sol[19,:]                                                                       #ATP concentration in mM
    elseif sol[1]=="continuousobserved"
        sol = sol[2]
        return 1e3*sol[10,:]
    else
        return 1e3*sol[10,:]
    end
end    

function cap(sol,p)      
    if sol[1]=="fedbatch"
        sol = sol[2]
        return 1e3*(sol[11,:]) ./sol[19,:]                                                                       #ATP concentration in mM
    elseif sol[1]=="continuousobserved"
        sol = sol[2]
        return 1e3*sol[11,:]
    else
        return 1e3*sol[11,:]
    end
end  

phosphate(sol,p) = 1e3*sol[14,:]  
                                                              #Phosphate concentration in mM
function ph(sol,p)
    if sol[1]=="fedbatch"
        sol = sol[2]
        return -log10.(sol[20,:])
    elseif sol[1]=="continuousobserved"
        sol = sol[2]
        -log10.(sol[17,:])
    else
        -log10.(sol[15,:])
    end
end

function volume(sol,p)
    if sol[1]=="fedbatch"
        sol = sol[2]
        return sol[19,:]
    else
        return 1
    end
end
nucleationoccured(sol,p) = sol[13,end]!=0.0

function phEDTA(sol,param)                                                                      #pH after EDTA addition removes almost all Mg from system
    measuredpH = zeros(length(sol[1,:]))
    for (ind,i) in enumerate(sol[1,:])
        Buffer = 40e-3
        buffer_pka = 8.1
        Cltot = 2*26e-3+Buffer*((1e-8*10^buffer_pka)/(1e-8*10^buffer_pka+1)) #Cl from HCl in Buffer - remove if using HEPES   note: removed 1e-8 -1e-6
        Buffertot = Buffer+3.27*36e-3#Adding Tris buffer from NTP solutions
        Natot = 0.001*36e-3+ 3*4e-3#+3.42*NTPtot#+0.001*NTPtot

        NTPtot = (sol[7,ind] .+ sol[8,ind] .+ sol[9,ind] .+ sol[10,ind] .+ sol[11,ind])
        Mgtot = 1e-7#sol[12,ind]

        PPitot = sol[6,ind]
        Pitot = sol[14,ind]
        measuredpH[ind] = -log10(getfreeconcentrations(param, NTPtot, Mgtot, Buffertot, PPitot, Pitot, Natot, Cltot;buffer_pka = 8.1, RNAtotalbases = 2117*(sol[3,ind] + sol[4,ind]))[1])
    end
    return measuredpH
end            


function MerckfreeMg(sol,param;dilutionfactor = 1)                                                                 #free Mg concentration in mM attempting to account for Merck's measurement method
    measuredMg = zeros(length(sol[1,:]))
    for (ind,i) in enumerate(sol[1,:])
        NTPtot = (sol[7,ind] .+ sol[8,ind] .+ sol[9,ind] .+ sol[10,ind] .+ sol[11,ind])/dilutionfactor
        Mgtot = sol[12,ind]/dilutionfactor
        Cltot = Mgtot*2
        Buffertot = 0.100
        Natot = 1e-8+Buffertot*((10^(-0.45))/(10^(-0.45)+1))
        PPitot = sol[6,ind]/dilutionfactor
        Pitot = sol[14,ind]/dilutionfactor
        measuredMg[ind] = 1e3*getfreeconcentrations(param, NTPtot, Mgtot, Buffertot, PPitot, Pitot, Natot, Cltot;buffer_pka = 6.5)[2]
    end
    return measuredMg*dilutionfactor
end

function ionicstrength(sol,param)#Not counting for RNA
    is = zeros(length(sol[1,:]))
    for (ind,i) in enumerate(sol[1,:])
        NTPtot = (sol[7,ind] .+ sol[8,ind] .+ sol[9,ind] .+ sol[10,ind] .+ sol[11,ind])
        Mgtot = sol[12,ind]
        Buffertot = 0.040
        Cltot = Mgtot*2+Buffertot*((1e-8*10^8.1)/(1e-8*10^8.1+1)) 
        PPitot = sol[6,ind]
        Pitot = sol[14,ind]
        H = sol[15,ind]
        Mg = sol[16,ind]
        Na = sol[17,ind]
        Natot = 3.7*NTPtot #Akama
        is[ind] = 1e3*speciationmodel(param, 0, NTPtot, Mgtot, Buffertot, PPitot, Pitot, Natot, H, Mg, Na, Cltot, 0)[1][6]
    end 
    return is
end

function supersaturation(sol,param)
    supersaturations = zeros(length(sol[1,:]))
    for (ind,i) in enumerate(sol[1,:])
        NTPtot = sol[7,ind] .+ sol[8,ind] .+ sol[9,ind] .+ sol[10,ind] .+ sol[11,ind]
        Mgtot = sol[12,ind]
        Buffertot = 0.040
        Na = NTPtot
        PPitot = sol[6,ind]
        Pitot = sol[14,ind]
        H = sol[15,ind]
        Mg = sol[16,ind]
        supersaturations[ind] = speciationmodel(param, NTPtot, Mgtot, Buffertot, PPitot, Pitot, H, Mg, Na)[1][4]/param.Mg2PPi_eq
    end
    if sol.t[1] == 0.0
        supersaturations[1] = supersaturations[2]
    end
    return supersaturations
end

freeMg(sol,p) = 1e3*sol[16,:]                                                                  #free Mg concentration in mM

function conversion(sol,param; limitingNTP = 1)
    initialNTP = sol[6+limitingNTP,1]
    return -(sol[6+limitingNTP,:] ./ initialNTP) .+1
end

function IVTrate(sol,param; limitingNTP = 1)
    derivatives = sol(sol.t, Val{1})
    return derivatives[6+limitingNTP,:]
end