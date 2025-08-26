// src/components/CCTC/CCTCInputs/InputField.jsx

import React from 'react';
import './InputField.css';

function InputField({ label, value, onChange, unit, placeholder, disabled }) {
  return (
    <div className="cctc-input-field">
      <label className="cctc-input-label">{label}</label>
      <div className="cctc-input-wrapper">
        <input
          type="number"
          value={value}
          onChange={onChange}
          step="any"
          min="0"
          placeholder={placeholder}
          disabled={disabled}
        />
        <span className="cctc-input-unit">{unit}</span>
      </div>
    </div>
  );
}

export default InputField;
