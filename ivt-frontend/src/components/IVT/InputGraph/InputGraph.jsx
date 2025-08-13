// src/components/InputGraph/InputGraph.jsx

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
import styles from './InputGraph.module.css';

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
  if (!timeData || !inputData || inputData.length === 0) {
    return <p>No data available for {inputName}.</p>;
  }

  // Get the last value and format
  const lastValue = formatNumber(inputData[inputData.length - 1]);

  // Determine y-axis bounds
  const maxDataPoint = Math.max(...inputData);
  const minDataPoint = Math.min(...inputData);

  // Chart data
  const chartData = {
    labels: timeData,
    datasets: [
      {
        label: `${inputName} (${lastValue} ${unit})`,
        data: inputData,
        fill: false,
        backgroundColor: 'rgba(128,128,128,0.6)',
        borderColor: 'rgba(128,128,128,1)',
        tension: 0.1,
        pointRadius: 3,
      },
    ],
  };

  // Chart options
  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        labels: {
          generateLabels: (chart) =>
            chart.data.datasets.map((ds) => ({ text: ds.label, fillStyle: 'rgba(0,0,0,0)', strokeStyle: 'rgba(0,0,0,0)', lineWidth: 0, hidden: false, index: ds.index })),
          font: { size: 16, family: 'Arial', weight: 'bold' },
          color: '#333333',
        },
      },
      tooltip: {
        callbacks: {
          label: (context) => formatNumber(context.parsed.y),
        },
      },
    },
    scales: {
      x: {
        title: { display: true, text: 'Time (hr)', font: { size: 14, weight: 'bold' }, color: '#333333' },
        ticks: { color: '#333333' },
        grid: { color: '#bfbfbf', borderColor: '#bfbfbf' },
      },
      y: {
        title: { display: true, text: `${inputName} (${unit})`, font: { size: 14, weight: 'bold' }, color: '#333333' },
        ticks: { color: '#333333', callback: (v) => formatNumber(v), stepSize: (maxDataPoint - minDataPoint) / 5 },
        grid: { color: '#bfbfbf', borderColor: '#bfbfbf' },
        suggestedMin: minDataPoint * 0.9,
        suggestedMax: maxDataPoint * 1.1,
      },
    },
    elements: { line: { borderWidth: 2 } },
  };

  return (
    <div className={styles.inputVariableGraph}>
      <Line data={chartData} options={chartOptions} />
    </div>
  );
}

export default InputGraph;