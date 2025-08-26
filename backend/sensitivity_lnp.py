
import os
import pickle
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
CACHE_FILE = "lnp_sensitivity_cache1.pkl"

# Debug‐mode Morris design (adjust for full run)
N_TRAJ = 30               # small for quick debug; increase for production
OPT_TRAJ = 20             # must be < N_TRAJ
NUM_LEVELS = 4

# -----------------------------------------------------------------------------
# 1) Define the LNP sensitivity problem
# -----------------------------------------------------------------------------
names = ['Residential_time', 'FRR', 'pH', 'Ion', 'TF', 'C_lipid']
bounds = [
    [3000.0, 4200.0],  # Residence time [s]
    [1.0, 5.0],        # Flow rate ratio FRR [-]
    [4.0, 6.0],        # pH [-]
    [0.01, 1.0],       # Ionic concentration [M]
    [1.0, 10.0],       # Total flow rate [mL/min]
    [5.0, 15.0]        # Lipid concentration [mg/mL]
]
problem = {'num_vars': len(names), 'names': names, 'bounds': bounds}

# 2) Nominal (fixed) input
nominal = {'mRNA_in': 10.0}  # mg/mL

# -----------------------------------------------------------------------------
# 3) Load or compute sensitivity indices
# -----------------------------------------------------------------------------
if os.path.exists(CACHE_FILE):
    # Load cached results
    with open(CACHE_FILE, "rb") as f:
        cache = pickle.load(f)
    Si_mean = cache["Si_mean"]
    Si_pdi  = cache["Si_pdi"]
    print(f"Loaded cached sensitivity results from '{CACHE_FILE}'.")
else:
    # Suppress irrelevant numpy warnings
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
    y_mean = np.full(param_values.shape[0], np.nan)
    y_pdi  = np.full(param_values.shape[0], np.nan)

    # 6) Loop over samples
    for i, xi in enumerate(param_values):
        print(f"\n--- Sample {i} ---")
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

            # Debug prints
            print("  raw out['Diameter']:", out['Diameter'])
            print("  raw out['PSD']    :", out['PSD'])

            # Parse final mean diameter
            D_arr  = np.array(out['Diameter'])   # (nTime, 2)
            diam_t = D_arr[:, 1]
            meanD  = float(diam_t[-1])
            y_mean[i] = meanD
            print(f"  parsed meanD = {meanD:.6g}")

            # Parse PSD and compute PDI
            PSD_arr = np.array(out['PSD'])       # (nBins, 2)
            bins, psd = PSD_arr[:, 0], PSD_arr[:, 1]
            print(f"  parsed PSD bins={bins.size}, sum(psd)={psd.sum():.6g}")
            cdf = np.cumsum(psd) / psd.sum()
            d10 = np.interp(0.1, cdf, bins)
            d50 = np.interp(0.5, cdf, bins)
            d90 = np.interp(0.9, cdf, bins)
            pdi = float((d90 - d10) / d50) if d50 > 0 else np.nan
            y_pdi[i] = pdi
            print(f"  parsed PDI   = {pdi:.6g}")

        except Exception as e:
            print(f"  ✗ Sample {i} failed: {e}")

    # 7) Morris analysis (only on valid runs)
    valid_mean = ~np.isnan(y_mean)
    Si_mean = morris_analyze.analyze(
        problem,
        param_values[valid_mean],
        y_mean[valid_mean],
        num_levels=NUM_LEVELS,
        print_to_console=False
    )
    print("\nMorris Sensitivity (mean diameter):")
    for name, mu in zip(names, Si_mean['mu_star']):
        print(f"  {name}: mu* = {mu:.4g}")

    valid_pdi = ~np.isnan(y_pdi)
    Si_pdi = morris_analyze.analyze(
        problem,
        param_values[valid_pdi],
        y_pdi[valid_pdi],
        num_levels=NUM_LEVELS,
        print_to_console=False
    )
    print("\nMorris Sensitivity (PDI):")
    for name, mu in zip(names, Si_pdi['mu_star']):
        print(f"  {name}: mu* = {mu:.4g}")

    # 8) Cache results
    with open(CACHE_FILE, "wb") as f:
        pickle.dump({"Si_mean": Si_mean, "Si_pdi": Si_pdi}, f)
    print(f"Sensitivity results cached to '{CACHE_FILE}'.")

# -----------------------------------------------------------------------------
# 9) Plot & save figures
# -----------------------------------------------------------------------------
# Mean Diameter

# LaTeX‐style labels for plotting
xtick_labels = [
    r'$t_R$',      # Residential_time
    r'FRR',        # Flow‐rate ratio
    r'pH',         # pH
    r'$I$',        # Ionic strength
    r'$TF$',        # Total flow
    r'$C_L$'       # Lipid concentration
]

plt.figure(figsize=(6, 4))
plt.bar(xtick_labels, Si_mean['mu_star'], yerr=Si_mean['sigma'], capsize=5, edgecolor='k')
plt.ylabel("Morris μ* (± σ)",fontsize=16)
plt.title("LNP Sensitivity: Mean Diameter")
plt.xticks(fontsize=16)
plt.tight_layout()
plt.savefig("sensitivity_mean_diameter.png", dpi=300)

# PDI
plt.figure(figsize=(6, 4))
plt.bar(xtick_labels, Si_pdi['mu_star'], yerr=Si_pdi['sigma'], capsize=5, edgecolor='k')
plt.ylabel("Morris μ* (± σ)", fontsize=16)
plt.title("LNP Sensitivity: PDI")
plt.xticks(fontsize=16)
plt.tight_layout()
plt.savefig("sensitivity_pdi.png", dpi=300)

plt.show()




# import numpy as np
# import matplotlib.pyplot as plt
# from SALib.sample import morris as morris_sample
# from SALib.analyze import morris as morris_analyze
# from schemas import LNPInput
# from matlab_interface import run_lnp_model
# import warnings

# # -----------------------------------------------------------------------------
# # 1) Define the LNP sensitivity problem
# # -----------------------------------------------------------------------------
# names = ['Residential_time', 'FRR', 'pH', 'Ion', 'TF', 'C_lipid']
# bounds = [
#     [3000.0, 4200.0],  # Residence time [s]
#     [1.0, 5.0],        # Flow rate ratio FRR [-]
#     [4.0, 6.0],        # pH [-]
#     [0.01, 1.0],       # Ionic concentration [M]
#     [1.0, 10.0],       # Total flow rate [mL/min]
#     [5.0, 15.0]        # Lipid concentration [mg/mL]
# ]
# problem = {'num_vars': len(names), 'names': names, 'bounds': bounds}

# # 2) Nominal settings
# nominal = {'mRNA_in': 10.0}  # mg/mL

# # 3) Generate a small Morris sample for debugging
# param_values = morris_sample.sample(
#     problem,
#     N=3,                   # small N for quick debug
#     num_levels=4,
#     optimal_trajectories=2 # must be < N
# )

# # 4) Prepare arrays to store outputs
# y_mean = np.full(len(param_values), np.nan)
# y_pdi  = np.full(len(param_values), np.nan)

# # Suppress irrelevant numpy warnings
# warnings.filterwarnings('ignore', category=RuntimeWarning)

# # -----------------------------------------------------------------------------
# # 5) Loop over samples, call MATLAB model, and debug-print intermediate data
# # -----------------------------------------------------------------------------
# for i, xi in enumerate(param_values):
#     print(f"\n--- Sample {i} ---")
#     for name, val in zip(names, xi):
#         print(f"  {name} = {val:.4g}")
#     params = dict(zip(names, xi))
#     params.update(nominal)
#     inp = LNPInput(**params)

#     try:
#         # Call the MATLAB LNP model
#         out = run_lnp_model(
#             inp.Residential_time,
#             inp.FRR,
#             inp.pH,
#             inp.Ion,
#             inp.TF,
#             inp.C_lipid,
#             inp.mRNA_in
#         )

#         # Debug: show raw returned structures
#         print("  raw out['Diameter']:", out['Diameter'])
#         print("  raw out['PSD']    :", out['PSD'])

#         # Parse the two-column "Diameter" (time vs mean D)
#         D_arr  = np.array(out['Diameter'])    # shape (nTime, 2)
#         diam_t = D_arr[:, 1]                  # mean diameter over time
#         meanD  = float(diam_t[-1])            # take final timepoint
#         print(f"  parsed meanD (final) = {meanD:.6g}")

#         # Parse the two-column "PSD" (bin center vs density)
#         PSD_arr = np.array(out['PSD'])        # shape (nBins, 2)
#         bins    = PSD_arr[:, 0]
#         psd     = PSD_arr[:, 1]
#         print(f"  parsed PSD bins = {bins.size}, sum(psd) = {psd.sum():.6g}")

#         # Store mean diameter
#         y_mean[i] = meanD

#         # Compute PDI from the PSD
#         cdf = np.cumsum(psd) / psd.sum()
#         d10 = np.interp(0.1, cdf, bins)
#         d50 = np.interp(0.5, cdf, bins)
#         d90 = np.interp(0.9, cdf, bins)
#         pdi = float((d90 - d10) / d50) if d50 > 0 else np.nan
#         y_pdi[i] = pdi
#         print(f"  parsed PDI = {pdi:.6g}")

#     except Exception as e:
#         print(f"  ✗ Sample {i} failed: {e}")

# # -----------------------------------------------------------------------------
# # 6) Perform Morris analysis only if enough valid runs
# # -----------------------------------------------------------------------------
# D = problem['num_vars']
# min_runs = D + 1

# # Mean diameter analysis
# mask_mean = ~np.isnan(y_mean)
# if mask_mean.sum() >= min_runs:
#     Si_mean = morris_analyze.analyze(
#         problem,
#         param_values[mask_mean],
#         y_mean[mask_mean],
#         num_levels=4,
#         print_to_console=False
#     )
#     print("\nMorris Sensitivity (mean diameter):")
#     for name, mu in zip(names, Si_mean['mu_star']):
#         print(f"  {name}: mu* = {mu:.4g}")
# else:
#     print(f"\nInsufficient valid runs for mean diameter ({mask_mean.sum()}/{min_runs})")

# # PDI analysis
# mask_pdi = ~np.isnan(y_pdi)
# if mask_pdi.sum() >= min_runs:
#     Si_pdi = morris_analyze.analyze(
#         problem,
#         param_values[mask_pdi],
#         y_pdi[mask_pdi],
#         num_levels=4,
#         print_to_console=False
#     )
#     print("\nMorris Sensitivity (PDI):")
#     for name, mu in zip(names, Si_pdi['mu_star']):
#         print(f"  {name}: mu* = {mu:.4g}")
# else:
#     print(f"\nInsufficient valid runs for PDI ({mask_pdi.sum()}/{min_runs})")

# # -----------------------------------------------------------------------------
# # 7) Optional: Plot results (uncomment after debugging)
# # -----------------------------------------------------------------------------
# fig, axes = plt.subplots(1, 2, figsize=(12, 5))
# for ax, (Si, title) in zip(axes, [(Si_mean, 'Mean Diameter'), (Si_pdi, 'PDI')]):
#     mu_star, sigma = Si['mu_star'], Si['sigma']
#     ax.bar(names, mu_star, yerr=sigma, capsize=5, edgecolor='k')
#     ax.set_title(f'LNP Sensitivity: {title}')
#     ax.tick_params(axis='x', rotation=45, ha='right')
# plt.tight_layout()
# plt.show()
