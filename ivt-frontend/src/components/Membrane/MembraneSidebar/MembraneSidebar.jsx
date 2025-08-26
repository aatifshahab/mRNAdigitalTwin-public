// src/components/Membrane/MembraneSidebar/MembraneSidebar.jsx

import React from 'react';
import styles from './MembraneSidebar.module.css';
import { labelMapping } from '../../utilits/labelMapping';
import MembraneVariableTag from '../MembraneVariableTag/MembraneVariableTag';

/*
  If you prefer, define units for each key in a separate file or inline here.
  For example:
*/
const inputUnits = {
  qF: 'mL/min',
  c0_mRNA: 'mg/mL',
  c0_protein: 'mg/mL',
  c0_ntps: 'mg/mL',
  X: '',
  n_stages: '',
  D: 'mL/min',
  // No unit for filterType, because it's a dropdown
};

function MembraneSidebar({
  inputs,
  handleInputChange,
  handleTagClick,
  selectedInputVar,
}) {
  return (
    <div className={styles.sidebar}>
      <h2 className={styles.title}>Inputs</h2>

      {Object.keys(inputs).map((key) => {
        const displayName = labelMapping[key] || key;
        const selected = selectedInputVar?.name === key;
        const value = inputs[key];

        // Retrieve units from the dictionary or use an empty string if not found
        const unit = inputUnits[key] || '';

        return (
          <div key={key} className={styles.inputItem}>
            {/* Clickable tag on the left */}
            <MembraneVariableTag
              name={displayName}
              value=""
              unit=""
              isSelected={selected}
              onTagClick={() => handleTagClick({ type: 'input', name: key })}
            />

            {/* Filter Type => dropdown, else numeric input + units */}
            {key === 'filterType' ? (
              <select
                value={value}
                onChange={(e) => handleInputChange(e, key)}
                className={styles.inputField}
              >
                <option value="HF">HF</option>
                <option value="VIBRO">VIBRO</option>
              </select>
            ) : (
              <div className={styles.inputWithUnit}>
                <input
                  type="number"
                  value={value}
                  onChange={(e) => handleInputChange(e, key)}
                  className={styles.numberInput}
                />
                {/* Show unit if it exists */}
                {unit && <span className={styles.unitLabel}>{unit}</span>}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

export default MembraneSidebar;
