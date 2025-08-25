import logging
from fastapi import FastAPI, Body, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict
from fastapi import HTTPException

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
                # Fallbacks for standalone CCTC runs (no 'final_mRNA' in last_output)
                if 'states0_last_value' not in inputs:
                    if 'mRNA' in inputs:               # assume g/L (== mg/mL)
                        inputs['states0_last_value'] = inputs['mRNA']
                    elif 'c0_mRNA' in inputs:          # also g/L (== mg/mL)
                        inputs['states0_last_value'] = inputs['c0_mRNA']
                    else:
                        
                        raise HTTPException(
                            status_code=400,
                            detail="CCTC requires 'states0_last_value' (g/L) when not chained after IVT/Membrane/CCTC."
                        )

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

    # 2) Fetch the full run from DB
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


#############################################################################
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", reload=True)
#############################################################################