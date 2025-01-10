"""
    pHplotting(params,pHrange,plottingpoints;npoints = 1000, yerror = 1.5)

Show effect of pH on initial rate, compared to data (Osumi et al)"""
function pHplotting(model,
    plottingpoints,
    paramslist,
    parametercovariancematrix;
    npoints = 1000, 
    yerror = 0.75, 
    mcuncertainty = true, 
    nmc = 10000, 
    pHrange = (5,11),
    α = 0.05,
    color = :black)

    params = fullparameterset(model,paramslist)
    pHvalues = LinRange(pHrange[1],pHrange[2],npoints)
    rateresults = zeros(npoints)
    for (ind,pH) in enumerate(pHvalues)
        rateresults[ind] = pHfactor(params,10^(-pH))
    end
    plt = plot(pHvalues, rateresults, linewidth = 3,xlabel = "pH",ylabel = "Reaction Rate (arb. units)", label = "", color = color,grid = false,)
    plot!(ylims = (0,Inf))
    # Using mc sampling for uncertainty
    if mcuncertainty
        mcensemble = zeros(nmc,npoints)
        mean = paramslist
        d = MvNormal(mean, Hermitian(parametercovariancematrix))
        for i in 1:nmc
            x = rand(d, 1)
            sampleparams = fullparameterset(model,x)
            for (j,pH) in enumerate(pHvalues)
                mcensemble[i,j] = pHfactor(sampleparams,10^(-pH))
            end
        end
        lower_pointwise_CB = [percentile(ensembleslice,100*α/2) for ensembleslice in eachcol(mcensemble)]
        upper_pointwise_CB = [percentile(ensembleslice,100*(1-α/2)) for ensembleslice in eachcol(mcensemble)]

    else
        lower_pointwise_CB = rateresults
        upper_pointwise_CB = rateresults
    end
    plot!(pHvalues, lower_pointwise_CB, fillrange = upper_pointwise_CB, fillalpha = 0.35,alpha=0.0,linewidth = 0.0,label="", color = color)

    #Plotting data
    scatter!(plottingpoints[:,1],plottingpoints[:,2],yerror = yerror,label = "", color = color)
 
    return plt
end