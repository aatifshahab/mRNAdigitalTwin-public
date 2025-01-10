// src/components/LNP/LNP.jsx

import React, { useState } from 'react';
import styles from './LNP.module.css';

import LNPInputs from './Inputs/LNPInputs';
import LNPOutputs from './Outputs/LNPOutputs';
import LNPGraphs from './Graphs/LNPGraphs';
import LNPFigure from './Figure/LNPFigure';
import LNPRun from './Run/LNPRun';

import LNPVariableTag from './Tags/LNPVariableTag'; // Ensure the path is correct

// Module-level window references
let ivtWindow = null;
let cctcWindow = null;
let membraneWindow = null;
let lyoWindow = null;

function LNP() {
  // State for Inputs
  const [inputs, setInputs] = useState({
    Residential_time: 60, // seconds
    FRR: 3,               // flow rate ratio
    pH: 5.5,              // pH value
    Ion: 0.1,             // ionic concentration
    TF: 0,                // total flowrate ml/min
  });

  // State for Outputs
  const [outputs, setOutputs] = useState({
    Diameter: [],
    PSD: [],
    error: null,
  });

  // State for Run Button
  const [isRunning, setIsRunning] = useState(false);

  // Handle Input Changes
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setInputs((prev) => ({
      ...prev,
      [name]: parseFloat(value),
    }));
  };

  // Handle Run Simulation
  const handleRun = async () => {
    setIsRunning(true);
    try {
      const response = await fetch('http://127.0.0.1:8000/run_lnp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(inputs),
      });

      const data = await response.json();

      if (data.error) {
        setOutputs({
          Diameter: [],
          PSD: [],
          error: data.error,
        });
        alert(`Error: ${data.error}`);
      } else {
        setOutputs({
          Diameter: data.Diameter,
          PSD: data.PSD,
          error: null,
        });
        alert('LNP Simulation Completed Successfully!');
      }
    } catch (error) {
      setOutputs({
        Diameter: [],
        PSD: [],
        error: 'Failed to connect to the backend.',
      });
      alert('Failed to connect to the backend.');
    }
    setIsRunning(false);
  };

  // Navigation Functions with Enhanced Window Management
  const openIVT = () => {
    const url = `${window.location.origin}/ivt`;
    const windowName = 'IVTUnit';
    const windowFeatures = 'width=800,height=600';

    if (ivtWindow == null || ivtWindow.closed) {
      ivtWindow = window.open(url, windowName, windowFeatures);
      if (ivtWindow) {
        ivtWindow.focus();
      } else {
        alert('Popup blocked! Please allow popups for this website.');
      }
    } else {
      ivtWindow.focus();
    }
  };

  const openCCTC = () => {
    const url = `${window.location.origin}/cctc`;
    const windowName = 'CCTCUnit';
    const windowFeatures = 'width=800,height=600';

    if (cctcWindow == null || cctcWindow.closed) {
      cctcWindow = window.open(url, windowName, windowFeatures);
      if (cctcWindow) {
        cctcWindow.focus();
      } else {
        alert('Popup blocked! Please allow popups for this website.');
      }
    } else {
      cctcWindow.focus();
    }
  };

  const openMembrane = () => {
    const url = `${window.location.origin}/membrane`;
    const windowName = 'MembraneUnit';
    const windowFeatures = 'width=800,height=600';

    if (membraneWindow == null || membraneWindow.closed) {
      membraneWindow = window.open(url, windowName, windowFeatures);
      if (membraneWindow) {
        membraneWindow.focus();
      } else {
        alert('Popup blocked! Please allow popups for this website.');
      }
    } else {
      membraneWindow.focus();
    }
  };

  const openLyo = () => {
    const url = `${window.location.origin}/lyo`;
    const windowName = 'FreezeDryingUnit';
    const windowFeatures = 'width=800,height=600';

    if (lyoWindow == null || lyoWindow.closed) {
      lyoWindow = window.open(url, windowName, windowFeatures);
      if (lyoWindow) {
        lyoWindow.focus();
      } else {
        alert('Popup blocked! Please allow popups for this website.');
      }
    } else {
      lyoWindow.focus();
    }
  };

  return (
    <div className={styles.lnpContainer}>
      <h1>LNP Unit</h1>

      {/* Navigation Buttons */}
      <div className={styles.navigationButtons}>
        <button onClick={openIVT}>Go to IVT Unit</button>
        <button onClick={openCCTC}>Go to CCTC Unit</button>
        <button onClick={openMembrane}>Go to Membrane Unit</button>
        <button onClick={openLyo}>Go to Freeze-drying Unit</button>
      </div>

      {/* Layout with Inputs and Outputs */}
      <div className={styles.lnpLayout}>
        {/* Inputs */}
        <LNPInputs inputs={inputs} handleInputChange={handleInputChange} />

        {/* Outputs */}
        <LNPOutputs outputs={outputs} />
      </div>

      {/* Graphs */}
      <LNPGraphs outputs={outputs} />

      {/* Figure Placeholder */}
      <LNPFigure />

      {/* Run Button */}
      <LNPRun handleRun={handleRun} isRunning={isRunning} />
    </div>
  );
}

export default LNP;
