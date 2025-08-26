// src/components/Membrane/MembraneOutputs/MembraneOutputs.jsx
import React from 'react';
import styles from './MembraneOutputs.module.css';
import { labelMapping } from '../../utilits/labelMapping';
import MembraneVariableTag from '../MembraneVariableTag/MembraneVariableTag';

function MembraneOutputs({ outputs, handleTagClick, selectedOutputVar }) {
  const jcritKey = 'Jcrit';
  const xactualKey = 'Xactual';

  const jcritLabel = labelMapping[jcritKey] || jcritKey;
  const xactualLabel = labelMapping[xactualKey] || xactualKey;

  const jcritValue =
    typeof outputs.Jcrit === 'number' ? outputs.Jcrit.toFixed(3) : '--';
  const xactualValue =
    typeof outputs.Xactual === 'number' ? outputs.Xactual.toFixed(3) : '--';

  const jcritSelected =
    selectedOutputVar?.name === jcritKey && selectedOutputVar?.type === 'output';
  const xactualSelected =
    selectedOutputVar?.name === xactualKey &&
    selectedOutputVar?.type === 'output';

  return (
    <div className={styles.outputs}>
      <h2>Outputs</h2>
      <div className={styles.outputTags}>
        <MembraneVariableTag
          name={jcritLabel}
          value={jcritValue}
          unit="mL/m^2/min"
          isSelected={jcritSelected}
          onTagClick={() => handleTagClick({ type: 'output', name: jcritKey })}
        />

        <MembraneVariableTag
          name={xactualLabel}
          value={xactualValue}
          unit=""
          isSelected={xactualSelected}
          onTagClick={() =>
            handleTagClick({ type: 'output', name: xactualKey })
          }
        />
      </div>
    </div>
  );
}

export default MembraneOutputs;
