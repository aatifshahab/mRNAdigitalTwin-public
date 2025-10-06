import logging
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

# adjust import path to where your function lives
from matlab_interface import run_cctc_model

def show(label, out):
    print(f"\n=== {label} ===")
    print(f"len(time) = {len(out['time'])}")
    print(f"final unbound = {out['unbound_mRNA'][-1]:.6g}")
    print(f"final  bound  = {out['bound_mRNA'][-1]:.6g}")

def main():
    # 1) Baseline (no overrides) — should work exactly like before
    out0 = run_cctc_model(0.5)
    show("BASELINE", out0)

    # 2) With overrides (2-arg call). Pick obvious changes so effect is visible.
    #    - larger qmax, faster k_ad, stronger K_ad_L
    #    - longer horizon and smaller dt if you like
    overrides = dict(
        qmax=5.0,        # capacity up
        k_ad=0.5,        # faster adsorption
        K_ad_L=2.0,      # higher affinity
        D_p=1e-10,       # keep same for now
        k_f=1e-5,        # keep same for now
        epsilonp=0.35,
        phi=0.40,
        Vbin_frac_1=0.2, Vbin_frac_2=0.3, Vbin_frac_3=0.5,  # sum ~1
        t_final_s=1200,  # run longer
        dt_s=60,
    )
    out1 = run_cctc_model(0.5, **overrides)
    show("OVERRIDES", out1)

    # 3) Sanity: final bound should generally increase when qmax/affinity increase
    delta = out1['bound_mRNA'][-1] - out0['bound_mRNA'][-1]
    print(f"\nΔ(final bound) = {delta:.6g}  (OVERRIDES - BASELINE)")

if __name__ == "__main__":
    main()
