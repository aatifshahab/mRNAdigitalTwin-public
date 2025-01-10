function plotbyMg(model,MgNTPdata,paramslist, parametercovariancematrix; kwargs...)
    plt = plot(legend_title = "NTP",legend_title_font_pointsize = 9)
    return plotbyMg!(plt,model,MgNTPdata,paramslist, parametercovariancematrix; kwargs...)
end

"""
    plotinitialrates(model,data,params, parametercovariancematrix, showconfidence)  

Generate figure 3A of main text showing model fit to initial rate Akama data."""
function plotbyMg!(plt,model,MgNTPdata,paramslist, parametercovariancematrix; 
    showconfidence = true,
    showpredictions = true,
    label = nothing, 
    Mgpoints = 50,
    Mgrange = (1e-3,120e-3),
    OAccounterion = false, 
    colorscheme = :berlin,
    T7RNAP = 200e-9,
    Buffer = 0.040,
    DNA = 24.48,
    finaltime = 1.0,
    plottingfunction = totalrna,
    datastddev = 1.0,
    stoich = (130,230,180,180),
    PPiase = 5,
    nmc = 10000,
    α = 0.05,
    reactionkwargs...)
    
    NTPvalues = unique(MgNTPdata[:,1])
    nNTP = length(NTPvalues)
    params = fullparameterset(model,paramslist)
    Mginput = LinRange(Mgrange[1],Mgrange[2],Mgpoints)
    mask = parametermask(model)
    for (NTPindex,NTPconc) in enumerate(NTPvalues)
        color = cgrad(colorscheme, nNTP, categorical = true)[NTPindex]
        RNAyield = zeros(Mgpoints)
        lower_pointwise_CB = zeros(Mgpoints)
        upper_pointwise_CB = zeros(Mgpoints)
        for (Mgindex,Mgconc) in enumerate(Mginput)
            inputs =(T7RNAP = T7RNAP, ATP = NTPconc/4,UTP = NTPconc/4,CTP = NTPconc/4,GTP = NTPconc/4, Mg = Mgconc, Buffer = Buffer, DNA = DNA, final_time = finaltime)
            sol = runDAE_batch(params,inputs; PPiase = PPiase, stoich = stoich, OAccounterion = OAccounterion, reactionkwargs...)
            RNAyield[Mgindex] = plottingfunction(sol,params)[end]
            if showconfidence
                mcensemble = zeros(nmc)
                mean = paramslist
                d = MvNormal(mean, Hermitian(parametercovariancematrix))
                for i in 1:nmc
                    x = rand(d, 1)
                    sampleparams = fullparameterset(model,x)
                    sol = runDAE_batch(sampleparams, inputs; PPiase = PPiase, stoich = stoich, OAccounterion = OAccounterion, reactionkwargs...)
                    mcensemble[i] = plottingfunction(sol,params)[end]
                end
                lower_pointwise_CB[Mgindex] = percentile(mcensemble,100*α/2)
                upper_pointwise_CB[Mgindex] = percentile(mcensemble,100*(1-α/2))
            else
                lower_pointwise_CB[Mgindex] = 0
                upper_pointwise_CB[Mgindex] = 0
            end
        end
        if showpredictions
            plot!(plt,1000*Mginput,RNAyield,linewidth = 2.5,color = color, label = "",z_order = :back)
            plot!(plt,1000*Mginput, lower_pointwise_CB[:,:], fillrange = upper_pointwise_CB[:,:], fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",z_order = :back)
        end
        dataMg = MgNTPdata[MgNTPdata[:,1] .== NTPconc,2]
        dataRNAyield = MgNTPdata[MgNTPdata[:,1] .== NTPconc,3]
        if plottingfunction == totalrna
            if isnothing(label)
                lab = string(round(NTPconc*1000, sigdigits = 2))*" mM"
            else
                lab = label
            end
            scatter!(plt,1000*dataMg,dataRNAyield,yerr = datastddev,markersize = 4,palette =:Dark2_5,label=lab,mc = color)
        end
    end
    plot!(plt,xlabel = "Mg (mM)",ylabel = "RNA (μM)",linewidth=3.5,legend=:outerright,ylims = (0,Inf),xlims = 1e3 .*Mgrange)
    return plt   
end

function plotbyNTP!(plt,model,MgNTPdata,paramslist, parametercovariancematrix; 
    showconfidence = true,
    showdata = true,
    NTPpoints = 50,
    CSTRsim = false,
    feedNTP = 50e-3,
    NTPrange = (1e-3,feedNTP),
    OAccounterion = false, 
    colorscheme = :berlin,
    T7RNAP = 200e-9,
    Buffer = 0.040,
    DNA = 24.48,
    finaltime = 1.0,
    plottingfunction = totalrna,
    datastddev = 1.0,
    stoich = (130,230,180,180),
    PPiase = 5,
    nmc = 10000,
    α = 0.05,
    reactionkwargs...)
    
    Mgvalues = unique(MgNTPdata[:,2])
    nMg = length(Mgvalues)
    params = fullparameterset(model,paramslist)
    NTPinput = LinRange(NTPrange[1],NTPrange[2],NTPpoints)
    mask = parametermask(model)
    for (Mgindex,Mgconc) in enumerate(Mgvalues)
        color = cgrad(colorscheme, nMg, categorical = true)[Mgindex]
        RNAyield = zeros(NTPpoints)
        lower_pointwise_CB = zeros(NTPpoints)
        upper_pointwise_CB = zeros(NTPpoints)
        for (NTPindex,NTPconc) in enumerate(NTPinput)
            if CSTRsim
                Pi = 2*(feedNTP - NTPconc)
                NaperNTP = 3.96*feedNTP/NTPconc
            else
                Pi = 1e-9
                NaperNTP = 3.96
            end
            inputs =(T7RNAP = T7RNAP, ATP = NTPconc/4,UTP = NTPconc/4,CTP = NTPconc/4,GTP = NTPconc/4, Mg = Mgconc, Buffer = Buffer, DNA = DNA, final_time = finaltime)
            sol = runDAE_batch(params,inputs; PPiase = PPiase, stoich = stoich, OAccounterion = OAccounterion, Pi = Pi, NaperNTP = NaperNTP, reactionkwargs...)
            RNAyield[NTPindex] = plottingfunction(sol,params)[end]
            if showconfidence
                mcensemble = zeros(nmc)
                mean = paramslist
                d = MvNormal(mean, Hermitian(parametercovariancematrix))
                for i in 1:nmc
                    x = rand(d, 1)
                    sampleparams = fullparameterset(model,x)
                    sol = runDAE_batch(sampleparams, inputs; PPiase = PPiase, stoich = stoich, OAccounterion = OAccounterion, reactionkwargs...)
                    mcensemble[i] = plottingfunction(sol,params)[end]
                end
                lower_pointwise_CB[Mgindex] = percentile(mcensemble,100*α/2)
                upper_pointwise_CB[Mgindex] = percentile(mcensemble,100*(1-α/2))
            else
                lower_pointwise_CB[Mgindex] = 0
                upper_pointwise_CB[Mgindex] = 0
            end
        end
        plot!(plt,1000*NTPinput,RNAyield,linewidth = 2.5,color = color, label = "",z_order = :back)
        plot!(plt,1000*NTPinput, lower_pointwise_CB[:,:], fillrange = upper_pointwise_CB[:,:], fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",z_order = :back)
        if showdata
            dataNTP = MgNTPdata[MgNTPdata[:,2] .== Mgconc,1]
            dataRNAyield = MgNTPdata[MgNTPdata[:,2] .== Mgconc,3]
            if plottingfunction == totalrna
                scatter!(plt,1000*dataNTP,dataRNAyield,yerr = datastddev,markersize = 4,palette =:Dark2_5,label=string(round(Mgconc*1000, sigdigits = 2))*" mM",mc = color)
            end
        end
    end
    plot!(plt,xlabel = "Total NTP (mM)",ylabel = "RNA (μM)",linewidth=3.5,legend=:outerright,ylims = (0,Inf))
    return plt   
end


function plotadditionscreen!(plt,model,MgNTPdata,paramslist, parametercovariancematrix; 
    showconfidence = true,
    showdata = true,
    NTPpoints = 50,
    initNTP = 7.5e-3,
    initMg = 38e-3,
    NTPrange = (1e-3,40e-3),
    colorscheme = :berlin,
    T7RNAP = 200e-9,
    Buffer = 0.040,
    DNA = 48.96,
    finaltime = 2.0,
    plottingfunction = totalrna,
    datastddev = 1.0,
    stoich = (130,230,180,180),
    PPiase = 5,
    nmc = 1000,
    α = 0.05,
    reactionkwargs...)
    
    Mgvalues = unique(MgNTPdata[:,2])
    nMg = length(Mgvalues)
    params = fullparameterset(model,paramslist)
    NTPinput = LinRange(NTPrange[1],NTPrange[2],NTPpoints)
    mask = parametermask(model)
    for (Mgindex,Mgadded) in enumerate(Mgvalues)
        color = cgrad(colorscheme, nMg, categorical = true)[Mgindex]
        RNAyield = zeros(NTPpoints)
        lower_pointwise_CB = zeros(NTPpoints)
        upper_pointwise_CB = zeros(NTPpoints)
        for (NTPindex,NTPadded) in enumerate(NTPinput)
            discretefeedingschedule = [[1.0, (25/18)*Mgadded, (25/18)*NTPadded/4, (25/18)*NTPadded/4, (25/18)*NTPadded/4, (25/18)*NTPadded/4, 5*NTPadded/4, (25/18)-1]  [Inf, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]'
            inputs =(T7RNAP = T7RNAP, ATP = initNTP,UTP = initNTP,CTP = initNTP,GTP = initNTP, Mg = initMg, Buffer = Buffer, DNA = DNA, final_time = finaltime)
            solls = runfedbatch(params, inputs; discretespeciesaddition = discretefeedingschedule, PPiase = PPiase, stoich = stoich, reactionkwargs...)
            sol = ("fedbatch",solls[end])
            RNAyield[NTPindex] = plottingfunction(sol,params)[end]
            if showconfidence
                mcensemble = zeros(nmc)
                mean = paramslist
                d = MvNormal(mean, Hermitian(parametercovariancematrix))
                for i in 1:nmc
                    x = rand(d, 1)
                    sampleparams = fullparameterset(model,x)
                    solls = runfedbatch(sampleparams, inputs; discretespeciesaddition = discretefeedingschedule, PPiase = PPiase, stoich = stoich, reactionkwargs...)
                    sol = ("fedbatch",solls[end])
                    mcensemble[i] = plottingfunction(sol,params)[end]
                end
                lower_pointwise_CB[NTPindex] = percentile(mcensemble,100*α/2)
                upper_pointwise_CB[NTPindex] = percentile(mcensemble,100*(1-α/2))
            else
                lower_pointwise_CB[NTPindex] = 0
                upper_pointwise_CB[NTPindex] = 0
            end
        end
        plot!(plt,1000*NTPinput,RNAyield,linewidth = 2.5,color = color, label = "",z_order = :back)
        plot!(plt,1000*NTPinput, lower_pointwise_CB, fillrange = upper_pointwise_CB, fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",z_order = :back)
        if showdata
            dataNTP = MgNTPdata[MgNTPdata[:,2] .== Mgadded,1]
            dataRNAyield = MgNTPdata[MgNTPdata[:,2] .== Mgadded,3]
            if plottingfunction == totalrna
                scatter!(plt,1000*dataNTP,dataRNAyield,yerr = datastddev,markersize = 4,palette =:Dark2_5,label=string(round(Mgadded*1000, sigdigits = 2))*" mM",mc = color)
            end
        end
    end
    plot!(plt,xlabel = "Total NTP (mM)",ylabel = "RNA (μM)",linewidth=3.5,legend=:outerright,ylims = (0,Inf))
    return plt   
end
