// src/components/CstrConnections.jsx

import React from 'react';
import './CstrConnections.css'; // Optional: For additional styling

function CstrConnections() {
  return (
    <svg className="cstr-connections" xmlns="http://www.w3.org/2000/svg">
      {/* Input Line with Arrow */}
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

      {/* Line from Input Box to CSTR */}
      <line
        x1="-550"    // Starting x-coordinate (adjust as needed)
        y1="50"    // Starting y-coordinate (adjust as needed)
        x2="10"   // Ending x-coordinate at CSTR (adjust as needed)
        y2="50"    // Ending y-coordinate at CSTR (adjust as needed)
        stroke="grey"
        strokeWidth="3"
        markerEnd="url(#arrowhead)"
      />

      {/* Line from CSTR to Output Box */}
      <line
        x1="200"   // Starting x-coordinate at CSTR (adjust as needed)
        y1="170"   // Starting y-coordinate at CSTR (adjust as needed)
        x2="545"   // Ending x-coordinate at Output Box (adjust as needed)
        y2="170"   // Ending y-coordinate at Output Box (adjust as needed)
        stroke="grey"
        strokeWidth="3"
        markerEnd="url(#arrowhead)"
      />

      {/* Line from CSTR to Measured Variable Box (No Arrow) */}
      <line
        x1="130"   // Starting x-coordinate inside CSTR (adjust as needed)
        y1="45"    // Starting y-coordinate inside CSTR (adjust as needed)
        x2="130"     // Ending x-coordinate at Measured Variable Box (adjust as needed)
        y2="-25"    // Ending y-coordinate at Measured Variable Box (adjust as needed)
        stroke="grey"
        strokeWidth="5"
      />
    </svg>
  );
}

export default CstrConnections;
