// src/components/CstrFigure/CstrFigure.jsx

import React from 'react';
import cstrImage from '../../utilits/cstr.png';
import CstrConnections from '../CstrConnections/CstrConnections';
import './CstrFigure.css';

function CstrFigure() {
  return (
    <div className="cstr-figure-container">
      <div className="cstr-figure-wrapper">
        <img src={cstrImage} alt="CSTR" className="cstr-image" />
        <CstrConnections /> {/* Render the connections overlay */}
      </div>
    </div>
  );
}

export default CstrFigure;
