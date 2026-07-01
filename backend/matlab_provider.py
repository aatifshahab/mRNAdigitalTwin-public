"""
MATLAB provider selector.

The backend can reach the MATLAB models in two different ways:

1. In-process engine (native install): import the functions directly from
   ``matlab_interface``. This requires a licensed MATLAB and the MATLAB Engine
   for Python installed in the same interpreter. This is the default and keeps
   the original local-dev workflow unchanged.

2. HTTP bridge (Docker): the backend runs in a Linux container that cannot launch
   the host's MATLAB, so it calls a small FastAPI "matlab-bridge" running natively
   on the host (see matlab_bridge.py / matlab_client.py).

Selection is controlled by the ``USE_MATLAB_BRIDGE`` environment variable so that
no application code has to change between the two modes. ``main.py`` and the
sensitivity scripts import the model functions from *this* module.
"""

import os
import logging

_USE_BRIDGE = os.getenv("USE_MATLAB_BRIDGE", "0").strip().lower() in ("1", "true", "yes")

if _USE_BRIDGE:
    logging.info("[matlab_provider] Using HTTP MATLAB bridge (matlab_client).")
    from matlab_client import (
        run_cctc_model,
        run_lyo_model,
        run_membrane_model,
        run_lnp_model,
    )
else:
    logging.info("[matlab_provider] Using in-process MATLAB engine (matlab_interface).")
    from matlab_interface import (
        run_cctc_model,
        run_lyo_model,
        run_membrane_model,
        run_lnp_model,
    )

__all__ = [
    "run_cctc_model",
    "run_lyo_model",
    "run_membrane_model",
    "run_lnp_model",
]
