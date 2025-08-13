// src/components/IVT/UpdatedOutputGraph/UpdatedOutputGraph.jsx

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
import { labelMapping } from '../../utilits/labelMapping';
import styles from './UpdatedOutputGraph.module.css';

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

/**
 * Renders a line graph for the 'mRNA' output variable only.
 *
 * Props:
 * - timeData: array of time points
 * - outputVariables: object mapping variableName -> array of values
 * - outputUnits: object mapping variableName -> unit string
 */
function UpdatedOutputGraph({ timeData, outputVariables, outputUnits }) {
  const name = 'mRNA';
  const valuesArray = outputVariables[name] || [];
  if (!timeData || valuesArray.length === 0) {
    return <p>No mRNA data available to display the graph.</p>;
  }

  // Format last value
  const lastRaw = valuesArray[valuesArray.length - 1];
  const lastValue = formatNumber(lastRaw);

  // Compute min/max
  const maxPoint = Math.max(...valuesArray);
  const minPoint = Math.min(...valuesArray);

  // Prepare chart data
  const chartData = {
    labels: timeData,
    datasets: [
      {
        label: `${labelMapping[name] || name} (${lastValue} ${outputUnits[name]})`,
        data: valuesArray,
        fill: false,
        backgroundColor: 'rgba(128,128,128,0.6)',
        borderColor: 'rgba(128,128,128,1)',
        tension: 0.1,
        pointRadius: 3,
      },
    ],
  };

  // Chart options
  const options = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        labels: {
          font: { size: 16, weight: 'bold' },
          color: '#333333',
        },
      },
      tooltip: {
        callbacks: {
          label: context => formatNumber(context.parsed.y),
        },
      },
    },
    scales: {
      x: {
        title: { display: true, text: 'Time', font: { size: 14, weight: 'bold' }, color: '#333' },
        ticks: { color: '#333' },
        grid: { color: '#bbb', borderColor: '#bbb' },
      },
      y: {
        title: { display: true, text: `${labelMapping[name] || name} (${outputUnits[name]})`, font: { size: 14, weight: 'bold' }, color: '#333' },
        ticks: { color: '#333', callback: value => formatNumber(value) },
        grid: { color: '#bbb', borderColor: '#bbb' },
        suggestedMin: minPoint * 0.9,
        suggestedMax: maxPoint * 1.1,
      },
    },
    elements: { line: { borderWidth: 2 } },
  };

  return (
    <div className={styles.graphContainer}>
      <Line data={chartData} options={options} />
    </div>
  );
}

export default UpdatedOutputGraph;