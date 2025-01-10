import React from 'react';
import './InputField.css';

function InputField({ name, value, unit, onChange }) {
  return (
    <div className="input-field">
      <label>{name}:</label>
      <input
        type="number"
        value={value}
        onChange={onChange}
        step="any"
        min="0"
      />
      <span>{unit}</span>
    </div>
  );
}

export default InputField;
