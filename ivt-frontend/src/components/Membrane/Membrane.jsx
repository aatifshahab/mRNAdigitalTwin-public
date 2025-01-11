// src/components/Membrane/Membrane.jsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';


import MembraneSidebar from './MembraneSidebar/MembraneSidebar';
import MembraneOutputs from './MembraneOutputs/MembraneOutputs';
import MembraneFigure from './MembraneFigure/MembraneFigure';
import MembraneGraphs from './MembraneGraphs/MembraneGraphs';
import MembraneRun from './MembraneRun/MembraneRun';

// Import sub-panels:
import MembraneConcentration from './MembraneConcentration/MembraneConcentration';
import MembraneDiafiltration from './MembraneDiafiltration/MembraneDiafiltration';

import './Membrane.module.css';

function Membrane() {
  // 1) Input states
  const [inputs, setInputs] = useState({
    qF: 5.0,
    c0_mRNA: 1.0,
    c0_protein: 1.0,
    c0_ntps: 1.0,
    X: 0.9,
    n_stages: 3,
    D: 4.5,
    filterType: 'VIBRO',
  });

  // 2) PDE solution data
  const [timePoints, setTimePoints] = useState([]);
  const [xPositions, setXPositions] = useState([]);
  const [Cmatrix_mRNA, setCmatrix_mRNA] = useState([]);
  const [Cmatrix_protein, setCmatrix_protein] = useState([]);
  const [Cmatrix_ntps, setCmatrix_ntps] = useState([]);
  const [interpolatedTimes, setInterpolatedTimes] = useState([]);
  const [interpolatedIndices, setInterpolatedIndices] = useState([]);

  // 3) Diafiltration data
  const [td, setTd] = useState([]);
  const [TFF_protein, setTFF_protein] = useState([]);
  const [TFF_ntps, setTFF_ntps] = useState([]);

  // 4) Outputs
  const [outputs, setOutputs] = useState({
    Jcrit: 0.0,
    Xactual: 0.0,
  });

  // 5) Graph selections
  // Keep "selectedInputVar" for Graph #1 (input variables)
  const [selectedInputVar, setSelectedInputVar] = useState(null);

  // For PDE (concentration step), create a new state that stores "species" + "plotType"
  const [concSelection, setConcSelection] = useState({
    species: 'mRNA',            // "mRNA", "Protein", or "NTPs"
    plotType: 'OUTLET_VS_TIME', // "OUTLET_VS_TIME" or "THREE_D"
  });

  // For TFF (diafiltration), store "variable" + "stage"
  const [diafSelection, setDiafSelection] = useState({
    variable: 'Protein', // "Protein" or "NTPs"
    stage: 1,           // integer stage index
  });

  // 6) Run time placeholder
  const [runTime, setRunTime] = useState(30);



  // 8) Input handling
  const handleInputChange = (e, key) => {
    const val = e.target.value;
    setInputs((prev) => ({
      ...prev,
      [key]: isNaN(parseFloat(val)) ? val : parseFloat(val),
    }));
  };

  // If user clicks an input variable tag:
  const handleTagClick = ({ type, name }) => {
    if (type === 'input') {
      setSelectedInputVar({ type, name });
    }
  };

  // 9) Run Membrane simulation
  const handleRunMembrane = async () => {
    try {
      const response = await axios.post(
        'http://127.0.0.1:8000/run_membrane',
        inputs,
        { headers: { 'Content-Type': 'application/json' } }
      );
      if (response.data.error) {
        alert(`Error: ${response.data.error}`);
        return;
      }
      const data = response.data;

      setTimePoints(data.time_points || []);
      setXPositions(data.x_positions || []);
      setCmatrix_mRNA(data.Cmatrix_mRNA || []);
      setCmatrix_protein(data.Cmatrix_protein || []);
      setCmatrix_ntps(data.Cmatrix_ntps || []);
      setInterpolatedTimes(data.interpolated_times || []);
      setInterpolatedIndices(data.interpolated_indices || []);
      setTd(data.td || []);
      setTFF_protein(data.TFF_protein || []);
      setTFF_ntps(data.TFF_ntps || []);
      setOutputs({ Jcrit: data.Jcrit, Xactual: data.Xactual });

      alert('Membrane simulation completed successfully!');
    } catch (err) {
      console.error('Membrane simulation error:', err);
      alert('Failed to run membrane simulation. Check console for details.');
    }
  };

  // 10) Default selection for Input variables
  useEffect(() => {
    if (!selectedInputVar && Object.keys(inputs).length > 0) {
      const firstKey = Object.keys(inputs)[0];
      setSelectedInputVar({ type: 'input', name: firstKey });
    }
  }, [inputs, selectedInputVar]);

  // Callback for PDE sub-panel
  // This sets "concSelection" => which species + plot type the user wants
  const handleConcentrationSelection = (sel) => {
    setConcSelection(sel); // { species, plotType }
  };

  // Callback for TFF sub-panel
  // This sets "diafSelection" => { variable, stage }
  const handleDiafiltrationSelection = (sel) => {
    setDiafSelection(sel);
  };


    // Function to open IVT in a new window
    const openIVT = () => {
      const ivtWindow = window.open('/', 'IVT Window', 'width=800,height=600');

      // Optional: Handle if the window fails to open
      if (!ivtWindow) {
          alert('Popup blocked! Please allow popups for this website.');
      }
  };

  // Function to open Lyo in a new window
  const openLyo = () => {
      const lyoWindow = window.open('/lyo', 'Lyo Window', 'width=800,height=600');

      // Optional: Handle if the window fails to open
      if (!lyoWindow) {
          alert('Popup blocked! Please allow popups for this website.');
      }
  };

  const openCCTC = () => {
   
      const membraneWindow = window.open('/cctc', 'CCTC Window', 'width=800,height=600');
      if (!membraneWindow) {
        alert('Popup blocked! Please allow popups for this website.');
      }
    };

  const openLNP = () => {
   
      const LnpWindow = window.open('/lnp', 'LNP Window', 'width=800,height=600');
      if (!LnpWindow) {
        alert('Popup blocked! Please allow popups for this website.');
      }
    };



  return (
    <div className="membrane-container">
      <h1>Membrane Unit</h1>

      {/* Navigation Buttons (top-right) */}
      <div className="navigation-buttons">
        <button onClick={openIVT}>Go to IVT Unit</button>
        <button onClick={openCCTC}>Go to CCTC Unit</button>
        <button onClick={openLNP}>Go to LNP Unit</button>
        <button onClick={openLyo}>Go to Freeze-drying Unit</button>
      </div>

      {/* Layout with sidebar + main content */}
      <div className="membrane-layout">
        {/* 1) Sidebar on the left */}
        <MembraneSidebar
          inputs={inputs}
          handleInputChange={handleInputChange}
          handleTagClick={handleTagClick}
          selectedInputVar={selectedInputVar}
        />

        {/* 2) Main content on the right (vertical stacking) */}
        <div className="membrane-main-content">
          {/* PDE Concentration Panel */}
          <div className="membrane-concentration-panel">
            <MembraneConcentration
              timePoints={timePoints}
              xPositions={xPositions}
              Cmatrix_mRNA={Cmatrix_mRNA}
              Cmatrix_protein={Cmatrix_protein}
              Cmatrix_ntps={Cmatrix_ntps}
              onConcentrationSelection={handleConcentrationSelection}
            />
          </div>

          {/* Diafiltration Panel */}
          <div className="membrane-diafiltration-panel">
            <MembraneDiafiltration
              TFF_protein={TFF_protein}
              TFF_ntps={TFF_ntps}
              td={td}
              onDiafiltrationSelection={handleDiafiltrationSelection}
            />
          </div>

          {/* Membrane Figure */}
          <div className="membrane-figure-panel">
            <MembraneFigure />
          </div>

          {/* Outputs (Jcrit, Xactual) */}
          <div className="membrane-outputs-panel">
            <MembraneOutputs
              outputs={outputs}
              handleTagClick={() => {}} // Not used
              selectedOutputVar={null}
            />
          </div>

          {/* Graphs (3 Panels) */}
          <div className="membrane-graphs-panel">
            <MembraneGraphs
              // Graph #1 => input
              selectedInputVar={selectedInputVar}
              inputs={inputs}

              // Graph #2 => PDE
              concSelection={concSelection}
              timePoints={timePoints}
              xPositions={xPositions}
              Cmatrix_mRNA={Cmatrix_mRNA}
              Cmatrix_protein={Cmatrix_protein}
              Cmatrix_ntps={Cmatrix_ntps}

              // Graph #3 => TFF
              diafSelection={diafSelection}
              td={td}
              TFF_protein={TFF_protein}
              TFF_ntps={TFF_ntps}
            />
          </div>

          {/* Run button at the bottom */}
          <div className="membrane-run-panel">
            <MembraneRun
              runTime={runTime}
              setRunTime={setRunTime}
              handleRunMembrane={handleRunMembrane}
            />
          </div>
        </div>
      </div>
    </div>
  );
}

export default Membrane;