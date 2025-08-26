// src/components/Lyo/Measured/LyoMeasured.jsx

import React from 'react';
import LyoTag from '../Tags/LyoTag';
import styles from './LyoMeasured.module.css';

function LyoMeasured({ lyoMeasured, selectedMeasuredVariable, setSelectedMeasuredVariable }) {
  // Define the specific measured variables to display
  const measuredKeys = ['operatingTemperature', 'operatingPressure'];

  // Function to handle tag click
  const handleTagClick = (label) => {
    setSelectedMeasuredVariable(label);
  };

  // Function to get the last value of a specific measured variable
  const getLastMeasuredValue = (key) => {
    const dataArray = lyoMeasured[key];
    if (Array.isArray(dataArray) && dataArray.length > 0) {
      return dataArray[dataArray.length - 1];
    }
    return 'N/A';
  };

  // Function to format labels from camelCase to Title Case
  const formatLabel = (key) => {
    return key.replace(/([A-Z])/g, ' $1').replace(/^./, (str) => str.toUpperCase());
  };

  return (
    <div className={styles.measured}>
      <h2 className={styles.header}>Measured Variables</h2>
      <div className={styles.measuredTags}>
        {measuredKeys.map((key) => (
          <div key={key} className={styles.tagContainer}>
            <LyoTag
              label={formatLabel(key)}
              isSelected={selectedMeasuredVariable === formatLabel(key)}
              onClick={() => handleTagClick(formatLabel(key))}
              readOnly={false}
            />
            <div className={styles.value}>
              {getLastMeasuredValue(key)} {key === 'operatingTemperature' ? 'K' : 'kPa'}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default LyoMeasured;
