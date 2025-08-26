import matlab.engine
import numpy as np
import logging
import os
from pathlib import Path



from pathlib import Path
import logging
import matlab.engine

eng = None

def _find_backend_dir() -> Path:
   
    here = Path(__file__).resolve()
    # If this file lives inside backend/, use that folder
    if here.parent.name.lower() == "backend":
        return here.parent
    # Otherwise, search upward for a folder literally named 'backend'
    for p in here.parents:
        if p.name.lower() == "backend":
            return p
        cand = p / "backend"
        if cand.is_dir():
            return cand
    # Fallback: current working directory
    return Path.cwd()

def get_matlab_engine():
    global eng
    if eng is None:
        try:
            eng = matlab.engine.start_matlab()

            backend_dir = _find_backend_dir()
            eng.cd(str(backend_dir), nargout=0)

            # Add MATLAB paths (recursively) for required modules
            for sub in ("cctc", "Lyo", "membrane", "LNP"):
                folder = backend_dir / sub
                if folder.is_dir():
                    eng.addpath(eng.genpath(str(folder)), nargout=0)
                else:
                    logging.warning(f"[MATLAB] Missing folder: {folder}")

            logging.info(f"[MATLAB] Engine started. Backend: {backend_dir}")
        except Exception as e:
            logging.error(f"Failed to start MATLAB engine: {e}")
            raise RuntimeError(f"Failed to start MATLAB engine: {e}")
    return eng


# CCTC model call
def run_cctc_model(states0_last_value):
    try:
        # Get the MATLAB engine instance
        eng = get_matlab_engine()

        cwd = eng.pwd(nargout=1)
        logging.info(f"[MATLAB] Current working directory: {cwd}")

        location = eng.which('run_cctc_model', nargout=1)
        if location:
            logging.info(f"[MATLAB] Found run_cctc_model at: {location}")
        else:
            logging.warning("[MATLAB] run_cctc_model not found in MATLAB path!")

        # Convert the input to MATLAB data type
        states0_last_value_matlab = matlab.double([float(states0_last_value)])
        logging.info(f"Calling MATLAB function 'run_cctc_model' with input: {states0_last_value}")
        

        # Call the MATLAB function
        tSol, unbound_mRNA, bound_mRNA = eng.run_cctc_model(states0_last_value_matlab, nargout=3)
        logging.info(f"Received unbound_mRNA from MATLAB: {unbound_mRNA}")
        logging.info(f"Received bound_mRNA from MATLAB: {bound_mRNA}")
        logging.info(f"Received time data from MATLAB: {tSol}")
       
        # Convert the output to a NumPy array
        time = np.array(tSol).flatten().tolist()
        unbound_mRNA = np.array(unbound_mRNA).flatten()
        bound_mRNA = np.array(bound_mRNA).flatten()
      

         # Calculate bound mRNA by subtracting unbound mRNA from the initial mRNA value
        # bound_mRNA = [states0_last_value - u for u in unbound_mRNA]

        # logging.info(f"Calculated bound_mRNA: {bound_mRNA}")

        return {
            "time": time,
            "unbound_mRNA": unbound_mRNA.tolist(),
            "bound_mRNA": bound_mRNA.tolist()
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
        logging.info(f"Running membrane model with qF={qF}, mRNA={c0_mRNA}, protein={c0_protein}, ntp={c0_ntps}, conversion={X}, stages={n_stages}")

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
        #  13) TFF_mRNA
        outputs = eng_instance.membraneAPI(
            qF_matlab,
            c0_matlab,
            X_matlab,
            n_stages_matlab,
            D_matlab,
            filterType_matlab,
            nargout=13
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
        TFF_mRNA_mat            = outputs[12]

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

        TFF_mRNA_py = []
        for cell_array in TFF_mRNA_mat:
            arr = np.array(cell_array).flatten().tolist()
            TFF_mRNA_py.append(arr)

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
            "Xactual": Xactual_val,
            "TFF_mRNA": TFF_mRNA_py
        }
        logging.info(f"Membrane model outputs: {result}")

        return result

    except Exception as e:
        logging.error(f"Error in run_membrane_model: {e}")
        raise RuntimeError(f"Error in run_membrane_model: {e}")



# LNP model call
def run_lnp_model(Residential_time, FRR, pH, Ion, TF, C_lipid, mRNA_in):
    try:
        eng = get_matlab_engine()
        logging.info(f"Running LNP model with Residential_time={Residential_time}, FRR={FRR}, pH={pH}, Ion={Ion}, TF={TF}, C_lipid={C_lipid}, mRNA_in={mRNA_in}")

        # Convert inputs to MATLAB data types
        Residential_time_matlab = float(Residential_time)
        FRR_matlab = float(FRR)
        pH_matlab = float(pH)
        Ion_matlab = float(Ion)
        TF_matlab = float(TF)
        C_lipid_matlab = float(C_lipid)
        mRNA_in_matlab = float(mRNA_in)

        # Call the MATLAB LNP function with 7 inputs and 5 outputs
        Diameter, PSD, EE, mRNA_out, Fraction = eng.Main(
            Residential_time_matlab,
            FRR_matlab,
            pH_matlab,
            Ion_matlab,
            TF_matlab,
            C_lipid_matlab,
            mRNA_in_matlab,
            nargout=5
        )

        logging.info("Received outputs from MATLAB LNP function.")

        # Convert MATLAB outputs to Python lists (if needed)
        Diameter_py = np.array(Diameter).tolist()
        PSD_py = np.array(PSD).tolist()
        EE_py = float(EE)
        mRNA_out_py = float(mRNA_out)
        Fraction_py = float(Fraction)

        return {
            "Diameter": Diameter_py,
            "PSD": PSD_py,
            "EE": EE_py,
            "mRNA_out": mRNA_out_py,
            "Fraction": Fraction_py,
        }

    except Exception as e:
        logging.error(f"Error in running MATLAB LNP function: {e}")
        raise RuntimeError(f"Error in running MATLAB LNP function: {e}")

# def run_lnp_model(Residential_time, FRR, pH, Ion, TF):
#     try:
#         # Get the MATLAB engine instance
#         eng = get_matlab_engine()

#         logging.info(f"Running LNP model with Residential_time={Residential_time}, FRR={FRR}, pH={pH}, Ion={Ion}, TF={TF}")

#         # Convert inputs to MATLAB data types
#         Residential_time_matlab = float(Residential_time)
#         FRR_matlab = float(FRR)
#         pH_matlab = float(pH)
#         Ion_matlab = float(Ion)
#         TF_matlab = float(TF)

#         # Call the MATLAB LNP function
       
#         Diameter, PSD = eng.LNP(Residential_time_matlab, FRR_matlab, pH_matlab, Ion_matlab, TF_matlab, nargout=2)

#         logging.info("Received outputs from MATLAB LNP function.")

#         # Convert MATLAB outputs to Python lists
#         Diameter_py = np.array(Diameter).tolist()  # Assuming Diameter is a 2D array
#         PSD_py = np.array(PSD).tolist()            # Assuming PSD is a 2D array

#         return {
#             "Diameter": Diameter_py,
#             "PSD": PSD_py
#         }

#     except Exception as e:
#         logging.error(f"Error in running MATLAB LNP function: {e}")
#         raise RuntimeError(f"Error in running MATLAB LNP function: {e}")



# def run_membrane_model(qF, c0_mRNA, c0_protein, c0_ntps, X, n_stages, D, filterType, V_IVT):
#     """
#     Runs the membraneAPI_new MATLAB function and retrieves the outputs.

#     Parameters:
#         qF (float): Feed flow rate [mL/min], e.g., 1-5
#         c0_mRNA (float): Initial mRNA concentration [mg/mL]
#         c0_protein (float): Initial protein concentration [mg/mL]
#         c0_ntps (float): Initial NTPs concentration [mg/mL]
#         X (float): Desired conversion (0 < X < 1)
#         n_stages (int): Number of TFF stages (>=2)
#         D (float): Diafiltration buffer flow rate [mL/min]
#         filterType (str): 'NOVIBRO' or 'VIBRO'
#         V_IVT (float): Total processing volume [mL], e.g., 3000 for 3L

#     Returns:
#         dict: A dictionary containing all outputs from membraneAPI_new
#     """
#     try:
#         eng_instance = get_matlab_engine()

#         # Convert Python values to MATLAB data types
#         qF_matlab = float(qF)
#         c0_matlab = matlab.double([float(c0_mRNA), float(c0_protein), float(c0_ntps)])
#         c0_matlab = eng_instance.transpose(c0_matlab)  # Convert to 3×1 column vector
#         X_matlab = float(X)
#         n_stages_matlab = float(n_stages)
#         D_matlab = float(D)
#         filterType_matlab = str(filterType)
#         V_IVT_matlab = float(V_IVT)

#         # ***Added Section: Call the updated membraneAPI_new MATLAB function with 17 outputs***
#         outputs = eng_instance.membraneAPI_new(
#             qF_matlab,
#             c0_matlab,
#             X_matlab,
#             n_stages_matlab,
#             D_matlab,
#             filterType_matlab,
#             V_IVT_matlab,
#             nargout=17  # Updated to reflect the new number of outputs
#         )
      

#         # Extract each output
#         time_points_mat = outputs[0]
#         x_positions_mat = outputs[1]
#         Cmatrix_mRNA_mat = outputs[2]
#         Cmatrix_protein_mat = outputs[3]
#         Cmatrix_ntps_mat = outputs[4]
#         td_mat = outputs[5]
#         TFF_protein_mat = outputs[6]
#         TFF_ntps_mat = outputs[7]
#         t_ss_mat = outputs[8]
#         Reduction_mat = outputs[9]
#         V_final_mat = outputs[10]
#         avg_conc_pre_ccdf_mat = outputs[11]
#         avg_conc_post_ccdf_mat = outputs[12]
#         ccdf_time_mat = outputs[13]
#         X_actual_mat = outputs[14]
#         interpolated_times_mat = outputs[15]  
#         interpolated_indices_mat = outputs[16] 

#         # Convert MATLAB data types to Python
#         time_points_py = np.array(time_points_mat).flatten().tolist()
#         x_positions_py = np.array(x_positions_mat).flatten().tolist()

#         Cmatrix_mRNA_py = np.array(Cmatrix_mRNA_mat).tolist()       # 2D list
#         Cmatrix_protein_py = np.array(Cmatrix_protein_mat).tolist() # 2D list
#         Cmatrix_ntps_py = np.array(Cmatrix_ntps_mat).tolist()       # 2D list

#         td_py = np.array(td_mat).flatten().tolist()

#         # Convert cell arrays to lists of lists for TFF_protein and TFF_ntps
#         TFF_protein_py = [np.array(stage).flatten().tolist() for stage in TFF_protein_mat]
#         TFF_ntps_py = [np.array(stage).flatten().tolist() for stage in TFF_ntps_mat]

#         t_ss_py = np.array(t_ss_mat).flatten().tolist()
#         Reduction_py = np.array(Reduction_mat).flatten().tolist()
#         V_final_py = float(V_final_mat)
#         avg_conc_pre_ccdf_py = np.array(avg_conc_pre_ccdf_mat).flatten().tolist()
#         avg_conc_post_ccdf_py = np.array(avg_conc_post_ccdf_mat).flatten().tolist()
#         ccdf_time_py = float(ccdf_time_mat)
#         X_actual_py = float(X_actual_mat)

   
#         interpolated_times_py = np.array(interpolated_times_mat).flatten().tolist()
#         interpolated_indices_py = np.array(interpolated_indices_mat).flatten().astype(int).tolist()
       

#         # Prepare the result dictionary
#         result = {
#             "time_points": time_points_py,
#             "x_positions": x_positions_py,
#             "Cmatrix_mRNA": Cmatrix_mRNA_py,
#             "Cmatrix_protein": Cmatrix_protein_py,
#             "Cmatrix_ntps": Cmatrix_ntps_py,
#             "td": td_py,
#             "TFF_protein": TFF_protein_py,
#             "TFF_ntps": TFF_ntps_py,
#             "t_ss": t_ss_py,
#             "Reduction": Reduction_py,
#             "V_final": V_final_py,
#             "avg_conc_pre_ccdf": avg_conc_pre_ccdf_py,
#             "avg_conc_post_ccdf": avg_conc_post_ccdf_py,
#             "ccdf_time": ccdf_time_py,
#             "X": X_actual_py,
#             "interpolated_times": interpolated_times_py,      
#             "interpolated_indices": interpolated_indices_py    
#         }

#         return result

#     except Exception as e:
#         logging.error(f"Error in run_membrane_model: {e}")
#         raise RuntimeError(f"Error in run_membrane_model: {e}")
