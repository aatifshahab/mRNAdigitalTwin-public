// src/components/CCTC/CCTCInputs/CCTCInputs.jsx

import React from 'react';
import CCTCTag from '../CCTCTags/CCTCTag';
import { formatNumber } from '../../utilits/formatNumber';
import './CCTCInputs.css';

function CCTCInputs({ cctcInputs, handleCCTCInputChange, selectedTag, setSelectedTag }) {
  // Handle tag click
  const handleTagClick = (label) => {
    setSelectedTag(label);
  };

  // Handle input change with formatting
  const handleFormattedInputChange = (e, key) => {
    let inputValue = e.target.value;

    // Convert value to number if not empty
    let numericValue = inputValue !== '' ? parseFloat(inputValue) : 0;

    // Format the number using formatNumber function
    let formattedValue = formatNumber(numericValue, 2);

    // Call the parent function to update the state with formatted value
    handleCCTCInputChange({ target: { value: numericValue } }, key);

    // Set the formatted value in the input field
    e.target.value = formattedValue;
  };

  return (
    <div className="cctc-inputs">
      <h2>Input Variables</h2>
      <div className="cctc-input-fields">
        {/* Flow Rate (F103) */}
        {/* <div className="cctc-input-item">
          <CCTCTag
            label="F103"
            
            isSelected={selectedTag === 'F103'}
            onClick={() => handleTagClick('F103')}
            readOnly={false}
          />
          <div className="cctc-input-wrapper">
            <input
              type="number"
              value={formatNumber(cctcInputs.F103, 2)}
              onChange={(e) => handleFormattedInputChange(e, 'F103')}
              step="any"
              min="0"
              className="cctc-input-field"
            />
            <span className="cctc-input-unit">L/hr</span>
          </div>
        </div> */}

        {/* Concentration of mRNA */}
        <div className="cctc-input-item">
          <CCTCTag
            label="mRNA"
            
            isSelected={selectedTag === 'mRNA'}
            onClick={() => handleTagClick('mRNA')}
            readOnly={false}
          />
          <div className="cctc-input-wrapper">
            <input
              type="number"
              value={formatNumber(cctcInputs.mRNA, 2)}
              onChange={(e) => handleFormattedInputChange(e, 'mRNA')}
              step="any"
              min="0"
              className="cctc-input-field"
            />
            <span className="cctc-input-unit">g/L</span>
          </div>
        </div>

        {/* Resin Concentration (Placeholder) */}
        <div className="cctc-input-item">
          <CCTCTag
            label="Resin"
            
            isSelected={selectedTag === 'resin'}
            onClick={() => handleTagClick('resin')}
            readOnly={true} // Non-interactive
          />
          <div className="cctc-input-wrapper">
            <input
              type="number"
              value={cctcInputs.resin}
              onChange={(e) => handleFormattedInputChange(e, 'resin')}
              step="any"
              min="0"
              className="cctc-input-field"
              placeholder="Coming Soon"
              disabled={true}
            />
            <span className="cctc-input-unit"></span>
          </div>
        </div>
      </div>
    </div>
  );
}

export default CCTCInputs;
