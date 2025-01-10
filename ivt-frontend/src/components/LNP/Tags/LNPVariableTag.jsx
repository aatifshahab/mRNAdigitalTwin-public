// src/components/LNP/Tags/LNPVariableTag.jsx

import React from 'react';
import styles from './LNPVariableTag.module.css';

function LNPVariableTag({
  name,
  isSelected,
  onTagClick,
}) {
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

export default LNPVariableTag;
