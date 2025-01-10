"""
    filtersensitivitymatrix(u,mask)

Take sensitivity matrix and mask, filter matrix to only contain rows representing fitted parameters.
""" 
function filtersensitivitymatrix(sensitivitymat,mask)
    result = zeros(Int(sum(mask)),size(sensitivitymat)[2])
    sumcounter = 1
    for i in 1:size(sensitivitymat)[1]
        if mask[i]==1
            result[sumcounter,:] = sensitivitymat[i,:]
            sumcounter+=1
        end
    end
    result
end

"""
    getcorrelationmatrix(mat)

Take covariance matrix and return correlation matrix.
""" 
function getcorrelationmatrix(mat)
    D = sqrt.(diagm(diag(mat)))
    DInv = inv(D);
    return DInv * mat * DInv
end

"""
    parametermask(model)

Take model, return prior component of information matrix for use in covariance matrix calculation.
""" 
function priormatrix(model)
    mask = parametermask(model)
    priorlen = Int(sum(mask))
    priormatrix = zeros(priorlen,priorlen)
    sumval = 1
    for i in 1:length(model.parameters)
        if model.parameters[i].hasprior
            priormatrix[sumval,sumval] = 1/model.parameters[i].variance
        end
        if model.parameters[i].isfitted
            sumval+=1
        end

    end
    return priormatrix
end

"""
    informationmatrix(model,data,optparamlist,getsensitivitymatrix,invvariance)

Take model, data for sensitivity matrix, and sensitivity matrix function. Return information matrix of data for use in covariance matrix calculation.
""" 
function getinformationmatrix(model,data,optparamlist,getsensitivitymatrix,invvariance)
    mask = parametermask(model)
    sensitivity = getsensitivitymatrix(model,data,optparamlist,false)#Get sensitivity matrix from supplied function
    filtered_sensitivity = filtersensitivitymatrix(sensitivity,mask)
    information = filtered_sensitivity*invvariance*filtered_sensitivity'
    return information
end

"""
    getcovariancematrix(model,data,optparamlist)

Take list of parameters from optimizer and return covariance matrix. 
""" 
function getcovariancematrix(model,data,pHdata,optparamlist; includeakama = true, customfile = false,customfilename = "", includepH = true, reactionkwargs...)
    informationmatrix = priormatrix(model).^2#Initialize information matrix with prior param values

    if includeakama
        RNAsensitivity = (model,data,optparamlist,log) -> sensitivitymatricies(model,data,optparamlist,log)[1]
        PPisensitivity = (model,data,optparamlist,log) -> sensitivitymatricies(model,data,optparamlist,log)[2]

        informationmatrix += getinformationmatrix(model,data,optparamlist,RNAsensitivity,diagm(1 ./(reshape(data.RNAstdev',(13*9))) .^2))
        informationmatrix += getinformationmatrix(model,data,optparamlist,PPisensitivity,diagm(1 ./(reshape(data.PPistdev',(13*9))) .^2))
        informationmatrix += getinformationmatrix(model,data,optparamlist,initialratesensitivity,inv(diagm(data.initialrateyieldstdev.^2)))
        informationmatrix += getinformationmatrix(model,data,optparamlist,PPititrationsensitivity,inv(diagm(data.Mgstdev.^2)))
    end

    if includepH
        nindconditions = size(pHdata)[1]
        informationmatrix += getinformationmatrix(model,pHdata,optparamlist,pHsensitivity,diagm(1 ./(0.75 .* ones(nindconditions)) .^2))
    end

    if customfile
        df = CSV.read(customfilename, DataFrame)
        customdata = Matrix(df)
        customsensitivity = (model,data,optparamlist,log) -> customsensitivitymatrix(model,data,optparamlist, log; reactionkwargs...)[1]
        stdevvector = customsensitivitymatrix(model,customdata,optparamlist,false; reactionkwargs...)[2]
        informationmatrix += getinformationmatrix(model,customdata,optparamlist,customsensitivity,inv(diagm(stdevvector .^2)))
    end
    parametercovariancematrix = inv(informationmatrix)
    return parametercovariancematrix
end


"""
    plotparametricellipseprojection(parameters,parametercovariance;α = 0.05,labels = ["",""])

Take list of parameters from optimizer and return covariance matrix. 
""" 
function plotparametricellipseprojection(parameters,parametercovariance;α = 0.05,labels = ["",""])
    χ²ₚ = Distributions.Chisq(3) # chi-squared distribution parameterized by p d.f.
    crit_χ² = Distributions.quantile(χ²ₚ, 1-α)
    crit_l = sqrt(crit_χ²)
    λ_covb, e_vec_covb = eigen(inv(parametercovariance)) # eigendecomposition of covariance
    t = collect(0.0:0.01:2.0*π)
    parametric_circle = vcat(cos.(t)',sin.(t)')
    major_minor_axes = crit_l * e_vec_covb * Diagonal(abs.(λ_covb).^(-0.5)) # map unit ball (ψ) to 2D ellipse confidence region (cov(b))
    parametric_ellipse = parameters .+major_minor_axes * parametric_circle
    plt = plot(parametric_ellipse[1,:],parametric_ellipse[2,:],xlabel = labels[1],ylabel = labels[2],label = "", linewidth = 3)
    return plt
end

"""
    samplecovariancematrix(covariancematrix)

Calculate 2sigma confidence intervals of each parameter by sampling covariance matrix.
""" 
function samplecovariancematrix(covariancematrix)
    mean = zeros(size(covariancematrix)[1])
    d = MvNormal(mean, Hermitian(covariancematrix))
    x = rand(d, 10000000)

    samplingresults = zeros(size(covariancematrix)[1])
    for i in 1:length(samplingresults)
        samplingresults[i] = Statistics.var(x[i,:])
    end
    return sqrt.(samplingresults)*2
end