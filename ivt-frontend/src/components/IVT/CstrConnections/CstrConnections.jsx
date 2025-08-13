// src/components/CstrConnections/CstrConnections.jsx

import React from 'react';
import styles from './CstrConnections.module.css';

function CstrConnections() {
  return (
    <svg className={styles.connections} xmlns="http://www.w3.org/2000/svg">
      <defs>
        <marker
          id="arrowhead"
          markerWidth="10"
          markerHeight="7"
          refX="10"
          refY="3.5"
          orient="auto"
        >
          <polygon points="0 0, 12 3.5, 0 7" fill="grey" />
        </marker>
      </defs>

      <line
        x1="-550"
        y1="50"
        x2="10"
        y2="50"
        stroke="grey"
        strokeWidth="3"
        markerEnd="url(#arrowhead)"
      />

      <line
        x1="200"
        y1="170"
        x2="545"
        y2="170"
        stroke="grey"
        strokeWidth="3"
        markerEnd="url(#arrowhead)"
      />

      <line
        x1="130"
        y1="45"
        x2="130"
        y2="-25"
        stroke="grey"
        strokeWidth="5"
      />
    </svg>
  );
}

export default CstrConnections;