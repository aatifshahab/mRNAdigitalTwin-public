// src/components/OutputVariableGraph.jsx

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
import { formatNumber } from '../utilits/formatNumber'; // Correct import path

import { labelMapping } from '../utilits/labelMapping';

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

function OutputVariableGraph({ variableName, timeData, variableData, unit }) {
  if (!timeData || !variableData || variableData.length === 0) {
    return <p>No data available to display the graph.</p>;
  }

  // Get the last value from variableData and format it
  const lastValue = formatNumber(variableData[variableData.length - 1]);

  // Determine y-axis bounds for smoother scaling
  const maxDataPoint = Math.max(...variableData);
  const minDataPoint = Math.min(...variableData);

  // Prepare data for the chart
  const chartData = {
    labels: timeData,
    datasets: [
      {
        label: `${labelMapping[variableName] || variableName} (${lastValue} ${unit}) `, // Include the last value in the label
        data: variableData,
        fill: false,
        backgroundColor: 'rgba(128, 128, 128, 0.6)', // Grey color
        borderColor: 'rgba(128, 128, 128, 1)', // Grey color
        tension: 0.1, // Smoothness of the line
        pointRadius: 3, // Point markers
      },
    ],
  };

  // Prepare chart options
  const chartOptions = {
    responsive: true,
    plugins: {
      legend: {
        display: true,
        labels: {
          // Customize the legend labels
          generateLabels: (chart) => {
            const datasets = chart.data.datasets;
            return datasets.map((dataset) => ({
              text: dataset.label, // Use the label with the latest value
              fillStyle: 'rgba(0,0,0,0)', // Make the color box fully transparent
              strokeStyle: 'rgba(0,0,0,0)', // Make the border fully transparent
              lineWidth: 0, // Remove line width
              hidden: false, // Ensure datasets are visible
              index: dataset.index,
            }));
          },
          font: {
            size: 16, // Increased font size
            family: 'Arial', // Optional: Change font family
            weight: 'bold', // Optional: Change font weight
          },
          color: '#333333', // Set text color to dark grey
        },
      },
      tooltip: {
        callbacks: {
          // Customize tooltips to show formatted numbers
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
          color: '#333333', // Customize axis title color
          font: {
            size: 14,
            weight: 'bold',
          },
        },
        ticks: {
          color: '#333333', // Customize tick color
        },
        grid: {
          color: '#bfbfbf', // Light grey grid lines
          borderColor: '#bfbfbf', // Light grey border
        },
      },
      y: {
        title: {
          display: true,
          text: `${labelMapping[variableName] || variableName} (${unit})`,
          color: '#333333', // Customize axis title color
          font: {
            size: 14,
            weight: 'bold',
          },
        },
        ticks: {
          color: '#333333', // Customize tick color
          callback: function (value) {
            return formatNumber(value); // Format y-axis tick labels
          },
          stepSize: (maxDataPoint - minDataPoint) / 5, // Example step size for 5 ticks
        },
        grid: {
          color: '#bfbfbf', // Light grey grid lines
          borderColor: '#bfbfbf', // Light grey border
        },
        beginAtZero: false, // Allow y-axis to adjust based on data
        suggestedMin: minDataPoint * 0.9, // 10% below min data point
        suggestedMax: maxDataPoint * 1.1, // 10% above max data point
      },
    },
    elements: {
      line: {
        borderWidth: 2, // Thickness of the line
      },
    },
  };

  return (
    <div className="input-graph">
      <Line data={chartData} options={chartOptions} />
    </div>
  );
}

export default OutputVariableGraph;
