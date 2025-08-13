import React from 'react';
import styles from './LyoFigure.module.css';
import lyoDiagram from '../../utilits/lyo.png';

function LyoFigure() {
  return (
    <div className={styles.figureContainer}>
     
      <img
        src={lyoDiagram}
        alt="Lyophilization process flow"
        className={styles.figureImage}
      />
    </div>
  );
}

export default LyoFigure;
