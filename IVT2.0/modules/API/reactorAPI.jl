using Pkg
# Pkg.activate("../IVTmodel")
# Pkg.instantiate()
# include("../IVTmodel.jl")


# Activate IVT2.0/IVTmodel RELATIVE to this file (portable)
Pkg.activate(normpath(joinpath(@__DIR__, "..", "..", "IVTmodel")))
Pkg.instantiate()

# Include the model file RELATIVE to this file
include(normpath(joinpath(@__DIR__, "..", "IVTmodel.jl")))

# Optional: print once for sanity during dev
# @info "Active Julia project" Base.active_project()

using CSV, DataFrames

# Project root and outputs dir RELATIVE to this file
const ROOT   = normpath(joinpath(@__DIR__, "..", ".."))
const OUTDIR = joinpath(ROOT, "outputs")

# Portable CSV loads (no machine-specific absolute paths)
akamafittedparametersmatrix = Matrix(CSV.read(joinpath(OUTDIR, "fittedparameters.csv"),
                                             DataFrame; header=false))
fittedparamslist = reshape(akamafittedparametersmatrix, (size(akamafittedparametersmatrix, 1),))
covariancemat = Matrix(CSV.read(joinpath(OUTDIR, "covariancematrix.csv"),
                                DataFrame; header=false))

#Generates settings for parameters used
fittingmodel = setupmodel_IVT4()


# akamafittedparametersmatrix = Matrix(CSV.read("C:/Users/User/mRNAdigitalTwin/IVT2.0/outputs/fittedparameters.csv", DataFrame,header=false))
# fittedparamslist = reshape(akamafittedparametersmatrix,(size(akamafittedparametersmatrix)[1],))
# covariancemat = Matrix(CSV.read("C:/Users/User/mRNAdigitalTwin/IVT2.0/outputs/covariancematrix.csv", DataFrame,header=false))
fittedparams = fullparameterset(fittingmodel,fittedparamslist)
alpha = 0.05

"""
    parameterized_IVT_PFR(parameters,T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; kwargs...)

Takes reactor inputs, (T7RNAP, etc) along with parameter values to generate single prediction. Can represent batch reaction (where spacetime=reaction time) or idealized PFR (where spacetime= reactor length/fluid speed)
""" 
# function parameterized_IVT_PFR(parameters,T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; outputfunction = totalrna, kwargs...)
#     inputs = (T7RNAP = T7RNAP, ATP = ATP,UTP = UTP,CTP = CTP,GTP = GTP, Mg = Mg, Buffer = 0.040, DNA = DNA, final_time = spacetime)
#     sol = runDAE_batch(parameters, inputs; kwargs...)
#     return (sol.t, outputfunction(sol,parameters))
# end
# modified by Aatif

function multiple_outputs(sol, parameters)
    return (
        ATP = atp(sol, parameters),
        UTP = utp(sol, parameters),
        CTP = ctp(sol, parameters),
        GTP = gtp(sol, parameters),
        Phosphate = phosphate(sol, parameters),
        pH = ph(sol, parameters),
        TotalMg = totalMg(sol, parameters),
        TotalRNA = totalrna(sol, parameters)
    )
end

function parameterized_IVT_PFR(parameters, T7RNAP, ATP, UTP, CTP, GTP, Mg, DNA, spacetime; outputfunction = totalrna, kwargs...)
    inputs = (T7RNAP = T7RNAP, ATP = ATP, UTP = UTP, CTP = CTP, GTP = GTP, Mg = Mg, Buffer = 0.040, DNA = DNA, final_time = spacetime)
    sol = runDAE_batch(parameters, inputs; kwargs...)
    
    # Check if the outputfunction is `multiple_outputs`, if so, return multiple values
    if outputfunction == multiple_outputs
        return (sol.t, sol, multiple_outputs(sol, parameters))
    else
        return (sol.t, sol, outputfunction(sol, parameters))
    end
end

"""
    IVT_PFR(T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; kwargs...)

Part of IVT API. Takes reactor inputs to generate single prediction using maximum likelihood parameter set. Can represent batch reaction (where spacetime=reaction time) or idealized PFR (where spacetime = reactor length/fluid speed)

### Inputs:
- T7RNAP: T7RNA polymerase input concentration (mol/L)
- ATP-GTP: Concentration of respective NTP in mol/L
- Mg: Concentration of Magnesium salt in mol/L
- DNA: Concentration of DNA in nanomoles/L
- spacetime: Time in hours

### Important keyword arguments:
- outputfunction = totalrna: function that operations on simulation solution to give known values. Some usful output functions include:
    - ph: pH of IVT solution
    - atp: Concentration of ATP in mM (can do other NTPs as well)
    - cappingfraction: fraction of RNA that contain 5' cap
- stoich = SVector(231, 246, 189, 202): tuple of integers describing number of A,U,C,G in target sequence.
- PPiase = 0.0: concentration of pyrophosphatase enzyme in U/uL
- Cap = 0.0: concentration of cap analogue in mol/L
- tol = 1e-5: float of DAE solver tolerance. 

### Outputs: 
- Vector of two values [RNAoutput, NTPconversion]
- RNAoutput = Concentration of RNA product in outlet stream in umol/L
- NTPconversion = fractional conversion of NTP feedstock (bounded between 0-1)

""" 
# function IVT_PFR(T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; kwargs...)
#     parameterized_IVT_PFR(fittedparams,T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; kwargs...)
# end
# modified by Aatif
function IVT_PFR(T7RNAP, ATP, UTP, CTP, GTP, Mg, DNA, spacetime; kwargs...)
    return parameterized_IVT_PFR(fittedparams, T7RNAP, ATP, UTP, CTP, GTP, Mg, DNA, spacetime; outputfunction = multiple_outputs, kwargs...)
end


"""
    IVT_PFR_uncertainty(T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; n_mc_samples = 1000, kwargs...)

Part of IVT API. Takes reactor inputs to generate median and 95% confidence bounds using maximum likelihood parameter set. Can represent batch reaction (where spacetime=reaction time) or idealized PFR (where spacetime = reactor length/fluid speed)

### Inputs:
- T7RNAP: T7RNA polymerase input concentration (mol/L)
- ATP-GTP: Concentration of respective NTP in mol/L
- Mg: Concentration of Magnesium salt in mol/L
- DNA: Concentration of DNA in nanomoles/L
- spacetime: Time in hours

### Important keyword arguments:
- stoich = SVector(231, 246, 189, 202): tuple of integers describing number of A,U,C,G in target sequence.
- PPiase = 0.0: concentration of pyrophosphatase enzyme in U/uL
- Cap = 0.0: concentration of cap analogue in mol/L
- tol = 1e-5: float of DAE solver tolerance. 

### Outputs: 
- tuple of vectors (maximumlikelihood, lowerCB, upperCB), representing uncertainty of output (median, lower 95% confidence bound, upper 95% confidence bound.) 
- Each vector comprises two values [RNAoutput, NTPconversion]
- RNAoutput = Concentration of RNA product in outlet stream in umol/L
- NTPconversion = fractional conversion of NTP feedstock (bounded between 0-1)


""" 
# function IVT_PFR_uncertainty(T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; n_mc_samples = 1000, kwargs...)
#     n_outputs = 2
#     maximumliklihood = IVT_PFR(T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; kwargs...)
#     mcensemble = zeros(2,n_mc_samples)
#     mean = fittedparamslist
#     d = MvNormal(mean, Hermitian(covariancematrix))
#     for i in 1:n_mc_samples
#         x = rand(d, 1)
#         sampleparams = fullparameterset(fittingmodel,x)
#         sol = parameterized_IVT_PFR(sampleparams,T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; kwargs...)
#         mcensemble[:,i] = sol
#     end
#     maximumliklihood = IVT_PFR(T7RNAP,ATP,UTP,CTP,GTP,Mg,DNA,spacetime; kwargs...)
#     lowerCB = [percentile(mcensemble[i,:],100*alpha/2) for i in 1:n_outputs]
#     upperCB = [percentile(mcensemble[i,:],100*(1-alpha/2)) for i in 1:n_outputs]
#     return maximumliklihood, lowerCB, upperCB
# end


########################################
########################################
########################################
# Modified by Aatif for CSTR

function IVT_CSTR(T7RNAP, ATP, UTP, CTP, GTP, Mg, DNA, Q, V; final_time = 100.0, saveat = nothing, kwargs...)
    
    
    if saveat === nothing
        saveat = 0:0.1:final_time
    end
    inputs = (
        T7RNAP = T7RNAP,
        ATP = ATP,
        UTP = UTP,
        CTP = CTP,
        GTP = GTP,
        Mg = Mg,
        Buffer = 0.040,
        DNA = DNA,
        final_time = final_time
    )
    sol = runDAE_CSTR(fittedparams, inputs, Q, V; saveat = saveat, kwargs...)
    # Extract steady-state values
    steady_state_values = sol.u[end]

    return (sol.t, sol, multiple_outputs(sol, fittedparams))
   
end

