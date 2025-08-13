import matlab.engine
import numpy as np
import matplotlib.pyplot as plt
from SALib.sample import morris as morris_sample
from SALib.analyze import morris as morris_analyze
import os, logging

logging.basicConfig(level=logging.INFO)

# 1) MATLAB engine setup
eng = None
def get_matlab_engine():
    global eng
    if eng is None:
        eng = matlab.engine.start_matlab()
        backend = r'C:\Users\moha0095\mRNAdigitalTwin\backend'
        eng.cd(backend, nargout=0)
        for sub in ['cctc','Lyo','membrane','LNP']:
            eng.addpath(os.path.join(backend, sub), nargout=0)
        logging.info("MATLAB engine ready.")
    return eng

# 2) Morris problem definition
problem = {
    'num_vars': 5,
    'names': ['C_in','qmax','K_ad_L','k_ad','phi'],
    'bounds': [
        [0.4, 0.6],   # C_in (g/mL)
        [1.5, 3.0],   # qmax (g/L resin)
        [0.05,0.2],   # K_ad_L (L/g)
        [0.01,0.2],   # k_ad (1/s)
        [0.2, 0.4]    # phi (–)
    ]
}

# 3) Sample
param_values = morris_sample.sample(problem, N=30, num_levels=4, optimal_trajectories=10)

# 4) Evaluate via MATLAB
eng = get_matlab_engine()
y = np.zeros(len(param_values))
for i, x in enumerate(param_values):
    try:
        # Unpack and call wrapper
        values = [float(v) for v in x]
        y[i] = eng.run_cctc_model_with_params(*values, nargout=1)
    except Exception as e:
        logging.warning(f"Sample {i} failed: {e}")
        y[i] = np.nan

# 5) Clean up NaNs
valid = ~np.isnan(y)
param_values = param_values[valid]
y = y[valid]

# 6) Morris analysis
Si = morris_analyze.analyze(problem, param_values, y, num_levels=4, print_to_console=True)

# -----------------------------------
# Plotting 
# -----------------------------------
labels = [
    r'$C_{\mathrm{in}}$',     # inlet mRNA concentration
    r'$q_{\mathrm{max}}$',    # resin capacity
    r'$K_{\mathrm{ad}}$',     # adsorption equilibrium constant
    r'$k_{\mathrm{ad}}$',     # adsorption rate constant
    r'$\phi$'                 # packing (solid) fraction
]

plt.figure(figsize=(6,4))
plt.bar(labels, Si['mu_star'], yerr=Si['sigma'], capsize=5, edgecolor='k')
plt.ylabel(r'Morris $\mu^*$ (± σ)',fontsize=16)
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.tight_layout()
plt.savefig("cctc_sensitivity.png", dpi=300)
plt.show()