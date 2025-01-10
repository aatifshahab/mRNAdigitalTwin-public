// src/components/Lyo/Graphs/LyoGraphs.jsx

import React from 'react';
import LyoGraph from './LyoGraph';
import styles from './LyoGraphs.module.css';

function LyoGraphs({ lyoOutputs, lyoMeasured, selectedOutputVariable, selectedMeasuredVariable }) {
  const { time, time1, time2, massOfIce, boundWater, productTemperature } = lyoOutputs;
  const { operatingTemperature, operatingPressure } = lyoMeasured;

  // Determine the end times of each phase
  const endTime1 = Array.isArray(time1) && time1.length > 0 ? time1[time1.length - 1] : 0;
  const endTime2 = Array.isArray(time2) && time2.length > 0 ? time2[time2.length - 1] : 0;
  const endTime3 = Array.isArray(time) && time.length > 0 ? time[time.length - 1] : endTime2; // Assuming endTime3 is the last time

  // Define phase labels
  const phaseLabels = ['Freezing', 'Primary Drying', 'Secondary Drying'];

  // Function to format labels from camelCase to Title Case
  const formatLabel = (key) => {
    return key.replace(/([A-Z])/g, ' $1').replace(/^./, (str) => str.toUpperCase());
  };

  return (
    <div className={styles.graphs}>
      <div className={styles.graphsContainer}>
        {/* Measured Variables Graph */}
        {selectedMeasuredVariable && (
          <div className={styles.graphSection}>
            <LyoGraph
              
              labels={time}
              datasets={[
                {
                  label: selectedMeasuredVariable,
                  data:
                    selectedMeasuredVariable === 'Operating Temperature'
                      ? operatingTemperature
                      : operatingPressure,
                  borderColor:
                    selectedMeasuredVariable === 'Operating Temperature'
                      ? 'rgba(128, 128, 128, 1)' // Gray
                      : 'rgba(105, 105, 105, 1)', // Dim Gray
                  backgroundColor:
                    selectedMeasuredVariable === 'Operating Temperature'
                      ? 'rgba(128, 128, 128, 0.2)'
                      : 'rgba(105, 105, 105, 0.2)',
                },
              ]}
              endTime1={endTime1}
              endTime2={endTime2}
              phaseLabels={phaseLabels}
            />
          </div>
        )}

        {/* Outputs Graph */}
        {selectedOutputVariable && (
          <div className={styles.graphSection}>
            <LyoGraph
              
              labels={time}
              datasets={[
                {
                  label: selectedOutputVariable,
                  data:
                    selectedOutputVariable === 'Mass Of Ice'
                      ? massOfIce
                      : selectedOutputVariable === 'Bound Water'
                      ? boundWater
                      : productTemperature,
                  borderColor:
                    selectedOutputVariable === 'Mass Of Ice'
                      ? 'rgba(169, 169, 169, 1)' // Dark Gray
                      : selectedOutputVariable === 'Bound Water'
                      ? 'rgba(105, 105, 105, 1)' // Dim Gray
                      : 'rgba(128, 128, 128, 1)', // Gray
                  backgroundColor:
                    selectedOutputVariable === 'Mass Of Ice'
                      ? 'rgba(169, 169, 169, 0.2)'
                      : selectedOutputVariable === 'Bound Water'
                      ? 'rgba(105, 105, 105, 0.2)'
                      : 'rgba(128, 128, 128, 0.2)',
                },
              ]}
              endTime1={endTime1}
              endTime2={endTime2}
              phaseLabels={phaseLabels}
            />
          </div>
        )}

        {/* 3D Plot Placeholder */}
        <div className={styles.graphSection}>
          <div className={styles.threeDPlaceholder}>
            <h3>3D Vial Distribution</h3>
            <p>3D Graph will be displayed here.</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default LyoGraphs;
