"""
    predictionuncertainty_linearized(speciesindex,α,model,params,parametercovariancematrix, inputs; kargs...)

For a output species of interest and confidence level (α), return prediction uncertainty of model using linearized approximation.
""" 
function predictionuncertainty_linearized(speciesindex,α,model,params,parametercovariancematrix, inputs; kargs...)
    mask = parametermask(model)
    Z = Distributions.Normal(0,1) # standard normal distribution parameterized by μ = 0, σ² = 1
    crit_z = Distributions.quantile(Z, 1-α/2)  
    predictiongrad = filterbymask(autodiffgradient(speciesindex, params, inputs; kargs...)[2] .* params .* log(10),mask)
    return sqrt(predictiongrad'*parametercovariancematrix*predictiongrad)*crit_z
end

"""
predictionuncertainty_linearized_multipoint(speciesindex,α,model,params,parametercovariancematrix, inputs, tvals; kargs...)

For a output species of interest and confidence level (α), return prediction uncertainty of model using linearized approximation for a vector of timepoints.
""" 
function predictionuncertainty_linearized_multipoint(speciesindex,α,model,params,parametercovariancematrix, inputs, tvals; kargs...)
    predictionerror = zeros(length(tvals))
    for (i,time) in enumerate(tvals)
        inputs_tval = (T7RNAP = inputs.T7RNAP, ATP = inputs.ATP,UTP = inputs.UTP,CTP = inputs.CTP,GTP = inputs.GTP, Mg = inputs.Mg, Buffer = inputs.Buffer, DNA = inputs.DNA, final_time = time)
        predictionerror[i] = predictionuncertainty_linearized(speciesindex,α,model,params,parametercovariancematrix, inputs_tval; kargs...)
    end
    predictionerror
end

"""
    filterbymask(vec,mask)

Take vector of parameters, return vector of parameters used for model fitting.
""" 
function filterbymask(vec,mask)
    res = zeros(Int(sum(mask)))
    sumval=1
    for i in 1:length(mask)
        if mask[i]==1
            res[sumval] = vec[i]
            sumval+=1
        end
    end
    res
end

function mcbounds(model,paramslist,parametercovariancematrix,outputfunction; nmc = 10000, alpha = 0.05)
    mcensemble = zeros(nmc)
    mean = paramslist
    d = MvNormal(mean, Hermitian(parametercovariancematrix))
    for i in 1:nmc
        x = rand(d, 1)
        sampleparams = fullparameterset(model,x)
        mcensemble[i] = outputfunction(sampleparams)
    end
    lowerCB = percentile(mcensemble,100*alpha/2)
    upperCB = percentile(mcensemble,100*(1-alpha/2))
    return [lowerCB,upperCB]
end