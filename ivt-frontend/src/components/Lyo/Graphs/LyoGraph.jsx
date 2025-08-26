// src/components/Lyo/Graphs/LyoGraph.jsx

import React from 'react';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  LinearScale, // Use LinearScale for numerical x-axis
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import annotationPlugin from 'chartjs-plugin-annotation'; // Import the annotation plugin
import styles from './LyoGraph.module.css';

ChartJS.register(
  LinearScale, // Register LinearScale
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  annotationPlugin // Register the plugin
);

function LyoGraph({ title, labels, datasets, endTime1, endTime2, phaseLabels }) {
  // Convert labels and data to numbers to ensure correct scaling
  const numericLabels = labels.map(label => Number(label));
  const numericDatasets = datasets.map(dataset => ({
    ...dataset,
    data: dataset.data.map(value => Number(value)),
    pointRadius: 2, // Remove point markers
  }));

  const data = {
    labels: numericLabels,
    datasets: numericDatasets,
  };

  const options = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top',
        labels: {
          font: {
            size: 12,
            weight: 'bold',
          },
          color: '#333333',
        },
      },
      title: {
        display: true,
        text: title,
        font: {
          size: 16,
          weight: 'bold',
        },
        color: '#333333',
      },
      tooltip: {
        callbacks: {
          label: function (context) {
            const label = context.dataset.label || '';
            const value = context.parsed.y;
            const unitMatch = label.match(/\(([^)]+)\)/);
            const unit = unitMatch ? unitMatch[1] : '';
            return `${label}: ${value} ${unit}`;
          },
        },
      },
      annotation: {
        annotations: {
          phase1: {
            type: 'line',
            xMin: endTime1,
            xMax: endTime1,
            borderColor: 'blue',
            borderWidth: 0,
            label: {
              enabled: true,
              content: phaseLabels[0],
              position: 'center', // Try 'center' or 'end' if 'start' doesn't work
              backgroundColor: 'rgba(0,0,0,0.7)',
              color: 'red',
              font: {
                weight: 'bold',
                size: 12, // Increase font size if necessary
              },
              yAdjust: 100, // Adjust Y position if necessary
              
            },
          },
          phase2: {
            type: 'line',
            xMin: endTime2,
            xMax: endTime2,
            borderColor: 'blue',
            borderWidth: 0,
            label: {
              enabled: true,
              content: phaseLabels[1],
              position: 'start', // Try 'center' or 'end' if 'start' doesn't work
              backgroundColor: 'rgba(0,0,0,0.7)',
              color: '#fff',
              font: {
                weight: 'bold',
                size: 12, // Increase font size if necessary
              },
              yAdjust: -10, // Adjust Y position if necessary
            },
          },
          phase3: {
            type: 'line',
            xMin: numericLabels[numericLabels.length - 1], // Ensure it's a number
            xMax: numericLabels[numericLabels.length - 1],
            borderColor: 'blue',
            borderWidth: 0,
            label: {
              enabled: true,
              content: phaseLabels[2],
              position: 'start', // Try 'center' or 'end' if 'start' doesn't work
              backgroundColor: 'rgba(0.5,0.5,0.5,0.7)',
              color: '#fff',
              font: {
                weight: 'bold',
                size: 12, // Increase font size if necessary
              },
              yAdjust: 0.03, // Adjust Y position if necessary
            },
          },
          // Optional: Shade the areas if desired
          freezingArea: {
            type: 'box',
            xMin: 0,
            xMax: endTime1,
            yMin: 'min',
            yMax: 'max',
            backgroundColor: 'rgba(255, 206, 86, 0.1)',
            borderWidth: 0,
          },
          primaryDryingArea: {
            type: 'box',
            xMin: endTime1,
            xMax: endTime2,
            yMin: 'min',
            yMax: 'max',
            backgroundColor: 'rgba(75, 192, 192, 0.1)',
            borderWidth: 0,
          },
          secondaryDryingArea: {
            type: 'box',
            xMin: endTime2,
            xMax: numericLabels[numericLabels.length - 1],
            yMin: 'min',
            yMax: 'max',
            backgroundColor: 'rgba(153, 102, 255, 0.1)',
            borderWidth: 0,
          },
        },
      },
    },
    scales: {
      x: {
        type: 'linear', // Set to linear for numerical scaling
        title: {
          display: true,
          text: 'Time (hr)',
          color: '#333333',
          font: {
            size: 14,
            weight: 'bold',
          },
        },
        ticks: {
          color: '#333333',
          callback: function (value) {
            // Format ticks to one decimal place or round to nearest integer
            return Number.isInteger(value) ? value : value.toFixed(1);
          },
        },
        grid: {
          color: '#bfbfbf',
          borderColor: '#bfbfbf',
        },
      },
      y: {
        title: {
          display: true,
          text: 'Values',
          color: '#333333',
          font: {
            size: 14,
            weight: 'bold',
          },
        },
        ticks: {
          color: '#333333',
          callback: function (value) {
            return value.toFixed(2);
          },
        },
        grid: {
          color: '#bfbfbf',
          borderColor: '#bfbfbf',
        },
      },
    },
    elements: {
      line: {
        borderWidth: 2,
      },
      point: {
        radius: 0, // Ensure no point markers are displayed
      },
    },
  };

  return (
    <div className={styles.graph}>
      <Line data={data} options={options} />
    </div>
  );
}

export default LyoGraph;
