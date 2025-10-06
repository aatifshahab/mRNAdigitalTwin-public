# sensitivity_lnp.py 

import warnings
import numpy as np
import matplotlib.pyplot as plt
from SALib.sample import morris as morris_sample
from SALib.analyze import morris as morris_analyze

from schemas import LNPInput
from matlab_interface import run_lnp_model

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
# Reproducibility (optional): set a seed BEFORE morris sampling
# np.random.seed(42)

# Debug‐mode Morris design (increase for production)
N_TRAJ = 30               # requested trajectories (SALib may return optimal_trajectories instead)
OPT_TRAJ = 20             # must be <= N_TRAJ; actual trajectories generated
NUM_LEVELS = 4

# -----------------------------------------------------------------------------
# 1) Define the LNP sensitivity problem
# -----------------------------------------------------------------------------
names = ['Residential_time', 'FRR', 'pH', 'Ion', 'TF', 'C_lipid']
bounds = [
    [0.5, 1.5],   # Residence time [s]
    [1.0, 5.0],   # Flow rate ratio FRR [-]
    [4.0, 6.0],   # pH [-]
    [0.01, 1.0],  # Ionic concentration [M]
    [1.0, 10.0],  # Total flow rate [mL/min]
    [5.0, 15.0]   # Lipid concentration [mg/mL]
]
problem = {'num_vars': len(names), 'names': names, 'bounds': bounds}

# 2) Nominal (fixed) input
nominal = {'mRNA_in': 0.05}  # mg/mL

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def _final_mean_diameter_from_output(out: dict) -> float:
    """Return final mean diameter [nm] from out['Diameter'] if available, else NaN."""
    try:
        D_arr = np.asarray(out.get('Diameter', []), dtype=float)
        if D_arr.ndim != 2 or D_arr.shape[1] < 2 or D_arr.size == 0:
            return np.nan
        return float(D_arr[-1, 1])
    except Exception:
        return np.nan

def _pdi_from_backend_or_psd(out: dict) -> float:
    """
    Prefer PDI provided by backend (out['PDI']).
    Otherwise, compute PDI = (D90 - D10) / D50 from out['PSD'] robustly.
    PSD is expected as [[diam_nm, pdf/weights], ...].
    """
    # 1) Prefer backend-provided PDI
    pdi_backend = out.get('PDI', None)
    if pdi_backend is not None:
        try:
            val = float(pdi_backend)
            if np.isfinite(val):
                return val
        except Exception:
            pass

    # 2) Fallback: compute from PSD
    try:
        PSD_arr = np.asarray(out.get('PSD', []), dtype=float)
        if PSD_arr.ndim != 2 or PSD_arr.shape[1] < 2 or PSD_arr.size == 0:
            return np.nan

        bins_nm = PSD_arr[:, 0]
        pdf     = PSD_arr[:, 1]

        # sort by diameter just in case
        order = np.argsort(bins_nm)
        x = bins_nm[order].astype(float)
        y = np.clip(pdf[order].astype(float), 0.0, None)

        # normalize area with trapezoid (handles non-uniform spacing)
        area = np.trapz(y, x)
        if not np.isfinite(area) or area <= 0:
            return np.nan
        y = y / area

        # cumulative by trapezoid; start at 0 exactly
        cdf = np.concatenate([[0.0], np.cumsum((y[:-1] + y[1:]) * 0.5 * np.diff(x))])
        if cdf[-1] > 0:
            cdf = cdf / cdf[-1]

        # dedupe flats so interpolation xp is strictly increasing
        cdf_u, ia = np.unique(cdf, return_index=True)
        x_u = x[ia]

        if cdf_u.size < 2:
            d10 = d50 = d90 = x_u[0]
        else:
            clamp = lambda p: float(min(max(p, float(cdf_u[0])), float(cdf_u[-1])))
            d10 = float(np.interp(clamp(0.10), cdf_u, x_u))
            d50 = float(np.interp(clamp(0.50), cdf_u, x_u))
            d90 = float(np.interp(clamp(0.90), cdf_u, x_u))

        return float((d90 - d10) / d50) if d50 > 0 else np.nan

    except Exception:
        return np.nan

def _keep_full_trajectories(y: np.ndarray, param_values: np.ndarray, num_vars: int):
    """
    Keep only complete trajectories (length num_vars+1) for which ALL points are finite.
    Returns filtered (param_values, y), along with counts for logging.
    """
    traj_size = num_vars + 1
    n_rows = param_values.shape[0]
    if n_rows % traj_size != 0:
        raise RuntimeError(f"param_values rows ({n_rows}) not a multiple of trajectory size ({traj_size})")
    n_traj = n_rows // traj_size

    Y = y.reshape(n_traj, traj_size)
    keep_traj_mask = np.all(np.isfinite(Y), axis=1)
    kept = keep_traj_mask.sum()

    if kept == 0:
        raise RuntimeError("No full valid trajectories remain for analysis.")

    keep_rows = np.repeat(keep_traj_mask, traj_size)
    return param_values[keep_rows], y[keep_rows], n_traj, kept, traj_size

# -----------------------------------------------------------------------------
# 3) Run Morris sampling and simulations (no cache)
# -----------------------------------------------------------------------------
warnings.filterwarnings('ignore', category=RuntimeWarning)

# 4) Generate Morris samples
param_values = morris_sample.sample(
    problem,
    N=N_TRAJ,
    num_levels=NUM_LEVELS,
    optimal_trajectories=OPT_TRAJ
)
print(f"Generated {param_values.shape[0]} Morris samples.")

# 5) Allocate arrays
y_mean = np.full(param_values.shape[0], np.nan)  # final Z-avg (mean diameter)
y_pdi  = np.full(param_values.shape[0], np.nan)  # PDI

# 6) Loop over samples
for i, xi in enumerate(param_values):
    print(f"\n--- Sample {i+1}/{param_values.shape[0]} ---")
    for name, val in zip(names, xi):
        print(f"  {name} = {val:.4g}")
    params = dict(zip(names, xi))
    params.update(nominal)
    inp = LNPInput(**params)

    try:
        out = run_lnp_model(
            inp.Residential_time,
            inp.FRR,
            inp.pH,
            inp.Ion,
            inp.TF,
            inp.C_lipid,
            inp.mRNA_in
        )

        # Final mean diameter (from time series)
        meanD = _final_mean_diameter_from_output(out)
        y_mean[i] = meanD
        print(f"  final Dz = {meanD:.6g} nm")

        # PDI: prefer backend field, else compute robustly from PSD
        pdi = _pdi_from_backend_or_psd(out)
        y_pdi[i] = pdi
        print(f"  PDI      = {pdi:.6g}")

    except Exception as e:
        print(f"  ✗ Sample {i} failed: {e}")

# -----------------------------------------------------------------------------
# 7) Morris analysis (whole-trajectory filtering)
# -----------------------------------------------------------------------------
num_vars = problem['num_vars']
try:
    Pv_mean, Y_mean, n_traj, kept_mean, traj_size = _keep_full_trajectories(y_mean, param_values, num_vars)
    print(f"\nMorris (mean diameter): kept {kept_mean}/{n_traj} full trajectories "
          f"({kept_mean*traj_size} samples).")
    Si_mean = morris_analyze.analyze(
        problem,
        Pv_mean,
        Y_mean,
        num_levels=NUM_LEVELS,
        print_to_console=False
    )
    print("Morris Sensitivity (mean diameter):")
    for name, mu, sig in zip(names, Si_mean['mu_star'], Si_mean['sigma']):
        print(f"  {name}: mu* = {mu:.4g} (sigma = {sig:.4g})")
except Exception as e:
    print(f"\n[WARN] Mean-diameter analysis skipped: {e}")
    Si_mean = None

try:
    Pv_pdi, Y_pdi, n_traj2, kept_pdi, traj_size2 = _keep_full_trajectories(y_pdi, param_values, num_vars)
    print(f"\nMorris (PDI): kept {kept_pdi}/{n_traj2} full trajectories "
          f"({kept_pdi*traj_size2} samples).")
    Si_pdi = morris_analyze.analyze(
        problem,
        Pv_pdi,
        Y_pdi,
        num_levels=NUM_LEVELS,
        print_to_console=False
    )
    print("Morris Sensitivity (PDI):")
    for name, mu, sig in zip(names, Si_pdi['mu_star'], Si_pdi['sigma']):
        print(f"  {name}: mu* = {mu:.4g} (sigma = {sig:.4g})")
except Exception as e:
    print(f"\n[WARN] PDI analysis skipped: {e}")
    Si_pdi = None

# -----------------------------------------------------------------------------
# 8) Plot & save figures (only if analysis succeeded)
# -----------------------------------------------------------------------------
xtick_labels = [
    r'$t_R$',  # Residential_time
    r'FRR',    # Flow‐rate ratio
    r'pH',     # pH
    r'$I$',    # Ionic strength
    r'$TF$',   # Total flow
    r'$C_L$'   # Lipid concentration
]



if Si_pdi is not None:
    plt.figure(figsize=(6, 4))
    plt.bar(xtick_labels, Si_pdi['mu_star'], yerr=Si_pdi['sigma'], capsize=5, edgecolor='k')
    plt.ylabel("Morris μ* (± σ)", fontsize=16)
   
    plt.xticks(fontsize=16)
    plt.tight_layout()
    plt.savefig("sensitivity_pdi1.png", dpi=300)

plt.show()
