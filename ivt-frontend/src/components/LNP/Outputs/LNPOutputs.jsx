// src/components/LNP/Outputs/LNPOutputs.jsx

import React from 'react';
import styles from './LNPOutputs.module.css';
import LNPVariableTag from '../Tags/LNPVariableTag'; // Ensure the path is correct

function LNPOutputs({ outputs }) {
  return (
    <div className={styles.outputsContainer}>
      <h2 className={styles.title}>Outputs</h2>
      {/* <div className={styles.outputItem}>
        <LNPVariableTag
          name="Diameter"
          isSelected={false}
          onTagClick={() => {}}
        />
      </div>
      <div className={styles.outputItem}>
        <LNPVariableTag
          name="PSD"
          isSelected={false}
          onTagClick={() => {}}
        />
      </div> */}
      <div className={styles.outputItem}>
        <LNPVariableTag
          name="EE"
          isSelected={false}
          onTagClick={() => {}}
        />
        <span>{outputs.EE.toFixed(2) !== null ? outputs.EE.toFixed(2) : 'N/A'}</span>
      </div>
      <div className={styles.outputItem}>
        <LNPVariableTag
          name="Mass Fraction"
          isSelected={false}
          onTagClick={() => {}}
        />
        <span>{outputs.Fraction.toFixed(3) !== null ? outputs.Fraction.toFixed(3) : 'N/A'}</span>
      </div>
      {outputs.error && (
        <div className={styles.error}>
          <span>Error: {outputs.error}</span>
        </div>
      )}
    </div>
  );
}

export default LNPOutputs;
