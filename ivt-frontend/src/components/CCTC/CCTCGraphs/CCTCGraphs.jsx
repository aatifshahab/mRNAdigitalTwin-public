// src/components/CCTC/CCTCGraphs/CCTCGraphs.jsx

import React from 'react';
import CCTCGraph from './CCTCGraph';
import './CCTCGraphs.css';

function CCTCGraphs({ cctcOutputs, cctcInputs = { mRNA: 0, F103: 0, resin: 0 }, selectedTag }) {
    const { time, unbound_mRNA, bound_mRNA } = cctcOutputs;
    const { mRNA, F103, resin } = cctcInputs; // Destructure inputs

    // Function to generate constant input arrays based on selectedTag
    const generateConstantData = (value) => {
        return time.map(() => value);
    };

    // Determine which input to display based on selectedTag
    let currentInputValue = 0;
    let currentInputLabel = '';
    let currentInputUnit = '';

    switch (selectedTag) {
        case 'mRNA':
            currentInputValue = mRNA;
            currentInputLabel = 'Input mRNA';
            currentInputUnit = 'g/L';
            break;
        case 'F103':
            currentInputValue = F103;
            currentInputLabel = 'Input F103 Flow Rate';
            currentInputUnit = 'L/hr';
            break;
        case 'resin':
            currentInputValue = resin;
            currentInputLabel = 'Input Resin Concentration';
            currentInputUnit = 'g/L';
            break;
        default:
            currentInputValue = mRNA;
            currentInputLabel = 'Input mRNA';
            currentInputUnit = 'g/L';
    }

    const inputData = generateConstantData(currentInputValue);

    return (
        <div className="cctc-graphs">
           

            {/* Input Graph */}
            <div className="cctc-graph-sections">
                <div className="graph-section">
                    <CCTCGraph
                        label={currentInputLabel}
                        timeData={time}
                        data={inputData}
                        unit={currentInputUnit}
                    />
                </div>

                {/* Unbound mRNA Graph */}
                <div className="graph-section">
                    <CCTCGraph
                        label="Unbound mRNA"
                        timeData={time}
                        data={unbound_mRNA}
                        unit="g/L"
                    />
                </div>

                {/* Bound mRNA Graph */}
                <div className="graph-section">
                    <CCTCGraph
                        label="Bound mRNA"
                        timeData={time}
                        data={bound_mRNA}
                        unit="g/L"
                    />
                </div>
            </div>
        </div>
    );
}

export default CCTCGraphs;
