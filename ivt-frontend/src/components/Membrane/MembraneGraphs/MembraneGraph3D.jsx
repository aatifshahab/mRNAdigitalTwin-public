// src/components/Membrane/MembraneGraphs/MembraneGraph3D.jsx

import React from 'react';
import Plot from 'react-plotly.js';

/*
  Renders a 3D surface plot using Plotly.

  Props:
    timePoints (array of length N)
    xPositions (array of length M)
    Cmatrix (N x M) => rows = time, columns = position
    species => name for the z-axis label
*/

function MembraneGraph3D({ timePoints, xPositions, Cmatrix, species }) {
  // shape: z must be array of arrays, size [N][M]
  // x = xPositions => length M
  // y = timePoints => length N

  // Example camera settings: eye.x, eye.y, eye.z define the viewpoint
  // Adjust these values for your desired initial angle/zoom.
  const cameraConfig = {
    eye: { x: 1.5, y: 1.5, z: 1.0 },  // Zoom out / angle
    center: { x: 0, y: 0, z: 0 },     // Center of the scene
    up: { x: 0, y: 0, z: 1 },         // 'up' vector
  };

  return (
    // Make the container fill its parent (which should be .graphContent)
    <div style={{ width: '100%', height: '100%' }}>
      <Plot
        data={[
          {
            type: 'surface',
            x: xPositions,
            y: timePoints,
            z: Cmatrix,
            colorscale: 'Viridis',
          },
        ]}
        layout={{
          // Force Plotly to auto-fit to the container size
          autosize: true,

          // Remove default margins so the surface can expand fully
          margin: { l: 0, r: 0, b: 0, t: 0 },

          // Set the paper and plot backgrounds to your desired color
          paper_bgcolor: 'rgb(230, 230, 230)',
          plot_bgcolor: 'rgb(230, 230, 230)',

          scene: {
            xaxis: { title: 'Position' },
            yaxis: { title: 'Time' },
            zaxis: { title: species },

            // Apply the camera config
            camera: cameraConfig,
          },
        }}
        style={{ width: '100%', height: '100%' }}
        config={{ responsive: true }}
      />
    </div>
  );
}

export default MembraneGraph3D;
