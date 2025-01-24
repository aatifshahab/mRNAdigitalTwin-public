// src/components/IVT/InputItem.jsx

import React from 'react';
import './InputItem.css';
import { labelMapping } from '../../utilits/labelMapping'; // Adjust the path if necessary

function InputItem({ name, value, unit, onTagClick, onValueChange, isSelected }) {
  // Get the frontend label using the mapping
  const displayName = labelMapping[name] || name;

  return (
    <div className="input-item">
      <div
        className={`input-tag ${isSelected ? 'selected' : ''}`}
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
      <div className="input-field">
        <input
          type="number"
          value={value}
          onChange={onValueChange}
          step="any"
          min="0"
        />
        <span>{unit}</span>
      </div>
    </div>
  );
}

export default InputItem;
