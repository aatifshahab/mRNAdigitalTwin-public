// src/components/Lyo/Lyo.jsx

import React, { useState } from 'react';
import axios from 'axios'; // Import axios for HTTP requests
import LyoInputs from './Inputs/LyoInputs';
import LyoMeasured from './Measured/LyoMeasured';
import LyoOutputs from './Outputs/LyoOutputs';
import LyoGraphs from './Graphs/LyoGraphs';
import styles from './Lyo.module.css'; // Import CSS Module

function Lyo() {
  // State for inputs
  const [lyoInputs, setLyoInputs] = useState({
    InitfreezingTemperature: '298.15', 
    InitprimaryDryingTemperature: '228',
    InitsecondaryDryingTemperature: '273',
    TempColdGasfreezing: '268', 
    TempShelfprimaryDrying: '270', 
    TempShelfsecondaryDrying: '295', 
    Pressure: '10',
    massFractionmRNA: '0.05',
    fluidVolume: '3e-6', 
  });

  // State for selected tags
  const [selectedInputTag, setSelectedInputTag] = useState('Temperature');
  const [selectedMeasuredVariable, setSelectedMeasuredVariable] = useState(null);
  const [selectedOutputVariable, setSelectedOutputVariable] = useState(null);

  // State for outputs
  const [lyoOutputs, setLyoOutputs] = useState({
    time1: [],
    time2: [],
    time3: [],
    time: [],
    massOfIce: [],
    boundWater: [],
    productTemperature: [],
    operatingPressure: [],
    operatingTemperature: [],
  });

  // State for measured variables
  const [lyoMeasured, setLyoMeasured] = useState({
    operatingTemperature: [],
    operatingPressure: [],
  });

  // State for loading and error
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  // Handle input changes
  const handleInputChange = (e, name) => {
    const value = e.target.value;
    setLyoInputs({ ...lyoInputs, [name]: value });
  };

  // Handle Run Unit
  const handleRunLyo = async () => {
    // Validate inputs before sending
    const requiredFields = [
      'fluidVolume',
      'massFractionmRNA',
      'InitfreezingTemperature',
      'InitprimaryDryingTemperature',
      'InitsecondaryDryingTemperature',
      'TempColdGasfreezing',
      'TempShelfprimaryDrying',
      'TempShelfsecondaryDrying',
      'Pressure',
    ];

    for (let field of requiredFields) {
      if (lyoInputs[field] === '' || isNaN(parseFloat(lyoInputs[field]))) {
        alert(`Please enter a valid value for ${field}`);
        return;
      }
    }

    setIsLoading(true);
    setError(null);

    try {
      // Prepare the payload
      const payload = {
        fluidVolume: parseFloat(lyoInputs.fluidVolume),
        massFractionmRNA: parseFloat(lyoInputs.massFractionmRNA),
        InitfreezingTemperature: parseFloat(lyoInputs.InitfreezingTemperature),
        InitprimaryDryingTemperature: parseFloat(lyoInputs.InitprimaryDryingTemperature),
        InitsecondaryDryingTemperature: parseFloat(lyoInputs.InitsecondaryDryingTemperature),
        TempColdGasfreezing: parseFloat(lyoInputs.TempColdGasfreezing),
        TempShelfprimaryDrying: parseFloat(lyoInputs.TempShelfprimaryDrying),
        TempShelfsecondaryDrying: parseFloat(lyoInputs.TempShelfsecondaryDrying),
        Pressure: parseFloat(lyoInputs.Pressure),
      };

      // Make the POST request to the backend
      const response = await axios.post('http://localhost:8000/run_lyo', payload);

      if (response.data.error) {
        setError(response.data.error);
        setIsLoading(false);
        return;
      }

      // Update outputs with the response data
      setLyoOutputs({
        time1: response.data.time1 || [],
        time2: response.data.time2 || [],
        time3: response.data.time3 || [],
        time: response.data.time || [],
        massOfIce: response.data.massOfIce || [],
        boundWater: response.data.boundWater || [],
        productTemperature: response.data.productTemperature || [],
        operatingPressure: response.data.operatingPressure || [],
        operatingTemperature: response.data.operatingTemperature || [],
      });

      // Update measured data with the last values
      setLyoMeasured({
        operatingTemperature: response.data.operatingTemperature || [],
        operatingPressure: response.data.operatingPressure || [],
      });

      // Optionally, display success message
      alert('Lyophilization simulation completed successfully!');
    } catch (err) {
      console.error('Error running Lyo simulation:', err);
      setError('Failed to run simulation. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // Function to open IVT in a new window
  const openIVT = () => {
    const ivtWindow = window.open('/', 'IVT Window', 'width=800,height=600');

    // Optional: Handle if the window fails to open
    if (!ivtWindow) {
      alert('Popup blocked! Please allow popups for this website.');
    }
  };

  // Function to open CCTC in a new window
  const openCCTC = () => {
    const cctcWindow = window.open('/cctc', 'CCTC Window', 'width=800,height=600');

    // Optional: Handle if the window fails to open
    if (!cctcWindow) {
      alert('Popup blocked! Please allow popups for this website.');
    }
  };

  const openMembrane = () => {
    // Open Membrane in a new tab (or same tab)
    const membraneWindow = window.open('/membrane', '_blank', 'width=800,height=600');
    if (!membraneWindow) {
      alert('Popup blocked! Please allow popups for this website.');
    }
  };

const openLNP = () => {
    // Open Membrane in a new tab (or same tab)
    const LnpWindow = window.open('/lnp', '_blank', 'width=800,height=600');
    if (!LnpWindow) {
      alert('Popup blocked! Please allow popups for this website.');
    }
  };

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Lyophilization Unit</h1>

      {/* Navigation Buttons */}
      <div className={styles.navigationButtons}>
        <button onClick={openIVT} className={styles.navButton}>Go to IVT Unit</button>
        <button onClick={openMembrane} className={styles.navButton}>Go to Membrane Unit</button>
        <button onClick={openCCTC} className={styles.navButton}>Go to CCTC Unit</button>
        <button onClick={openLNP} className={styles.navButton}>Go to LNP Unit</button>
      </div>

      {/* Independent Containers */}
      <div className={styles.inputsContainer}>
        <LyoInputs
          lyoInputs={lyoInputs}
          handleInputChange={handleInputChange}
          selectedInputTag={selectedInputTag}
          setSelectedInputTag={setSelectedInputTag}
        />
      </div>

      <div className={styles.measuredContainer}>
        <LyoMeasured
          lyoMeasured={lyoMeasured}
          selectedMeasuredVariable={selectedMeasuredVariable}
          setSelectedMeasuredVariable={setSelectedMeasuredVariable}
        />
      </div>

      <div className={styles.outputContainer}>
        <LyoOutputs
          lyoOutputs={lyoOutputs}
          selectedOutputVariable={selectedOutputVariable}
          setSelectedOutputVariable={setSelectedOutputVariable}
        />
      </div>

      <div className={styles.figureContainer}>
        <div className={styles.figureWrapper}>
          <h3>Figure Placeholder</h3>
          {/* Add your figure content here */}
        </div>
      </div>

      {/* Graph Container with Three Graphs */}
      <div className={styles.graphContainer}>
        <LyoGraphs
          selectedMeasuredVariable={selectedMeasuredVariable}
          selectedOutputVariable={selectedOutputVariable}
          lyoOutputs={lyoOutputs}
          lyoMeasured={lyoMeasured}
        />
      </div>

      {/* Run Unit Button */}
      <div className={styles.runUnitButton}>
        <button onClick={handleRunLyo} className={styles.runButton} disabled={isLoading}>
          {isLoading ? 'Running...' : 'Run Lyophilization Unit'}
        </button>
      </div>

      {/* Error Message */}
      {error && <div className={styles.errorMessage}>{error}</div>}
    </div>
  );
}

export default Lyo;