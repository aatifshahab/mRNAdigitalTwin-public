"""
MATLAB bridge — runs NATIVELY on the host (not in Docker).

This is a thin FastAPI service that exposes the four MATLAB models over HTTP so
the containerized backend can call them. It simply re-uses the existing
in-process functions in ``matlab_interface.py`` (which start the MATLAB engine
and add the cctc/Lyo/membrane/LNP folders to the MATLAB path).

Run it from the ``backend`` directory inside a Python environment that has the
MATLAB Engine for Python installed (setup-matlab-bridge.ps1 does this for you):

    uvicorn matlab_bridge:app --host 0.0.0.0 --port 8001

The container reaches it at http://host.docker.internal:8001 (see matlab_client.py).
"""

import logging

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Optional

from matlab_interface import (
    run_cctc_model,
    run_lyo_model,
    run_membrane_model,
    run_lnp_model,
)

logging.basicConfig(level=logging.INFO)

app = FastAPI(title="mRNA Digital Twin — MATLAB bridge")


@app.get("/health")
def health():
    return {"status": "ok"}


# --- request models (mirror matlab_interface signatures) ---------------------

class CCTCRequest(BaseModel):
    states0_last_value: float
    overrides: Dict[str, float] = {}


class LyoRequest(BaseModel):
    fluidVolume: float
    massFractionSolids: float
    InitfreezingTemperature: float
    InitprimaryDryingTemperature: float
    InitsecondaryDryingTemperature: float
    TempColdGasfreezing: float
    TempShelfprimaryDrying: float
    TempShelfsecondaryDrying: float
    Pressure: float


class MembraneRequest(BaseModel):
    qF: float
    c0_mRNA: float
    c0_protein: float
    c0_ntps: float
    X: float
    n_stages: float
    D: float
    filterType: str
    overrides: Dict[str, float] = {}


class LNPRequest(BaseModel):
    Residential_time: float
    FRR: float
    pH: float
    Ion: float
    TF: float
    C_lipid: float
    mRNA_in: float


# --- endpoints ---------------------------------------------------------------

@app.post("/run_cctc_model")
def cctc(req: CCTCRequest):
    try:
        return run_cctc_model(req.states0_last_value, **req.overrides)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/run_lyo_model")
def lyo(req: LyoRequest):
    try:
        return run_lyo_model(
            req.fluidVolume, req.massFractionSolids, req.InitfreezingTemperature,
            req.InitprimaryDryingTemperature, req.InitsecondaryDryingTemperature,
            req.TempColdGasfreezing, req.TempShelfprimaryDrying,
            req.TempShelfsecondaryDrying, req.Pressure,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/run_membrane_model")
def membrane(req: MembraneRequest):
    try:
        return run_membrane_model(
            req.qF, req.c0_mRNA, req.c0_protein, req.c0_ntps, req.X,
            req.n_stages, req.D, req.filterType, **req.overrides,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/run_lnp_model")
def lnp(req: LNPRequest):
    try:
        return run_lnp_model(
            req.Residential_time, req.FRR, req.pH, req.Ion, req.TF,
            req.C_lipid, req.mRNA_in,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
