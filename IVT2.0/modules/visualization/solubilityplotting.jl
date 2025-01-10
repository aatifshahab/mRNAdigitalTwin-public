"""
    function plotMgtitrations(model,data,params, parametercovariancematrix, showconfidence, Mg = 0.004, time = 24, showdata = true, maxNTP = 0.8)

Generate figure 3B of main text showing model fit to Mg2PPi solubility Akama data."""
function plotMgsolubilitycurves(model,params, parametercovariancematrix,filename; PPirange = (1e-5,1e-2), labels = [], showdata = true, showconfidence = true)
    df = CSV.read(filename, DataFrame)
    data = Matrix(df)
    range = 1:size(data)[1]
    runparams = fullparameterset(model,params)

    PPipoints = 100
    addedPPi = LinRange(PPirange[1], PPirange[2],PPipoints)
    mask = parametermask(model)
    plt = plot(xlabel = "PPi (mM)", ylabel = "Mg Remaining in Solution (mM)",legend_title_font_pointsize = 9)
    Mgs = data[:,10]
    uniqueMgs = unique(Mgs)
    nMgs = length(uniqueMgs)
    for (Mgind, Mg) in enumerate(uniqueMgs) 
        color = cgrad(:berlin, max(nMgs,2), categorical = true)[Mgind]
        Mgexampleind = 0
        totalMgoutput = zeros(PPipoints)
        predictionerror = zeros(PPipoints)
        for i in (range)
            if data[i,10] == Mg
                Mgexampleind = i
                (outputs, confint, inputs, Cap, PPiase, PPi, stoich, times, speciesoutputfunction, plotspecieslabel, maximumoutput) = readdatarow(data[i,:])
                scatter!(1000*[PPi], outputs, yerror = confint, markersize = 4,mc = color,label = "")
            end
        end
        for (PPiind,PPiconc) in enumerate(addedPPi)
            (outputs, confint, inputs, Cap, PPiase, PPi, stoich, times, speciesoutputfunction, plotspecieslabel, maximumoutput) = readdatarow(data[Mgexampleind,:])
            sol = runDAE_batch(runparams, inputs, PPiase = PPiase, stoich = stoich, Cap = Cap, PPi = PPiconc, saveevery = false)
            totalMgoutput[PPiind] = sol.u[end][Mgindex]
            if showconfidence
                predictionerror[PPiind] = predictionuncertainty_linearized(Mgindex,alpha,model,runparams,parametercovariancematrix, inputs; PPi = PPiconc, saveevery = false)
            else
                predictionerror[PPiind] = 0
            end
        end
        plot!(1000*addedPPi,1000*totalMgoutput,linewidth = 2.5,color = color,z_order = :back,label="",)
        lower_pointwise_CB = max.(1000*totalMgoutput .- 1000*predictionerror,0)
        upper_pointwise_CB = 1000*totalMgoutput .+ 1000*predictionerror
        plot!(1000*addedPPi, lower_pointwise_CB[:,:], fillrange = upper_pointwise_CB[:,:], fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",z_order = :back)
    end
    return plt
end

#Need to adjust warm start DAE initialization guesses to run this
function plotpHcurvePPi!(plt,model,params,parametercovariancematrix,Buffer,Naratio,PPidata,pHdata, color; PPirange = (1e-4,1e-1), showconfidence = true, plotlabel = "", nmc = 1000, alpha = 0.05, PPipoints = 100)
    runparams = fullparameterset(model,params)
    addedPPi = 10 .^(LinRange(log10(PPirange[1]), log10(PPirange[2]),PPipoints))
    mask = parametermask(model)
    #color = cgrad(:berlin, max(nMgs,2), categorical = true)[Mgind]
    pHs = zeros(PPipoints)
    lower_pointwise_CB = zeros(PPipoints)
    upper_pointwise_CB = zeros(PPipoints)

    #(outputs, confint, inputs, Cap, PPiase, PPi, stoich, times, speciesoutputfunction, plotspecieslabel, maximumoutput) = readdatarow(data[i,:])
    scatter!(1000*PPidata, pHdata, markersize = 3,mc = color,xscale = :log, label = plotlabel)

    for (PPiind,PPiconc) in enumerate(addedPPi)
        #(outputs, confint, inputs, Cap, PPiase, PPi, stoich, times, speciesoutputfunction, plotspecieslabel, maximumoutput) = readdatarow(data[Mgexampleind,:])
        inputs =(T7RNAP = 0, ATP = 4e-9,UTP = 4e-9,CTP = 4e-9,GTP = 4e-9, Mg = 8e-9, Buffer = Buffer, DNA = 0, final_time = 1)
        sol = runDAE_batch(runparams, inputs, PPi = PPiconc, saveevery = false, Na = Naratio*PPiconc)#, Na = Naratio*PPiconc, saveevery = false)
        pHs[PPiind] = ph(sol,params)[end]
        if showconfidence
            mcensemble = zeros(nmc)
            mean = params
            d = MvNormal(mean, Hermitian(parametercovariancematrix))
            for i in 1:nmc
                x = rand(d, 1)
                sampleparams = fullparameterset(model,x)
                sol = runDAE_batch(sampleparams, inputs, PPi = PPiconc, saveevery = false, Na = Naratio*PPiconc)
                mcensemble[i] = (ph(sol,sampleparams))[end]
            end
            lower_pointwise_CB[PPiind] = percentile(mcensemble[:],100*alpha/2)
            upper_pointwise_CB[PPiind] = percentile(mcensemble[:],100*(1-alpha/2))
        else
            lower_pointwise_CB = zeros(PPipoints)
            upper_pointwise_CB = zeros(PPipoints)
        end
    end
    plot!(1000*addedPPi,pHs,linewidth = 2.5,color = color,z_order = :back,label="",xscale = :log)
    plot!(1000*addedPPi, lower_pointwise_CB[:,:], fillrange = upper_pointwise_CB[:,:], fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",z_order = :back)
    return plt
end


function plotpHcurveATP!(plt,model,params,parametercovariancematrix,Buffer, color; ATPrange = (1e-4,1e-1), showconfidence = true, plotlabel = "", nmc = 1000, alpha = 0.05, ATPpoints = 100, NaOHmoleratio = 0, trisratio = 0.0)
    runparams = fullparameterset(model,params)
    addedATP = 10 .^(LinRange(log10(ATPrange[1]), log10(ATPrange[2]),ATPpoints))
    mask = parametermask(model)
    pHs = zeros(ATPpoints)
    lower_pointwise_CB = zeros(ATPpoints)
    upper_pointwise_CB = zeros(ATPpoints)
    Naratio = 2+NaOHmoleratio

    for (ATPind,ATPconc) in enumerate(addedATP)
        totalBuffer = Buffer+trisratio*ATPconc
        inputs =(T7RNAP = 0, ATP = ATPconc,UTP = 1e-9,CTP = 1e-9,GTP = 1e-9, Mg = 1e-9, Buffer = totalBuffer, DNA = 0, final_time = 1)
        sol = runDAE_batch(runparams, inputs, saveevery = false, Na = (Naratio)*ATPconc)
        pHs[ATPind] = ph(sol,params)[end]
        if showconfidence
            mcensemble = zeros(nmc)
            mean = params
            d = MvNormal(mean, Hermitian(parametercovariancematrix))
            for i in 1:nmc
                x = rand(d, 1)
                sampleparams = fullparameterset(model,x)
                sol = runDAE_batch(sampleparams, inputs, saveevery = false, Na = (Naratio)*ATPconc)
                mcensemble[i] = (ph(sol,sampleparams))[end]
            end
            lower_pointwise_CB[ATPind] = percentile(mcensemble[:],100*alpha/2)
            upper_pointwise_CB[ATPind] = percentile(mcensemble[:],100*(1-alpha/2))
        else
            lower_pointwise_CB = zeros(ATPpoints)
            upper_pointwise_CB = zeros(ATPpoints)
        end
    end
    plot!(1000*addedATP,pHs,linewidth = 2.5,color = color,z_order = :back,xscale = :log, label = plotlabel)
    plot!(1000*addedATP, lower_pointwise_CB[:,:], fillrange = upper_pointwise_CB[:,:], fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",z_order = :back)
    return plt
end

function plotMg2PPiphasediagram(model,params, parametercovariancematrix; time = 2400, showconfidence = false)
    addedMg = 1e-3*[4]#1e-3*[8,16,32,64]
    #addedMg = 1e-3*[2,4,8,16,32]
    NTPconc = 1e-9
    mask = parametermask(model)
    #plt = plot(ylabel = "Final pH", xlabel = "Initial pH")
    plt = plot(ylabel = "Final PPi (mM)", xlabel = "Final Mg (mM)")
    for (Mgindex,Mgconc) in enumerate(addedMg)
        addedPPi = 1e-3*(Mgconc/0.004) .* [0.5,1,1.5,1.75,2,2.25,2.5,3,4,8,16,32,64]#LinRange(0.5,12,1000)
        #addedPPi = 1e-3*(Mgconc/0.004) .*[1.5,1.875,2.125,2.5]
        finalMg = []
        finalPPi = []
        for (PPiind,PPiconc) in enumerate(addedPPi)
            inputs =(T7RNAP = 0, ATP = NTPconc/4,UTP = NTPconc/4,CTP = NTPconc/4,GTP = NTPconc/4, Mg = Mgconc, Buffer = 0.040, DNA = 1e-8, final_time = time)
            sol = runDAE_batch(params,inputs; PPi = PPiconc, saveevery = false)
            #finalMgval = (ph(sol,params))[1]
            #finalPPival = (ph(sol,params))[end]
            finalMgval = (totalMg(sol,params))[end]
            finalPPival = (totalPPi(sol,params))[end]
            if nucleationoccured(sol,params)
                append!(finalMg,finalMgval)
                append!(finalPPi,finalPPival)
            end
        end
        scatter!(finalMg,finalPPi, yscale = :log, xscale = :log, linewidth = 3, label = "")
    end
    return plt
end
