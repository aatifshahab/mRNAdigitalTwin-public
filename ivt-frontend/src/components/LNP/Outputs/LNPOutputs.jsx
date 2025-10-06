// src/components/LNP/Outputs/LNPOutputs.jsx

// src/components/LNP/Outputs/LNPOutputs.jsx

import React, { useState } from 'react';
import styles from './LNPOutputs.module.css';
import LNPVariableTag from '../Tags/LNPVariableTag';

function LNPOutputs({ outputs }) {
  // helpers
  const hasVal = (v) => v !== null && v !== undefined && isFinite(Number(v));
  const fmt2 = (v) => (hasVal(v) ? Number(v).toFixed(3) : '—');  
  const fmt3 = (v) => (hasVal(v) ? Number(v).toFixed(3) : '—');  

  const finalZavg = (() => {
    const arr = outputs?.Diameter || [];
    if (!arr.length) return '—';
    const last = arr[arr.length - 1]; // [time_s, Dz_nm]
    return Array.isArray(last) && last.length > 1 ? `${fmt2(last[1])} nm` : '—';
  })();

  // Dropdown for D-metrics
  const [dSelect, setDSelect] = useState('All');
  const dMap = {
    D10: outputs?.D10,
    D25: outputs?.D25,
    D50: outputs?.D50,
    D75: outputs?.D75,
    D90: outputs?.D90,
  };

  const renderDItem = (label) => {
    const v = dMap[label];
    return (
      hasVal(v) && (
        <div key={label} className={styles.outputItem}>
          <LNPVariableTag name={label} isSelected={false} onTagClick={() => {}} />
          <span>{`${fmt2(v)} nm`}</span>
        </div>
      )
    );
  };

  const renderDSection = () => {
    if (dSelect === 'All') {
      // Show in common order
      return (
        <>
          {renderDItem('D10')}
          {renderDItem('D25')}
          {renderDItem('D50')}
          {renderDItem('D75')}
          {renderDItem('D90')}
        </>
      );
    }
    return renderDItem(dSelect);
  };

  return (
    <div className={styles.outputsContainer}>
      <h2 className={styles.title}>Outputs</h2>

      <div className={styles.outputItem}>
        <LNPVariableTag name="EE" isSelected={false} onTagClick={() => {}} />
        <span>{fmt2(outputs?.EE)}</span>
      </div>

      <div className={styles.outputItem}>
        <LNPVariableTag name="Z-average (final)" isSelected={false} onTagClick={() => {}} />
        <span>{finalZavg}</span>
      </div>

      <div className={styles.outputItem}>
        <LNPVariableTag name="PDI" isSelected={false} onTagClick={() => {}} />
        <span>{fmt2(outputs?.PDI)}</span>
      </div>

      <div className={styles.outputItem}>
        <LNPVariableTag name="Mass Fraction Solids" isSelected={false} onTagClick={() => {}} />
        <span>{fmt3(outputs?.Fraction)}</span>
      </div>

      {/* D-metrics selector */}
      <div className={styles.outputItem}>
        <LNPVariableTag name="Percentiles" isSelected={false} onTagClick={() => {}} />
        <select
          value={dSelect}
          onChange={(e) => setDSelect(e.target.value)}
          aria-label="Select D-percentile to display"
        >
          <option value="All">All (D10, D25, D50, D75, D90)</option>
          <option value="D10">D10</option>
          <option value="D25">D25</option>
          <option value="D50">D50 (median)</option>
          <option value="D75">D75</option>
          <option value="D90">D90</option>
        </select>
      </div>
      {renderDSection()}

      {outputs?.error && (
        <div className={styles.error}>
          <span>Error: {outputs.error}</span>
        </div>
      )}
    </div>
  );
}

export default LNPOutputs;




{/*}
import React from 'react';
import styles from './LNPOutputs.module.css';
import LNPVariableTag from '../Tags/LNPVariableTag'; // Ensure the path is correct

function LNPOutputs({ outputs }) {
  return (
    <div className={styles.outputsContainer}>
      <h2 className={styles.title}>Outputs</h2>
      
      <div className={styles.outputItem}>
        <LNPVariableTag
          name="EE"
          isSelected={false}
          onTagClick={() => {}}
        />
        <span>{outputs.EE.toFixed(2) !== null ? outputs.EE.toFixed(2) : 'N/A'}</span>
      </div>
      <div className={styles.outputItem}>
        <LNPVariableTag
          name="Mass Fraction"
          isSelected={false}
          onTagClick={() => {}}
        />
        <span>{outputs.Fraction.toFixed(3) !== null ? outputs.Fraction.toFixed(3) : 'N/A'}</span>
      </div>
      {outputs.error && (
        <div className={styles.error}>
          <span>Error: {outputs.error}</span>
        </div>
      )}
    </div>
  );
}

export default LNPOutputs;*/}
