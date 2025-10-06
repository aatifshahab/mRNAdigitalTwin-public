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


def _build_overrides_struct(eng, overrides: dict):
    """
    Build a MATLAB struct('k1',v1,'k2',v2,...) from numeric overrides.
    Returns None if no valid fields provided.
    """
    if not overrides:
        return None
    arglist = []
    for k, v in overrides.items():
        if k == 'states0_last_value' or v is None:
            continue
        # keep it simple: only scalars for now
        if isinstance(v, (int, float)):
            arglist.extend([k, float(v)])
    if not arglist:
        return None
    # struct('k1',v1,'k2',v2,...) -> MATLAB will create a 1x1 struct
    return eng.struct(*arglist, nargout=1)


# CCTC model call updated (see ivt-frontend/src/units/cctcSpec   to knw what units can be tuned)
def run_cctc_model(states0_last_value, **overrides):
    try:
        eng = get_matlab_engine()

        cwd = eng.pwd(nargout=1)
        logging.info(f"[MATLAB] Current working directory: {cwd}")

        location = eng.which('run_cctc_model', nargout=1)
        if location:
            logging.info(f"[MATLAB] Found run_cctc_model at: {location}")
        else:
            logging.warning("[MATLAB] run_cctc_model not found in MATLAB path!")

        # MATLAB scalar double
        states0_last_value_matlab = matlab.double([float(states0_last_value)])
        logging.info(f"Calling MATLAB 'run_cctc_model' with states0_last_value={states0_last_value}")

        # Build overrides struct only if extras were provided
        ov_struct = _build_overrides_struct(eng, overrides)

        # Prefer the 2-arg call if we have overrides; otherwise use 1-arg
        if ov_struct is not None:
            try:
                tSol, unbound_mRNA, bound_mRNA = eng.run_cctc_model(
                    states0_last_value_matlab, ov_struct, nargout=3
                )
            except Exception as e:
                # Backward-compat: fall back to the original 1-arg signature
                logging.warning(f"[MATLAB] 2-arg call failed, falling back to 1-arg. Error: {e}")
                tSol, unbound_mRNA, bound_mRNA = eng.run_cctc_model(
                    states0_last_value_matlab, nargout=3
                )
        else:
            tSol, unbound_mRNA, bound_mRNA = eng.run_cctc_model(
                states0_last_value_matlab, nargout=3
            )

        # Convert outputs to Python lists
        time = np.array(tSol).flatten().tolist()
        unbound_mRNA = np.array(unbound_mRNA).flatten().tolist()
        bound_mRNA = np.array(bound_mRNA).flatten().tolist()

        return {
            "time": time,
            "unbound_mRNA": unbound_mRNA,
            "bound_mRNA": bound_mRNA
        }

    except Exception as e:
        logging.error(f"Error in running MATLAB function: {e}")
        raise RuntimeError(f"Error in running MATLAB function: {e}")




# Lyo model call
def run_lyo_model(fluidVolume, massFractionSolids, InitfreezingTemperature, 
                 InitprimaryDryingTemperature, InitsecondaryDryingTemperature, 
                 TempColdGasfreezing, TempShelfprimaryDrying, 
                 TempShelfsecondaryDrying, Pressure):
    """
    Runs the Lyo simulation by calling the MATLAB LyoAppInterface function.

    Parameters:
    - fluidVolume (float): Volume of the fluid (m3).
    - massFractionSolids (float):  (kg/kg).
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
        massFractionSolids_matlab = float(massFractionSolids)
        InitfreezingTemperature_matlab = float(InitfreezingTemperature)
        InitprimaryDryingTemperature_matlab = float(InitprimaryDryingTemperature)
        InitsecondaryDryingTemperature_matlab = float(InitsecondaryDryingTemperature)
        TempColdGasfreezing_matlab = float(TempColdGasfreezing)
        TempShelfprimaryDrying_matlab = float(TempShelfprimaryDrying)
        TempShelfsecondaryDrying_matlab = float(TempShelfsecondaryDrying)
        Pressure_matlab = float(Pressure)

        # Log input values
        logging.info(f"Inputs to LyoAppInterface: fluidVolume={fluidVolume_matlab}, "
                     f"massFractionSolids={massFractionSolids_matlab}, "
                     f"InitfreezingTemperature={InitfreezingTemperature_matlab}, "
                     f"InitprimaryDryingTemperature={InitprimaryDryingTemperature_matlab}, "
                     f"InitsecondaryDryingTemperature={InitsecondaryDryingTemperature_matlab}, "
                     f"TempColdGasfreezing={TempColdGasfreezing_matlab}, "
                     f"TempShelfprimaryDrying={TempShelfprimaryDrying_matlab}, "
                     f"TempShelfsecondaryDrying={TempShelfsecondaryDrying_matlab}, "
                     f"Pressure={Pressure_matlab}")

        # Call the MATLAB function
        outputs = eng.LyoAppInterface(fluidVolume_matlab, massFractionSolids_matlab, 
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

def run_membrane_model(qF, c0_mRNA, c0_protein, c0_ntps, X, n_stages, D, filterType, **overrides):
    try:
        eng_instance = get_matlab_engine()
        logging.info(
            "Running membrane model with qF=%s, mRNA=%s, protein=%s, ntp=%s, conversion=%s, stages=%s, D=%s, filterType=%s, overrides=%s",
            qF, c0_mRNA, c0_protein, c0_ntps, X, n_stages, D, filterType, list(overrides.keys())
        )

        # === original conversions (unchanged) ===
        qF_matlab         = float(qF)
        c0_matlab         = matlab.double([float(c0_mRNA), float(c0_protein), float(c0_ntps)])
        c0_matlab         = eng_instance.transpose(c0_matlab)  # 3×1 column vector
        X_matlab          = float(X)
        n_stages_matlab   = float(n_stages)
        D_matlab          = float(D)
        ft                = str(filterType)

        # (Optional) normalize the HF spelling used in MATLAB code:
        # MATLAB checks "NOVIBRO" for the HF branch; keep behavior identical
        filterType_matlab = "NOVIBRO" if ft.upper() == "HF" else ft

        # === NEW: pack overrides (numeric/simple scalars only) ===
        ov_struct = _build_overrides_struct(eng_instance, overrides)

        # === Call MATLAB (prefer with overrides; fall back if needed) ===
        if ov_struct is not None:
            try:
                outputs = eng_instance.membraneAPI(
                    qF_matlab,
                    c0_matlab,
                    X_matlab,
                    n_stages_matlab,
                    D_matlab,
                    filterType_matlab,
                    ov_struct,
                    nargout=13
                )
            except Exception as e:
                logging.warning("[MATLAB] membraneAPI(..., opts) failed; falling back: %s", e)
                outputs = eng_instance.membraneAPI(
                    qF_matlab,
                    c0_matlab,
                    X_matlab,
                    n_stages_matlab,
                    D_matlab,
                    filterType_matlab,
                    nargout=13
                )
        else:
            outputs = eng_instance.membraneAPI(
                qF_matlab,
                c0_matlab,
                X_matlab,
                n_stages_matlab,
                D_matlab,
                filterType_matlab,
                nargout=13
            )

        # === original unpack + conversions (unchanged) ===
        time_points_mat          = outputs[0]
        x_positions_mat          = outputs[1]
        Cmatrix_mRNA_mat         = outputs[2]
        Cmatrix_protein_mat      = outputs[3]
        Cmatrix_ntps_mat         = outputs[4]
        interpolated_times_mat   = outputs[5]
        interpolated_indices_mat = outputs[6]
        td_mat                   = outputs[7]
        TFF_protein_mat          = outputs[8]
        TFF_ntps_mat             = outputs[9]
        Jcrit_val                = float(outputs[10])
        Xactual_val              = float(outputs[11])
        TFF_mRNA_mat             = outputs[12]

        time_points_py          = np.array(time_points_mat).flatten().tolist()
        x_positions_py          = np.array(x_positions_mat).flatten().tolist()
        Cmatrix_mRNA_py         = np.array(Cmatrix_mRNA_mat).tolist()
        Cmatrix_protein_py      = np.array(Cmatrix_protein_mat).tolist()
        Cmatrix_ntps_py         = np.array(Cmatrix_ntps_mat).tolist()
        interpolated_times_py   = np.array(interpolated_times_mat).flatten().tolist()
        interpolated_indices_py = np.array(interpolated_indices_mat).astype(int).flatten().tolist()
        td_py                   = np.array(td_mat).flatten().tolist()

        TFF_protein_py = [np.array(cell_array).flatten().tolist() for cell_array in TFF_protein_mat]
        TFF_ntps_py    = [np.array(cell_array).flatten().tolist() for cell_array in TFF_ntps_mat]
        TFF_mRNA_py    = [np.array(cell_array).flatten().tolist() for cell_array in TFF_mRNA_mat]

        result = {
            "time_points":          time_points_py,
            "x_positions":          x_positions_py,
            "Cmatrix_mRNA":         Cmatrix_mRNA_py,
            "Cmatrix_protein":      Cmatrix_protein_py,
            "Cmatrix_ntps":         Cmatrix_ntps_py,
            "interpolated_times":   interpolated_times_py,
            "interpolated_indices": interpolated_indices_py,
            "td":                   td_py,
            "TFF_protein":          TFF_protein_py,
            "TFF_ntps":             TFF_ntps_py,
            "Jcrit":                Jcrit_val,
            "Xactual":              Xactual_val,
            "TFF_mRNA":             TFF_mRNA_py,
        }

        # === NEW: echo back the exact inputs the model used (for GUI display) ===
        # Map NOVIBRO back to "HF" so the UI shows what users expect.
        filter_out = "HF" if filterType_matlab.upper() == "NOVIBRO" else filterType_matlab
        inputs_used = {
            "qF": float(qF),
            "c0_mRNA": float(c0_mRNA),
            "c0_protein": float(c0_protein),
            "c0_ntps": float(c0_ntps),
            "X": float(X),
            "n_stages": float(n_stages),
            "D": float(D),
            "filterType": filter_out,
        }
        for k, v in overrides.items():
            if isinstance(v, (int, float)): inputs_used[k] = float(v)
            elif isinstance(v, (str, bool)): inputs_used[k] = v
        result["inputs_used"] = inputs_used

        logging.info("Membrane model outputs ready.")
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
        Diameter, PSD, EE, mRNA_out, Fraction, PDI_val, Dstats = eng.Main(
            Residential_time_matlab,
            FRR_matlab,
            pH_matlab,
            Ion_matlab,
            TF_matlab,
            C_lipid_matlab,
            mRNA_in_matlab,
            nargout=7
        )

        logging.info("Received outputs from MATLAB LNP function.")

        # Convert MATLAB outputs to Python lists (if needed)
        Diameter_py = np.array(Diameter).tolist()
        PSD_py = np.array(PSD).tolist()
        EE_py = float(EE)
        mRNA_out_py = float(mRNA_out)
        Fraction_py = float(Fraction)
        PDI_py       = float(PDI_val)

        # Dstats is [D10, D50, D90, (optional) D25, D75]; handle length safely
        Dstats_arr = np.array(Dstats).flatten().tolist()
        D10_py = Dstats_arr[0] if len(Dstats_arr) > 0 else None
        D50_py = Dstats_arr[1] if len(Dstats_arr) > 1 else None
        D90_py = Dstats_arr[2] if len(Dstats_arr) > 2 else None
        D25_py = Dstats_arr[3] if len(Dstats_arr) > 3 else None
        D75_py = Dstats_arr[4] if len(Dstats_arr) > 4 else None

        return {
            "Diameter": Diameter_py,
            "PSD": PSD_py,
            "EE": EE_py,
            "mRNA_out": mRNA_out_py,
            "Fraction": Fraction_py,
            "PDI":       PDI_py,
            "D10":       D10_py,
            "D50":       D50_py,
            "D90":       D90_py,
            "D25":       D25_py,
            "D75":       D75_py,
        }

    except Exception as e:
        logging.error(f"Error in running MATLAB LNP function: {e}")
        raise RuntimeError(f"Error in running MATLAB LNP function: {e}")

