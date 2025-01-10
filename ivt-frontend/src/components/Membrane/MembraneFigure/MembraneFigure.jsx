// src/components/Membrane/MembraneFigure/MembraneFigure.jsx
import React from 'react';
import styles from './MembraneFigure.module.css';

function MembraneFigure() {
  return (
    <div className={styles.figureContainer}>
      <h3>Membrane Process Figure</h3>
      <div className={styles.placeholder}>
        [Diagram or Image of Membrane Filtration]
      </div>
    </div>
  );
}

export default MembraneFigure;
