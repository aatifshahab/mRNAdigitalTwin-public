// src/utilits/labelMapping.js

export const labelMapping = {
    Q: 'F101',
    V: 'Reactor Volume',
    ATPo: 'ATP',
    GTPo: 'GTP',
    CTPo: 'CTP',
    UTPo: 'UTP',
    Phosphateo: 'Phosphate',
    pHo: 'pH',
    TotalMgo: 'Mg',
    
    TotalRNAo: 'mRNA',
    // F102: 'Flow Rate', // Assuming F102 is already an output variable
    // Add other mappings as needed

    // Membrane inputs
    qF: 'F103', // feed flow rate
    c0_mRNA: 'mRNA In', 
    c0_protein: 'Protein In',
    c0_ntps: 'NTPs In',
    X: 'Conversion Setpoint',
    n_stages: 'Stages',
    D: 'Buffer Flow',
    filterType: 'Filter Type',
  
    // TFF stages for measured variables
    ProteinStage1: 'Protein (Stage 1)',
    ProteinStage2: 'Protein (Stage 2)',
    ProteinStage3: 'Protein (Stage 3)', 
    NTPsStage1: 'NTPs (Stage 1)',
    NTPsStage2: 'NTPs (Stage 2)',
    NTPsStage3: 'NTPs (Stage 3)',
  
    //Membrane outputs 
    Jcrit: 'Critical Flux',
    Xactual: 'Actual Conversion',

    // LNP inputs
    Residential_time: 'Residence time',
    FRR:              'Flow rate ratio',
    pH:               'pH',
    Ion:              'Ionic strength',
    TF:               'Total flow rate',
    C_lipid:          'Lipid In.',
    mRNA_in:          'mRNA In',
  };
  