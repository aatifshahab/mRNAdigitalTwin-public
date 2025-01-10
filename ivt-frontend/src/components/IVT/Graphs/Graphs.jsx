// src/components/Graphs/Graphs.jsx

import React from 'react';
import InputGraph from '../InputGraph/InputGraph';
import MeasuredVariableGraph from '../MeasuredVariableGraph/MeasuredVariableGraph';
import OutputVariableGraph from '../OutputVariableGraph/OutputVariableGraph';
import './Graphs.css';

function Graphs({
  selectedInputVariable,
  simulationResult,
  timeData,
  inputs,
  selectedMeasuredVariable,
  measuredVariables,
  measuredUnits,
  selectedOutputVariable,
  outputVariables,
  outputUnits,
  inputUnits,
}) {
  return (
    <div className="graphs">
      {/* Input Variables Graph */}
      <div className="graph-section">
        {selectedInputVariable && simulationResult && (
          <InputGraph
            inputName={selectedInputVariable.name}
            timeData={timeData}
            inputData={
              timeData.length > 0
                ? Array(timeData.length).fill(inputs[selectedInputVariable.name])
                : []
            }
            unit={inputUnits[selectedInputVariable.name]}
          />
        )}
      </div>

      {/* Measured Variables Graph */}
      <div className="graph-section">
        {selectedMeasuredVariable && simulationResult && (
          <MeasuredVariableGraph
            variableName={selectedMeasuredVariable.name}
            timeData={timeData}
            variableData={measuredVariables[selectedMeasuredVariable.name]}
            unit={measuredUnits[selectedMeasuredVariable.name]}
          />
        )}
      </div>

      {/* Output Variables Graph */}
      <div className="graph-section">
        {selectedOutputVariable && simulationResult && (
          <OutputVariableGraph
            variableName={selectedOutputVariable.name}
            timeData={timeData}
            variableData={outputVariables[selectedOutputVariable.name]}
            unit={outputUnits[selectedOutputVariable.name]}
          />
        )}
      </div>
    </div>
  );
}

export default Graphs;
