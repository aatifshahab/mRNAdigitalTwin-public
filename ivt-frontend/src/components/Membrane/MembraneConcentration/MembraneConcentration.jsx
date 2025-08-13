// src/components/Membrane/MembraneConcentration/MembraneConcentration.jsx
import React, { useState } from 'react';
import styles from './MembraneConcentration.module.css';
import MembraneVariableTag from '../MembraneVariableTag/MembraneVariableTag';

/*
  This sub-panel:
  1) Shows three tags: mRNA, Protein, NTPs
  2) Each tag is clickable => sets "species"
  3) Displays the last numeric value below each tag
  4) Has a dropdown for plot type => "OUTLET_VS_TIME" or "THREE_D"
*/

function MembraneConcentration({
  timePoints,
  xPositions,
  Cmatrix_mRNA,
  Cmatrix_protein,
  Cmatrix_ntps,
  onConcentrationSelection,
}) {
  const [selectedSpecies, setSelectedSpecies] = useState('mRNA');
  const [plotType, setPlotType] = useState('OUTLET_VS_TIME');

  // Helper: final row, final col => last numeric
  const getLastValuePDE = (matrix) => {
    if (!matrix || !matrix.length) return '--';
    const numRows = matrix.length;
    const numCols = matrix[0].length;
    if (!numCols) return '--';
    const val = matrix[numRows - 1][numCols - 1];
    if (typeof val === 'number') return val.toFixed(3);
    return '--';
  };

  const lastValue_mRNA = getLastValuePDE(Cmatrix_mRNA);
  const lastValue_protein = getLastValuePDE(Cmatrix_protein);
  const lastValue_ntps = getLastValuePDE(Cmatrix_ntps);

  // Notifying parent
  const notifyParent = (species, type) => {
    onConcentrationSelection({ species, plotType: type });
  };

  const handleSpeciesClick = (species) => {
    setSelectedSpecies(species);
    notifyParent(species, plotType);
  };

  const handlePlotChange = (e) => {
    const newType = e.target.value;
    setPlotType(newType);
    notifyParent(selectedSpecies, newType);
  };

  return (
    <div className={styles.concentrationPanel}>
      <h2 className={styles.header}>Concentration Step</h2>

      <div className={styles.speciesRow}>
        {/* mRNA */}
        <div className={styles.speciesBox}>
          <MembraneVariableTag
            name="mRNA"
            value="" // The numeric is shown below, not in the tag
            isSelected={selectedSpecies === 'mRNA'}
            onTagClick={() => handleSpeciesClick('mRNA')}
          />
          <div className={styles.valueLabel}>{lastValue_mRNA} mg/mL</div>
        </div>

        {/* Protein */}
        <div className={styles.speciesBox}>
          <MembraneVariableTag
            name="Protein"
            value=""
            isSelected={selectedSpecies === 'Protein'}
            onTagClick={() => handleSpeciesClick('Protein')}
          />
          <div className={styles.valueLabel}>{lastValue_protein} mg/mL</div>
        </div>

        {/* NTPs */}
        <div className={styles.speciesBox}>
          <MembraneVariableTag
            name="NTPs"
            value=""
            isSelected={selectedSpecies === 'NTPs'}
            onTagClick={() => handleSpeciesClick('NTPs')}
          />
          <div className={styles.valueLabel}>{lastValue_ntps} mg/mL</div>
        </div>
      </div>

      <div className={styles.plotTypeRow}>
        <label className={styles.label}>Plot Type:</label>
        <select
          value={plotType}
          onChange={handlePlotChange}
          className={styles.plotSelect}
        >
          <option value="OUTLET_VS_TIME">Outlet vs. Time</option>
          <option value="THREE_D">3D Surface (x vs t)</option>
        </select>
      </div>
    </div>
  );
}

export default MembraneConcentration;
