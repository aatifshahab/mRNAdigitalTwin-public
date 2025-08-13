// src/components/LNP/Figure/LNPFigure.jsx

import React from 'react';
import styles from './LNPFigure.module.css';


import lnpDiagram from '../../utilits/lnp.png'; 


function LNPFigure() {
  return (
    <div className={styles.figureContainer}>

      {/* SHOW THE REAL FIGURE */}
      <img
        src={lnpDiagram}
       
        className={styles.figureImage}
      />
    </div>
  );
}

export default LNPFigure;
