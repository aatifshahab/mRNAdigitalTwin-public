"""
    parseexceltuple(s::AbstractString) 

Parse tuple cells in csv data.
"""
function parseexceltuple(s::AbstractString) 
    if s[1]=='('
        if length(s)==2
            return []
        elseif s[end-1]==','
            return parse.(Float64, split(s[2:end-2], ','))
        else
            return (parse.(Float64, split(s[2:end-1], ',')))
        end
    else
          return [parse(Float64, s)]
    end
end
function parseexceltuple(s::Number) 
    return [s]
end

function parseexceltuple(s::Missing)
    return []
end

function speciesindicies()
    #Global variables for species indexing
    RNAindex = 4
    PPiindex = 6
    Mgindex = 12
    return (RNAindex,PPiindex,Mgindex)
end

function getoutputfunction(outputlabel)
    label = lowercase(outputlabel)
    if label == "total rna"
        return totalrna, "Total RNA Concentration (μM)"
    elseif label == "capped rna"
        return cappedrna, "Capped RNA Concentration (μM)"
    elseif label == "uncapped rna"
        return uncappedrna, "Uncapped RNA Concentration (μM)"
    elseif label == "capping fraction"
        return cappingfraction, "Capping Fraction"
    elseif label == "dsrna"
        return dsrna, "Double-Stranded RNA Concentration (nM)"
    elseif label == "dsrna fraction"
        return dsrnafraction, "dsRNA Fraction"
    elseif label == "dsrna percent"
        return dsrnapercent, "Percent dsRNA"
    elseif label == "atp"
        return atp, "ATP Concentration (mM)"
    elseif label == "utp"
        return utp, "UTP Concentration (mM)"
    elseif label == "ctp"
        return ctp, "CTP Concentration (mM)"
    elseif label == "gtp"
        return gtp, "GTP Concentration (mM)"
    elseif label == "cap"
        return cap, "Cap Concentration (mM)"
    elseif label == "magnesium" || label == "mg"
        return totalMg, "Total Mg Concentration (mM)"
    elseif label == "free magnesium" || label == "free mg"
        return freeMg, "Free Mg Concentration (mM)"
    elseif label == "merck free magnesium" || label == "merck free mg"
        return MerckfreeMg, "Free Mg Concentration (mM)"
    elseif label == "pyrophosphate" || label == "ppi"
        return totalPPi, "Total PPi Concentration (mM)"
    elseif label == "phosphate" || label == "pi"
        return phosphate, "Phosphate Concentration (mM)"
    elseif label == "supersaturation"
        return supersaturation, "Supersaturation"
    elseif label == "ph"
        return ph, "pH"
    elseif label == "ph after edta"
        return phEDTA, "pH"
    elseif label == "free mg"
        return freeMg, "Free Mg Concentration (mM)"
    elseif label == "ionic strength"
        return ionicstrength, "Ionic Strength (mM)"
    elseif label == "volume"
        return volume, "Normalized Volume"
    elseif label == "dodecamer"
        return dodecamer, "Concentration of Dodecamer (μM)"
    elseif label == "38mer"
        return thirtyeightmer, "Concentration of 38mer (μM)"
    elseif label == "atp conversion"
        return (x,p) -> conversion(x,p,limitingNTP = 1), "ATP Conversion"
    elseif label == "utp conversion"
        return (x,p) -> conversion(x,p,limitingNTP = 2), "UTP Conversion"
    elseif label == "ctp conversion"
        return (x,p) -> conversion(x,p,limitingNTP = 3), "CTP Conversion"
    elseif label == "gtp conversion"
        return (x,p) -> conversion(x,p,limitingNTP = 4), "GTP Conversion"
    elseif label == "rna moles"
        return (sol,p) -> totalrna(sol,p) .* volume(sol,p), "μmol of RNA per initial liter"
    elseif label == "shifted ph"
        return (x,p) -> ph(x,p) .- 1, "pH (Shifted)" 
    elseif label == "scaled total rna"
        return (x,p) -> 0.8 .*totalrna(x,p), "Total RNA Concentration (Scaled) (μM)"
    elseif label == "scaled ctp"
        return (x,p) -> 0.8 .*ctp(x,p), "CTP Concentration (Scaled) (mM)"
    else
        return ArgumentError("Invalid measurement label in data sheet.")
    end
end

function readdatarow(data)
    #Elements of data sheet rows converted to internal units of model
    specieslabel = data[1]
    times = parseexceltuple(data[2])
    T7RNAP = data[3]/1e9
    DNA = data[4]
    ATP = data[5]/1000
    UTP = data[6]/1000
    CTP = data[7]/1000
    GTP = data[8]/1000
    Cap = data[9]/1000
    Mg = data[10]/1000
    PPiase = data[11]
    Buffer = data[12]/1000
    N_A = data[15]
    N_U = data[16]
    N_C = data[17]
    N_G = data[18]
    PPi = data[19]/1000
    outputs = parseexceltuple(data[20])
    confinterval = parseexceltuple(data[21])
    
    #Get function for calculating output of solution object
    (speciesoutputfunction,speciesplotlabel) = getoutputfunction(specieslabel)

    #Can either input uncertainty as scalar or vector
    if length(confinterval) == 1
        confint = confinterval[1] .* ones(length(outputs))
    else
        confint = confinterval
    end

    #Used for maximum values in plots
    if lowercase(specieslabel) == "total rna"
        maximumoutput = 1e6*min((ATP/N_A),(UTP/N_U),(CTP/N_C),(GTP/N_G))
    else
        maximumoutput = Inf
    end 

    stoich = SVector(N_A, N_U, N_C, N_G)

    inputs =(T7RNAP = T7RNAP, ATP = ATP,UTP = UTP,CTP = CTP,GTP = GTP, Mg = Mg, Buffer = Buffer, DNA = DNA, final_time = maximum(times))

    return outputs, confint, inputs, Cap, PPiase, PPi, stoich, times, speciesoutputfunction, speciesplotlabel, maximumoutput
end