// src/components/OutputVariables/OutputVariables.jsx
import React from 'react';
import VariableTag from '../../VariableTag/VariableTag';
import styles from './OutputVariables.module.css';

function OutputVariables({ outputVariables, outputUnits, handleTagClick, selectedOutputVariable }) {
  return (
    <div className={styles.container}>
      <h2 className={styles.title}>Output Variables</h2>
      <div className={styles.variablesBox}>
        {Object.keys(outputVariables)
          .filter(name => name === 'mRNA')
          .map(name => (
            <VariableTag
              key={name}
              name={name}
              value={
                Array.isArray(outputVariables[name])
                  ? outputVariables[name][outputVariables[name].length - 1]
                  : outputVariables[name]
              }
              unit={outputUnits[name]}
              onTagClick={() => handleTagClick({ type: 'output', name })}
              isSelected={
                selectedOutputVariable &&
                selectedOutputVariable.type === 'output' &&
                selectedOutputVariable.name === name
              }
            />
          ))}
      </div>
    </div>
  );
}

export default OutputVariables;
