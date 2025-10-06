import os
import sys
import logging
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

# SALib (pip install SALib)
from SALib.sample import morris as morris_sample
from SALib.analyze import morris as morris_analyze


logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


# -----------------------------------------------------------------------------
# 1) import backend.matlab_interface from *any* working dir
# -----------------------------------------------------------------------------
def _ensure_backend_on_path():
    """
    Search upward from CWD for a folder literally named 'backend'.
    If found, append its parent to sys.path so 'backend' becomes importable.
    """
    here = Path.cwd().resolve()
    # Allow overriding via env var 
    env = os.environ.get("DIGITAL_TWIN_BACKEND")
    if env and (Path(env) / "matlab_interface.py").exists():
        parent = Path(env).resolve().parent
        if str(parent) not in sys.path:
            sys.path.insert(0, str(parent))
        return

    for p in [here] + list(here.parents):
        cand = p / "backend"
        if cand.is_dir() and (cand / "matlab_interface.py").exists():
            if str(p) not in sys.path:
                sys.path.insert(0, str(p))
            return

_ensure_backend_on_path()

# import  wrapper
from backend.matlab_interface import run_cctc_model  # noqa: E402


# -----------------------------------------------------------------------------
# 2) Define the Morris problem
#    Names are the knobs we vary; bounds are physical ranges.
#    Note: C_in is used to set the required 'states0_last_value' (g/L).
# -----------------------------------------------------------------------------
problem = {
    "num_vars": 5,
    "names": ["C_in", "qmax", "K_ad_L", "k_ad", "phi"],
    "bounds": [
        [0.4, 0.6],   # C_in  (g/L) feed mRNA (== mg/mL numerically)
        [1.5, 3.0],   # qmax  (g/L_resin)
        [0.05, 0.2],  # K_ad_L (L/g)
        [0.01, 0.2],  # k_ad  (1/s)
        [0.20, 0.40], # phi   (–)
    ],
}

# -----------------------------------------------------------------------------
# 3) Sampling (Morris)
# -----------------------------------------------------------------------------
def sample_parameters(N=30, num_levels=4, optimal_trajectories=10, seed=123):
    rng = np.random.default_rng(seed)
    # SALib's morris uses numpy's global RNG; seed for reproducibility
    np.random.seed(seed)
    X = morris_sample.sample(
        problem,
        N=N,
        num_levels=num_levels,
        optimal_trajectories=optimal_trajectories,
    )
    logging.info(f"Generated {len(X)} samples for Morris screening.")
    return X

# -----------------------------------------------------------------------------
# 4) Model evaluation via MATLAB wrapper
#    We use final bound_mRNA as the scalar response y.
# -----------------------------------------------------------------------------
def evaluate_samples(X):
    """
    X: (n_samples, num_vars)
    Returns y: (n_samples,) with final bound_mRNA as scalar response.
    """
    y = np.zeros(len(X), dtype=float)

    for i, row in enumerate(X):
        # Map row -> dict of parameters
        C_in, qmax, K_ad_L, k_ad, phi = [float(v) for v in row]

        try:
            # states0_last_value is required; pass others as overrides
            result = run_cctc_model(
                states0_last_value=C_in,
                qmax=qmax,
                K_ad_L=K_ad_L,
                k_ad=k_ad,
                phi=phi,
            )

            # Expect dict with arrays: "time", "unbound_mRNA", "bound_mRNA"
            bound = result.get("bound_mRNA", [])
            if not bound:
                raise ValueError("Empty 'bound_mRNA' returned.")

            y[i] = float(bound[-1])  
        except Exception as e:
            logging.warning(f"Sample {i} failed: {e}")
            y[i] = np.nan

    return y

# -----------------------------------------------------------------------------
# 5) Run Morris analysis (handle NaNs conservatively)
# -----------------------------------------------------------------------------
def run_morris_analysis(X, y, num_levels=4):
    valid = ~np.isnan(y)
    Xv = X[valid]
    yv = y[valid]

    if len(Xv) < len(X):
        logging.warning(f"Dropped {np.sum(~valid)} samples due to evaluation failures.")

 
    Si = morris_analyze.analyze(
        problem,
        Xv,
        yv,
        num_levels=num_levels,
        print_to_console=True,
    )
    return Si

# -----------------------------------------------------------------------------
# 6) Plotting helper
# -----------------------------------------------------------------------------
def plot_morris(Si, outfile="cctc_sensitivity1.png"):
    labels = [
        r"$C_{\mathrm{in}}$",  # inlet mRNA concentration
        r"$q_{\max}$",         # resin capacity
        r"$K_{\mathrm{ad}}$",  # adsorption equilibrium constant
        r"$k_{\mathrm{ad}}$",  # adsorption rate constant
        r"$\phi$",             # bed void fraction
    ]
    mu_star = Si["mu_star"]
    sigma = Si["sigma"]

    plt.figure(figsize=(6, 4))
    plt.bar(labels, mu_star, yerr=sigma, capsize=5, edgecolor="k")
    plt.ylabel(r"Morris $\mu^*$ (± $\sigma$)", fontsize=14)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.tight_layout()
    plt.savefig(outfile, dpi=300)
    logging.info(f"Saved: {outfile}")
    plt.show()

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    N = 30
    num_levels = 4
    optimal_traj = 10
    seed = 123

    X = sample_parameters(N=N, num_levels=num_levels, optimal_trajectories=optimal_traj, seed=seed)
    y = evaluate_samples(X)
    Si = run_morris_analysis(X, y, num_levels=num_levels)
    plot_morris(Si, outfile="cctc_sensitivity1.png")
