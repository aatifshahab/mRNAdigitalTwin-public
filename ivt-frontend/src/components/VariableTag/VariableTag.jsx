// src/components/VariableTag.jsx

import React from 'react';
import './VariableTag.css';
import { labelMapping } from '../utilits/labelMapping'; // Adjust the path if necessary
import { formatNumber } from '../utilits/formatNumber'; // Import formatNumber

function VariableTag({ name, value, unit, onTagClick, isSelected }) {
  // Get the frontend label using the mapping
  const displayName = labelMapping[name] || name;

  // Function to format value
  const formatValue = (val) => {
    if (typeof val === 'number' && val > 1) {
      return val.toFixed(2);
    }
    return formatNumber(val); // Use formatNumber for consistency
  };

  return (
    <div className="variable-tag-container">
      <div
        className={`variable-tag ${isSelected ? 'selected' : ''}`}
        onClick={onTagClick}
        tabIndex="0"
        role="button"
        aria-pressed={isSelected}
        onKeyPress={(e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            onTagClick();
          }
        }}
      >
        {displayName}
      </div>
      <div className="variable-value">
        {formatValue(value)} {unit}
      </div>
    </div>
  );
}

export default VariableTag;
