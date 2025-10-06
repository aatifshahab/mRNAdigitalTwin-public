// src/units/lyoSpec.js
export const LYO_SECTIONS = [
  { title: 'Initial Temperature', tag: 'Initial Temperature', fields: [
    { key: 'InitfreezingTemperature',  label: 'Freezing',            unit: 'K' },
    { key: 'InitprimaryDryingTemperature',   label: 'Primary Drying',    unit: 'K' },
    { key: 'InitsecondaryDryingTemperature', label: 'Secondary Drying',  unit: 'K' },
  ]},
  { title: 'Temperature', tag: 'Temperature', fields: [
    { key: 'TempColdGasfreezing',      label: 'Cold Gas (Freezing)',     unit: 'K' },
    { key: 'TempShelfprimaryDrying',   label: 'Shelf (Primary Drying)',  unit: 'K' },
    { key: 'TempShelfsecondaryDrying', label: 'Shelf (Secondary Drying)',unit: 'K' },
  ]},
  { title: 'Pressure', tag: 'Pressure', fields: [
    { key: 'Pressure', label: 'Pressure', unit: 'kPa' },
  ]},
  { title: 'Mass Fraction Solids', tag: 'Mass Fraction Solids', fields: [
    { key: 'massFractionSolids', label: 'Mass Fraction', unit: 'kg/kg' },
  ]},
  { title: 'Volume of Fluid in Vial', tag: 'Volume of Fluid in Vial', fields: [
    { key: 'fluidVolume', label: 'Volume', unit: 'L' },
  ]},
];

export const lyoDefaults = () =>
  Object.fromEntries([
    ['InitfreezingTemperature', 298.15],
    ['InitprimaryDryingTemperature', 228],
    ['InitsecondaryDryingTemperature', 273],
    ['TempColdGasfreezing', 268],
    ['TempShelfprimaryDrying', 270],
    ['TempShelfsecondaryDrying', 295],
    ['Pressure', 10],
    ['massFractionSolids', 0.05],
    ['fluidVolume', 3e-6],
  ]);

export function buildLyoPayload(inputs) {
  const out = {};
  for (const section of LYO_SECTIONS) {
    for (const f of section.fields) {
      const v = inputs[f.key];
      out[f.key] = v === '' || v == null ? undefined : Number(v);
    }
  }
  // alias safety
  if (inputs.volumeFluidVial != null && !Number.isNaN(Number(inputs.volumeFluidVial))) {
    out.fluidVolume = Number(inputs.volumeFluidVial);
  }
  return out;
}
