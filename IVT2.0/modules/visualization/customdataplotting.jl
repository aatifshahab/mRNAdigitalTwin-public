(RNAindex,PPiindex,Mgindex) = speciesindicies()
alpha = 0.05

"""
   plotfromcsv(model,paramslist,parametercovariancematrix,filename; kwargs...)

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
function plotfromcsv(model,paramslist,parametercovariancematrix,filename; kwargs...)
    df = CSV.read(filename, DataFrame)
    rawdatamat = Matrix(df)
    return plotdata(model,paramslist,parametercovariancematrix,rawdatamat; kwargs...)
end


function plotdata(model,
    paramslist,
    parametercovariancematrix,
    data;
    labels = [], 
    range = 1:size(data)[1], 
    markersize = 3,
    plotsize = (400,400), 
    multiplot = true, 
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
    
    #Multiplot creates a set of plot windows. Turning multiplot off plots everything in the same window.
    if multiplot
        pltvec = [plot() for i in 1:length(range)]
    else
        masterplot = plot()
    end

    for (plotind,i) in enumerate(range)
        if multiplot
            plt = plot()
        end
        color = cgrad(colorscheme, max(2,plotsplit[1]+length(range)), categorical = true)[plotind+plotsplit[2]]
        (outputs, confint, inputs, Cap, PPiase, PPi, stoich, times, speciesoutputfunction, plotspecieslabel, maximumoutput) = readdatarow(data[i,:])
        if showpredictions
            #Adding error bars
            if dataerrorbars
                confint = confint
            else
                confint = 0
            end

            sol = runDAE_batch(params, inputs; PPiase = PPiase, stoich = stoich, Cap = Cap, PPi = PPi, reactionkwargs...)
            plot!(sol.t,speciesoutputfunction(sol,params),color = color,label = "",linewidth =3)
            tvals = sol.t

            #Generate uncertainty in predictions
            predictionerror = zeros(length(tvals))
            if mcuncertainty # Using mc sampling for uncertainty
                mcensemble = zeros(nmc,length(tvals))
                mean = paramslist
                d = MvNormal(mean, Hermitian(parametercovariancematrix))
                for i in 1:nmc
                    x = rand(d, 1)
                    sampleparams = fullparameterset(model,x)
                    sol = runDAE_batch(sampleparams, inputs; PPiase = PPiase, stoich = stoich, Cap = Cap, PPi = PPi, reactionkwargs...)
                    timepointsol = sol(tvals)
                    mcensemble[i,:] = speciesoutputfunction(timepointsol,sampleparams)
                end
                lower_pointwise_CB = [percentile(mcensemble[:,j],100*alpha/2) for j in 1:length(tvals)]
                upper_pointwise_CB = [percentile(mcensemble[:,j],100*(1-alpha/2)) for j in 1:length(tvals)]

            else #Using Linearized approximation for uncertainty calculation
                predictionerror = 0

                lower_pointwise_CB = speciesoutputfunction(sol,params)
                upper_pointwise_CB = speciesoutputfunction(sol,params)
            end
            
            plot!(tvals, lower_pointwise_CB, fillrange = upper_pointwise_CB, fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",ylabel = plotspecieslabel)
        end
        #Shows purple line to denote maximum yield
        if maximumyield 
            if multiplot || !multiplemaximum
                plotlabel = ""
                plotcolor = palette(:tab10)[5]
            else
                plotlabel = "Max. Yield: "
                plotcolor = color
            end
            plot!(times,maximumoutput .* ones(length(times)),color = plotcolor,linewidth = 4,linestyle = :dash,label = plotlabel)
        end
        
        #Uses labels input for plot legend
        if isempty(labels)
            label = "Condition "*string(i)
        else
            label = labels[plotind]
        end

        scatter!(times,outputs,mc = color,markersize = markersize,label = label, yerror = confint,markerstrokecolor=palette(:grays,10)[3])
        if multiplot
            pltvec[plotind] = plt
        end
    end
    if multiplot
        if length(pltvec)<4
            masterplot = plot(pltvec...,size = plotsize,xtickfontsize=12,ytickfontsize=12,xguidefontsize=15,yguidefontsize=15,grid = false,layout = (1,3),legend=:outerright,xlabel = "Time (h)")
        else
            masterplot = plot(pltvec...,size = plotsize,xtickfontsize=12,ytickfontsize=12,xguidefontsize=15,yguidefontsize=15,grid = false,legend=:outerright,xlabel = "Time (h)")
        end
    else
        plot!(size = plotsize,xtickfontsize=12,ytickfontsize=12,xguidefontsize=15,yguidefontsize=15,grid = false,legend=:outerright,xlabel = "Time (h)")
    end
    plot!(ylims=(0,Inf))
    return masterplot
end


function plotcalibrationfromcsv(model,paramslist,parametercovariancematrix,filename; kwargs...)
    df = CSV.read(filename, DataFrame)
    rawdatamat = Matrix(df)
    return plotcalibration(model,paramslist,parametercovariancematrix,rawdatamat; kwargs...)
end

function plotcalibration(model,
    paramslist,
    parametercovariancematrix,
    data;
    range = 1:size(data)[1], 
    markersize = 3,
    plotsize = (400,400), 
    reactionkwargs...)

    measuredvalues = []
    measureduncertainty = []
    predictedvalues = []
    
    params = fullparameterset(model,paramslist)
    
    for (plotind,i) in enumerate(range)

        (outputs, confint, inputs, Cap, PPiase, PPi, stoich, times, speciesoutputfunction, plotspecieslabel, maximumoutput) = readdatarow(data[i,:])
        sol = runDAE_batch(params, inputs; PPiase = PPiase, stoich = stoich, Cap = Cap, PPi = PPi, reactionkwargs...)
        conditionpredictions = speciesoutputfunction(sol(times),params)
        append!(predictedvalues,conditionpredictions)
        append!(measuredvalues,outputs)
        append!(measureduncertainty,confint)
    end
    
    masterplot= scatter(measuredvalues,predictedvalues,yerror = measureduncertainty, label = "Data")
    plot!(measuredvalues,measuredvalues, label = "Calibration Line", size = plotsize, ylims = (0,Inf))
    return masterplot
end



