// src/components/RunPlant/RunPlant.jsx

import React from 'react';
import RunPlantButton from '../RunPlantButton/RunPlantButton';
import './RunPlant.css';

function RunPlant({ finalTime, handleFinalTimeChange, handleRunPlant }) {
  return (
    <div className="run-plant-section">
      <div className="final-time-input">
        <label htmlFor="finalTime">Simulation Time:</label>
        <input
          type="number"
          id="finalTime"
          value={finalTime}
          onChange={handleFinalTimeChange}
          step="any"
          min="0"
        />
        <span>hr</span>
      </div>
      <RunPlantButton onClick={handleRunPlant} />
    </div>
  );
}

export default RunPlant;
