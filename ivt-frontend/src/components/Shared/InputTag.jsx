import React from 'react';
import './InputTag.css';

function InputTag({ name, onClick }) {
  return (
    <div className="input-tag" onClick={onClick}>
      {name}
    </div>
  );
}

export default InputTag;
