// src/components/Membrane/MembraneDiafiltration/MembraneDiafiltration.jsx
import React, { useState } from 'react';
import styles from './MembraneDiafiltration.module.css';
import MembraneVariableTag from '../MembraneVariableTag/MembraneVariableTag';

/*
  Updated logic:
  1) Always show last numeric value for both Protein and NTPs 
     under their tags (independent of which is selected).
  2) Still allow user to click "Protein" or "NTPs" to select 
     which variable is graphed (via selectedVar).
  3) A stage dropdown controls which array index is used for
     computing each last value. 
*/

function MembraneDiafiltration({
  TFF_protein,
  TFF_ntps,
  td,
  onDiafiltrationSelection,
}) {
  // States
  const [selectedVar, setSelectedVar] = useState('Protein'); // "Protein" or "NTPs"
  const [selectedStage, setSelectedStage] = useState(1);

  // Determine how many stages we have
  const numStages = Math.max(TFF_protein.length, TFF_ntps.length);

  // Helper: final element in array => last numeric
  const getLastValueTFF = (array) => {
    if (!array || !array.length) return '--';
    const val = array[array.length - 1];
    if (typeof val === 'number') return val.toFixed(3);
    return '--';
  };

  // For the current stage, compute final values for both Protein and NTPs
  const currentProteinArray = TFF_protein[selectedStage - 1] || [];
  const currentNTPsArray = TFF_ntps[selectedStage - 1] || [];

  const lastValueProtein = getLastValueTFF(currentProteinArray);
  const lastValueNTPs = getLastValueTFF(currentNTPsArray);

  // Notifies parent whenever user changes variable or stage
  const notifyParent = (variable, stage) => {
    onDiafiltrationSelection({ variable, stage });
  };

  // Click handlers for variable selection
  const handleVarClick = (varName) => {
    setSelectedVar(varName);
    notifyParent(varName, selectedStage);
  };

  // Stage selection
  const handleStageChange = (e) => {
    const stg = parseInt(e.target.value, 10);
    setSelectedStage(stg);
    notifyParent(selectedVar, stg);
  };

  return (
    <div className={styles.diaPanel}>
      <h2 className={styles.header}>Diafiltration Step</h2>

      {/* Row with Protein and NTPs tags + final values */}
      <div className={styles.tagRow}>
        {/* Protein Box */}
        <div className={styles.tagBox}>
          <MembraneVariableTag
            name="Protein"
            value=""
            // isSelected => highlight if "Protein" is the chosen variable
            isSelected={selectedVar === 'Protein'}
            onTagClick={() => handleVarClick('Protein')}
          />
          {/* Show final numeric for Protein no matter selection */}
          <div className={styles.valueLabel}>
            {lastValueProtein} mg/mL
          </div>
        </div>

        {/* NTPs Box */}
        <div className={styles.tagBox}>
          <MembraneVariableTag
            name="NTPs"
            value=""
            isSelected={selectedVar === 'NTPs'}
            onTagClick={() => handleVarClick('NTPs')}
          />
          {/* Show final numeric for NTPs no matter selection */}
          <div className={styles.valueLabel}>
            {lastValueNTPs} mg/mL
          </div>
        </div>
      </div>

      {/* Stage selection dropdown */}
      <div className={styles.stageRow}>
        <label className={styles.label}>Stage:</label>
        <select
          className={styles.stageSelect}
          value={selectedStage}
          onChange={handleStageChange}
        >
          {Array.from({ length: numStages }, (_, i) => i + 1).map((stg) => (
            <option key={stg} value={stg}>
              Stage {stg}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}

export default MembraneDiafiltration;
