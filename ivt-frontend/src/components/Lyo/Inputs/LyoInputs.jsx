// src/components/Lyo/Inputs/LyoInputs.jsx
import React from 'react';
import LyoTag from '../Tags/LyoTag';
import styles from './LyoInputs.module.css';
import { LYO_SECTIONS } from '../../../units/lyoSpec';

function LyoInputs({ lyoInputs, handleInputChange, selectedInputTag, setSelectedInputTag }) {
  return (
    <div className={styles.inputs}>
      <h2 className={styles.header}>Input Variables</h2>

      {LYO_SECTIONS.map((section) => (
        <div key={section.title} className={styles.inputSection}>
          <LyoTag
            label={section.title}
            isSelected={selectedInputTag === section.title}
            onClick={() => setSelectedInputTag(section.title)}
            readOnly={false}
          />

          <div
            className={
              section.fields.length === 1
                ? `${styles.inputGroup} ${styles.singleInput}`
                : styles.inputGroup
            }
          >
            {section.fields.map((f) => (
              <div key={f.key} className={styles.inputItem}>
                <label className={styles.label} htmlFor={f.key}>{f.label}</label>
                <div className={styles.inputWithUnit}>
                  <input
                    id={f.key}
                    type="number"
                    value={lyoInputs[f.key] ?? ''}
                    onChange={(e) => handleInputChange(e, f.key)}
                    step="any"
                    className={styles.input}
                  />
                  <span className={styles.unit}>{f.unit || ''}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

export default LyoInputs;  // <-- important
