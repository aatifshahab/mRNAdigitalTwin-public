// src/components/IVT/IVT.jsx

import React, { useState, useEffect } from 'react';
import Sidebar from './Sidebar/Sidebar';
import MeasuredVariables from './MeasuredVariables/MeasuredVariables';
import OutputVariables from './OutputVariables/OutputVariables';
import CstrFigure from './CstrFigure/CstrFigure';
import Graphs from './Graphs/Graphs';
import RunPlant from './RunPlant/RunPlant';
import axios from 'axios';
import './IVT.css';
import { labelMapping } from '../utilits/labelMapping';
import { calculateF102 } from '../utilits/calculateF102';

function IVT() {
  // -----------------------------------
  // 1. State Management
  // -----------------------------------

  // State for input variables
  const [inputs, setInputs] = useState({
    Q: 1.0,
    V: 2.0,
    T7RNAP: 1e-7,
    ATP: 0.0032,
    CTP: 0.0032,
    GTP: 0.0032,
    UTP: 0.0032,
    Mg: 0.008,
    DNA: 7.4,
  });

  const [finalTime, setFinalTime] = useState(2.0);

  // State for simulation results
  const [simulationResult, setSimulationResult] = useState(null);
  const [timeData, setTimeData] = useState([]);

  // State for measured variables and their units
  const [measuredVariables, setMeasuredVariables] = useState({
    ATP: [0.00],
    GTP: [0.00],
    CTP: [0.00],
    UTP: [0.00],
    Phosphate: [0.00],
    pH: [7.00],
    Mg: [0.00],
    mRNA: [0.00],
  });
  const [measuredUnits, setMeasuredUnits] = useState({
    ATP: 'mM',
    GTP: 'mM',
    CTP: 'mM',
    UTP: 'mM',
    pH: '',
    Mg: 'mM',
    Phosphate: 'mM',
    mRNA: 'µM',
  });

  // State for output variables and their units
  const [outputVariables, setOutputVariables] = useState({
    F102: [0.00], // Dummy value
    // Add other output variables with dummy values if any
  });
  const [outputUnits, setOutputUnits] = useState({
    F102: 'L/hr',
    // Add units for other output variables if any
  });

  // State for selected variables
  const [selectedInputVariable, setSelectedInputVariable] = useState(null);
  const [selectedMeasuredVariable, setSelectedMeasuredVariable] = useState(null);
  const [selectedOutputVariable, setSelectedOutputVariable] = useState(null);

  // State for error handling
  const [error, setError] = useState(null);

  // -----------------------------------
  // 2. Helper Mappings
  // -----------------------------------

  // Units mapping for measured variables
  const unitsMapping = {
    ATPo: 'mM',
    GTPo: 'mM',
    CTPo: 'mM',
    UTPo: 'mM',
    pHo: '',
    TotalMgo: 'mM',
    Phosphateo: 'mM',
    TotalRNAo: 'µM',
    // Add other units as needed
  };

  // Variable name mapping from backend to frontend
  const variableNameMapping = {
    TotalMgo: 'Mg',
    TotalRNAo: 'mRNA',
    // Add other mappings as needed
  };

  // Units mapping for output variables
  const outputUnitsMapping = {
    F102: 'L/hr', // Replace 'F102' with actual output variable names and units
    // Add other output variables and their units as needed
  };

  // -----------------------------------
  // 3. Utility Functions
  // -----------------------------------

  // Function to map backend variable names to frontend-friendly names
  const mapVariableNames = (data) => {
    const mappedVariables = {};
    const mappedUnits = {};

    Object.keys(data).forEach((key) => {
      if (key === 'time') return; // Skip time

      // Use labelMapping for frontend labels
      const frontendName = labelMapping[key] || (key.endsWith('o') ? key.slice(0, -1) : key);

      mappedVariables[frontendName] = data[key];
      mappedUnits[frontendName] = unitsMapping[key] || '';
    });

    return { mappedVariables, mappedUnits };
  };

  // Function to handle simulation run
  const handleRunPlant = async () => {
    // Prepare data
    const inputData = {
      ...inputs,
      finaltime: finalTime,
    };

    try {
      const response = await axios.post(
        'http://127.0.0.1:8000/run_simulation',
        inputData, // Send input data to backend
        {
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );
      console.log('IVT Simulation result:', response.data);
      setSimulationResult(response.data);
      setTimeData(response.data.time);

      // Map and set measured variables
      const { mappedVariables, mappedUnits } = mapVariableNames(response.data);
      setMeasuredVariables(mappedVariables);
      setMeasuredUnits(mappedUnits);

      // Generate F102 data
      const F102Data = calculateF102(response.data.time, inputs.Q, inputs.V);
      setOutputVariables((prevOutputVars) => ({
        ...prevOutputVars,
        F102: F102Data,
      }));
      setOutputUnits(outputUnitsMapping);

      // Optionally, alert the user
      alert('IVT Simulation completed successfully!');
      setError(null);
    } catch (error) {
      console.error('Error running IVT simulation:', error);
      alert('Error running IVT simulation. Please check the console for details.');
      setError('Failed to run IVT simulation.');
    }
  };

  // Function to handle input changes
  const handleInputChange = (e, name) => {
    const value = parseFloat(e.target.value);
    if (!isNaN(value)) {
      setInputs({ ...inputs, [name]: value });
    }
  };

  // Function to handle final time change
  const handleFinalTimeChange = (e) => {
    const value = parseFloat(e.target.value);
    if (!isNaN(value)) {
      setFinalTime(value);
    }
  };

  // Function to handle VariableTag click
  const handleTagClick = (variable) => {
    const { type, name } = variable;
    if (type === 'input') {
      setSelectedInputVariable({ type, name });
    } else if (type === 'measured') {
      setSelectedMeasuredVariable({ type, name });
    } else if (type === 'output') {
      setSelectedOutputVariable({ type, name });
    }
  };

  // Define input units
  const inputUnits = {
    T7RNAP: 'nM',
    ATP: 'mM',
    CTP: 'mM',
    GTP: 'mM',
    UTP: 'mM',
    Mg: 'mM',
    DNA: 'nM',
    Q: 'L/hr',
    V: 'L',
  };

  // Initialize default selected variables on initial load
  useEffect(() => {
    // Set default selected variables if not already set
    if (!selectedInputVariable && Object.keys(inputs).length > 0) {
      setSelectedInputVariable({ type: 'input', name: Object.keys(inputs)[0] });
    }
    if (!selectedMeasuredVariable && Object.keys(measuredVariables).length > 0) {
      setSelectedMeasuredVariable({ type: 'measured', name: Object.keys(measuredVariables)[0] });
    }
    if (!selectedOutputVariable && Object.keys(outputVariables).length > 0) {
      setSelectedOutputVariable({ type: 'output', name: Object.keys(outputVariables)[0] });
    }
  }, [inputs, measuredVariables, outputVariables, selectedInputVariable, selectedMeasuredVariable, selectedOutputVariable]);

  // -----------------------------------
  // 4. Render Components
  // -----------------------------------


  // Function to open CCTC in a new window
  const openCCTC = () => {
    // Retrieve mRNA concentration from IVT measured variables
    const mRNAConcentration = measuredVariables.mRNA[measuredVariables.mRNA.length - 1];

    // Open a new window and pass mRNA concentration via query parameters
    const cctcWindow = window.open(`/cctc?mRNA=${mRNAConcentration}`, 'CCTC Window', 'width=800,height=600');

    // Optional: Handle if the window fails to open
    if (!cctcWindow) {
      alert('Popup blocked! Please allow popups for this website.');
    }
  };

  // Function to open Lyo in a new window
  const openLyo = () => {
    // Open a new window without any query parameters
    const lyoWindow = window.open('/lyo', 'Lyo Window', 'width=800,height=600');

    // Optional: Handle if the window fails to open
    if (!lyoWindow) {
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
    <div className="ivt-container">
      <h1>IVT Unit</h1>

      {/* Navigation Button to CCTC */}
      <div className="navigation-buttons">
        <button onClick={openMembrane}>Go to Membrane Unit</button>
        <button onClick={openCCTC}>Go to CCTC Unit</button>
        <button onClick={openLNP}>Go to LNP Unit</button>
        <button onClick={openLyo}>Go to Freeze-drying Unit</button>
      </div>

      <div className="ivt-layout">
        {/* Sidebar */}
        <Sidebar
          inputs={inputs}
          inputUnits={inputUnits}
          handleInputChange={handleInputChange}
          handleTagClick={handleTagClick}
          selectedInputVariable={selectedInputVariable}
        />

        {/* Main Content */}
        <div className="ivt-main-content">
          {/* Top Section: Measured Variables and CSTR Figure & Output Variables */}
          <div className="ivt-top-section">
            {/* Measured Variables */}
            <MeasuredVariables
              measuredVariables={measuredVariables}
              measuredUnits={measuredUnits}
              handleTagClick={handleTagClick}
              selectedMeasuredVariable={selectedMeasuredVariable}
            />

            {/* CSTR Figure and Output Variables Side by Side */}
            <div className="ivt-figure-output">
              {/* CSTR Figure */}
              <CstrFigure />

              {/* Output Variables */}
              <OutputVariables
                outputVariables={outputVariables}
                outputUnits={outputUnits}
                handleTagClick={handleTagClick}
                selectedOutputVariable={selectedOutputVariable}
              />
            </div>
          </div>

          {/* Graphs */}
          <Graphs
            selectedInputVariable={selectedInputVariable}
            simulationResult={simulationResult}
            timeData={timeData}
            inputs={inputs}
            selectedMeasuredVariable={selectedMeasuredVariable}
            measuredVariables={measuredVariables}
            measuredUnits={measuredUnits}
            selectedOutputVariable={selectedOutputVariable}
            outputVariables={outputVariables}
            outputUnits={outputUnits}
            inputUnits={inputUnits}
          />

          {/* Run Plant */}
          <RunPlant
            finalTime={finalTime}
            handleFinalTimeChange={handleFinalTimeChange}
            handleRunPlant={handleRunPlant}
          />
        </div>
      </div>

      {/* Error Display */}
      {error && <div className="error-message">{error}</div>}
    </div>
  );
}

export default IVT;
