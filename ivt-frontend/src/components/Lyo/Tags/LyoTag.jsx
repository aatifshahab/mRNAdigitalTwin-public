// src/components/Lyo/Tags/LyoTag.jsx

import React from 'react';
import styles from './LyoTag.module.css';

function LyoTag({ label, isSelected, onClick, readOnly }) {
  return (
    <div className={styles.tag}>
      {!readOnly ? (
        <div
          className={`${styles.label} ${isSelected ? styles.selected : ''}`}
          onClick={onClick}
          tabIndex="0"
          role="button"
          aria-pressed={isSelected}
          onKeyPress={(e) => {
            if (e.key === 'Enter' || e.key === ' ') {
              onClick();
            }
          }}
        >
          {label}
        </div>
      ) : (
        <div className={`${styles.label} ${styles.readOnly} ${isSelected ? styles.selected : ''}`}>
          {label}
        </div>
      )}
    </div>
  );
}

export default LyoTag;
