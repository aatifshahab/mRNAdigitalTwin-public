

# from julia_interface import run_ivt_process
# from schemas import IVTInput
# import logging

# # Define the input data using the IVTInput Pydantic model
# input_data = IVTInput(
#     T7RNAP=1e-7,
#     ATP=0.0032,
#     CTP=0.0032,
#     GTP=0.0032,
#     UTP=0.0032,
#     Mg=0.008,
#     DNA=7.4,
#     finaltime=2.0,  # Simulation time in hours
#     Q=1.0,          # Flow rate in L/hr
#     V=2.0           # Reactor volume in L
# )

# # Run the simulation
# result = run_ivt_process(input_data)
# logging.info(f"Simulation completed successfully. Result: {result}")
# print(result)



import logging
from fastapi import FastAPI, Body
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

from julia_interface import run_ivt_process
from matlab_interface import run_cctc_model, run_lyo_model, run_membrane_model, run_lnp_model
from schemas import (
    IVTInput, IVTOutput,
    CCTCInput, CCTCOutput,
    LyoInput, LyoOutput,
    MembraneInput, MembraneOutput,
    LNPInput, LNPOutput
)


# Initialize logging
logging.basicConfig(level=logging.INFO)

app = FastAPI()

# Allow CORS for frontend's origin

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # React app runs on port 3000
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# default input data for IVT
default_ivt_input = IVTInput(
    T7RNAP=1e-7,
    ATP=0.0032,
    CTP=0.0032,
    GTP=0.0032,
    UTP=0.0032,
    Mg=0.008,
    DNA=7.4,
    finaltime=2.0,
    Q=1.0,
    V=2.0
)


# default input data for CCTC
default_cctc_input = CCTCInput(
    states0_last_value=1.26  # Example default value (g/L)
)

# default input data for Lyo
default_lyo_input = LyoInput(
    fluidVolume=3e-6,  # Example value in m3
    massFractionmRNA=0.05,  # Example value in kg/kg
    InitfreezingTemperature=298.15,  # 0°C in Kelvin
    InitprimaryDryingTemperature=228,  # 0°C in Kelvin
    InitsecondaryDryingTemperature=273,  # 0°C in Kelvin
    TempColdGasfreezing=268,  # -10°C in Kelvin
    TempShelfprimaryDrying=270,  # 10°C in Kelvin
    TempShelfsecondaryDrying=295,  # 20°C in Kelvin
    Pressure=10  #  kPa
)

# Default input data for LNP (optional)
default_lnp_input = LNPInput(
    Residential_time=60.0,  # Example value in seconds
    FRR=3.0,                # Example value
    pH=5.5,                 # Example value
    Ion=0.1,                # Example value in M
    TF=0.0                  # Example value in ml/min
)

@app.post("/run_simulation", response_model=IVTOutput)
async def run_simulation(input_data: IVTInput = Body(default_ivt_input)):
    """
    Endpoint to run IVT simulation using Julia.
    """
    logging.info("Received IVT simulation request.")
    try:
        result = run_ivt_process(input_data)
        logging.info("IVT simulation completed successfully.")
        return result
    except Exception as e:
        logging.error(f"IVT simulation failed: {e}")
        return {"error": str(e)}

@app.post("/run_cctc", response_model=CCTCOutput)
async def run_cctc(input_data: CCTCInput = Body(default_cctc_input)):
    """
    Endpoint to run CCTC simulation using MATLAB.
    """
    logging.info("Received CCTC simulation request.")
    try:
        result = run_cctc_model(input_data.states0_last_value)
        logging.info("CCTC simulation completed successfully.")
        return result
    except Exception as e:
        logging.error(f"CCTC simulation failed: {e}")
        return {"error": str(e)}


@app.post("/run_lyo", response_model=LyoOutput)
async def run_lyo(input_data: LyoInput = Body(default_lyo_input)):
    """
    Endpoint to run Lyo simulation using MATLAB.
    """
    logging.info("Received Lyo simulation request.")
    try:
        result = run_lyo_model(
            fluidVolume=input_data.fluidVolume,
            massFractionmRNA=input_data.massFractionmRNA,
            InitfreezingTemperature=input_data.InitfreezingTemperature,
            InitprimaryDryingTemperature=input_data.InitprimaryDryingTemperature,
            InitsecondaryDryingTemperature=input_data.InitsecondaryDryingTemperature,
            TempColdGasfreezing=input_data.TempColdGasfreezing,
            TempShelfprimaryDrying=input_data.TempShelfprimaryDrying,
            TempShelfsecondaryDrying=input_data.TempShelfsecondaryDrying,
            Pressure=input_data.Pressure
        )
        logging.info("Lyo simulation completed successfully.")
        return LyoOutput(**result)
    except Exception as e:
        logging.error(f"Lyo simulation failed: {e}")
        return LyoOutput(error=str(e))


# Endpoint for Membrane model
@app.post("/run_membrane", response_model=MembraneOutput)
async def run_membrane(input_data: MembraneInput = Body(...)):
    logging.info("Received Membrane simulation request.")
    try:
        result = run_membrane_model(
            qF=input_data.qF,
            c0_mRNA=input_data.c0_mRNA,
            c0_protein=input_data.c0_protein,
            c0_ntps=input_data.c0_ntps,
            X=input_data.X,
            n_stages=input_data.n_stages,
            D=input_data.D,
            filterType=input_data.filterType
        )
        logging.info("Membrane simulation completed successfully.")
        return MembraneOutput(**result)
    except Exception as e:
        logging.error(f"Membrane simulation failed: {e}")
        # Return an empty result plus the error
        return MembraneOutput(
            time_points=[],
            x_positions=[],
            Cmatrix_mRNA=[],
            Cmatrix_protein=[],
            Cmatrix_ntps=[],
            interpolated_times=[],
            interpolated_indices=[],
            td=[],
            TFF_protein=[],
            TFF_ntps=[],
            Jcrit=0.0,
            Xactual=0.0,
            error=str(e)
        )


# Endpoint for LNP model
@app.post("/run_lnp", response_model=LNPOutput)
async def run_lnp(input_data: LNPInput = Body(default_lnp_input)):
    """
    Endpoint to run LNP simulation using MATLAB.
    """
    logging.info("Received LNP simulation request.")
    try:
        result = run_lnp_model(
            Residential_time=input_data.Residential_time,
            FRR=input_data.FRR,
            pH=input_data.pH,
            Ion=input_data.Ion,
            TF=input_data.TF
        )
        logging.info("LNP simulation completed successfully.")
        return LNPOutput(**result)
    except Exception as e:
        logging.error(f"LNP simulation failed: {e}")
        return LNPOutput(error=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", reload=True)







