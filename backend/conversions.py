# conversions.py

def convert_uM_to_mg_per_ml(uM_value, molar_mass):
    """
    Convert µM (micromolar) to mg/mL.
    
    Parameters:
    - uM_value: float, concentration in micromolar (µM)
    - molar_mass: float, molar mass in g/mol
    
    Returns:
    - float, concentration in mg/mL
    """
    # Convert µM to mol/L
    mol_per_l = uM_value * 1e-6
    # Convert mol/L to g/L
    g_per_l = mol_per_l * molar_mass
    # Convert g/L to mg/mL (1 g/L = 1 mg/mL)
    mg_per_ml = g_per_l / 1  # 1 g/L = 1 mg/mL
    return mg_per_ml

def convert_mg_ml_to_g_l(mg_per_ml):
    """
    Convert mg/mL to g/L.
    
    Parameters:
    - mg_per_ml: float, concentration in mg/mL
    
    Returns:
    - float, concentration in g/L
    """
    # 1 mg/mL = 1 g/L
    return mg_per_ml
