// src/components/CCTC/CCTCTags/CCTCTag.jsx

import React from 'react';
import './CCTCTag.css';



function CCTCTag({ label, value, unit, onClick, isSelected, readOnly }) {
    return (
        <div className="cctc-tag">
            {!readOnly ? (
                <div
                    className={`cctc-tag-label ${isSelected ? 'selected' : ''}`}
                    onClick={onClick}
                    tabIndex="0"
                    role="button"
                    aria-pressed={isSelected}
                    onKeyPress={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                            onClick();
                        }
                    }}
                >
                    {label}
                </div>
            ) : (
                <div className={`cctc-tag-label read-only ${isSelected ? 'selected' : ''}`}>
                    {label}
                </div>
            )}
            <div className="cctc-tag-value">
                <span>{(value)} {unit}</span>
                
            </div>
        </div>
    );
}

export default CCTCTag;
