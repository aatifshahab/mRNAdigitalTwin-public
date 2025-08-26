import numpy as np
import matplotlib.pyplot as plt
from SALib.sample import morris as morris_sample
from SALib.analyze import morris as morris_analyze
from schemas import MembraneInput
from matlab_interface import run_membrane_model

# ---------- Pretty labels for x-axis ----------
LABELS = {
    'qF': r'$q_F$',
    'D': r'$D$',
    'c0_mRNA': r'$c_{0,\mathrm{mRNA}}$',
}

# ---------- Sensitivity problem (NO X here) ----------
names = ['qF', 'D', 'c0_mRNA']
bounds = [
    [2.0, 5.0],    # qF [mL/min]
    [4.0, 5.0],    # D [mL/min]
    [0.8, 1.2],    # c0_mRNA [mg/mL]
]
problem = {'num_vars': len(names), 'names': names, 'bounds': bounds}

# ---------- Nominal (unchanged inputs; X fixed at 0.90) ----------
nominal = {
    'c0_protein': 1.0,   # mg/mL
    'c0_ntps': 1.0,      # mg/mL
    'X': 0.90,           # conversion (fixed)
    'n_stages': 3,       # number of TFF stages
    'filterType': 'NOVIBRO'
}

# ---------- Morris sampling ----------
param_values = morris_sample.sample(
    problem, N=30, num_levels=4, optimal_trajectories=10
)

# ---------- Helper: keep only complete trajectories ----------
def keep_complete_trajectories(X, Y, k):
    traj_size = k + 1
    n_rows = len(Y)
    n_traj = n_rows // traj_size
    if n_rows % traj_size != 0:
        cut = n_traj * traj_size
        X, Y = X[:cut], Y[:cut]
    Yb = Y.reshape(n_traj, traj_size)
    mask = np.all(np.isfinite(Yb), axis=1)
    idx = np.arange(len(Y)).reshape(n_traj, traj_size)[mask].ravel()
    return X[idx], Y[idx]

# ---------- Run model and collect last-stage final TFF mRNA ----------
y_tff_mrna = np.zeros(len(param_values))
for i, xi in enumerate(param_values):
    params = dict(zip(names, xi))
    params.update(nominal)  # add fixed inputs (incl. X)
    try:
        inp = MembraneInput(**params)
        out = run_membrane_model(
            inp.qF,
            inp.c0_mRNA,
            inp.c0_protein,
            inp.c0_ntps,
            inp.X,
            inp.n_stages,
            inp.D,
            inp.filterType
        )
        last_stage_idx = int(inp.n_stages) - 1
        y_tff_mrna[i] = out['TFF_mRNA'][last_stage_idx][-1]
    except Exception:
        y_tff_mrna[i] = np.nan

# ---------- Clean & Morris analysis ----------
Xc, Yc = keep_complete_trajectories(param_values, y_tff_mrna, problem['num_vars'])
Si = morris_analyze.analyze(problem, Xc, Yc, num_levels=4, print_to_console=False)
mu_star, sigma = Si['mu_star'], Si['sigma']

# ---------- Plot ----------
plt.figure(figsize=(6, 4))
tick_labels = [LABELS.get(n, n) for n in names]
plt.bar(tick_labels, mu_star, yerr=sigma, capsize=5, edgecolor='k')
plt.ylabel(r"Morris $\mu^{\ast}$ ($\pm\,\sigma$)", fontsize=16)
plt.xticks(rotation=0, ha='center', fontsize=16)
plt.yticks(fontsize=16)
plt.tight_layout()
plt.savefig("sensitivity_tff.png", dpi=300)
plt.show()






# import numpy as np
# import matplotlib.pyplot as plt
# from SALib.sample import morris as morris_sample
# from SALib.analyze import morris as morris_analyze
# from schemas import MembraneInput
# from matlab_interface import run_membrane_model

# # 1) Define the Membrane sensitivity problem: varying qF, D, and c0_mRNA
# names = ['qF', 'D', 'c0_mRNA']
# bounds = [
#     [2.0, 5.0],    # Feed flow rate qF [mL/min]
#     [4.0, 5.0],    # Buffer wash flow D [mL/min]
#     [0.8, 1.2]     # Initial mRNA concentration c0_mRNA [mg/mL]
# ]
# problem = {'num_vars': len(names), 'names': names, 'bounds': bounds}

# # 2) Nominal settings for unchanged inputs
# nominal = {
#     'c0_protein': 1.0,    # mg/mL
#     'c0_ntps': 1.0,       # mg/mL
#     'X': 0.90,            # conversion fraction
#     'n_stages': 3,        # fixed number of TFF stages
#     'filterType': 'NOVIBRO'  # valid filter type
# }

# # 3) Generate Morris samples
# param_values = morris_sample.sample(
#     problem,
#     N=30,
#     num_levels=4,
#     optimal_trajectories=10
# )

# # 4) Run model and collect final TFF mRNA for last stage
# y_tff_mrna = np.zeros(len(param_values))
# for i, xi in enumerate(param_values):
#     params = dict(zip(names, xi))
#     params.update(nominal)
#     inp = MembraneInput(**params)
#     try:
#         out = run_membrane_model(
#             inp.qF,
#             inp.c0_mRNA,
#             inp.c0_protein,
#             inp.c0_ntps,
#             inp.X,
#             inp.n_stages,
#             inp.D,
#             inp.filterType
#         )
#         # Extract last stage's final mRNA
#         last_stage_idx = inp.n_stages - 1
#         y_tff_mrna[i] = out['TFF_mRNA'][last_stage_idx][-1]
#     except Exception:
#         y_tff_mrna[i] = np.nan

# # 5) Clean up any NaNs and perform Morris analysis on valid samples
# mask = ~np.isnan(y_tff_mrna)
# X_valid = param_values[mask]
# y_valid = y_tff_mrna[mask]

# if len(y_valid) < len(y_tff_mrna):
#     print(f"Dropped {len(y_tff_mrna) - len(y_valid)} invalid samples due to simulation errors.")

# Si = morris_analyze.analyze(
#     problem,
#     X_valid,
#     y_valid,
#     num_levels=4,
#     print_to_console=False
# )
# mu_star, sigma = Si['mu_star'], Si['sigma']
# LABELS = {
#     'qF': r'$q_F$',
#     'D': r'$D$',
#     'c0_mRNA': r'$c_{0,\mathrm{mRNA}}$',
    
# }

# # 6) Visualization: Bar chart only
# plt.figure(figsize=(6, 4))
# # names1 = ['Input\nflow rate', 'Diafiltration\nflow rate', 'Input mRNA\nconcentration']
# plt.bar(LABELS, mu_star, yerr=sigma, capsize=5, edgecolor='k')
# plt.ylabel('Morris μ* (± σ)', fontsize=16)
# # plt.title('Membrane Sensitivity: mRNA concentration', fontsize=16)
# plt.xticks(rotation=0, ha='center', fontsize=16)
# plt.yticks(fontsize=16)
# plt.tight_layout()
# plt.savefig("sensitivity_tff.png", dpi=300)
# plt.show()
