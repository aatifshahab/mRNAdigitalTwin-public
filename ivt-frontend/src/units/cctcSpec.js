// src/units/cctcSpec.js
// Single source of truth for CCTC inputs (labels, symbols, units, defaults, help).
// Keep names aligned with MATLAB 'overrides' keys.

export const CCTC_FIELDS = [
  // Feed concentration (also used to set states0_last_value)
  {
    key: "mRNA",
    label: "Feed mRNA concentration",
    symbol: "c_s,in",
    unit: "g/L",
    default: 0.5,
    desc: "Bulk mRNA entering the resin bed; used to populate states0_last_value.",
    min: 0
  },

  // Adsorption isotherm & kinetics
  { key: "qmax",     label: "Max capacity",           symbol: "q_max",   unit: "g/L_resin", default: 2.32,
    desc: "Langmuir capacity; raises the bound plateau.", min: 0 },
  { key: "K_ad_L",   label: "Affinity (Langmuir K)",  symbol: "K",       unit: "L/g",       default: 1.0,
    desc: "Langmuir affinity; higher means stronger binding.", min: 0 },
  { key: "k_ad",     label: "Adsorption rate",        symbol: "k_ad",    unit: "1/s",       default: 0.1,
    desc: "Kinetic rate toward isotherm; shapes breakthrough.", min: 0 },

  // Mass transfer
  { key: "D_p",      label: "Intraparticle diffusivity", symbol: "D_p",  unit: "m²/s",      default: 1e-10,
    desc: "Diffusion inside beads; lower slows equilibration.", min: 0 },
  { key: "k_f",      label: "Film transfer coefficient", symbol: "k_f",  unit: "m/s",       default: 1e-5,
    desc: "External mass transfer around beads; linked to flow.", min: 0 },

  // Porosities & bed voids
  { key: "epsilonp", label: "Particle porosity",       symbol: "ε_p",     unit: "–",        default: 0.35,
    desc: "Void fraction inside particles; affects accumulations.", min: 0, max: 0.9 },
  { key: "phi",      label: "Bed void fraction",       symbol: "φ",       unit: "–",        default: 0.40,
    desc: "Interstitial voids in the packed bed; affects cs balance.", min: 0, max: 0.9 },

  // Resin size-bin fractions (sum ≈ 1)
  { key: "Vbin_frac_1", label: "Resin size-bin 1",    symbol: "f₁",      unit: "–",        default: 0.15,
    desc: "Volume fraction of resin size bin 1.", min: 0 },
  { key: "Vbin_frac_2", label: "Resin size-bin 2",    symbol: "f₂",      unit: "–",        default: 0.15,
    desc: "Volume fraction of resin size bin 2.", min: 0 },
  { key: "Vbin_frac_3", label: "Resin size-bin 3",    symbol: "f₃",      unit: "–",        default: 0.15,
    desc: "Volume fraction of resin size bin 3.", min: 0 },

  // Time window (simulation controls)
  { key: "t_final_s", label: "Simulation horizon",     symbol: "t_final", unit: "s",        default: 500,
    desc: "End time for the simulation.", min: 1 },
  { key: "dt_s",      label: "Time step",              symbol: "Δt",      unit: "s",        default: 60,
    desc: "Integration step for output sampling.", min: 1 }
];

// Defaults object for state/init
export const cctcDefaults = () =>
  Object.fromEntries(CCTC_FIELDS.map(f => [f.key, f.default]));

// Normalize Vbin fractions if provided
export function normalizeVbin(payload) {
  const f1 = Number(payload?.Vbin_frac_1 ?? 0);
  const f2 = Number(payload?.Vbin_frac_2 ?? 0);
  const f3 = Number(payload?.Vbin_frac_3 ?? 0);
  const sum = f1 + f2 + f3;
  if (sum > 0) {
    payload.Vbin_frac_1 = f1 / sum;
    payload.Vbin_frac_2 = f2 / sum;
    payload.Vbin_frac_3 = f3 / sum;
  }
  return payload;
}

// Build the POST body (adds states0_last_value from mRNA)
export function buildCctcPayload(inputs) {
  const clean = {};
  for (const [k, v] of Object.entries(inputs || {})) {
    if (v === "" || v === null || v === undefined) continue;
    const num = Number(v);
    clean[k] = Number.isFinite(num) ? num : v; // keep numeric where possible
  }
  // states0_last_value is required by backend
  if (clean.mRNA !== undefined) clean.states0_last_value = clean.mRNA;
  return normalizeVbin(clean);
}
