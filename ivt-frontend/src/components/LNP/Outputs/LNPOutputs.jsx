// src/components/LNP/Outputs/LNPOutputs.jsx

import React from 'react';
import styles from './LNPOutputs.module.css';
import LNPVariableTag from '../Tags/LNPVariableTag'; // Ensure the path is correct

function LNPOutputs({ outputs }) {
  return (
    <div className={styles.outputsContainer}>
      <h2 className={styles.title}>Outputs</h2>

      <div className={styles.outputItem}>
        {/* Output Tag */}
        <LNPVariableTag
          name="Diameter"
          isSelected={false} // Set to true if you implement selection
          onTagClick={() => {}} // Implement if needed
        />
      </div>

      <div className={styles.outputItem}>
        <LNPVariableTag
          name="PSD"
          isSelected={false}
          onTagClick={() => {}}
        />
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
