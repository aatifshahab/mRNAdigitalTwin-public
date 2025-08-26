from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

# IVT schemas
class IVTInput(BaseModel):
    T7RNAP: float
    ATP: float
    CTP: float
    GTP: float
    UTP: float
    Mg: float
    DNA: float
    finaltime: float
    Q: float  # Flow rate in L/hr
    V: float  # Reactor volume in L
    saveat_step: Optional[float] = Field(
        default=0.1,
        description="Step size for the saveat Range. Example: 0.1 for every 0.1 hour."
    )
 
class IVTOutput(BaseModel):
    # Time-Series Data
    time: List[float]
    # Additional Outputs (lists instead of single floats)
    ATPo: List[float]
    UTPo: List[float]
    CTPo: List[float]
    GTPo: List[float]
    Phosphateo: List[float]
    pHo: List[float]
    TotalMgo: List[float]
    TotalRNAo: List[float]

# CCTC schemas
class CCTCInput(BaseModel):
    states0_last_value: float = Field(
        ...,
        description="Last value of states0 from the IVT simulation."
    )

class CCTCOutput(BaseModel):
    time: List[float]
    unbound_mRNA: List[float]
    bound_mRNA: List[float]



# Lyo schemas
class LyoInput(BaseModel):
    fluidVolume: float  # Volume of the fluid (L)
    massFractionmRNA: float  # Mass fraction of mRNA (kg/kg)
    InitfreezingTemperature: float  # Initial freezing temperature (K)
    InitprimaryDryingTemperature: float  # Initial primary drying temperature (K)
    InitsecondaryDryingTemperature: float  # Initial secondary drying temperature (K)
    TempColdGasfreezing: float  # Temperature of cold gas during freezing (K)
    TempShelfprimaryDrying: float  # Temperature of the shelf during primary drying (K)
    TempShelfsecondaryDrying: float  # Temperature of the shelf during secondary drying (K)
    Pressure: float  # Pressure in kPa

class LyoOutput(BaseModel):
    time1: List[float]
    time2: List[float]
    time3: List[float]
    time: List[float]
    massOfIce: List[float]
    boundWater: List[float]
    productTemperature: List[float]
    operatingPressure: List[float]
    operatingTemperature: List[float]
    error: Optional[str] = None  # To handle error messages

#Membrane schemas
class MembraneInput(BaseModel):

    qF: float = Field(..., description="Feed flow rate [mL/min], 1–5")
    c0_mRNA: float = Field(..., description="Initial mRNA concentration [mg/mL]")
    c0_protein: float = Field(..., description="Initial protein concentration [mg/mL]")
    c0_ntps: float = Field(..., description="Initial NTPs concentration [mg/mL]")
    X: float = Field(..., description="Desired conversion (0 < X < 1)")
    n_stages: int = Field(..., description="Number of TFF stages (>=2, max=5)")
    D: float = Field(..., description="Flow rate of buffer for washing step [mL/min]")
    filterType: str = Field(..., description="Either 'HF' or 'VIBRO'")

class MembraneOutput(BaseModel):
    # PDE solution arrays
    time_points: List[float]
    x_positions: List[float]

    Cmatrix_mRNA: List[List[float]]
    Cmatrix_protein: List[List[float]]
    Cmatrix_ntps: List[List[float]]

    # Interpolation data
    interpolated_times: List[float]
    interpolated_indices: List[int]

    # Diafiltration
    td: List[float]
    TFF_protein: List[List[float]]  # each element of TFF_protein is a stage array
    TFF_ntps: List[List[float]]     # each element of TFF_ntps is a stage array
    TFF_mRNA: List[List[float]]  # each element is the mRNA array per TFF stage

    # Flux and conversion
    Jcrit: float
    Xactual: float
    

    error: Optional[str] = None




# LNP schemas
class LNPInput(BaseModel):
    Residential_time: float = Field(
        ...,
        description="Residential time [s], e.g., 60"
    )
    FRR: float = Field(
        ...,
        description="Flow rate ratio [-], range 1 to 3"
    )
    pH: float = Field(
        ...,
        description="pH [-], range 4 to 6"
    )
    Ion: float = Field(
        ...,
        description="Ionic concentration [M], range 0.01 to 1"
    )
    TF: float = Field(
        ...,
        description="Total flowrate [ml/min]"
    )
    mRNA_in: float = Field(
        ...,
        description="MRNA concnetration in from previous unit [mg/ml]"
    )
    C_lipid: float = Field(
        ...,
        description="lipic cncnetration [mg/ml]"
    )

class LNPOutput(BaseModel):
    Diameter: List[List[float]]  # Particle diameters (2D array)
    PSD: List[List[float]]       # Particle size distribution (2D array)
    EE: float                    # Encapsulation efficiency (dimensionless)
    mRNA_out: float              # mRNA concentration after processing
    error: Optional[str] = None  


# Serial aka chain simulation
class ChainUnit(BaseModel):
    id: str
    inputs: dict
    uniqueId: str

class ChainRequest(BaseModel):
    chain: list[ChainUnit]

class ChainResult(BaseModel):
    unitId: str
    uniqueId: str
    result: dict

class ChainResponse(BaseModel):
    chainResults: list[ChainResult]


class UnitResult(BaseModel):
    result: dict