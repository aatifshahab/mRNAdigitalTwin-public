// src/components/LNP/Graphs/LNPGraphs.jsx

import React from 'react';
import styles from './LNPGraphs.module.css';

import LNPGraph from './LNPGraph';

function LNPGraphs({ outputs }) {
  // Destructure Diameter and PSD from outputs
  const { Diameter, PSD, error } = outputs;

  return (
    <div className={styles.graphsContainer}>
      

      <div className={styles.graphs}>
        {/* Graph 1: Diameter */}
        <div className={styles.graphSection}>
          <h3>Z-average Diameter</h3>
          {Diameter.length > 0 ? (
            <LNPGraph
              label="Diameter"
              xData={Diameter.map(item => item[0])}
              yData={Diameter.map(item => item[1])}
              xTitle="Time [sec]"
              yTitle="Z-average Diameter [nm]"
              // No axis limits for Diameter graph
            />
          ) : (
            <p>No Diameter data available.</p>
          )}
        </div>

        {/* Graph 2: PSD */}
        <div className={styles.graphSection}>
          <h3>Particle Size Distribution (PSD)</h3>
          {PSD.length > 0 ? (
            <LNPGraph
              label="PSD"
              xData={PSD.map(item => item[0])}
              yData={PSD.map(item => item[1])}
              xTitle="Particle size [nm]"
              yTitle="Intensity-based Population"
             
            />
          ) : (
            <p>No PSD data available.</p>
          )}
        </div>
      </div>

      {/* Display error if exists */}
      {error && (
        <div className={styles.error}>
          <span>Error: {error}</span>
        </div>
      )}
    </div>
  );
}

export default LNPGraphs;
