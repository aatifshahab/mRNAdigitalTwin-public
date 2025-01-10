// src/components/Lyo/Inputs/LyoInputs.jsx

import React from 'react';
import LyoTag from '../Tags/LyoTag';
import styles from './LyoInputs.module.css';

function LyoInputs({ lyoInputs, handleInputChange, selectedInputTag, setSelectedInputTag }) {
  return (
    <div className={styles.inputs}>
      <h2 className={styles.header}>Input Variables</h2>

      {/* Initial Temperature Inputs */}
      <div className={styles.inputSection}>
        <LyoTag
          label="Initial Temperature"
          isSelected={selectedInputTag === 'Initial Temperature'}
          onClick={() => setSelectedInputTag('Initial Temperature')}
          readOnly={false}
        />
        <div className={styles.inputGroup}>
          {/* Freezing */}
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="InitfreezingTemperature">Freezing</label>
            <div className={styles.inputWithUnit}>
              <input
                id="InitfreezingTemperature"
                type="number"
                value={lyoInputs.InitfreezingTemperature || ''}
                onChange={(e) => handleInputChange(e, 'InitfreezingTemperature')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>K</span>
            </div>
          </div>

          {/* Primary Drying */}
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="InitprimaryDryingTemperature">Primary Drying</label>
            <div className={styles.inputWithUnit}>
              <input
                id="InitprimaryDryingTemperature"
                type="number"
                value={lyoInputs.InitprimaryDryingTemperature || ''}
                onChange={(e) => handleInputChange(e, 'InitprimaryDryingTemperature')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>K</span>
            </div>
          </div>

          {/* Secondary Drying */}
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="InitsecondaryDryingTemperature">Secondary Drying</label>
            <div className={styles.inputWithUnit}>
              <input
                id="InitsecondaryDryingTemperature"
                type="number"
                value={lyoInputs.InitsecondaryDryingTemperature || ''}
                onChange={(e) => handleInputChange(e, 'InitsecondaryDryingTemperature')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>K</span>
            </div>
          </div>
        </div>
      </div>

      {/* Temperature Inputs */}
      <div className={styles.inputSection}>
        <LyoTag
          label="Temperature"
          isSelected={selectedInputTag === 'Temperature'}
          onClick={() => setSelectedInputTag('Temperature')}
          readOnly={false}
        />
        <div className={styles.inputGroup}>
          {/* Cold Gas (Freezing) */}
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="TempColdGasfreezing">Cold Gas (Freezing)</label>
            <div className={styles.inputWithUnit}>
              <input
                id="TempColdGasfreezing"
                type="number"
                value={lyoInputs.TempColdGasfreezing || ''}
                onChange={(e) => handleInputChange(e, 'TempColdGasfreezing')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>K</span>
            </div>
          </div>

          {/* Shelf (Primary Drying) */}
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="TempShelfprimaryDrying">Shelf (Primary Drying)</label>
            <div className={styles.inputWithUnit}>
              <input
                id="TempShelfprimaryDrying"
                type="number"
                value={lyoInputs.TempShelfprimaryDrying || ''}
                onChange={(e) => handleInputChange(e, 'TempShelfprimaryDrying')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>K</span>
            </div>
          </div>

          {/* Shelf (Secondary Drying) */}
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="TempShelfsecondaryDrying">Shelf (Secondary Drying)</label>
            <div className={styles.inputWithUnit}>
              <input
                id="TempShelfsecondaryDrying"
                type="number"
                value={lyoInputs.TempShelfsecondaryDrying || ''}
                onChange={(e) => handleInputChange(e, 'TempShelfsecondaryDrying')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>K</span>
            </div>
          </div>
        </div>
      </div>

      {/* Pressure Input */}
      <div className={styles.inputSection}>
        <LyoTag
          label="Pressure"
          isSelected={selectedInputTag === 'Pressure'}
          onClick={() => setSelectedInputTag('Pressure')}
          readOnly={false}
        />
        <div className={`${styles.inputGroup} ${styles.singleInput}`}>
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="Pressure">Pressure</label>
            <div className={styles.inputWithUnit}>
              <input
                id="Pressure"
                type="number"
                value={lyoInputs.Pressure || ''}
                onChange={(e) => handleInputChange(e, 'Pressure')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>kPa</span>
            </div>
          </div>
        </div>
      </div>

      {/* Mass Fraction of mRNA */}
      <div className={styles.inputSection}>
        <LyoTag
          label="Mass Fraction of mRNA"
          isSelected={selectedInputTag === 'Mass Fraction of mRNA'}
          onClick={() => setSelectedInputTag('Mass Fraction of mRNA')}
          readOnly={false}
        />
        <div className={`${styles.inputGroup} ${styles.singleInput}`}>
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="massFractionmRNA">Mass Fraction</label>
            <div className={styles.inputWithUnit}>
              <input
                id="massFractionmRNA"
                type="number"
                value={lyoInputs.massFractionmRNA || ''}
                onChange={(e) => handleInputChange(e, 'massFractionmRNA')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>kg/kg</span>
            </div>
          </div>
        </div>
      </div>

      {/* Volume of Fluid in Vial */}
      <div className={styles.inputSection}>
        <LyoTag
          label="Volume of Fluid in Vial"
          isSelected={selectedInputTag === 'Volume of Fluid in Vial'}
          onClick={() => setSelectedInputTag('Volume of Fluid in Vial')}
          readOnly={false}
        />
        <div className={`${styles.inputGroup} ${styles.singleInput}`}>
          <div className={styles.inputItem}>
            <label className={styles.label} htmlFor="volumeFluidVial">Volume</label>
            <div className={styles.inputWithUnit}>
              <input
                id="volumeFluidVial"
                type="number"
                value={lyoInputs.volumeFluidVial || ''}
                onChange={(e) => handleInputChange(e, 'volumeFluidVial')}
                step="any"
                className={styles.input}
              />
              <span className={styles.unit}>L</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default LyoInputs;
