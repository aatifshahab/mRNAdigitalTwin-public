// src/components/CCTC/CCTCOutputs/CCTCOutputs.jsx

import React from 'react';
import CCTCTag from '../CCTCTags/CCTCTag';
import './CCTCOutputs.css';

function CCTCOutputs({ cctcOutputs }) {
    const { unbound_mRNA, bound_mRNA } = cctcOutputs;

    // Function to safely get the last element of an array
    const getLastValue = (arr) => {
        if (Array.isArray(arr) && arr.length > 0) {
            return arr[arr.length - 1];
        }
        return 0; // Default value if array is empty or not an array
    };

    const lastUnbound = getLastValue(unbound_mRNA).toFixed(2);
    const lastBound = getLastValue(bound_mRNA).toFixed(2);

    return (
        <div className="cctc-outputs">
            <h2>Output Variables</h2>
            <div className="cctc-output-tags">
                {/* Unbound mRNA */}
                <CCTCTag
                    label="Unbound mRNA"
                    value={lastUnbound}
                    unit="g/L"
                    readOnly={true}
                    isSelected={false}
                />

                {/* Bound mRNA */}
                <CCTCTag
                    label="Bound mRNA"
                    value={lastBound}
                    unit="g/L"
                    readOnly={true}
                    isSelected={false}
                />
            </div>
        </div>
    );
}

export default CCTCOutputs;
