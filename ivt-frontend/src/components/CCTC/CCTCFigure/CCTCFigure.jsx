// src/components/CCTC/CCTCFigure/CCTCFigure.jsx

import React from 'react';
import cctcImage from '../../utilits/cctc.png'; // Ensure the image is placed correctly
import './CCTCFigure.css';

function CCTCFigure() {
  return (
    <div className="cctc-figure">
      <img src={cctcImage} alt="CCTC Process" className="cctc-image" />
    </div>
  );
}

export default CCTCFigure;
