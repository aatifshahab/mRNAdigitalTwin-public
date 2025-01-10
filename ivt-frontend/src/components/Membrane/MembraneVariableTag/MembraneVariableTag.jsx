// src/components/Membrane/MembraneVariableTag/MembraneVariableTag.jsx
import React from 'react';
import styles from './MembraneVariableTag.module.css';

function MembraneVariableTag({
  name,
  value,
  unit,
  isSelected,
  onTagClick,
}) {
  // Numeric vs. string check
  const displayValue =
    typeof value === 'number' ? value.toString() : (value || '').toString();

  return (
    <div
      className={`${styles.tagContainer} ${isSelected ? styles.selected : ''}`}
      onClick={onTagClick}
      role="button"
      tabIndex={0}
      onKeyPress={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          onTagClick();
        }
      }}
    >
      <div className={styles.tagName}>{name}</div>
      
    </div>
  );
}

export default MembraneVariableTag;
