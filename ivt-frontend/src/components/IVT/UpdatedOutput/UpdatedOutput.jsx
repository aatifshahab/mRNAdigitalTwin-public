// src/components/IVT/UpdatedOutput/UpdatedOutput.jsx

import React from 'react';
import VariableTag from '../../VariableTag/VariableTag';
import styles from './UpdatedOutput.module.css';

function UpdatedOutput({ outputVariables, outputUnits, handleTagClick, selectedOutputVariable }) {
  // We only render the mRNA output here
  const name = 'mRNA';
  const values = outputVariables[name] || [];
  const raw = Array.isArray(values) ? values[values.length - 1] : values;
  const value = Number(raw);

  return (
    <div className={styles.container}>
      <h2 className={styles.title}>Output</h2>
      <div className={styles.variablesBox}>
        <VariableTag
          key={name}
          name={name}
          value={value}
          unit={outputUnits[name]}
          onTagClick={() => handleTagClick({ type: 'output', name })}
          isSelected={
            selectedOutputVariable &&
            selectedOutputVariable.type === 'output' &&
            selectedOutputVariable.name === name
          }
        />
      </div>
    </div>
  );
}

export default UpdatedOutput;