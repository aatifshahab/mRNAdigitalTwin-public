// src/components/LNP/Graphs/LNPGraph.jsx

import React from 'react';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  LinearScale,     // Use LinearScale for numerical axes
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import styles from './LNPGraph.module.css';

// Register the necessary Chart.js components
ChartJS.register(LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

function LNPGraph({
  label,
  xData,
  yData,
  xTitle = 'X',
  yTitle = 'Y',
  xLimits = null,
  yLimits = null,
}) {
  // Prepare the data for the chart as { x, y } pairs
  const data = {
    datasets: [
      {
        label,
        data: xData.map((x, index) => ({ x: parseFloat(x), y: parseFloat(yData[index]) })),
        borderColor: 'rgb(171, 173, 173)',
        backgroundColor: 'rgba(185, 187, 187, 0.2)',
        fill: true,
        tension: 0.1,
        pointRadius: 2,
      },
    ],
  };

  // Configure the chart options
  const options = {
    responsive: true,
    maintainAspectRatio: false, // Ensures the chart fills the container
    plugins: {
      legend: {
        display: false, // Hide the legend if not needed
      },
      title: {
        display: false, // Hide the chart title if not needed
      },
    },
    scales: {
      x: {
        type: 'linear', // Specify linear scale for x-axis
        title: {
          display: true,
          text: xTitle,
          font: {
            size: 14,
            weight: 'bold',
          },
        },
        ticks: {
          callback: function (value) {
            // Round the x-axis labels to one decimal place
            return parseFloat(value).toFixed(1);
          },
        },
        ...(xLimits && {
          min: xLimits[0],
          max: xLimits[1],
        }),
      },
      y: {
        type: 'linear', // Specify linear scale for y-axis
        title: {
          display: true,
          text: yTitle,
          font: {
            size: 14,
            weight: 'bold',
          },
        },
        ticks: {
          callback: function (value) {
            // Round the y-axis labels to one decimal place
            return parseFloat(value).toFixed(1);
          },
        },
        ...(yLimits && {
          min: yLimits[0],
          max: yLimits[1],
        }),
      },
    },
  };

  return (
    <div className={styles.graphContainer}>
      <Line data={data} options={options} />
    </div>
  );
}

export default LNPGraph;
