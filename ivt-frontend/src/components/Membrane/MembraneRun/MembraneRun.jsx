// src/components/Membrane/MembraneRun/MembraneRun.jsx
import React from 'react';
import styles from './MembraneRun.module.css';

function MembraneRun({ runTime, setRunTime, handleRunMembrane }) {
  return (
    <div className={styles.runContainer}>
      <label className={styles.label}>Run Time (min):</label>
      <input
        type="number"
        value={runTime}
        onChange={(e) => setRunTime(parseFloat(e.target.value))}
        className={styles.inputField}
      />
      <button onClick={handleRunMembrane} className={styles.runButton}>
        Run Membrane Unit
      </button>
    </div>
  );
}

export default MembraneRun;
