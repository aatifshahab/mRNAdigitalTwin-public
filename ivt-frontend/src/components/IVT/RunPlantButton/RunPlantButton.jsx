import React from 'react';
import './RunPlantButton.css';

function RunPlantButton({ onClick }) {
  return (
    <button className="run-plant-button" onClick={onClick}>
      Run Plant
    </button>
  );
}

export default RunPlantButton;
