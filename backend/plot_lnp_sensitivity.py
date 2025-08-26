# plot_sensitivity.py
import pickle
import matplotlib.pyplot as plt

# 1) Load cached sensitivity results
with open("lnp_sensitivity_cache1.pkl", "rb") as f:
    cache = pickle.load(f)
Si_mean = cache["Si_mean"]
Si_pdi  = cache["Si_pdi"]

# 2) Define your labels
xtick_labels = [
    r'$t_R$',  # Residence time
    r'FRR',
    r'pH',
    r'$I$',
    r'$TF$',
    r'$C_L$',
]

# 3) Plot mean diameter sensitivity
fig, ax = plt.subplots(figsize=(6, 4))
ax.bar(xtick_labels, Si_mean['mu_star'], 
       yerr=Si_mean['sigma'], capsize=5, edgecolor='k')

ax.set_ylabel(r"Morris $\mu^*$ (± σ)", fontsize=16)
ax.tick_params(axis='x', labelsize=16)      # x-tick font size
ax.tick_params(axis='y', labelsize=16)      # y-tick font size
plt.tight_layout()
fig.savefig("sensitivity_mean_diameter.png", dpi=300)

# 4) Plot PDI sensitivity
fig, ax = plt.subplots(figsize=(6, 4))
ax.bar(xtick_labels, Si_pdi['mu_star'], 
       yerr=Si_pdi['sigma'], capsize=5, edgecolor='k')

ax.set_ylabel(r"Morris $\mu^*$ (± σ)", fontsize=16)
ax.tick_params(axis='x', labelsize=16)
ax.tick_params(axis='y', labelsize=16)
plt.tight_layout()
fig.savefig("sensitivity_pdi.png", dpi=300)

plt.show()
