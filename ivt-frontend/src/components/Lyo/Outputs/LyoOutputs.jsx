// src/components/Lyo/Outputs/LyoOutputs.jsx

import React from 'react';
import LyoTag from '../Tags/LyoTag';
import styles from './LyoOutputs.module.css';

function LyoOutputs({ lyoOutputs, selectedOutputVariable, setSelectedOutputVariable }) {
  // Define the specific outputs to display
  const outputKeys = ['massOfIce', 'boundWater', 'productTemperature'];

  // Function to handle tag click
  const handleTagClick = (label) => {
    setSelectedOutputVariable(label);
  };

  // Function to get the last value of a specific output
  const getLastValue = (key) => {
    const dataArray = lyoOutputs[key];
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
    <div className={styles.outputs}>
      <h2 className={styles.header}>Outputs</h2>
      <div className={styles.outputTags}>
        {outputKeys.map((key) => (
          <div key={key} className={styles.tagContainer}>
            <LyoTag
              label={formatLabel(key)}
              isSelected={selectedOutputVariable === formatLabel(key)}
              onClick={() => handleTagClick(formatLabel(key))}
              readOnly={false}
            />
            <div className={styles.value}>
              {getLastValue(key)}{' '}
              {key === 'productTemperature'
                ? 'K'
                : key === 'massOfIce'
                ? 'kg'
                : 'kg water/kg solid'}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default LyoOutputs;
