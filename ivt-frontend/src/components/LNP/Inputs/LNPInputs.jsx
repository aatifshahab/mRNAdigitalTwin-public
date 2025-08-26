// src/components/LNP/Inputs/LNPInputs.jsx

import React from 'react';
import styles from './LNPInputs.module.css';
import LNPVariableTag from '../Tags/LNPVariableTag'; // Ensure the path is correct
import { labelMapping } from '../../utilits/labelMapping';

function LNPInputs({ inputs, handleInputChange }) {
  // Define input units
  const inputUnits = {
    Residential_time: 's',
    FRR: '',
    pH: '',
    Ion: 'M',
    TF: 'ml/min',
    C_lipid: 'mg/ml', 
    mRNA_in: 'mg/ml',
  };

  return (
    <div className={styles.inputsContainer}>
      <h2 className={styles.title}>Inputs</h2>

      {Object.keys(inputs).map((key) => {
        // const displayName = key.replace('_', ' '); 
        const displayName = labelMapping[key] || key.replace(/_/g, ' ');
        const unit = inputUnits[key] || '';

        return (
          <div key={key} className={styles.inputItem}>
            {/* Variable Tag */}
            <LNPVariableTag
              name={displayName}
              isSelected={false} 
              onTagClick={() => {}}
            />

            {/* Input Field with Unit */}
            <div className={styles.inputWithUnit}>
              <input
                type="number"
                name={key}
                value={inputs[key]}
                onChange={handleInputChange}
                className={styles.numberInput}
                min="0"
                step="0.1"
              />
              {/* Display unit if it exists */}
              {unit && <span className={styles.unitLabel}>{unit}</span>}
            </div>
          </div>
        );
      })}
    </div>
  );
}

export default LNPInputs;
