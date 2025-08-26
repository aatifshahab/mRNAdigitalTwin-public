// src/components/Membrane/MembraneFigure/MembraneFigure.jsx

import React from 'react';
import styles from './MembraneFigure.module.css';
import membraneDiagram from '../../utilits/tff.png';

function MembraneFigure() {
  return (
    <div className={styles.figureContainer}>
     
      <img
        src={membraneDiagram}
        alt="Schematic of tangential flow filtration"
        className={styles.figureImage}
      />
    </div>
  );
}

export default MembraneFigure;
