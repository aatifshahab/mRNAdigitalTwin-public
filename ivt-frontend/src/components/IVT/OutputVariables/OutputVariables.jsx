// src/components/OutputVariables/OutputVariables.jsx

import React from 'react';
import VariableTag from '../../VariableTag/VariableTag';
import './OutputVariables.css';

function OutputVariables({
  outputVariables,
  outputUnits,
  handleTagClick,
  selectedOutputVariable,
}) {
  return (
    <div className="output-variable-container">
      <h2>Output Variables</h2>
      <div className="variables-box">
        {Object.keys(outputVariables).map((name) => (
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
