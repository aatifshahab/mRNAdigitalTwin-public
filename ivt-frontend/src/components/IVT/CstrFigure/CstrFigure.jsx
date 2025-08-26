// src/components/CstrFigure/CstrFigure.jsx

import React from 'react';
import cstrImage from '../../utilits/cstr.png';
import CstrConnections from '../CstrConnections/CstrConnections';
import styles from './CstrFigure.module.css';

function CstrFigure() {
  return (
    <div className={styles.container}>
      <div className={styles.wrapper}>
        <img src={cstrImage} alt="CSTR" className={styles.image} />
        <CstrConnections />
      </div>
    </div>
  );
}

export default CstrFigure;