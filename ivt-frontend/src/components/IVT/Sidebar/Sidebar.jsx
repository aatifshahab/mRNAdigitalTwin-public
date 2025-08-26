import React from 'react';
import InputItem from '../InputItem/InputItem';
import styles from './Sidebar.module.css';

function Sidebar({ inputs, inputUnits, handleInputChange, handleTagClick, selectedInputVariable }) {
  return (
    <div className={styles.sidebar}>
      <h2 className={styles.title}>Input Variables</h2>
      <div className={styles.inputVariables}>
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