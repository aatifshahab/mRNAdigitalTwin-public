"""
    plotinitialrates(model,data,params, parametercovariancematrix, showconfidence)  

Generate figure 3A of main text showing model fit to initial rate Akama data."""
function plotDatabyNTP(model,params, parametercovariancematrix, showconfidence; immobilized = true, color = :blue, reactionkwargs...)
    plt = plot()
    NTPpoints = 100
    NTPinput = LinRange(1e-18,0.015,NTPpoints)
    RNAyield = zeros(NTPpoints)
    predictionerror = zeros(NTPpoints)
    for (NTPindex,NTPconc) in enumerate(NTPinput)
        inputs =(T7RNAP = 0.812e-7, ATP = NTPconc/4,UTP = NTPconc/4,CTP = NTPconc/4,GTP = NTPconc/4, Mg = NTPconc+4e-3, Buffer = 0.0425, DNA = 605.7, final_time = 0.02472)
        sol = runDAE_batch(params,inputs;immobilized = immobilized, reactionkwargs...)
        RNAyield[NTPindex] = sol.u[end][RNAindex]
        if showconfidence
            predictionerror[NTPindex] = predictionuncertainty_linearized(RNAindex,alpha,model,params,parametercovariancematrix, inputs; saveevery = false,immobilized = immobilized, reactionkwargs...)
        else
            predictionerror[NTPindex] = 0
        end
    end
    plot!(1000*NTPinput,1e6*RNAyield,linewidth = 2.5,color = color, label = "",z_order = :back)
    lower_pointwise_CB = max.(1e6*RNAyield .- 1e6*predictionerror,0)
    upper_pointwise_CB = 1e6*RNAyield .+ 1e6*predictionerror
    plot!(1000*NTPinput, lower_pointwise_CB[:,:], fillrange = upper_pointwise_CB[:,:], fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",z_order = :back)
    

    scatter!([5.0,7.0,9.0,11.0],[0.242101846, 0.38870331, 0.587359264, 0.499159036],yerr = 0.06,markersize = 4,palette =:Dark2_5,mc = color,label = "")

    plot!(xlabel = "NTP (mM)",ylabel = "RNA (μM)",linewidth=3.5,legend=:outerright,ylims = (0,Inf))
    return plt   
end

"""
    plotinitialrates(model,data,params, parametercovariancematrix, showconfidence)  

Generate figure 3A of main text showing model fit to initial rate Akama data."""
function plotDatabyPolymerase(model,params, parametercovariancematrix, showconfidence; immobilized = true, color = :blue, reactionkwargs...)
    plt = plot()
    Polymerasepoints = 100
    Polymeraseinput = LinRange(0,200,Polymerasepoints)
    RNAyield = zeros(Polymerasepoints)
    predictionerror = zeros(Polymerasepoints)
    for (Polymeraseindex,Polymeraseconc) in enumerate(Polymeraseinput)
        inputs =(T7RNAP = Polymeraseconc*1e-9, ATP = 7/4*1e-3,UTP = 7/4*1e-3,CTP = 7/4*1e-3,GTP = 7/4*1e-3, Mg = 11e-3, Buffer = 0.0425, DNA = 377.2, final_time = 0.02472)
        sol = runDAE_batch(params,inputs;immobilized = immobilized, reactionkwargs...)
        RNAyield[Polymeraseindex] = sol.u[end][RNAindex]
        if showconfidence
            predictionerror[Polymeraseindex] = predictionuncertainty_linearized(RNAindex,alpha,model,params,parametercovariancematrix, inputs; saveevery = false,immobilized = immobilized, reactionkwargs...)
        else
            predictionerror[Polymeraseindex] = 0
        end
    end
    plot!(Polymeraseinput,1e6*RNAyield,linewidth = 2.5,color = color, label = "",z_order = :back)
    lower_pointwise_CB = max.(1e6*RNAyield .- 1e6*predictionerror,0)
    upper_pointwise_CB = 1e6*RNAyield .+ 1e6*predictionerror
    plot!(Polymeraseinput, lower_pointwise_CB[:,:], fillrange = upper_pointwise_CB[:,:], fillalpha = 0.35,alpha=0.0, color = color,linewidth = 0.0,label="",z_order = :back)
    

    scatter!([40.6,81.2,121.8],[0.075439706, 0.177983497, 0.218187891],yerr = 0.037493985, markersize = 4,palette =:Dark2_5,mc = color,label = "")

    plot!(xlabel = "SP6 Polymerase (nM)",ylabel = "RNA (μM)",linewidth=3.5,legend=:outerright,ylims = (0,Inf))
    return plt   
end

#Calculation units in m and s, output in h
function IPFReffectivespacetime(t; maxspacetime = 89, v_front = 3.491968909923764e-5, reactor_length = 19.8e-3)
    return (1/3600)*min(maxspacetime,maxspacetime*(3600*t)*(v_front)/(reactor_length))
end

function integralIPRFoutput(params, final_time;
    stoich = (444,444,444,444),
    PPiase = 2e-3,
    outputfunction = totalrna)

    inputs =(T7RNAP = 81.2, ATP = 1.75e-3,UTP = 1.75e-3,CTP = 1.75e-3,GTP = 1.75e-3, Mg = 11e-3, Buffer = 42.5e-3, DNA = 605.7, final_time = final_time)
    sol = runDAE_batch(params, inputs, PPiase = PPiase, stoich = stoich, saveevery = false, immobilized = true)
    return outputfunction(sol,[])[end]
end

function IPFRintegralinfinitesimal!(du,u,params,t)
    effectivespacetime = IPFReffectivespacetime(t)
    du[1] =  integralIPRFoutput(params, effectivespacetime)
    nothing
end

function solveintegralIPFR(params,t_final)
    #Generate initialization
    ntotalvars =  1
    initial = zeros(ntotalvars)
    f = ODEFunction(IPFRintegralinfinitesimal!)
    prob_mm = ODEProblem(f,initial,(0.0,t_final),params)
    sol = solve(prob_mm,Tsit5(),tstops = LinRange(0,t_final,1000))
   return sol
end  

function plotintegralIPFR(model,paramslist,parametercovariancematrix;nmc = 100,alpha = 0.05,mcuncertainty = true)
    params = fullparameterset(model,paramslist)
    times = [0.25,0.5,0.75,1.0]
    totalRNAproduced = [86.08452446, 236.8948262, 379.6952547, 522.8565872]
    sol = solveintegralIPFR(params,1.1)
    plt = plot(sol.t,[3600*0.37*i[1] for i in sol.u], ylabel = "Total RNA Product (femtomoles)", xlabel = "Time (h)", label = "", color = :black,linewidth = 2)
    scatter!(times,totalRNAproduced,yerror = 20,mc = :black, markersize = 5,label = "")
    plot!(size = (400,300),ylims = (0,Inf), xlims = (0,Inf))

    mean = paramslist
    tvals = sol.t
    d = MvNormal(mean, Hermitian(parametercovariancematrix))
    if mcuncertainty # Using mc sampling for uncertainty
        mcensemble = zeros(nmc,length(tvals))
        mean = paramslist
        d = MvNormal(mean, Hermitian(parametercovariancematrix))
        for i in 1:nmc
            x = rand(d, 1)
            sampleparams = fullparameterset(model,x)
            sol = solveintegralIPFR(sampleparams,1.1)
            timepointsol = sol(tvals)
            mcensemble[i,:] = [3600*0.37*j[1] for j in timepointsol.u]
        end
        lower_pointwise_CB = [percentile(mcensemble[:,j],100*alpha/2) for j in 1:length(tvals)]
        upper_pointwise_CB = [percentile(mcensemble[:,j],100*(1-alpha/2)) for j in 1:length(tvals)]
        plot!(tvals, lower_pointwise_CB, fillrange = upper_pointwise_CB, fillalpha = 0.35,alpha=0.0, color = :black,linewidth = 0.0,label="")
    end
    return plt
end
