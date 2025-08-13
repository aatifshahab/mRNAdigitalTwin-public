import logging
from fastapi import FastAPI, Body, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict

from julia_interface import run_ivt_process
from matlab_interface import run_cctc_model, run_lyo_model, run_membrane_model, run_lnp_model
from schemas import (
    IVTInput, IVTOutput,
    CCTCInput, CCTCOutput,
    LyoInput, LyoOutput,
    MembraneInput, MembraneOutput,
    LNPInput, LNPOutput,
    ChainUnit, ChainRequest,
    ChainResult, ChainResponse,
    UnitResult
)

# Import necessary conversion functions
from conversions import (
    convert_uM_to_mg_per_ml,
    convert_mg_ml_to_g_l
)

# Imports for data storage
import uuid
from datetime import datetime
from db_storage import init_db, store_run_in_db, get_run_from_db

# Initialize logging
logging.basicConfig(level=logging.INFO)

app = FastAPI()

# Allow CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for simulation results
simulation_storage: Dict[str, dict] = {}

# Initialize database on startup
init_db()



#############################################################################
# PRIMARY ENDPOINT: Run a Chain of Simulations
#############################################################################

@app.post("/run_chain", response_model=ChainResponse)
async def run_chain(chain_request: ChainRequest):
    """
    Endpoint to run a chain of simulations in sequence.
    """
    logging.info("Received chain simulation request.")
    chain_results = []
    last_output = {}

    try:
        # Preliminary chain restriction:
        if len(chain_request.chain) > 1:
            # Ensure IVT, if present, is the first unit.
            for idx, unit in enumerate(chain_request.chain):
                if unit.id == 'ivt' and idx != 0:
                    error_msg = "IVT must be the first unit in a chain."
                    logging.error(error_msg)
                    return {"error": error_msg}
            # Ensure that if LYO is present, it follows LNP and nothing comes after LNP except LYO.
            for idx, unit in enumerate(chain_request.chain):
                if unit.id == 'lnp' and idx < len(chain_request.chain) - 1:
                    next_unit = chain_request.chain[idx + 1].id
                    if next_unit != 'lyo':
                        error_msg = "Only Lyophilization (LYO) can follow LNP."
                        logging.error(error_msg)
                        return {"error": error_msg}

        # Process each unit in the chain.
        for idx, unit in enumerate(chain_request.chain):
            unit_id = unit.id
            inputs = unit.inputs.copy()  # Copy inputs to avoid accidental mutation.
            prev_unit = chain_request.chain[idx - 1].id if idx > 0 else None

            # Unit conversions based on previous unit's output in last_output:
            if unit_id == 'membrane' and 'final_mRNA' in last_output:
                # Membrane expects mRNA in mg/mL.
                if prev_unit == 'ivt':
                    # IVT outputs mRNA in μM; convert to mg/mL.
                    inputs['c0_mRNA'] = convert_uM_to_mg_per_ml(last_output['final_mRNA'], molar_mass=660000)
                elif prev_unit == 'cctc':
                    # CCTC outputs in g/L (numerically equal to mg/mL).
                    inputs['c0_mRNA'] = last_output['final_mRNA']
                else:
                    inputs['c0_mRNA'] = last_output['final_mRNA']

            elif unit_id == 'cctc' and 'final_mRNA' in last_output:
                # CCTC expects mRNA in g/L.
                if prev_unit == 'ivt':
                    inputs['states0_last_value'] = convert_uM_to_mg_per_ml(last_output['final_mRNA'], molar_mass=660000)
                elif prev_unit == 'membrane':
                    inputs['states0_last_value'] = last_output['final_mRNA']
                elif prev_unit == 'cctc':
                    inputs['states0_last_value'] = last_output['final_mRNA']
                else:
                    inputs['states0_last_value'] = last_output['final_mRNA']

            elif unit_id == 'lnp' and 'final_mRNA' in last_output:
                # LNP expects its mRNA input (C_mRNA) in mg/mL.
                if prev_unit == 'ivt':
                    inputs['C_mRNA'] = convert_uM_to_mg_per_ml(last_output['final_mRNA'], molar_mass=660000)
                elif prev_unit in ['membrane', 'cctc']:
                    inputs['C_mRNA'] = last_output['final_mRNA']
                else:
                    inputs['C_mRNA'] = last_output['final_mRNA']

            elif unit_id == 'lyo' and 'final_mRNA' in last_output:
                # LYO takes the mass fraction (Fraction) from LNP.
                if prev_unit == 'lnp':
                    inputs['massFractionmRNA'] = last_output['final_mRNA']

            # Run simulation for the current unit:
            if unit_id == 'ivt':
                result = run_ivt_process(IVTInput(**inputs))
                if 'TotalRNAo' in result and result['TotalRNAo']:
                    final_mRNA = result['TotalRNAo'][-1]
                else:
                    final_mRNA = None
                    logging.warning("IVT output missing or empty 'TotalRNAo'.")
            elif unit_id == 'membrane':
                membrane_input = MembraneInput(**inputs)
                result = run_membrane_model(**membrane_input.dict())
                if ('TFF_mRNA' in result and result['TFF_mRNA'] and 
                    isinstance(result['TFF_mRNA'][-1], list) and result['TFF_mRNA'][-1]):
                    final_mRNA = result['TFF_mRNA'][-1][-1]
                else:
                    final_mRNA = None
                    logging.warning("Membrane output missing or empty 'TFF_mRNA'.")
            elif unit_id == 'cctc':
                cctc_input = CCTCInput(**inputs)
                result = run_cctc_model(cctc_input.states0_last_value)
                if 'bound_mRNA' in result and result['bound_mRNA']:
                    final_mRNA = result['bound_mRNA'][-1]
                else:
                    final_mRNA = None
                    logging.warning("CCTC output missing or empty 'bound_mRNA'.")
            elif unit_id == 'lnp':
                lnp_input = LNPInput(**inputs)
                result = run_lnp_model(**lnp_input.dict())
                if 'Fraction' in result and result['Fraction'] is not None:
                    final_mRNA = result['Fraction']
                else:
                    final_mRNA = None
            elif unit_id == 'lyo':
                lyo_input = LyoInput(**inputs)
                result = run_lyo_model(**lyo_input.dict())
                final_mRNA = None
            else:
                error_msg = f"Unknown unit ID: {unit_id}"
                logging.error(error_msg)
                return {"error": error_msg}

            # Store and update results:
            simulation_storage[unit.uniqueId] = result
            chain_results.append({
                "unitId": unit_id,
                "uniqueId": unit.uniqueId,
                "result": result
            })
            if final_mRNA is not None:
                last_output['final_mRNA'] = final_mRNA

        logging.info("Chain simulation completed successfully.")
        
        # === NEW CODE TO STORE THE RUN ===
        chain_results_response = {"chainResults": chain_results}
        run_id = str(uuid.uuid4())
        timestamp_str = datetime.utcnow().isoformat()
        store_run_in_db(
            run_id=run_id,
            timestamp_str=timestamp_str,
            chain_request=chain_request.dict(),  # You might use model_dump() if using Pydantic V2+
            chain_results=chain_results_response
        )
        chain_results_response["runId"] = run_id
        # ====================================
        
        
        return {"chainResults": chain_results}

    except Exception as e:
        logging.error(f"Chain simulation failed: {e}")
        return {"error": str(e)}

#############################################################################
# ENDPOINT TO RETRIEVE RESULTS BY UNIQUE ID
#############################################################################
# @app.get("/get_unit_result", response_model=UnitResult)
# async def get_unit_result(uniqueId: str):
#     """s
#     Endpoint to retrieve simulation results for a specific unit by uniqueId.
#     """
#     if uniqueId in simulation_storage:
#         return {"result": simulation_storage[uniqueId]}
#     else:
#         raise HTTPException(
#             status_code=404, 
#             detail=f"Simulation result not found for uniqueId={uniqueId}."
#         )

@app.get("/get_unit_result", response_model=UnitResult)
async def get_unit_result(run_id: str, unit_uniqueId: str):
    """
    1) First try in-memory cache (for newly run sims)
    2) Then load historic run by run_id from SQLite
    3) Return only that unit’s result
    """
    # 1) In-memory
    if unit_uniqueId in simulation_storage:
        return {"result": simulation_storage[unit_uniqueId]}

    # 2) Fetch the full run from your DB
    run = get_run_from_db(run_id)
    if run is None:
        raise HTTPException(404, f"Run not found for run_id={run_id}")

    # 3) Look inside the stored JSON for the matching unit
    for u in run["chain_results"].get("chainResults", []):
        if u.get("uniqueId") == unit_uniqueId:
            return {"result": u["result"]}

    # 4) If nothing matched
    raise HTTPException(
        404,
        f"No simulation result for unit_uniqueId={unit_uniqueId} in run {run_id}"
    )


@app.get("/get_all_runs")
def get_all_runs_endpoint():
    """
    Returns a list of all simulation runs with their run_id and timestamp.
    """
    from db_storage import get_all_runs  # Import the helper function from db_storage module
    runs = get_all_runs()
    if not runs:
        raise HTTPException(status_code=404, detail="No simulation runs found.")
    return {"runs": runs}
#############################################################################
@app.get("/get_run_details")
def get_run_details(run_id: str):
    """
    Returns the full run data (chain_request + chain_results)
    for a given run_id from the database.
    """
    print(f"[BACKEND] api_get_run called with run_id={run_id!r}")
    run_data = get_run_from_db(run_id)
    print(f"[BACKEND] get_run_from_db returned: {run_data}")
    if run_data is None:
        raise HTTPException(status_code=404, detail="Run ID not found.")
    return run_data



if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", reload=True)


# # from julia_interface import run_ivt_process
# # from schemas import IVTInput
# # import logging

# # # Define the input data using the IVTInput Pydantic model
# # input_data = IVTInput(
# #     T7RNAP=1e-7,
# #     ATP=0.0032,
# #     CTP=0.0032,
# #     GTP=0.0032,
# #     UTP=0.0032,
# #     Mg=0.008,
# #     DNA=7.4,
# #     finaltime=2.0,  # Simulation time in hours
# #     Q=1.0,          # Flow rate in L/hr
# #     V=2.0           # Reactor volume in L
# # )

# # # Run the simulation
# # result = run_ivt_process(input_data)
# # logging.info(f"Simulation completed successfully. Result: {result}")
# # print(result)



# import logging
# from fastapi import FastAPI, Body
# from pydantic import BaseModel
# from fastapi.middleware.cors import CORSMiddleware
# from typing import Dict

# from julia_interface import run_ivt_process
# from matlab_interface import run_cctc_model, run_lyo_model, run_membrane_model, run_lnp_model
# from schemas import (
#     IVTInput, IVTOutput,
#     CCTCInput, CCTCOutput,
#     LyoInput, LyoOutput,
#     MembraneInput, MembraneOutput,
#     LNPInput, LNPOutput,
#     ChainUnit, ChainRequest,
#     ChainResult, ChainResponse,
#     UnitResult

# )

# # Import necessary conversion functions
# from conversions import (
#     convert_uM_to_mg_per_ml,
#     convert_mg_ml_to_g_l
# )

# # Initialize logging
# logging.basicConfig(level=logging.INFO)

# app = FastAPI()

# # Allow CORS for frontend's origin

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"], 
#     # allow_origins=["http://localhost:3000"],  # React app runs on port 3000
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )


# # default input data for IVT
# default_ivt_input = IVTInput(
#     T7RNAP=1e-7,
#     ATP=0.0032,
#     CTP=0.0032,
#     GTP=0.0032,
#     UTP=0.0032,
#     Mg=0.008,
#     DNA=7.4,
#     finaltime=2.0,
#     Q=1.0,
#     V=2.0
# )


# # default input data for CCTC
# default_cctc_input = CCTCInput(
#     states0_last_value=1.26  # Example default value (g/L)
# )

# # default input data for Lyo
# default_lyo_input = LyoInput(
#     fluidVolume=3e-6, 
#     massFractionmRNA=0.05, 
#     InitfreezingTemperature=298.15,  
#     InitprimaryDryingTemperature=228,  
#     InitsecondaryDryingTemperature=273, 
#     TempColdGasfreezing=268,  
#     TempShelfprimaryDrying=270,  
#     TempShelfsecondaryDrying=295,  
#     Pressure=10  
# )

# # Default input data for LNP (optional)
# default_lnp_input = LNPInput(
#     Residential_time=60.0,  # Example value in seconds
#     FRR=3.0,                # Example value
#     pH=5.5,                 # Example value
#     Ion=0.1,                # Example value in M
#     TF=0.0                  # Example value in ml/min
# )

# @app.post("/run_simulation", response_model=IVTOutput)
# async def run_simulation(input_data: IVTInput = Body(default_ivt_input)):
#     """
#     Endpoint to run IVT simulation using Julia.
#     """
#     logging.info("Received IVT simulation request.")
#     try:
#         result = run_ivt_process(input_data)
#         logging.info("IVT simulation completed successfully.")
#         return result
#     except Exception as e:
#         logging.error(f"IVT simulation failed: {e}")
#         return {"error": str(e)}

# @app.post("/run_cctc", response_model=CCTCOutput)
# async def run_cctc(input_data: CCTCInput = Body(default_cctc_input)):
#     """
#     Endpoint to run CCTC simulation using MATLAB.
#     """
#     logging.info("Received CCTC simulation request.")
#     try:
#         result = run_cctc_model(input_data.states0_last_value)
#         logging.info("CCTC simulation completed successfully.")
#         return result
#     except Exception as e:
#         logging.error(f"CCTC simulation failed: {e}")
#         return {"error": str(e)}


# @app.post("/run_lyo", response_model=LyoOutput)
# async def run_lyo(input_data: LyoInput = Body(default_lyo_input)):
#     """
#     Endpoint to run Lyo simulation using MATLAB.
#     """
#     logging.info("Received Lyo simulation request.")
#     try:
#         result = run_lyo_model(
#             fluidVolume=input_data.fluidVolume,
#             massFractionmRNA=input_data.massFractionmRNA,
#             InitfreezingTemperature=input_data.InitfreezingTemperature,
#             InitprimaryDryingTemperature=input_data.InitprimaryDryingTemperature,
#             InitsecondaryDryingTemperature=input_data.InitsecondaryDryingTemperature,
#             TempColdGasfreezing=input_data.TempColdGasfreezing,
#             TempShelfprimaryDrying=input_data.TempShelfprimaryDrying,
#             TempShelfsecondaryDrying=input_data.TempShelfsecondaryDrying,
#             Pressure=input_data.Pressure
#         )
#         logging.info("Lyo simulation completed successfully.")
#         return LyoOutput(**result)
#     except Exception as e:
#         logging.error(f"Lyo simulation failed: {e}")
#         return LyoOutput(error=str(e))


# # Endpoint for Membrane model
# @app.post("/run_membrane", response_model=MembraneOutput)
# async def run_membrane(input_data: MembraneInput = Body(...)):
#     logging.info("Received Membrane simulation request.")
#     try:
#         result = run_membrane_model(
#             qF=input_data.qF,
#             c0_mRNA=input_data.c0_mRNA,
#             c0_protein=input_data.c0_protein,
#             c0_ntps=input_data.c0_ntps,
#             X=input_data.X,
#             n_stages=input_data.n_stages,
#             D=input_data.D,
#             filterType=input_data.filterType
#         )
#         logging.info("Membrane simulation completed successfully.")
#         return MembraneOutput(**result)
#     except Exception as e:
#         logging.error(f"Membrane simulation failed: {e}")
#         # Return an empty result plus the error
#         return MembraneOutput(
#             time_points=[],
#             x_positions=[],
#             Cmatrix_mRNA=[],
#             Cmatrix_protein=[],
#             Cmatrix_ntps=[],
#             interpolated_times=[],
#             interpolated_indices=[],
#             td=[],
#             TFF_protein=[],
#             TFF_ntps=[],
#             TFF_mRNA=[],
#             Jcrit=0.0,
#             Xactual=0.0,
#             error=str(e)
#         )


# # Endpoint for LNP model
# @app.post("/run_lnp", response_model=LNPOutput)
# async def run_lnp(input_data: LNPInput = Body(default_lnp_input)):
#     """
#     Endpoint to run LNP simulation using MATLAB.
#     """
#     logging.info("Received LNP simulation request.")
#     try:
#         result = run_lnp_model(
#             Residential_time=input_data.Residential_time,
#             FRR=input_data.FRR,
#             pH=input_data.pH,
#             Ion=input_data.Ion,
#             TF=input_data.TF
#         )
#         logging.info("LNP simulation completed successfully.")
#         return LNPOutput(**result)
#     except Exception as e:
#         logging.error(f"LNP simulation failed: {e}")
#         return LNPOutput(error=str(e))



# # Endpoint for Running a Chain of Simulations


# # main.py

# @app.post("/run_chain", response_model=ChainResponse)
# async def run_chain(chain_request: ChainRequest):
#     """
#     Endpoint to run a chain of simulations.
#     """
#     logging.info("Received chain simulation request.")
#     chain_results = []
#     last_output = {}

#     try:
#         for idx, unit in enumerate(chain_request.chain):
#             unit_id = unit.id
#             inputs = unit.inputs.copy()  # Copy to avoid mutating the original

#             # Handle unit sequence rules: No units after LNP except Lyophilization
#             if idx > 0:
#                 prev_unit = chain_request.chain[idx - 1].id
#                 if prev_unit == 'lnp' and unit_id != 'lyo':
#                     error_msg = "Only Lyophilization can follow LNP."
#                     logging.error(error_msg)
#                     return {"error": error_msg}

#             # Handle necessary data conversions based on previous unit's output
#             if unit_id == 'membrane' and 'final_mRNA' in last_output:
#                 # IVT outputs mRNA in µM, convert to mg/mL for Membrane
#                 inputs['c0_mRNA'] = convert_uM_to_mg_per_ml(last_output['final_mRNA'], molar_mass=660000)  # Adjust molar_mass as needed
#             elif unit_id == 'cctc' and 'final_mRNA' in last_output:
#                 # Membrane outputs mRNA in mg/mL, convert to g/L for CCTC
#                 inputs['states0_last_value'] = convert_mg_ml_to_g_l(last_output['final_mRNA'])

#             # Add more conversions as necessary for other unit transitions

#             # Run the simulation based on unit_id
#             if unit_id == 'ivt':
#                 result = run_ivt_process(IVTInput(**inputs))
#                 # Extract 'final_mRNA' from 'TotalRNAo'
#                 if 'TotalRNAo' in result and result['TotalRNAo']:
#                     final_mRNA = result['TotalRNAo'][-1]
#                 else:
#                     final_mRNA = None
#                     logging.warning("IVT simulation output does not contain 'TotalRNAo' or it's empty.")
            


#             elif unit_id == 'membrane':
#                 membrane_input = MembraneInput(**inputs)
#                 result = run_membrane_model(**membrane_input.dict())
#                 # Extract 'final_mRNA' from the last element of the last sublist in 'TFF_mRNA'
#                 if (
#                     'TFF_mRNA' in result 
#                     and result['TFF_mRNA'] 
#                     and isinstance(result['TFF_mRNA'][-1], list) 
#                     and result['TFF_mRNA'][-1]
#                 ):
#                     final_mRNA = result['TFF_mRNA'][-1][-1]  # Access the last mRNA value in the last stage
#                 else:
#                     final_mRNA = None
#                     logging.warning("Membrane simulation output does not contain 'TFF_mRNA' or it's empty.")
#             elif unit_id == 'cctc':
#                 cctc_input = CCTCInput(**inputs)
#                 # result = run_cctc_model(**cctc_input.dict())
#                 result = run_cctc_model(cctc_input.states0_last_value)
#                 # result = run_cctc_model(CCTCInput(**inputs))
#                 # Extract 'final_mRNA' from 'bound_mRNA'
#                 if 'bound_mRNA' in result and result['bound_mRNA']:
#                     final_mRNA = result['bound_mRNA'][-1]
#                 else:
#                     final_mRNA = None
#                     logging.warning("CCTC simulation output does not contain 'bound_mRNA' or it's empty.")
#             elif unit_id == 'lnp':
#                 lnp_input = LNPInput(**inputs)
#                 result = run_lnp_model(**lnp_input.dict())
#                 final_mRNA = None  # LNP does not output mRNA needed by next units
#             elif unit_id == 'lyo':
#                 lyo_input = LyoInput(**inputs)
#                 result = run_lyo_model(**lyo_input.dict())
#                 final_mRNA = None  # Lyophilization does not output mRNA needed by next units
#             else:
#                 error_msg = f"Unknown unit ID: {unit_id}"
#                 logging.error(error_msg)
#                 return {"error": error_msg}

#             # Collect the results
#             chain_results.append({
#                 "unitId": unit_id,
#                 "uniqueId": unit.uniqueId,
#                 "result": result  # Assuming result is a dict
#             })

#             # Update last_output if necessary
#             if final_mRNA is not None:
#                 last_output['final_mRNA'] = final_mRNA

#         logging.info("Chain simulation completed successfully.")
#         return {"chainResults": chain_results}

#     except Exception as e:
#         logging.error(f"Chain simulation failed: {e}")
#         return {"error": str(e)}


# # In-memory storage for simulation results
# simulation_storage: Dict[str, dict] = {}
# @app.get("/get_unit_result", response_model=UnitResult)
# async def get_unit_result(uniqueId: str):
#     """
#     Endpoint to retrieve simulation results for a specific unit by uniqueId.
#     """
#     if uniqueId in simulation_storage:
#         return {"result": simulation_storage[uniqueId]}
#     else:
#         raise HTTPException(status_code=404, detail="Simulation result not found for the given uniqueId.")





# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run("main:app", reload=True)




