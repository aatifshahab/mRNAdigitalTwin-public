// src/components/IVT/InputItem/InputItem.jsx

import React from 'react';
import styles from './InputItem.module.css';
import { labelMapping } from '../../utilits/labelMapping';

function InputItem({ name, value, unit, onTagClick, onValueChange, isSelected }) {
  const displayName = labelMapping[name] || name.replace(/_/g, ' ');

  return (
    <div className={styles.inputItem}>
      <div
        className={`${styles.inputTag} ${isSelected ? styles.selected : ''}`}
        onClick={onTagClick}
        tabIndex={0}
        role="button"
        aria-pressed={isSelected}
        onKeyPress={(e) => {
          if (e.key === 'Enter' || e.key === ' ') onTagClick();
        }}
      >
        {displayName}
      </div>
      <div className={styles.inputField}>
        <input
          type="number"
          value={value}
          onChange={onValueChange}
          step="any"
          min="0"
          className={styles.input}
        />
        <span className={styles.unit}>{unit}</span>
      </div>
    </div>
  );
}

export default InputItem;