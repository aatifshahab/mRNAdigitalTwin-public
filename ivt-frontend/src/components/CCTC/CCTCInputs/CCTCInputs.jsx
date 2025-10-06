// src/components/CCTC/CCTCInputs/CCTCInputs.jsx


import React from 'react';
import CCTCTag from '../CCTCTags/CCTCTag';
import './CCTCInputs.css';
import { CCTC_FIELDS } from '../../../units/cctcSpec';


function CCTCInputs({ cctcInputs, handleCCTCInputChange, selectedTag, setSelectedTag }) {
  const handleTagClick = (key) => setSelectedTag(key);

  return (
    <div className="cctc-inputs">
      <h2>Input Variables</h2>

      {/* 👇 This wrapper adds vertical scrolling without changing your layout */}
      <div className="cctc-inputs-scroll">
        <div className="cctc-input-fields">
          {CCTC_FIELDS.map((f) => {
            const labelText = f.symbol ? ` ${f.symbol}` : f.label;
            const value = cctcInputs[f.key] ?? f.default;

            return (
              <div key={f.key} className="cctc-input-item" title={f.desc || ''}>
                <CCTCTag
                  label={labelText}
                  isSelected={selectedTag === f.key}
                  onClick={() => handleTagClick(f.key)}
                  readOnly={false}
                />
                <div className="cctc-input-wrapper">
                  <input
                    type="number"
                    value={value === '' ? '' : value}
                    onChange={(e) => handleCCTCInputChange(e, f.key)}
                    step="any"
                    min={f.min !== undefined ? f.min : undefined}
                    max={f.max !== undefined ? f.max : undefined}
                    className="cctc-input-field"
                  />
                  <span className="cctc-input-unit">{f.unit || ''}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

export default CCTCInputs;



{/*
import React from 'react';
import CCTCTag from '../CCTCTags/CCTCTag';
import { formatNumber } from '../../utilits/formatNumber';
import './CCTCInputs.css';
import { CCTC_FIELDS } from '../../../units/cctcSpec';

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
        {/*
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
        {/*
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
*/}
