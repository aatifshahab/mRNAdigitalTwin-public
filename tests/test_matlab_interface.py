# tests/test_matlab_interface.py

import sys
import os
# Add the parent directory to the Python path so that "backend" can be imported
current_dir = os.path.dirname(os.path.realpath(__file__))
parent_dir = os.path.join(current_dir, "..")
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from unittest.mock import patch, MagicMock
import unittest
import numpy as np

# Patch the matlab module if it's not installed.
if 'matlab' not in sys.modules:
    from unittest.mock import MagicMock
    sys.modules['matlab'] = MagicMock()
    sys.modules['matlab.engine'] = MagicMock()

# Now import your functions from the backend module.
from backend.matlab_interface import (
    run_cctc_model, run_lyo_model, run_membrane_model, run_lnp_model, get_matlab_engine
)

class TestMatlabInterface(unittest.TestCase):

    @patch('backend.matlab_interface.get_matlab_engine')
    def test_run_cctc_model(self, mock_get_engine):
        """Test run_cctc_model with a mock MATLAB engine."""
        mock_eng = MagicMock()
        mock_get_engine.return_value = mock_eng
        
        # Simulate MATLAB function return values:
        mock_tSol = [[0], [3600], [7200]]        # Time points (seconds)
        mock_unbound = [[1.0], [0.8], [0.5]]       # Unbound mRNA values
        mock_eng.run_cctc_model.return_value = (mock_tSol, mock_unbound)
        
        result = run_cctc_model(states0_last_value=1.26)
        
        # Verify that the returned dictionary has keys: time, unbound_mRNA, bound_mRNA.
        self.assertIn('time', result)
        self.assertIn('unbound_mRNA', result)
        self.assertIn('bound_mRNA', result)
        
        # Check that the bound mRNA is calculated correctly: bound = initial - unbound.
        self.assertAlmostEqual(result['bound_mRNA'][0], 1.26 - 1.0, places=3)
        self.assertAlmostEqual(result['bound_mRNA'][1], 1.26 - 0.8, places=3)
        self.assertAlmostEqual(result['bound_mRNA'][2], 1.26 - 0.5, places=3)
        
        mock_eng.run_cctc_model.assert_called_once()

    @patch('backend.matlab_interface.get_matlab_engine')
    def test_run_lyo_model(self, mock_get_engine):
        """Test run_lyo_model with a mock MATLAB engine."""
        mock_eng = MagicMock()
        mock_get_engine.return_value = mock_eng

        # Simulate MATLAB function outputs (9 outputs)
        mock_outputs = (
            [[0, 10, 20]],  # time1
            [[0, 10, 20]],  # time2
            [[0, 10, 20]],  # time3
            [[0, 10, 20]],  # time
            [[0, 1, 2]],    # massOfIce
            [[0.1, 0.2, 0.3]],  # boundWater
            [[25, 30, 35]], # productTemperature
            [[1, 1, 1]],    # operatingPressure
            [[-20, -15, -10]]  # operatingTemperature
        )
        mock_eng.LyoAppInterface.return_value = mock_outputs
        
        result = run_lyo_model(
            fluidVolume=3e-6,
            massFractionmRNA=0.05,
            InitfreezingTemperature=298.15,
            InitprimaryDryingTemperature=228,
            InitsecondaryDryingTemperature=273,
            TempColdGasfreezing=268,
            TempShelfprimaryDrying=270,
            TempShelfsecondaryDrying=295,
            Pressure=10
        )
        self.assertIn('time1', result)
        self.assertIn('massOfIce', result)
        self.assertEqual(len(result['time']), 3)

    @patch('backend.matlab_interface.get_matlab_engine')
    def test_run_membrane_model(self, mock_get_engine):
        """Test run_membrane_model with a mock MATLAB engine."""
        mock_eng = MagicMock()
        mock_get_engine.return_value = mock_eng

        # Fake minimal data for membraneAPI output (13 outputs)
        mock_outputs = (
            [[0, 10, 20]],   # time_points
            [[0, 1]],        # x_positions
            [[0.5, 0.4]],    # Cmatrix_mRNA
            [[0.2, 0.1]],    # Cmatrix_protein
            [[0.3, 0.2]],    # Cmatrix_ntps
            [[0, 5, 10]],    # interpolated_times
            [[1, 2]],        # interpolated_indices
            [[0, 30, 60]],   # td
            [['dummy_protein']],  # TFF_protein
            [['dummy_ntps']],     # TFF_ntps
            12.34,           # Jcrit
            0.9,             # Xactual
            [['dummy_mRNA']]  # TFF_mRNA
        )
        mock_eng.membraneAPI.return_value = mock_outputs
        
        result = run_membrane_model(
            qF=1.0, c0_mRNA=1.0, c0_protein=0.5, c0_ntps=0.5, 
            X=0.9, n_stages=3, D=4, filterType='VIBRO'
        )
        self.assertIn('time_points', result)
        self.assertIn('TFF_protein', result)
        self.assertEqual(result['Jcrit'], 12.34)
        self.assertEqual(result['Xactual'], 0.9)

    @patch('backend.matlab_interface.get_matlab_engine')
    def test_run_lnp_model(self, mock_get_engine):
        """Test run_lnp_model with a mock MATLAB engine."""
        mock_eng = MagicMock()
        mock_get_engine.return_value = mock_eng

        # Simulate eng.Main return values: (Diameter, PSD, EE, mRNA_out, Fraction)
        mock_Diameter = [[100], [120]]
        mock_PSD = [[0.1], [0.3]]
        mock_EE = 0.75
        mock_mRNA_out = 5.0
        mock_Fraction = 0.2
        mock_eng.Main.return_value = (mock_Diameter, mock_PSD, mock_EE, mock_mRNA_out, mock_Fraction)

        result = run_lnp_model(
            Residential_time=60,
            FRR=3,
            pH=5.5,
            Ion=0.1,
            TF=5,
            C_lipid=10,
            mRNA_in=10
        )
        self.assertIn('Diameter', result)
        self.assertIn('PSD', result)
        self.assertIn('Fraction', result)
        self.assertAlmostEqual(result['Fraction'], 0.2)

if __name__ == '__main__':
    unittest.main()
