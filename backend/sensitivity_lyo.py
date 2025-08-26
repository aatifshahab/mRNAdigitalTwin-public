# lyo_phasewise_morris_toggle.py
import matlab.engine
import numpy as np
import matplotlib.pyplot as plt
from SALib.sample import morris as morris_sample
from SALib.analyze import morris as morris_analyze
import os, logging

logging.basicConfig(level=logging.INFO)

# ========= USER SWITCH =========
# Choose which output to analyze globally:
#   "T"  -> phase mean Temperature
#   "BW" -> Bound water (Freezing/PD: phase mean; SD: residual moisture)
OUTPUT_MODE = "T"   # change to "BW" when you want moisture
# ==============================

# Pretty math labels for plotting
LABELS = {
    'TempColdGasfreezing':            r'$T_{b,1}$',   # freezing gas/shelf
    'TempShelfprimaryDrying':         r'$T_{b,2}$',
    'TempShelfsecondaryDrying':       r'$T_{b,3}$',
    'Pressure_kPa':                   r'$P$',
    'Rp0':                            r'$R_{p0}$',
    'Rp1':                            r'$R_{p1}$',
    'Rp2':                            r'$R_{p2}$',
    'hb2':                            r'$h_{b,2}$',
    'hb3':                            r'$h_{b,3}$',
    'fa':                             r'$f_{a}$',
    'Ea':                             r'$E_{a}$',
}

# Map OUTPUT_MODE -> per-phase metric key
def phase_output_key(mode, phase):
    if mode == "T":
        return {
            "Freezing":  "T_freezing_mean",
            "Primary":   "T_primary_mean",
            "Secondary": "T_secondary_mean",
        }[phase]
    elif mode == "BW":
        return {
            "Freezing":  "BW_freezing_mean",
            "Primary":   "BW_primary_mean",
            "Secondary": "BW_residual",     # residual moisture at end of SD
        }[phase]
    else:
        raise ValueError("OUTPUT_MODE must be 'T' or 'BW'")

# ---------------------------l
# MATLAB engine
# ---------------------------
_eng = None
def get_matlab_engine():
    global _eng
    if _eng is None:
        _eng = matlab.engine.start_matlab()
        backend = r'C:\Users\moha0095\mRNAdigitalTwin\backend'
        _eng.cd(backend, nargout=0)
        for sub in ['Lyo','cctc','membrane','LNP']:
            _eng.addpath(os.path.join(backend, sub), nargout=0)
        logging.info("MATLAB engine ready.")
    return _eng

# ---------------------------
# Nominals (sync with MATLAB)
# ---------------------------
NOM = dict(
    fluidVolume=3e-6,
    massFractionmRNA=0.05,
    InitfreezingTemperature=298.15,
    InitprimaryDryingTemperature=228.0,
    InitsecondaryDryingTemperature=273.0,
    TempColdGasfreezing=268.0,        # "Tb1"
    TempShelfprimaryDrying=270.0,     # Tb2
    TempShelfsecondaryDrying=295.0,   # Tb3
    Pressure_kPa=10.0,                # MATLAB multiplies by 1000 internally
    Rp0=1.5e4,                        # m/s
    Rp1=3.0e7,                        # 1/s
    Rp2=1.0e1,                        # 1/m
    hb2=15.0,                         # W/m^2-K
    hb3=15.0,                         # W/m^2-K
    fa=1.5e-3,                        # 1/s
    Ea=6500.0                         # J/mol
)

# ---------------------------
# Bounds (edit to validated ranges)
# ---------------------------
B = dict(
    # Freezing (narrow to avoid VISF corner cases)
    TempColdGasfreezing=[256.0, 270.0],
    # Primary
    TempShelfprimaryDrying=[260.0, 275.0],
    Pressure_kPa=[5.0, 15.0],
    Rp0=[NOM['Rp0']/10.0, NOM['Rp0']*10.0],
    Rp1=[NOM['Rp1']/10.0, NOM['Rp1']*10.0],
    hb2=[8.0, 30.0],
    # Secondary
    TempShelfsecondaryDrying=[290.0, 305.0],
    hb3=[8.0, 30.0],
    fa=[NOM['fa']/10.0, NOM['fa']*10.0],
    Ea=[5000.0, 8000.0],
)

# ---------------------------
# Call MATLAB (16 inputs, 9 outputs)
# ---------------------------
def call_matlab(params):
    eng = get_matlab_engine()
    p = {**NOM, **params}
    out = eng.LyoAppInterfaceWithParams(
        float(p['fluidVolume']),
        float(p['massFractionmRNA']),
        float(p['InitfreezingTemperature']),
        float(p['InitprimaryDryingTemperature']),
        float(p['InitsecondaryDryingTemperature']),
        float(p['TempColdGasfreezing']),
        float(p['TempShelfprimaryDrying']),
        float(p['TempShelfsecondaryDrying']),
        float(p['Pressure_kPa']),
        float(p['Rp0']),
        float(p['Rp1']),
        float(p['Rp2']),
        float(p['hb2']),
        float(p['hb3']),
        float(p['fa']),
        float(p['Ea']),
        nargout=9
    )
    # Validate quickly
    if (out is None) or (len(out) != 9):
        raise RuntimeError("MATLAB returned no outputs")
    t_all = np.asarray(out[3]).squeeze()
    T_all = np.asarray(out[6]).squeeze()
    if t_all.size < 2 or T_all.size < 1:
        raise RuntimeError("Empty time/productTemperature")
    return out

# ---------------------------
# Helpers: time-weighted mean, slicing, metrics
# ---------------------------
def tw_mean(x, t):
    t = np.asarray(t).squeeze(); x = np.asarray(x).squeeze()
    if x.size == 0: return np.nan
    if t.size < 2:  return float(np.mean(x))
    return float(np.trapezoid(x, t) / (t[-1] - t[0]))

def slice_phases(out):
    t1 = np.asarray(out[0]).squeeze()
    t2 = np.asarray(out[1]).squeeze()
    t3 = np.asarray(out[2]).squeeze()
    tall = np.asarray(out[3]).squeeze()
    bw   = np.asarray(out[5]).squeeze()
    T    = np.asarray(out[6]).squeeze()
    n1, n2 = len(t1), len(t2)
    F = slice(0, n1)
    P = slice(n1, n1+n2)
    S = slice(n1+n2, None)
    return dict(
        tF=tall[F], tP=tall[P], tS=tall[S],
        TF=T[F], TP=T[P], TS=T[S],
        BWF=bw[F], BWP=bw[P], BWS=bw[S],
        BWfinal=float(bw[-1]),
    )

def metrics_by_phase(out):
    seg = slice_phases(out)
    return dict(
        # Temperatures (time-weighted means)
        T_freezing_mean  = tw_mean(seg['TF'], seg['tF']),
        T_primary_mean   = tw_mean(seg['TP'], seg['tP']),
        T_secondary_mean = tw_mean(seg['TS'], seg['tS']),
        # Bound water
        BW_freezing_mean = tw_mean(seg['BWF'], seg['tF']),
        BW_primary_mean  = tw_mean(seg['BWP'], seg['tP']),
        BW_residual      = seg['BWfinal'],
    )

# ---------------------------
# Keep only complete Morris trajectories
# ---------------------------
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

# ---------------------------
# Generic Morris runner
# ---------------------------
def run_morris(phase, var_names, bounds, output_key, N=30, levels=4, opt_traj=10, make_plot=True):
    problem = {'num_vars': len(var_names), 'names': var_names, 'bounds': [bounds[v] for v in var_names]}
    X = morris_sample.sample(problem, N=N, num_levels=levels, optimal_trajectories=opt_traj)

    Y = np.zeros(len(X))
    for i, row in enumerate(X):
        try:
            params = {name: float(val) for name, val in zip(var_names, row)}
            out = call_matlab(params)
            Y[i] = metrics_by_phase(out)[output_key]
        except Exception as e:
            logging.warning(f"{phase} sample {i} failed: {e}")
            Y[i] = np.nan

    Xc, Yc = keep_complete_trajectories(X, Y, problem['num_vars'])
    if len(Yc) == 0:
        raise RuntimeError(f"No complete trajectories for {phase}/{output_key}. Check bounds or model robustness.")

    Si = morris_analyze.analyze(problem, Xc, Yc, num_levels=levels, print_to_console=True)

    if make_plot:
        tick_labels = [LABELS.get(n, n) for n in var_names]
        plt.figure(figsize=(7.2, 4.2))
        plt.bar(tick_labels, Si['mu_star'], yerr=Si['sigma'], capsize=5, edgecolor='k')
        plt.ylabel(r"Morris $\mu^*$ (± σ)", fontsize=16)
        # plt.title(f"{phase}: {output_key}", fontsize=16)
        plt.xticks(fontsize=16)
        plt.yticks(fontsize=16)
        plt.tight_layout()
        fname = f"{phase.lower()}_{output_key}.png"
        plt.savefig(fname, dpi=300); plt.close()
        print("Saved:", fname)
    else:
        # Freeze: print a clean text summary instead of saving a plot
        import pandas as pd
        summary = pd.DataFrame({
            'mu': Si['mu'], 'mu_star': Si['mu_star'],
            'sigma': Si['sigma'], 'mu_star_conf': Si['mu_star_conf']
        }, index=var_names)
        print(f"\n=== {phase} — {output_key} (text summary) ===")
        print(summary, "\n")

    return Si

# ---------------------------
# RUN (Freezing printed; PD & SD plotted) 
# ---------------------------
if __name__ == "__main__":
    # Which metric per phase?
    fk = phase_output_key(OUTPUT_MODE, "Freezing")
    pk = phase_output_key(OUTPUT_MODE, "Primary")
    sk = phase_output_key(OUTPUT_MODE, "Secondary")

    # Freezing: one input, no plot -> text summary only
    run_morris("Freezing", ["TempColdGasfreezing"], B, fk, make_plot=False)

    # Primary: plot
    run_morris("Primary", ["TempShelfprimaryDrying","Rp0","Rp1","hb2","Pressure_kPa"], B, pk, make_plot=True)

    # Secondary: plot
    run_morris("Secondary", ["TempShelfsecondaryDrying","fa","Ea","hb3"], B, sk, make_plot=True)



# # lyo_morris_sensitivity_linear_Rp.py
# import matlab.engine
# import numpy as np
# import matplotlib.pyplot as plt
# from SALib.sample import morris as morris_sample
# from SALib.analyze import morris as morris_analyze
# import os, logging

# logging.basicConfig(level=logging.INFO)

# # Choose scalar metric: "mean_Tprod", "max_Tprod", "final_boundWater"
# METRIC = "mean_Tprod"

# # ---------------------------
# # MATLAB engine bootstrap
# # ---------------------------
# eng = None
# def get_matlab_engine():
#     global eng
#     if eng is None:
#         eng = matlab.engine.start_matlab()
#         backend = r'C:\Users\moha0095\mRNAdigitalTwin\backend'
#         eng.cd(backend, nargout=0)
#         for sub in ['Lyo', 'cctc', 'membrane', 'LNP']:
#             eng.addpath(os.path.join(backend, sub), nargout=0)
#         logging.info("MATLAB engine ready.")
#     return eng

# # ---------------------------
# # Fixed (nominal) inputs
# # ---------------------------
# nominal = {
#     'fluidVolume':             3e-6,   # m^3
#     'massFractionmRNA':        0.05,   # -
#     'TempColdGasfreezing':     268.0,  # K
#     'TempShelfprimaryDrying':  270.0,  # K
#     'TempShelfsecondaryDrying':295.0   # K
# }
# # MATLAB multiplies Pressure by 1000 (kPa -> Pa). Keep bounds here in kPa.

# # ---------------------------
# # Rp nominals and linear bounds (±1 decade: 0.1× to 10× nominal)
# # ---------------------------
# Rp0_nom, Rp1_nom, Rp2_nom = 1.5e4, 3e7, 1e1  # (m/s), (1/s), (1/m)
# Rp0_bounds = [Rp0_nom/100.0, Rp0_nom*100.0]    # [1.5e3, 1.5e5]
# Rp1_bounds = [Rp1_nom/100.0, Rp1_nom*100.0]    # [3e6, 3e8]
# Rp2_bounds = [Rp2_nom/100.0, Rp2_nom*100.0]    # [1e0, 1e2]

# # ---------------------------
# # SALib problem (linear sampling)
# # ---------------------------
# problem = {
#     'num_vars': 7,
#     'names': [
#         'InitfreezingTemperature',        # K
#         'InitprimaryDryingTemperature',   # K
#         'InitsecondaryDryingTemperature', # K
#         'Pressure_kPa',                   # kPa
#         'Rp0',                            # m/s
#         'Rp1',                            # 1/s
#         'Rp2'                             # 1/m
#     ],
#     'bounds': [
#         [228.15, 368.15],    # T_f,i
#         [198.00, 258.00],    # T_PD,i
#         [243.00, 303.00],    # T_SD,i
#         [5.00,   15.00],     # Pressure in kPa
#         Rp0_bounds,
#         Rp1_bounds,
#         Rp2_bounds
#     ]
# }

# # ---------------------------
# # Morris sampling
# # ---------------------------
# param_values = morris_sample.sample(
#     problem,
#     N=30,
#     num_levels=4,
#     optimal_trajectories=10
# )

# # ---------------------------
# # Metric helper
# # MATLAB returns:
# # (time1, time2, time3, time, massOfIce, boundWater, productTemperature, operatingPressure, operatingTemperature)
# # ---------------------------
# def compute_metric(out_tuple, metric: str) -> float:
#     import numpy as np
#     # Unpack MATLAB outputs
#     t1 = np.asarray(out_tuple[0]).squeeze()   # time1 (freezing)
#     t2 = np.asarray(out_tuple[1]).squeeze()   # time2 (primary)
#     t3 = np.asarray(out_tuple[2]).squeeze()   # time3 (secondary)
#     t  = np.asarray(out_tuple[3]).squeeze()   # combined time
#     mi = np.asarray(out_tuple[4]).squeeze()   # massOfIce (combined)
#     bw = np.asarray(out_tuple[5]).squeeze()   # boundWater (combined)
#     T  = np.asarray(out_tuple[6]).squeeze()   # productTemperature (combined)
#     Tb = np.asarray(out_tuple[8]).squeeze()   # operatingTemperature (combined)

#     # Indices for primary segment in concatenated arrays
#     n1, n2 = len(t1), len(t2)
#     i2s, i2e = n1, n1 + n2
#     t_primary  = t[i2s:i2e]
#     T_primary  = T[i2s:i2e]
#     Tb_primary = Tb[i2s:i2e]
#     mi_primary = mi[i2s:i2e]

#     if metric == "EOPD_time":
#         # Use time2 directly (primary-only clock)
#         return float(t2[-1] - t2[0])

#     elif metric == "mean_sublimation_rate_primary":
#         # Average -d(mi)/dt over primary (use gradient to handle nonuniform dt)
#         if len(t_primary) < 3: raise ValueError("Too few samples in primary")
#         rate = -np.gradient(mi_primary, t_primary)
#         return float(np.mean(rate))

#     elif metric == "mean_deltaT_primary":
#         return float(np.mean(T_primary - Tb_primary))

#     elif metric == "max_T_primary":
#         return float(np.max(T_primary))

#     elif metric == "final_T_secondary":
#         # last point of the whole run (end of secondary)
#         return float(T[-1])

#     elif metric == "mean_Tprod":
#         # simple overall mean 
#         return float(np.mean(T))

#     elif metric == "final_boundWater":
#         return float(bw[-1])

#     else:
#         raise ValueError(f"Unknown METRIC='{metric}'")


# # ---------------------------
# # Evaluate model
# # ---------------------------
# eng = get_matlab_engine()
# y = np.zeros(len(param_values))

# for i, x in enumerate(param_values):
#     try:
#         T_f_i, T_PD_i, T_SD_i, P_kPa, Rp0, Rp1, Rp2 = map(float, x)

#         out = eng.LyoAppInterfaceWithParams(
#             float(nominal['fluidVolume']),
#             float(nominal['massFractionmRNA']),
#             float(T_f_i),
#             float(T_PD_i),
#             float(T_SD_i),
#             float(nominal['TempColdGasfreezing']),
#             float(nominal['TempShelfprimaryDrying']),
#             float(nominal['TempShelfsecondaryDrying']),
#             float(P_kPa),
#             float(Rp0), float(Rp1), float(Rp2),
#             nargout=9
#         )

#         y[i] = compute_metric(out, METRIC)

#     except Exception as e:
#         logging.warning(f"Sample {i} failed: {e}")
#         y[i] = np.nan

# # Drop failed samples
# valid = np.isfinite(y)
# if not np.all(valid):
#     logging.info(f"Dropping {np.sum(~valid)} failed samples.")
# param_values = param_values[valid]
# y = y[valid]

# # ---------------------------
# # Morris analysis
# # ---------------------------
# Si = morris_analyze.analyze(
#     problem,
#     param_values,
#     y,
#     num_levels=4,
#     print_to_console=True
# )

# # ---------------------------
# # Plot μ* with σ error bars
# # ---------------------------
# labels = [
#     r'$T_{f,i}$',
#     r'$T_{PD,i}$',
#     r'$T_{SD,i}$',
#     r'$P$',
#     r'$R_{p0}$',
#     r'$R_{p1}$',
#     r'$R_{p2}$'
# ]

# plt.figure(figsize=(7.2, 4.2))
# plt.bar(labels, Si['mu_star'], yerr=Si['sigma'], capsize=5, edgecolor='k')
# plt.ylabel(r"Morris $\mu^*$ (± σ)", fontsize=16)
# plt.xticks(fontsize=14)
# plt.yticks(fontsize=14)
# plt.tight_layout()
# plt.savefig("lyo_sensitivity_mu_star_linearRpboundWater.png", dpi=300)
# plt.close()

# print("Saved: lyo_sensitivity_mu_star_linearRp.png")
