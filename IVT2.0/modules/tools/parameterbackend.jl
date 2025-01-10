"""
    IVTmodel

List of parameter objects."""
struct IVTmodel
    parameters
end

"""
    Parameter

Collects information of name, fitting status, prior (hasprior, prior value, and prior variance), and upper and lower bound of parameter for optimization."""
struct Parameter
    name
    isfitted
    hasprior
    value
    variance
    upperbound
    lowerbound
end

"""
    parametermask(model)

Take model, return bitvector representing if parameters are fitted or fixed.
"""
function parametermask(model)
    mask = zeros(length(model.parameters))
    for i in 1:length(model.parameters)
        if model.parameters[i].isfitted
            mask[i] = 1
        end
    end
    return mask      
end

"""
    fixparameters(model:IVTmodel;resetparameters = [],addparameters = [])

Take IVT model, fix all parameters other than resetparameters and addparameters.
"""
function fixparameters(model::IVTmodel,fittedparameters;resetparameters = [],addparameters = [])
    fixedparametermodel = []
    resetparametersnames = [parameter.name for parameter in resetparameters]
    labeledparameters = fullparameterset(model,fittedparameters)
    for (ind,parameter) in enumerate(model.parameters)
        if parameter.name in resetparametersnames
            resetindex = findfirst(item -> item == parameter.name, resetparametersnames)
            addtoinputlist!(fixedparametermodel,resetparameters[resetindex])
        else
            addtoinputlist!(fixedparametermodel,Parameter(parameter.name,labeledparameters[ind]))
        end
    end
    for newparameter in addparameters
        addtoinputlist!(fixedparametermodel,newparameter)
    end
    return IVTmodel(fixedparametermodel)
end

Parameter(name,value) = Parameter(name,false,false,value,0,0,0)
Parameter(name,value,upperbound,lowerbound) = Parameter(name,true,false,value,0,upperbound,lowerbound)
Parameter(name,value,upperbound,lowerbound,standarddev) = Parameter(name,true,true,value,standarddev,upperbound,lowerbound)

"""
    fullparameterset(model,roundparameters)

Take model and list of fitted parameter values, return ComponentArray of all parameters for use in model evaluation.
"""
function fullparameterset(model::IVTmodel,roundparameters)
    namesofvalues::Vector{String} = []
    parametervalues = []
    fittedparametercounter = 1
    for i in model.parameters
        append!(namesofvalues,[i.name])
        if i.isfitted
            append!(parametervalues,[10^(roundparameters[fittedparametercounter])])
            fittedparametercounter+=1
        else
            append!(parametervalues,[i.value])  
        end
    end
    nt = ComponentArray(namedtuple(namesofvalues, parametervalues))
    return nt
end


function reportparametertypes(model::IVTmodel)
    fittedparametercounter = 1
    bayesianparametercounter = 1
    for i in model.parameters
        if i.isfitted
            fittedparametercounter+=1
            if i.hasprior
                bayesianparametercounter+=1
            end
        end
    end
    return (fittedparametercounter,bayesianparametercounter)
end

addtoinputlist!(list,parameter::Parameter) = append!(list,[parameter])

"""
    setupmodel()

Generate model with parameter names, fitting status, and prior distrubution.
"""
function setupmodel_IVT1()
    #This is our "interface": each line here represents adding a parameter and some associated information
    #format is Parameter(name, bayesian prior, lower bound (useful for optimization), upper bound, bayesian stdev)
    modelinputparameters = []

    #Parameters for T7 degredation rate
    addtoinputlist!(modelinputparameters,Parameter("k_dT7",0))

    #Parameters for transcription rate
    addtoinputlist!(modelinputparameters,Parameter("k_i",936,1,50000,0.3))
    addtoinputlist!(modelinputparameters,Parameter("k_e",5.3e5,1e4,15e5,0.15))
    addtoinputlist!(modelinputparameters,Parameter("k_off",4320,400,74000,0.25))
    addtoinputlist!(modelinputparameters,Parameter("k_on",204,20,2100,0.05))
    addtoinputlist!(modelinputparameters,Parameter("K_1",10^(-3.692),0.00001,0.1))
    addtoinputlist!(modelinputparameters,Parameter("K_2",10^(-3.80),0.00001,0.05))
    addtoinputlist!(modelinputparameters,Parameter("Ki_PPi",0.0002,0.00001,0.05,0.3))

    #Parameters for Capping Fraction
    addtoinputlist!(modelinputparameters,Parameter("gamma",1, 0.001,100,0.2))#ML prior
    addtoinputlist!(modelinputparameters,Parameter("theta",0.0208,0.000208,2.08,0.2))#Moderna Patent based on ML prior

    #Parameters for dsRNA Formation
    addtoinputlist!(modelinputparameters,Parameter("K_ds",1))#Usui et al

    #Parameters for Pyrophosphatase activity
    addtoinputlist!(modelinputparameters,Parameter("kPPiase",1))
    addtoinputlist!(modelinputparameters,Parameter("KMPPiase",0.000214))
    # addtoinputlist!(modelinputparameters,Parameter("kPPiase",1,0.1,10,0.08))
    # addtoinputlist!(modelinputparameters,Parameter("KMPPiase",0.000214))

    #Parameters for solid formation
    addtoinputlist!(modelinputparameters,Parameter("k_precip",10^(-0.26),1e-8,1e6))
    addtoinputlist!(modelinputparameters,Parameter("B",13.48,1e-5,90,0.1))
    addtoinputlist!(modelinputparameters,Parameter("k_d",10^(4.47),1e-2,1e12))

    #Parameters for equilibria
    addtoinputlist!(modelinputparameters,Parameter("K_HNTP",10^(6.91),10^(4.91),10^(8.91),0.02))#
    addtoinputlist!(modelinputparameters,Parameter("K_HMgNTP",10^(2.08),10^(0.08),10^(4.08),0.05))#
    addtoinputlist!(modelinputparameters,Parameter("K_HPPi",10^(9.02),10^(8.02),10^(10.01),0.05))
    addtoinputlist!(modelinputparameters,Parameter("K_HMgPPi",10^(3.32),10^(1.32),10^(4.32),0.05))      
    addtoinputlist!(modelinputparameters,Parameter("K_H2PPi",10^(6.26),10^(4.26),10^(8.26),0.1))#
    addtoinputlist!(modelinputparameters,Parameter("K_H2MgPPi",10^(2.11),10^(0.11),10^(4.11),0.1))#
    addtoinputlist!(modelinputparameters,Parameter("K_MgNTP",10^(4.54),10^(3.0),10^(6),0.58))
    addtoinputlist!(modelinputparameters,Parameter("K_NaNTP",10^(1.16)))
    addtoinputlist!(modelinputparameters,Parameter("K_Mg2NTP",10^(1.77),10^(0.01),10^(3.5),0.58))
    addtoinputlist!(modelinputparameters,Parameter("K_MgPPi",10^(4.80),10^(3.80),10^(7),0.58))
    addtoinputlist!(modelinputparameters,Parameter("K_Mg2PPi",10^(2.57),10^(1.57),10^(4.8),0.58))
    addtoinputlist!(modelinputparameters,Parameter("K_MgPi",10^(2.20)))
    addtoinputlist!(modelinputparameters,Parameter("K_HPi",10^(6.92)))
    addtoinputlist!(modelinputparameters,Parameter("K_NaPi",10^(0.77)))
    addtoinputlist!(modelinputparameters,Parameter("Mg2PPi_eq",1.4e-5,1.4e-10,1.4e-2,0.3))

    return IVTmodel(modelinputparameters)
end

function setupmodel_IVT2()
    #This is our "interface": each line here represents adding a parameter and some associated information
    #format is Parameter(name, bayesian prior, lower bound (useful for optimization), upper bound, bayesian stdev)
    modelinputparameters = []

    #Parameters for T7 degredation rate
    #addtoinputlist!(modelinputparameters,Parameter("k_dT7",0.84)) #From Arnold et al
    addtoinputlist!(modelinputparameters,Parameter("k_dT7",0)) #From Arnold et al
    
    #Parameters for transcription rate
    addtoinputlist!(modelinputparameters,Parameter("k_i",936,1,50000,0.3))
    addtoinputlist!(modelinputparameters,Parameter("k_e",5.3e5,1e4,15e5,0.15))
    addtoinputlist!(modelinputparameters,Parameter("k_off",4320))#addtoinputlist!(modelinputparameters,Parameter("k_off",4320,400,74000,0.25))
    addtoinputlist!(modelinputparameters,Parameter("k_on",204))#addtoinputlist!(modelinputparameters,Parameter("k_on",204,20,2100,0.05))
    addtoinputlist!(modelinputparameters,Parameter("K_1",10^(-3.692),1e-5,1e-1))
    addtoinputlist!(modelinputparameters,Parameter("K_2",10^(-3.692),1e-5,1e-1))
    addtoinputlist!(modelinputparameters,Parameter("Ki_PPi",0.0002,0.00001,0.05,0.3))

    #Parameters for Capping Fraction
    addtoinputlist!(modelinputparameters,Parameter("gamma",1))#ML prior
    addtoinputlist!(modelinputparameters,Parameter("theta",0.0208))#Moderna Patent based on ML prior
    # addtoinputlist!(modelinputparameters,Parameter("gamma",1, 0.001,100,0.2))#ML prior
    # addtoinputlist!(modelinputparameters,Parameter("theta",0.0208,0.000208,2.08,0.2))#Moderna Patent based on ML prior

    #Parameters for dsRNA Formation
    addtoinputlist!(modelinputparameters,Parameter("K_ds",1))#Usui et al

    #Parameters for Pyrophosphatase activity
    addtoinputlist!(modelinputparameters,Parameter("kPPiase",1))
    addtoinputlist!(modelinputparameters,Parameter("KMPPiase",0.000214))
    # addtoinputlist!(modelinputparameters,Parameter("kPPiase",1,0.1,10,0.08))
    # addtoinputlist!(modelinputparameters,Parameter("KMPPiase",0.000214))

    #Parameters for solid formation
    addtoinputlist!(modelinputparameters,Parameter("k_precip",10^(-0.26),1e-8,1e6))
    addtoinputlist!(modelinputparameters,Parameter("B",13.48,1e-5,90,0.1))
    addtoinputlist!(modelinputparameters,Parameter("k_d",10^(4.47),1e-2,1e12))

    #Parameters for equilibria
    addtoinputlist!(modelinputparameters,Parameter("K_HNTP",10^(6.91)))#addtoinputlist!(modelinputparameters,Parameter("K_HNTP",10^(6.91),10^(4.91),10^(8.91),0.02))#
    addtoinputlist!(modelinputparameters,Parameter("K_HMgNTP",10^(2.08)))#addtoinputlist!(modelinputparameters,Parameter("K_HMgNTP",10^(2.08),10^(0.08),10^(4.08),0.05))
    addtoinputlist!(modelinputparameters,Parameter("K_HPPi",10^(9.02)))#addtoinputlist!(modelinputparameters,Parameter("K_HPPi",10^(9.02),10^(8.02),10^(10.01),0.05))
    addtoinputlist!(modelinputparameters,Parameter("K_HMgPPi",10^(3.32)))#addtoinputlist!(modelinputparameters,Parameter("K_HMgPPi",10^(3.32),10^(1.32),10^(4.32),0.05))      
      
    addtoinputlist!(modelinputparameters,Parameter("K_H2PPi",10^(6.26)))#addtoinputlist!(modelinputparameters,Parameter("K_H2PPi",10^(6.26),10^(4.26),10^(8.26),0.1))
    addtoinputlist!(modelinputparameters,Parameter("K_H2MgPPi",10^(2.11)))#addtoinputlist!(modelinputparameters,Parameter("K_H2MgPPi",10^(2.11),10^(0.11),10^(4.11),0.1))
    addtoinputlist!(modelinputparameters,Parameter("K_MgNTP",10^(4.54),10^(3.0),10^(6),0.58))
    addtoinputlist!(modelinputparameters,Parameter("K_Mg2NTP",10^(1.77),10^(0.01),10^(3.5),0.58))

    addtoinputlist!(modelinputparameters,Parameter("K_MgPPi",10^(4.80),10^(3.80),10^(7),0.58))
    addtoinputlist!(modelinputparameters,Parameter("K_Mg2PPi",10^(2.57),10^(1.57),10^(4.8),0.58))

    addtoinputlist!(modelinputparameters,Parameter("Mg2PPi_eq",1.4e-5,1.4e-10,1.4e-2,0.3))

    addtoinputlist!(modelinputparameters,Parameter("K_MgPi",10^(2.20)))#From Kern and Davis 1995
    addtoinputlist!(modelinputparameters,Parameter("K_HPi",10^(6.92)))#From Kern and Davis 1995
    addtoinputlist!(modelinputparameters,Parameter("K_NaPi",10^(0.77)))#From Kern and Davis 1995
    addtoinputlist!(modelinputparameters,Parameter("K_NaNTP",10^(1.16)))#From Kern and Davis 1995

    #Parameters for Effective Buffer and Na addition
    # addtoinputlist!(modelinputparameters,Parameter("effectiveNTPNa",1e-4))
    # addtoinputlist!(modelinputparameters,Parameter("effectiveBufferadded",5.27))

    model = IVTmodel(modelinputparameters)
    (fittedparams, bayesianparams) = reportparametertypes(model)
    println("Model has "*string(fittedparams)*" fitted parameters, "*string(bayesianparams)*" of which have a bayesian prior")
    return model
end

function setupmodel_IVT3()#using adjusted values for temp/IS
    #This is our "interface": each line here represents adding a parameter and some associated information
    #format is Parameter(name, bayesian prior, lower bound (useful for optimization), upper bound, bayesian stdev)
    modelinputparameters = []

    #Parameters for T7 degredation rate
    #addtoinputlist!(modelinputparameters,Parameter("k_dT7",0.84)) #From Arnold et al
    addtoinputlist!(modelinputparameters,Parameter("k_dT7",0)) #From Arnold et al
    
    #Parameters for transcription rate
    addtoinputlist!(modelinputparameters,Parameter("k_i",936,1,50000,0.3))
    #addtoinputlist!(modelinputparameters,Parameter("k_i",936))#,1,50000,0.3))
    addtoinputlist!(modelinputparameters,Parameter("k_e",5.3e5,1e4,15e6,0.15))
    addtoinputlist!(modelinputparameters,Parameter("k_off",4320))#addtoinputlist!(modelinputparameters,Parameter("k_off",4320,400,74000,0.25))
    addtoinputlist!(modelinputparameters,Parameter("k_on",204))#addtoinputlist!(modelinputparameters,Parameter("k_on",204,20,2100,0.05))
    addtoinputlist!(modelinputparameters,Parameter("K_1",10^(-3.692),1e-5,1e-1))
    addtoinputlist!(modelinputparameters,Parameter("K_2",10^(-3.692),1e-5,1e-1))
    addtoinputlist!(modelinputparameters,Parameter("Ki_PPi",0.0002,0.00001,0.05,0.3))

    #Parameters for pH effect 
    addtoinputlist!(modelinputparameters,Parameter("K_a",10^(-7.5),1e-10,1e-3))
    addtoinputlist!(modelinputparameters,Parameter("K_b",10^(-9.2),1e-12,1e-4))
    addtoinputlist!(modelinputparameters,Parameter("k_pH",15.0,0.00001,150))

    #Parameters for Capping Fraction
    addtoinputlist!(modelinputparameters,Parameter("gamma",1))#ML prior
    addtoinputlist!(modelinputparameters,Parameter("theta",0.0208))#Moderna Patent based on ML prior
    # addtoinputlist!(modelinputparameters,Parameter("gamma",1, 0.001,100,0.2))#ML prior
    # addtoinputlist!(modelinputparameters,Parameter("theta",0.0208,0.000208,2.08,0.2))#Moderna Patent based on ML prior

    #Parameters for dsRNA Formation
    addtoinputlist!(modelinputparameters,Parameter("K_ds",1))#Usui et al

    #Parameters for Pyrophosphatase activity
    addtoinputlist!(modelinputparameters,Parameter("kPPiase",1))
    addtoinputlist!(modelinputparameters,Parameter("KMPPiase",0.000214))
    # addtoinputlist!(modelinputparameters,Parameter("kPPiase",1,0.1,10,0.08))
    # addtoinputlist!(modelinputparameters,Parameter("KMPPiase",0.000214))

    #Parameters for solid formation
    addtoinputlist!(modelinputparameters,Parameter("k_precip",10^(-0.26),1e-8,1e6))
    addtoinputlist!(modelinputparameters,Parameter("B",13.48,1e-5,90,0.1))
    addtoinputlist!(modelinputparameters,Parameter("k_d",10^(4.47),1e-2,1e12))

    #Parameters for equilibria
    addtoinputlist!(modelinputparameters,Parameter("K_HNTP",10^(6.4867)))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_HMgNTP",10^(2.00832)))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_HPPi",10^(9.02)))
    addtoinputlist!(modelinputparameters,Parameter("K_HMgPPi",10^(3.32)))
      
    addtoinputlist!(modelinputparameters,Parameter("K_H2PPi",10^(6.26)))
    addtoinputlist!(modelinputparameters,Parameter("K_H2MgPPi",10^(2.11)))

    addtoinputlist!(modelinputparameters,Parameter("K_MgNTP",10^(4.0227)))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_Mg2NTP",10^(1.6049)))#adjusted

    #addtoinputlist!(modelinputparameters,Parameter("K_MgNTP",10^(4.0227),10^(3.0),10^(6),0.58))#adjusted
    #addtoinputlist!(modelinputparameters,Parameter("K_Mg2NTP",10^(1.6049),10^(0.01),10^(3.5),0.58))#adjusted

    addtoinputlist!(modelinputparameters,Parameter("K_MgPPi",10^(4.80),10^(3.80),10^(7),0.58))
    #addtoinputlist!(modelinputparameters,Parameter("K_Mg2PPi",10^(2.57)))
    addtoinputlist!(modelinputparameters,Parameter("K_Mg2PPi",10^(2.57),10^(1.57),10^(4.8),0.58))

    addtoinputlist!(modelinputparameters,Parameter("Mg2PPi_eq",1.4e-5,1.4e-10,1.4e-2,0.3))

    addtoinputlist!(modelinputparameters,Parameter("K_MgPi",10^(1.6354428)))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_HPi",10^(6.620343)))#adjusted
    #addtoinputlist!(modelinputparameters,Parameter("K_MgPi",10^(2.20)))#From Kern and Davis 1995
    #addtoinputlist!(modelinputparameters,Parameter("K_HPi",10^(6.92)))#From Kern and Davis 1995 
    addtoinputlist!(modelinputparameters,Parameter("K_NaPi",10^(0.77)))#From Kern and Davis 1995
    addtoinputlist!(modelinputparameters,Parameter("K_NaNTP",10^(1.16)))#From Kern and Davis 1995

    #Parameters for Effective Buffer and Na addition
    # addtoinputlist!(modelinputparameters,Parameter("effectiveNTPNa",1e-4))
    # addtoinputlist!(modelinputparameters,Parameter("effectiveBufferadded",5.27))

    model = IVTmodel(modelinputparameters)
    (fittedparams, bayesianparams) = reportparametertypes(model)
    println("Model has "*string(fittedparams)*" fitted parameters, "*string(bayesianparams)*" of which have a bayesian prior")
    return model
end

function setupmodel_IVT4()#using adjusted values for temp/IS, used for parameter estimation with new system
    #This is our "interface": each line here represents adding a parameter and some associated information
    #format is Parameter(name, bayesian prior, lower bound (useful for optimization), upper bound, bayesian stdev)
    modelinputparameters = []

    #Parameters for T7 degredation rate
    addtoinputlist!(modelinputparameters,Parameter("k_dT7",0)) #From Arnold et al
    
    #Parameters for transcription rate
    addtoinputlist!(modelinputparameters,Parameter("k_i",1800,1,100000,0.1))#Tweaked prior distribution from Maslak
    addtoinputlist!(modelinputparameters,Parameter("k_i_guo",1800,1,100000,0.1))#Tweaked prior distribution from Maslak

    addtoinputlist!(modelinputparameters,Parameter("k_e",5.3e5,1e4,15e6,0.15))#Tweaked prior distribution
    addtoinputlist!(modelinputparameters,Parameter("k_e_guo",5.3e5,1e4,15e6,0.15))#Tweaked prior distribution

    addtoinputlist!(modelinputparameters,Parameter("k_off",4320))
    addtoinputlist!(modelinputparameters,Parameter("k_on",204,2,21000,0.15))
    addtoinputlist!(modelinputparameters,Parameter("K_1",10^(-3.692),1e-9,1e-1))
    addtoinputlist!(modelinputparameters,Parameter("K_2",10^(-3.692),1e-9,1e-1))
    addtoinputlist!(modelinputparameters,Parameter("nMg",4.0,1.0,100.0))
    addtoinputlist!(modelinputparameters,Parameter("Ki_PPi",0.0002,0.00001,0.5,0.3))

    addtoinputlist!(modelinputparameters,Parameter("K_Mg",exp(4.0),exp(1.0),exp(10),0.07))
    addtoinputlist!(modelinputparameters,Parameter("K_u0",exp(2.86),exp(1.0),exp(3),0.03))


    #Parameters for pH effects 
    addtoinputlist!(modelinputparameters,Parameter("K_a",10^(-7.5),1e-10,1e-3))
    addtoinputlist!(modelinputparameters,Parameter("K_b",10^(-9.2),1e-12,1e-4))
    addtoinputlist!(modelinputparameters,Parameter("k_pH",15.0,0.00001,150))

    #Parameters for Capping Fraction
    addtoinputlist!(modelinputparameters,Parameter("gamma",1,0.01,10,0.1))#ML prior
    addtoinputlist!(modelinputparameters,Parameter("theta",0.0208))#Moderna Patent based on ML prior

    #Parameters for dsRNA Formation
    addtoinputlist!(modelinputparameters,Parameter("K_ds",1))#Usui et al

    #Parameters for Pyrophosphatase activity
    addtoinputlist!(modelinputparameters,Parameter("kPPiase",1))
    addtoinputlist!(modelinputparameters,Parameter("KMPPiase",0.000214))

    #Parameters for solid formation
    addtoinputlist!(modelinputparameters,Parameter("k_precip",10^(-0.26),1e-8,1e6))
    addtoinputlist!(modelinputparameters,Parameter("B",13.48,1e-5,90,0.1))
    addtoinputlist!(modelinputparameters,Parameter("k_d",10^(4.47),1e-2,1e12))

    #Parameters for equilibria
    addtoinputlist!(modelinputparameters,Parameter("K_HNTP",10^(6.4867)))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_HMgNTP",10^(2.00832)))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_HPPi",10^(9.02)))
    addtoinputlist!(modelinputparameters,Parameter("K_HMgPPi",10^(3.32),10^(1.32),10^(5.32),0.58))      
      
    addtoinputlist!(modelinputparameters,Parameter("K_H2PPi",10^(6.26)))
    addtoinputlist!(modelinputparameters,Parameter("K_H2MgPPi",10^(2.11)))

    #addtoinputlist!(modelinputparameters,Parameter("K_MgNTP",10^(4.0227)))#adjusted
    #addtoinputlist!(modelinputparameters,Parameter("K_MgNTP",10^(4.522878745280337)))#adjusted

    #addtoinputlist!(modelinputparameters,Parameter("K_Mg2NTP",10^(1.6049)))#adjusted

    addtoinputlist!(modelinputparameters,Parameter("K_MgNTP",10^(4.0227),10^(3.0),10^(6),0.58))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_Mg2NTP",10^(1.6049),10^(0.01),10^(5.5),0.58))#adjusted

    addtoinputlist!(modelinputparameters,Parameter("K_MgPPi",10^(4.80),10^(3.80),10^(7),0.58))
    addtoinputlist!(modelinputparameters,Parameter("K_Mg2PPi",10^(2.57),10^(1.57),10^(4.8),0.58))

    addtoinputlist!(modelinputparameters,Parameter("Mg2PPi_eq",1.4e-5,1.4e-10,1.4e-2,0.3))

    addtoinputlist!(modelinputparameters,Parameter("K_MgPi",10^(1.6354428)))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_HPi",10^(6.620343)))#adjusted
    addtoinputlist!(modelinputparameters,Parameter("K_NaPi",10^(0.77)))#From Kern and Davis 1995
    addtoinputlist!(modelinputparameters,Parameter("K_NaNTP",10^(1.16)))#From Kern and Davis 1995

    model = IVTmodel(modelinputparameters)
    (fittedparams, bayesianparams) = reportparametertypes(model)
    println("Model has "*string(fittedparams)*" fitted parameters, "*string(bayesianparams)*" of which have a bayesian prior")
    return model
end