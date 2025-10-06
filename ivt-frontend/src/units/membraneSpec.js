// src/units/membraneSpec.js
export const MEMBRANE_FIELDS = [
  // Base
  { key: 'qF',        label: 'Feed flow rate',           symbol: 'qF',        unit: 'mL/min',  default: 1.0 },
  { key: 'c0_mRNA',   label: 'mRNA In',                  symbol: 'c₀,mRNA',   unit: 'mg/mL',   default: 1.0 },
  { key: 'c0_protein',label: 'Protein In',               symbol: 'c₀,prot',   unit: 'mg/mL',   default: 0.5 },
  { key: 'c0_ntps',   label: 'NTPs In',                  symbol: 'c₀,NTPs',   unit: 'mg/mL',   default: 0.5 },
  { key: 'X',         label: 'Conversion setpoint',      symbol: 'X',         unit: '',        default: 0.9 },
  { key: 'n_stages',  label: 'Stages',                   symbol: 'N',         unit: '',        default: 3 },
  { key: 'D',         label: 'Buffer flow',              symbol: 'D',         unit: 'mL/min',  default: 4 },
  { key: 'filterType',label: 'Filter type',              symbol: '',          unit: '',        default: 'VIBRO' },

  // Overrides (pre-filled to MATLAB defaults)
  { key: 'dt',        label: 'Time step',                symbol: 'Δt',        unit: 'min',     default: 1e-3 },   // VIBRO
  { key: 'tfinal',    label: 'PDE final time',           symbol: 't_final',   unit: 'min',     default: 24 },     // VIBRO
  { key: 'Diff',      label: 'Diffusivity',              symbol: 'D',         unit: 'cm²/min', default: 6e-7 },
  { key: 'VTFF',      label: 'TFF volume',               symbol: 'V_TFF',     unit: '',        default: 8 },
  { key: 'S',         label: 'Retention exponent',       symbol: 'S',         unit: '',        default: 0.45 },   // VIBRO

  // Vibro flux params
  { key: 'B',         label: 'VIBRO flux coeff',         symbol: 'B',         unit: '',        default: 18.3417 },
  { key: 'n_v',       label: 'VIBRO exponent',           symbol: 'n_v',       unit: '',        default: 0.8725 },

  // HF flux params (present but ignored unless filterType === 'HF')
  { key: 'L_HF',      label: 'HF coeff L',               symbol: 'L_HF',      unit: '',        default: 23.9960 },
  { key: 'K_HF',      label: 'HF coeff K',               symbol: 'K_HF',      unit: '',        default: 1.3333 },
  { key: 'n_HF',      label: 'HF exponent',              symbol: 'n_HF',      unit: '',        default: 16.3122 },
];

export function membraneDefaults() {
  const obj = {};
  MEMBRANE_FIELDS.forEach(f => { obj[f.key] = f.default; });
  return obj;
}

export function membraneLabelFor(key) {
  const f = MEMBRANE_FIELDS.find(x => x.key === key);
  return f ? `${f.label}${f.symbol ? ` (${f.symbol})` : ''}` : key;
}

export function buildMembranePayload(raw) {
  const out = {};
  for (const [k, v] of Object.entries(raw || {})) {
    if (v === '' || v === null || v === undefined) continue;
    if (k === 'filterType') { out[k] = String(v).toUpperCase(); continue; }
    const n = Number(v);
    out[k] = Number.isFinite(n) ? n : v;
  }
  return out;
}
