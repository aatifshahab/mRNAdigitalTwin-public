// src/components/InputGraph.jsx

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
import { formatNumber } from '../../utilits/formatNumber'; 
import './InputGraph.css';

// Register necessary Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

function InputGraph({ inputName, timeData, inputData, unit }) {
 

  // Get the last value from inputData and format it
  const lastValue = formatNumber(inputData[inputData.length - 1]);

  // Determine y-axis bounds for smoother scaling
  const maxDataPoint = Math.max(...inputData);
  const minDataPoint = Math.min(...inputData);

  // Prepare data for the chart
  const chartData = {
    labels: timeData,
    datasets: [
      {
        label: `${inputName} (${lastValue} ${unit}) `,
        data: inputData,
        fill: false,
        backgroundColor: 'rgba(128, 128, 128, 0.6)', // Grey color
        borderColor: 'rgba(128, 128, 128, 1)', // Grey color
        tension: 0.1,
        pointRadius: 3,
      },
    ],
  };

  // Prepare chart options
  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    
    plugins: {
      legend: {
        display: true,
        labels: {
          generateLabels: (chart) => {
            const datasets = chart.data.datasets;
            return datasets.map((dataset) => ({
              text: dataset.label,
              fillStyle: 'rgba(0,0,0,0)', // Fully transparent color box
              strokeStyle: 'rgba(0,0,0,0)', // Fully transparent border
              lineWidth: 0,
              hidden: false,
              index: dataset.index,
            }));
          },
          font: {
            size: 16,
            family: 'Arial',
            weight: 'bold',
          },
          color: '#333333', // Dark grey text
        },
      },
      tooltip: {
        callbacks: {
          label: function (context) {
            const label = context.dataset.label || '';
            return `${label}: ${formatNumber(context.parsed.y)}`;
          },
        },
      },
    },
    scales: {
      x: {
        title: {
          display: true,
          text: 'Time (hr)',
          color: '#333333', // Dark grey text
          font: {
            size: 14,
            weight: 'bold',
          },
        },
        ticks: {
          color: '#333333', // Dark grey text
        },
        grid: {
          color: '#bfbfbf', // Light grey grid lines
          borderColor: '#bfbfbf', // Light grey borders
        },
      },
      y: {
        title: {
          display: true,
          text: `${inputName} (${unit})`,
          color: '#333333', // Dark grey text
          font: {
            size: 14,
            weight: 'bold',
          },
        },
        ticks: {
          color: '#333333', // Dark grey text
          callback: function (value) {
            return formatNumber(value); // Format y-axis tick labels
          },
          stepSize: (maxDataPoint - minDataPoint) / 5, // Example step size for 5 ticks
        },
        grid: {
          color: '#bfbfbf', // Light grey grid lines
          borderColor: '#bfbfbf', // Light grey borders
        },
        beginAtZero: false,
        suggestedMin: minDataPoint * 1,
        suggestedMax: maxDataPoint * 1,
      },
    },
    elements: {
      line: {
        borderWidth: 2,
      },
    },
  };

  return (
    <div className="input-variable-graph" style={{ width: '100%', height: '100%' }} >
      <Line data={chartData} options={chartOptions} />
    </div>
  );
}

export default InputGraph;
