// src/components/LNP/Run/LNPRun.jsx

import React from 'react';
import styles from './LNPRun.module.css';

function LNPRun({ handleRun, isRunning }) {
  return (
    <div className={styles.runContainer}>
      <button
        className={styles.runButton}
        onClick={handleRun}
        disabled={isRunning}
      >
        {isRunning ? 'Running...' : 'Run LNP Simulation'}
      </button>
    </div>
  );
}

export default LNPRun;
