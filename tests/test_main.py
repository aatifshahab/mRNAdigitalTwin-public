import sys
import os
import asyncio
from unittest.mock import MagicMock, patch
import unittest

# --- Add the project root and backend folder to sys.path ---
current_dir = os.path.dirname(os.path.realpath(__file__))
parent_dir = os.path.join(current_dir, "..")
backend_dir = os.path.join(parent_dir, "backend")
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

# --- Patch missing modules (matlab and julia) before importing production code ---
if 'matlab' not in sys.modules:
    sys.modules['matlab'] = MagicMock()
if 'matlab.engine' not in sys.modules:
    sys.modules['matlab.engine'] = MagicMock()
if 'julia' not in sys.modules:
    sys.modules['julia'] = MagicMock()

import logging
from main import app, run_chain
from schemas import ChainRequest, ChainUnit

# --- Define complete dummy inputs for each unit ---
REAL_IVT_INPUT = {
    "T7RNAP": 1e-7,
    "ATP": 0.0032,
    "CTP": 0.0032,
    "GTP": 0.0032,
    "UTP": 0.0032,
    "Mg": 0.008,
    "DNA": 7.4,
    "finaltime": 2.0,
    "Q": 1.0,  # Flow rate in L/hr
    "V": 2.0,  # Reactor volume in L
    "saveat_step": 0.1  # Optional
}

REAL_MEMBRANE_INPUT = {
    "qF": 1.0,
    "c0_mRNA": 1.0,    # Dummy value; may be overwritten by chain logic
    "c0_protein": 0.5,
    "c0_ntps": 0.5,
    "X": 0.9,
    "n_stages": 3,
    "D": 4,
    "filterType": "VIBRO"
}

REAL_CCTC_INPUT = {
    "states0_last_value": 1.0
}

REAL_LNP_INPUT = {
    "Residential_time": 60.0,
    "FRR": 3.0,
    "pH": 5.5,
    "Ion": 0.1,
    "TF": 5.0,
    "mRNA_in": 10.0,   # Will be replaced by chain logic if needed
    "C_lipid": 10.0
}

REAL_LYO_INPUT = {
    "fluidVolume": 3e-6,
    "massFractionmRNA": 0.05,
    "InitfreezingTemperature": 298.15,
    "InitprimaryDryingTemperature": 228,
    "InitsecondaryDryingTemperature": 273,
    "TempColdGasfreezing": 268,
    "TempShelfprimaryDrying": 270,
    "TempShelfsecondaryDrying": 295,
    "Pressure": 10.0
}

class TestMainChain(unittest.TestCase):

    @patch('main.run_ivt_process', return_value={"TotalRNAo": [10.0]})
    @patch('main.run_membrane_model', return_value={"TFF_mRNA": [[3.0]]})  # Changed nesting here
    @patch('main.run_cctc_model', return_value={"bound_mRNA": [[1.5]]})
    @patch('main.run_lnp_model', return_value={"Fraction": 0.8})
    @patch('main.run_lyo_model', return_value={"lyo_output": "Finished"})
    def test_full_chain(self, mock_lyo, mock_lnp, mock_cctc, mock_membrane, mock_ivt):
        """
        Test a full chain: IVT → Membrane → CCTC → LNP → LYO.
        Verify that each unit is called and that the final chain result has the expected keys.
        """
        # Build the chain request with complete inputs.
        chain_units = [
            ChainUnit(id="ivt", uniqueId="unit_ivt", inputs=REAL_IVT_INPUT),
            ChainUnit(id="membrane", uniqueId="unit_membrane", inputs=REAL_MEMBRANE_INPUT),
            ChainUnit(id="cctc", uniqueId="unit_cctc", inputs=REAL_CCTC_INPUT),
            ChainUnit(id="lnp", uniqueId="unit_lnp", inputs=REAL_LNP_INPUT),
            ChainUnit(id="lyo", uniqueId="unit_lyo", inputs=REAL_LYO_INPUT),
        ]
        request = ChainRequest(chain=chain_units)

        # Await the asynchronous chain simulation.
        result = asyncio.run(run_chain(request))
        self.assertIn("chainResults", result)
        self.assertEqual(len(result["chainResults"]), 5, "Chain should have 5 units")

        # Verify that each unit's result contains the expected key.
        for item in result["chainResults"]:
            if item["unitId"] == "ivt":
                self.assertIn("TotalRNAo", item["result"])
            elif item["unitId"] == "membrane":
                self.assertIn("TFF_mRNA", item["result"])
            elif item["unitId"] == "cctc":
                self.assertIn("bound_mRNA", item["result"])
            elif item["unitId"] == "lnp":
                self.assertIn("Fraction", item["result"])
            elif item["unitId"] == "lyo":
                self.assertIn("lyo_output", item["result"])

    @patch('main.run_cctc_model', return_value={"bound_mRNA": [[2.0]]})
    def test_single_unit_cctc(self, mock_cctc):
        """
        Test running a single unit: CCTC.
        """
        chain_units = [
            ChainUnit(id="cctc", uniqueId="unit_cctc", inputs=REAL_CCTC_INPUT)
        ]
        request = ChainRequest(chain=chain_units)
        result = asyncio.run(run_chain(request))
        mock_cctc.assert_called_once()
        self.assertIn("chainResults", result)
        self.assertEqual(len(result["chainResults"]), 1)
        self.assertEqual(result["chainResults"][0]["unitId"], "cctc")
        self.assertIn("bound_mRNA", result["chainResults"][0]["result"])

if __name__ == '__main__':
    unittest.main()
