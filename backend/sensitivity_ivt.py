
import numpy as np
import matplotlib.pyplot as plt
from SALib.sample import morris as morris_sample
from SALib.analyze import morris as morris_analyze
from schemas import IVTInput
from julia_interface import run_ivt_process

# 1) Define the IVT sensitivity problem
names = ['T7RNAP', 'ATP', 'CTP', 'GTP', 'UTP', 'Mg']
bounds = [
    [0.5e-7, 1.5e-7],     # T7RNAP (nM)
    [0.0032*0.5, 0.0032*1.5],  # ATP (mM)
    [0.0032*0.5, 0.0032*1.5],  # CTP (mM)
    [0.0032*0.5, 0.0032*1.5],  # GTP (mM)
    [0.0032*0.5, 0.0032*1.5],  # UTP (mM)
    [0.008*0.5, 0.008*1.5]      # Mg (mM)
]
problem = { 'num_vars': len(names), 'names': names, 'bounds': bounds }

# 2) Nominal settings for unchanged inputs
nominal = { 'T7RNAP':1e-7,'ATP':0.0032,'CTP':0.0032,'GTP':0.0032,'UTP':0.0032,
            'Mg':0.008,'DNA':7.4,'Q':1.0,'V':2.0,'finaltime':2.0,'saveat_step':0.1 }

# 3) Sample using Morris design
param_values = morris_sample.sample(problem, N=50, num_levels=4, optimal_trajectories=10)

# 4) Run model for each sample and collect final RNA output
y = np.zeros(param_values.shape[0])
for i, xi in enumerate(param_values):
    params = dict(zip(names, xi))
    params.update({k: v for k,v in nominal.items() if k not in params})
    inp = IVTInput(**params)
    try:
        out = run_ivt_process(inp)
        y[i] = out['TotalRNAo'][-1]
    except:
        y[i] = np.nan

# 5) Perform Morris analysis
Si = morris_analyze.analyze(problem, param_values, y, num_levels=4, print_to_console=False)
mu_star, sigma = Si['mu_star'], Si['sigma']

# 6) Visualization: Bar chart only
plt.figure(figsize=(6, 4))
plt.bar(names, mu_star, yerr=sigma, capsize=5, edgecolor='k')
plt.ylabel('Morris μ* (± σ)', fontsize=16)
# plt.title('IVT Unit Sensitivity Analysis: NTPs, T7RNAP, Mg', fontsize=16)
plt.xticks(rotation=45, ha='right', fontsize=16)
plt.yticks(fontsize=16)
plt.tight_layout()
plt.savefig("sensitivity_ivt.png", dpi=300)
plt.show()
