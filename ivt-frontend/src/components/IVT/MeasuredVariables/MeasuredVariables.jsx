// src/components/MeasuredVariables/MeasuredVariables.jsx

import React from 'react';
import VariableTag from '../../VariableTag/VariableTag';
import './MeasuredVariables.css';

function MeasuredVariables({
  measuredVariables,
  measuredUnits,
  handleTagClick,
  selectedMeasuredVariable,
}) {
  return (
    <div className="measured-variables-container">
      <h2>Measured Variables</h2>
      <div className="measured-variable-tags">
        {Object.keys(measuredVariables).map((name) => (
          <VariableTag
            key={name}
            name={name}
            value={
              Array.isArray(measuredVariables[name])
                ? measuredVariables[name][measuredVariables[name].length - 1]
                : measuredVariables[name]
            }
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
