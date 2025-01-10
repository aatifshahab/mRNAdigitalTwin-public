import matlab.engine
import numpy as np
import logging
import os

# Initialize the MATLAB engine at module load time
eng = None

def get_matlab_engine():
    global eng
    if eng is None:
        try:
            eng = matlab.engine.start_matlab()
            # Navigate to the backend directory
            backend_dir = r'C:\Users\moha0095\ivtappNew1\backend'  # Update this path as needed
            eng.cd(backend_dir, nargout=0)

            # Add the Lyo folder to MATLAB's path
            lyo_folder = os.path.join(backend_dir, 'Lyo')
            eng.addpath(lyo_folder, nargout=0)

            # Add the membrane folder to MATLAB's path
            membrane_folder = os.path.join(backend_dir, 'membrane')
            eng.addpath(membrane_folder, nargout=0)

            # Add the LNP folder to MATLAB's path
            lnp_folder = os.path.join(backend_dir, 'LNP')
            eng.addpath(lnp_folder, nargout=0)

            logging.info(f"MATLAB engine started. Path set to: {lyo_folder}, {membrane_folder}, and {lnp_folder}")
        except Exception as e:
            logging.error(f"Failed to start MATLAB engine: {e}")
            raise RuntimeError(f"Failed to start MATLAB engine: {e}")
    return eng


# CCTC model call
def run_cctc_model(states0_last_value):
    try:
        # Get the MATLAB engine instance
        eng = get_matlab_engine()

        # Convert the input to MATLAB data type
        states0_last_value_matlab = matlab.double([float(states0_last_value)])
        logging.info(f"Calling MATLAB function 'run_cctc_model' with input: {states0_last_value}")
        
        # Call the MATLAB function
        tSol, unbound_mRNA = eng.run_cctc_model(states0_last_value_matlab, nargout=2)
        logging.info(f"Received unbound_mRNA from MATLAB: {unbound_mRNA}")
        logging.info(f"Received time data from MATLAB: {tSol}")
       
        # Convert the output to a NumPy array
        time = np.array(tSol).flatten().tolist()
        unbound_mRNA = np.array(unbound_mRNA).flatten()
      

         # Calculate bound mRNA by subtracting unbound mRNA from the initial mRNA value
        bound_mRNA = [states0_last_value - u for u in unbound_mRNA]

        logging.info(f"Calculated bound_mRNA: {bound_mRNA}")

        return {
            "time": time,
            "unbound_mRNA": unbound_mRNA.tolist(),
            "bound_mRNA": bound_mRNA
        }
    
    
    except Exception as e:
        logging.error(f"Error in running MATLAB function: {e}")
        raise RuntimeError(f"Error in running MATLAB function: {e}")



# Lyo model call
def run_lyo_model(fluidVolume, massFractionmRNA, InitfreezingTemperature, 
                 InitprimaryDryingTemperature, InitsecondaryDryingTemperature, 
                 TempColdGasfreezing, TempShelfprimaryDrying, 
                 TempShelfsecondaryDrying, Pressure):
    """
    Runs the Lyo simulation by calling the MATLAB LyoAppInterface function.

    Parameters:
    - fluidVolume (float): Volume of the fluid (m3).
    - massFractionmRNA (float): Mass fraction of mRNA (kg/kg).
    - InitfreezingTemperature (float): Initial freezing temperature (K).
    - InitprimaryDryingTemperature (float): Initial primary drying temperature (K).
    - InitsecondaryDryingTemperature (float): Initial secondary drying temperature (K).
    - TempColdGasfreezing (float): Temperature of cold gas during freezing (K).
    - TempShelfprimaryDrying (float): Temperature of the shelf during primary drying (K).
    - TempShelfsecondaryDrying (float): Temperature of the shelf during secondary drying (K).
    - Pressure (float): Pressure in kPa.

    Returns:
    dict: Dictionary containing simulation results.
    """
    try:
        # Get the MATLAB engine instance
        eng = get_matlab_engine()

        logging.info("Preparing inputs for MATLAB LyoAppInterface function.")

        # Convert inputs to MATLAB data types (floats)
        fluidVolume_matlab = float(fluidVolume)
        massFractionmRNA_matlab = float(massFractionmRNA)
        InitfreezingTemperature_matlab = float(InitfreezingTemperature)
        InitprimaryDryingTemperature_matlab = float(InitprimaryDryingTemperature)
        InitsecondaryDryingTemperature_matlab = float(InitsecondaryDryingTemperature)
        TempColdGasfreezing_matlab = float(TempColdGasfreezing)
        TempShelfprimaryDrying_matlab = float(TempShelfprimaryDrying)
        TempShelfsecondaryDrying_matlab = float(TempShelfsecondaryDrying)
        Pressure_matlab = float(Pressure)

        # Log input values
        logging.info(f"Inputs to LyoAppInterface: fluidVolume={fluidVolume_matlab}, "
                     f"massFractionmRNA={massFractionmRNA_matlab}, "
                     f"InitfreezingTemperature={InitfreezingTemperature_matlab}, "
                     f"InitprimaryDryingTemperature={InitprimaryDryingTemperature_matlab}, "
                     f"InitsecondaryDryingTemperature={InitsecondaryDryingTemperature_matlab}, "
                     f"TempColdGasfreezing={TempColdGasfreezing_matlab}, "
                     f"TempShelfprimaryDrying={TempShelfprimaryDrying_matlab}, "
                     f"TempShelfsecondaryDrying={TempShelfsecondaryDrying_matlab}, "
                     f"Pressure={Pressure_matlab}")

        # Call the MATLAB function
        outputs = eng.LyoAppInterface(fluidVolume_matlab, massFractionmRNA_matlab, 
                                      InitfreezingTemperature_matlab, 
                                      InitprimaryDryingTemperature_matlab, 
                                      InitsecondaryDryingTemperature_matlab, 
                                      TempColdGasfreezing_matlab, 
                                      TempShelfprimaryDrying_matlab, 
                                      TempShelfsecondaryDrying_matlab, 
                                      Pressure_matlab, nargout=9)

        # Unpack the outputs
        (time1, time2, time3, time, massOfIce, boundWater, 
         productTemperature, operatingPressure, operatingTemperature) = outputs

        logging.info("Received outputs from MATLAB LyoAppInterface function.")

        # Convert MATLAB arrays to Python lists
        time1 = np.array(time1).flatten().tolist()
        time2 = np.array(time2).flatten().tolist()
        time3 = np.array(time3).flatten().tolist()
        time = np.array(time).flatten().tolist()
        massOfIce = np.array(massOfIce).flatten().tolist()
        boundWater = np.array(boundWater).flatten().tolist()
        productTemperature = np.array(productTemperature).flatten().tolist()
        operatingPressure = np.array(operatingPressure).flatten().tolist()
        operatingTemperature = np.array(operatingTemperature).flatten().tolist()

        logging.info("Converted MATLAB outputs to Python data types.")

        return {
            "time1": time1,
            "time2": time2,
            "time3": time3,
            "time": time,
            "massOfIce": massOfIce,
            "boundWater": boundWater,
            "productTemperature": productTemperature,
            "operatingPressure": operatingPressure,
            "operatingTemperature": operatingTemperature
        }

    except Exception as e:
        logging.error(f"Error in running MATLAB LyoAppInterface function: {e}")
        raise RuntimeError(f"Error in running MATLAB LyoAppInterface function: {e}")



# Membrane model call
def run_membrane_model(qF, c0_mRNA, c0_protein, c0_ntps, X, n_stages, D, filterType):
    try:
        eng_instance = get_matlab_engine()

        # Convert Python values to MATLAB data types
        qF_matlab         = float(qF)
        c0_matlab         = matlab.double([float(c0_mRNA), float(c0_protein), float(c0_ntps)])
        c0_matlab         = eng_instance.transpose(c0_matlab)  # 3×1 column vector
        X_matlab          = float(X)
        n_stages_matlab   = float(n_stages)
        D_matlab          = float(D)
        filterType_matlab = str(filterType)

        # The  membraneAPI.m  has 12 outputs:
        #   1) time_points
        #   2) x_positions
        #   3) Cmatrix_mRNA
        #   4) Cmatrix_protein
        #   5) Cmatrix_ntps
        #   6) interpolated_times
        #   7) interpolated_indices
        #   8) td
        #   9) TFF_protein
        #  10) TFF_ntps
        #  11) Jcrit
        #  12) Xactual
        outputs = eng_instance.membraneAPI(
            qF_matlab,
            c0_matlab,
            X_matlab,
            n_stages_matlab,
            D_matlab,
            filterType_matlab,
            nargout=12
        )

        # Extract each
        time_points_mat         = outputs[0]
        x_positions_mat         = outputs[1]
        Cmatrix_mRNA_mat        = outputs[2]
        Cmatrix_protein_mat     = outputs[3]
        Cmatrix_ntps_mat        = outputs[4]
        interpolated_times_mat  = outputs[5]
        interpolated_indices_mat= outputs[6]
        td_mat                  = outputs[7]
        TFF_protein_mat         = outputs[8]
        TFF_ntps_mat            = outputs[9]
        Jcrit_val               = float(outputs[10])
        Xactual_val             = float(outputs[11])

        # Convert to Python
        time_points_py         = np.array(time_points_mat).flatten().tolist()
        x_positions_py         = np.array(x_positions_mat).flatten().tolist()

        Cmatrix_mRNA_py        = np.array(Cmatrix_mRNA_mat).tolist()   # 2D
        Cmatrix_protein_py     = np.array(Cmatrix_protein_mat).tolist()# 2D
        Cmatrix_ntps_py        = np.array(Cmatrix_ntps_mat).tolist()   # 2D

        interpolated_times_py  = np.array(interpolated_times_mat).flatten().tolist()
        interpolated_indices_py= np.array(interpolated_indices_mat).astype(int).flatten().tolist()

        td_py                  = np.array(td_mat).flatten().tolist()

        # TFF_protein_mat and TFF_ntps_mat are cell arrays of dimension 1×n_stages
        # Each cell is a column vector of that stage's data.
        # Convert each stage to a Python list
        TFF_protein_py = []
        for cell_array in TFF_protein_mat:
            arr = np.array(cell_array).flatten().tolist()
            TFF_protein_py.append(arr)

        TFF_ntps_py = []
        for cell_array in TFF_ntps_mat:
            arr = np.array(cell_array).flatten().tolist()
            TFF_ntps_py.append(arr)

        result = {
            "time_points": time_points_py,
            "x_positions": x_positions_py,
            "Cmatrix_mRNA": Cmatrix_mRNA_py,
            "Cmatrix_protein": Cmatrix_protein_py,
            "Cmatrix_ntps": Cmatrix_ntps_py,
            "interpolated_times": interpolated_times_py,
            "interpolated_indices": interpolated_indices_py,
            "td": td_py,
            "TFF_protein": TFF_protein_py,
            "TFF_ntps": TFF_ntps_py,
            "Jcrit": Jcrit_val,
            "Xactual": Xactual_val
        }

        return result

    except Exception as e:
        logging.error(f"Error in run_membrane_model: {e}")
        raise RuntimeError(f"Error in run_membrane_model: {e}")



# LNP model call

def run_lnp_model(Residential_time, FRR, pH, Ion, TF):
    try:
        # Get the MATLAB engine instance
        eng = get_matlab_engine()

        logging.info(f"Running LNP model with Residential_time={Residential_time}, FRR={FRR}, pH={pH}, Ion={Ion}, TF={TF}")

        # Convert inputs to MATLAB data types
        Residential_time_matlab = float(Residential_time)
        FRR_matlab = float(FRR)
        pH_matlab = float(pH)
        Ion_matlab = float(Ion)
        TF_matlab = float(TF)

        # Call the MATLAB LNP function
       
        Diameter, PSD = eng.LNP(Residential_time_matlab, FRR_matlab, pH_matlab, Ion_matlab, TF_matlab, nargout=2)

        logging.info("Received outputs from MATLAB LNP function.")

        # Convert MATLAB outputs to Python lists
        Diameter_py = np.array(Diameter).tolist()  # Assuming Diameter is a 2D array
        PSD_py = np.array(PSD).tolist()            # Assuming PSD is a 2D array

        return {
            "Diameter": Diameter_py,
            "PSD": PSD_py
        }

    except Exception as e:
        logging.error(f"Error in running MATLAB LNP function: {e}")
        raise RuntimeError(f"Error in running MATLAB LNP function: {e}")
