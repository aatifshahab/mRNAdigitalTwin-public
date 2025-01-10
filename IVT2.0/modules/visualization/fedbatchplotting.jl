(RNAindex,PPiindex,Mgindex) = speciesindicies()
alpha = 0.05

"""
   plotfedbatchfromcsv(model,paramslist,parametercovariancematrix,filename; kwargs...)

Generate plot of model predictions alongside data. Uses csv file name.
# Keyword Arguments
- `labels::Array(String)`: labels to add to plot legend.
- `range::Array(Integer)`: rows of csv file to add to plot. Defaults to all rows.
- `plotsize = (400,400)`
- `multiplot = true`: Add a new plot window for each reaction condition.
- `maximumyield = true`: Add line denoting maximum yield of reaction.
- `multiplemaximum = false`: Give each maximum yield line a new color and legend label.
- `dataerrorbars = false`: Add error bars to data points from csv.
- `mcuncertainty = true`: Use Monte Carlo sampling from covariance matrix to generate prediction interval. If false uses linearized approximation.
- `nmc = 1000`: Number of Monte Carlo samples to use for uncertainty calculations.
- `plotsplit = (0,0)`: Start color scheme at point i of color gradient with maximum index j. Input as plotsplit = (i,j)
- `showpredictions = true`: Show model predictions in addition to data
...
"""
function plotfedbatchfromcsv!(plt,model,paramslist,parametercovariancematrix,filename,discretefeedingschedules; kwargs...)
    df = CSV.read(filename, DataFrame)
    rawdatamat = Matrix(df)
    return plotfedbatchdata!(plt,model,paramslist,parametercovariancematrix,rawdatamat,discretefeedingschedules; kwargs...)
end


function plotfedbatchdata!(masterplot,
    model,
    paramslist,
    parametercovariancematrix,
    data,
    discretefeedingschedules;
    labels = [], 
    range = 1:size(data)[1], 
    markersize = 3,
    plotsize = (400,400), 
    maximumyield=true, 
    multiplemaximum = false,
    plotsplit = (0,0),
    dataerrorbars = false,
    mcuncertainty = true, 
    showpredictions = true,
    nmc = 1000, 
    colorscheme = :berlin,
    reactionkwargs...)
    params = fullparameterset(model,paramslist)
    masterplot

    #Multiplot creates a set of plot windows. Turning multiplot off plots everything in the same window.

    for (plotind,i) in enumerate(range)
        color = cgrad(colorscheme, max(2,plotsplit[1]+length(range)), categorical = true)[plotind+plotsplit[2]]
        (outputs, confint, inputs, Cap, PPiase, PPi, stoich, times, speciesoutputfunction, plotspecieslabel, maximumoutput) = readdatarow(data[i,:])
        if showpredictions
            #Adding error bars
            if dataerrorbars
                confint = confint
            else
                confint = 0
            end

            solls = runfedbatch(params, inputs; discretespeciesaddition = discretefeedingschedules[plotind], PPiase = PPiase, stoich = stoich, Cap = Cap, reactionkwargs...)
            tvalsls = []            
            for solobj in solls
                sol = ("fedbatch",solobj)
                plot!(sol[2].t,speciesoutputfunction(sol,params),color = color,label = "",linewidth =3,ylabel = plotspecieslabel)
                append!(tvalsls,[sol[2].t])
            end

            if mcuncertainty # Using mc sampling for uncertainty
                mcensembles = []
                for (ind,_) in enumerate(solls)
                    tvals = tvalsls[ind]
                    mcensemble = zeros(nmc,length(tvals))
                    append!(mcensembles,[mcensemble])
                end
                mean = paramslist
                d = MvNormal(mean, Hermitian(parametercovariancematrix))
                for i in 1:nmc
                    x = rand(d, 1)
                    sampleparams = fullparameterset(model,x)
                    mcsolls = runfedbatch(sampleparams, inputs; discretespeciesaddition = discretefeedingschedules[plotind], PPiase = PPiase, stoich = stoich, Cap = Cap, reactionkwargs...)
                    for (ind,mcsolobj) in enumerate(mcsolls)
                        tvals = tvalsls[ind]
                        mcensemble = mcensembles[ind]
                        mctimepointsol = mcsolobj(tvals)
                        mcsol = ("fedbatch",mctimepointsol)
                        mcensemble[i,:] = speciesoutputfunction(mcsol,sampleparams)
                    end
                end
                for (ind,_) in enumerate(solls)
                    tvals = tvalsls[ind]
                    mcensemble = mcensembles[ind]
                    lower_pointwise_CB = [percentile(mcensemble[:,j],100*alpha/2) for j in 1:length(tvals)]
                    upper_pointwise_CB = [percentile(mcensemble[:,j],100*(1-alpha/2)) for j in 1:length(tvals)]
                    plot!(tvalsls[ind], lower_pointwise_CB, fillrange = upper_pointwise_CB, fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",ylabel = plotspecieslabel)
                end
            end
            
        end
        #Shows purple line to denote maximum yield
        # if maximumyield 
        #     if multiplot || !multiplemaximum
        #         plotlabel = ""
        #         plotcolor = palette(:tab10)[5]
        #     else
        #         plotlabel = "Max. Yield: "
        #         plotcolor = color
        #     end
        #     plot!(times,maximumoutput .* ones(length(times)),color = plotcolor,linewidth = 4,linestyle = :dash,label = plotlabel)
        # end
        
        #Uses labels input for plot legend
        if isempty(labels)
            label = "Condition "*string(i)
        else
            label = labels[plotind]
        end

        scatter!(times,outputs,mc = color,markersize = markersize,label = label, yerror = confint,markerstrokecolor=palette(:grays,10)[3])
    end

    plot!(size = plotsize,xtickfontsize=12,ytickfontsize=12,xguidefontsize=15,yguidefontsize=15,grid = false,legend=:outerright,xlabel = "Time (h)")
    plot!(ylims=(0,Inf))
    return masterplot
end