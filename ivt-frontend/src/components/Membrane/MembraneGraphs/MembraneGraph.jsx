// src/components/Membrane/MembraneGraphs/MembraneGraph.jsx
import React from 'react';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

function MembraneGraph({ label, xData, yData, xTitle = 'X', yTitle = 'Y' }) {
  const data = {
    labels: xData.map((val) => (typeof val === 'number' ? val.toFixed(2) : val)),
    datasets: [
      {
        label,
        data: yData,
        borderColor: 'gray',
        fill: false,
        tension: 0.1,
        pointRadius: 2,
      },
    ],
  };

  // Key: maintainAspectRatio: false => allows 100% height
  const options = {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      x: { title: { display: true, text: xTitle } },
      y: { title: { display: true, text: yTitle } },
    },
  };

  return (
    <div style={{ width: '100%', height: '100%' }}>
      <Line data={data} options={options} />
    </div>
  );
}

export default MembraneGraph;
