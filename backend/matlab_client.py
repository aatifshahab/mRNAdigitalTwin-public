"""
HTTP client for the MATLAB models.

Used when the backend runs inside Docker. Each function mirrors the signature and
return shape of its counterpart in ``matlab_interface.py`` but, instead of calling
the in-process MATLAB engine, it POSTs the arguments to the host "matlab-bridge"
and returns the JSON result. This makes the swap transparent to ``main.py``.

Configure the bridge location with the MATLAB_BRIDGE_URL environment variable
(default: http://host.docker.internal:8001, which from a Linux container resolves
to the Docker host where the bridge runs natively against your licensed MATLAB).
"""

import os
import logging

import requests

BRIDGE_URL = os.getenv("MATLAB_BRIDGE_URL", "http://host.docker.internal:8001").rstrip("/")

# MATLAB cold-starts and long simulations can take a while; keep a generous timeout.
REQUEST_TIMEOUT = float(os.getenv("MATLAB_BRIDGE_TIMEOUT", "600"))


def _post(endpoint: str, payload: dict) -> dict:
    url = f"{BRIDGE_URL}/{endpoint}"
    logging.info("[matlab_client] POST %s", url)
    try:
        resp = requests.post(url, json=payload, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.ConnectionError as e:
        raise RuntimeError(
            f"Could not reach the MATLAB bridge at {BRIDGE_URL}. "
            f"Make sure setup-matlab-bridge.ps1 is running on the host. ({e})"
        )
    if resp.status_code != 200:
        raise RuntimeError(
            f"MATLAB bridge returned {resp.status_code} for /{endpoint}: {resp.text}"
        )
    return resp.json()


def run_cctc_model(states0_last_value, **overrides):
    return _post("run_cctc_model", {
        "states0_last_value": states0_last_value,
        "overrides": overrides,
    })


def run_lyo_model(fluidVolume, massFractionSolids, InitfreezingTemperature,
                  InitprimaryDryingTemperature, InitsecondaryDryingTemperature,
                  TempColdGasfreezing, TempShelfprimaryDrying,
                  TempShelfsecondaryDrying, Pressure):
    return _post("run_lyo_model", {
        "fluidVolume": fluidVolume,
        "massFractionSolids": massFractionSolids,
        "InitfreezingTemperature": InitfreezingTemperature,
        "InitprimaryDryingTemperature": InitprimaryDryingTemperature,
        "InitsecondaryDryingTemperature": InitsecondaryDryingTemperature,
        "TempColdGasfreezing": TempColdGasfreezing,
        "TempShelfprimaryDrying": TempShelfprimaryDrying,
        "TempShelfsecondaryDrying": TempShelfsecondaryDrying,
        "Pressure": Pressure,
    })


def run_membrane_model(qF, c0_mRNA, c0_protein, c0_ntps, X, n_stages, D, filterType, **overrides):
    return _post("run_membrane_model", {
        "qF": qF,
        "c0_mRNA": c0_mRNA,
        "c0_protein": c0_protein,
        "c0_ntps": c0_ntps,
        "X": X,
        "n_stages": n_stages,
        "D": D,
        "filterType": filterType,
        "overrides": overrides,
    })


def run_lnp_model(Residential_time, FRR, pH, Ion, TF, C_lipid, mRNA_in):
    return _post("run_lnp_model", {
        "Residential_time": Residential_time,
        "FRR": FRR,
        "pH": pH,
        "Ion": Ion,
        "TF": TF,
        "C_lipid": C_lipid,
        "mRNA_in": mRNA_in,
    })
