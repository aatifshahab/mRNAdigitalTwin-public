// src/components/MeasuredVariables/MeasuredVariables.jsx
import React from 'react';
import VariableTag from '../../VariableTag/VariableTag';
import styles from './MeasuredVariables.module.css';

function MeasuredVariables({ measuredVariables, measuredUnits, handleTagClick, selectedMeasuredVariable }) {
  return (
    <div className={styles.container}>
      <h2 className={styles.title}>Measured Variables</h2>
      <div className={styles.tags}>
        {Object.keys(measuredVariables)
          .filter(name => name !== 'mRNA')
          .map(name => (
            <VariableTag
              key={name}
              name={name}
              value={Number(
                 Array.isArray(measuredVariables[name])
                   ? measuredVariables[name][measuredVariables[name].length - 1]
                   : measuredVariables[name]
               )}
              unit={measuredUnits[name]}
              onTagClick={() => handleTagClick({ type: 'measured', name })}
              isSelected={
                selectedMeasuredVariable &&
                selectedMeasuredVariable.type === 'measured' &&
                selectedMeasuredVariable.name === name
              }
            />
          ))}
      </div>
    </div>
  );
}

export default MeasuredVariables;