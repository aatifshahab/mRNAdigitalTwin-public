// src/components/IVT/Sidebar/Sidebar.jsx

import React from 'react';
import InputItem from '../InputItem/InputItem';
import './Sidebar.css';

function Sidebar({ inputs, inputUnits, handleInputChange, handleTagClick, selectedInputVariable }) {
  return (
    <div className="sidebar">
      <h2>Input Variables</h2>
      <div className="input-variables">
        {Object.keys(inputs).map((name) => (
          <InputItem
            key={name}
            name={name}
            value={inputs[name]}
            unit={inputUnits[name]}
            onValueChange={(e) => handleInputChange(e, name)}
            onTagClick={() => handleTagClick({ type: 'input', name })}
            isSelected={
              selectedInputVariable &&
              selectedInputVariable.type === 'input' &&
              selectedInputVariable.name === name
            }
          />
        ))}
      </div>
    </div>
  );
}

export default Sidebar;
