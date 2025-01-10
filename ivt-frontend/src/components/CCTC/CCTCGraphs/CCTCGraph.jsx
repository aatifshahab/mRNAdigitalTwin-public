// src/components/CCTC/CCTCGraphs/CCTCGraph.jsx

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
import './CCTCGraph.css';

ChartJS.register(
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Tooltip,
    Legend
);

function CCTCGraph({ label, timeData, data, unit }) {
    const hasData = timeData && data && data.length > 0;
    const lastValue = (data[data.length - 1]);

    if (!hasData) {
        return (
            <div className="cctc-graph">
                <p>No data available to display the graph.</p>
            </div>
        );
    }

    // Format `timeData` to two decimal places
    const formattedTimeData = timeData.map((time) => parseFloat(time).toFixed(2));

    const chartData = {
        labels: formattedTimeData,
        datasets: [
            {
                label: `${label} (${lastValue.toFixed(2)} ${unit})`,
                data: data,
                fill: false,
                backgroundColor: 'rgba(115, 115, 115, 0.5)', // Grey color
                borderColor: 'rgba(128, 128, 128, 0.5)', // Grey color
                tension: 0.1,
                pointRadius: 3,
            },
        ],
    };

    const chartOptions = {
        responsive: true,
        maintainAspectRatio: false, // Allow the chart to fill its container
        plugins: {
            legend: {
                display: true,
                labels: {
                    font: {
                        size: 14,
                        family: 'Arial',
                        weight: 'bold',
                    },
                    color: '#333333', // Dark gray text
                    usePointStyle: true, // Makes the legend use point styles instead of box
                    boxWidth: 0,
                },
            },
            tooltip: {
                callbacks: {
                    label: function (context) {
                        const label = context.dataset.label || '';
                        const value = context.parsed.y.toFixed(2);
                        return `${label}: ${value} ${unit}`;
                    },
                },
            },
        },
        scales: {
            x: {
                display: hasData,
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
                },
                grid: {
                    color: '#bfbfbf',
                    borderColor: '#bfbfbf',
                },
            },
            y: {
                display: hasData,
                title: {
                    display: true,
                    text: `${label} (${unit})`,
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
                    stepSize: (Math.max(...data) - Math.min(...data)) / 5,
                },
                grid: {
                    color: '#bfbfbf',
                    borderColor: '#bfbfbf',
                },
                beginAtZero: false,
                suggestedMin: Math.min(...data) * 0.9,
                suggestedMax: Math.max(...data) * 1.1,
            },
        },
        elements: {
            line: {
                borderWidth: 2, // Thickness of the line
            },
        },
    };

    return (
        <div className="cctc-graph">
            <Line data={chartData} options={chartOptions} />
        </div>
    );
}

export default CCTCGraph;
