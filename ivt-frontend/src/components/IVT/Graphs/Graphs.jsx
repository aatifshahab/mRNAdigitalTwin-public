import React from 'react';
import InputGraph from '../InputGraph/InputGraph';
import MeasuredVariableGraph from '../MeasuredVariableGraph/MeasuredVariableGraph';
import UpdatedOutputGraph from '../UpdatedOutputGraph/UpdatedOutputGraph';
import styles from './Graphs.module.css';

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
    <div className={styles.graphs}>
      {/* Input Variables Graph */}
      <div className={styles.graphSection}>
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
      <div className={styles.graphSection}>
        {selectedMeasuredVariable && simulationResult && (
          <MeasuredVariableGraph
            variableName={selectedMeasuredVariable.name}
            timeData={timeData}
            variableData={measuredVariables[selectedMeasuredVariable.name]}
            unit={measuredUnits[selectedMeasuredVariable.name]}
          />
        )}
      </div>

      {/* Updated Output Variables Graph (mRNA only) */}
      <div className={styles.graphSection}>
        {simulationResult && (
          <UpdatedOutputGraph
            timeData={timeData}
            outputVariables={outputVariables}
            outputUnits={outputUnits}
          />
        )}
      </div>
    </div>
  );
}

export default Graphs;