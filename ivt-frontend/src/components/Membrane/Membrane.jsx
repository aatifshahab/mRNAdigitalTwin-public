// src/components/Membrane/Membrane.jsx
import React, { useState, useEffect, useContext } from 'react';
import { useLocation } from 'react-router-dom';
import { v4 as uuidv4 } from 'uuid';

import { SimulationContext } from '../../context/SimulationContext';

// Import subcomponents:
import MembraneSidebar from './MembraneSidebar/MembraneSidebar';
import MembraneOutputs from './MembraneOutputs/MembraneOutputs';
import MembraneFigure from './MembraneFigure/MembraneFigure';
import MembraneGraphs from './MembraneGraphs/MembraneGraphs';
import MembraneRun from './MembraneRun/MembraneRun';
import MembraneConcentration from './MembraneConcentration/MembraneConcentration';
import MembraneDiafiltration from './MembraneDiafiltration/MembraneDiafiltration';

import './Membrane.module.css';

function Membrane() {
  const location = useLocation();
  const { getUnitResult, addChainResult } = useContext(SimulationContext);
  const params        = new URLSearchParams(location.search);
  const runId         = params.get('run_id');         // e.g. “0682…”
  const unitUniqueId  = params.get('unit_uniqueId');

  // -----------------------------------
  // 1. State Management
  // -----------------------------------
  const [inputs, setInputs] = useState({
    qF: 1.0,
    c0_mRNA: 1.0,
    c0_protein: 0.5,
    c0_ntps: 0.5,
    X: 0.9,
    n_stages: 3,
    D: 4,
    filterType: 'VIBRO',
  });

  // PDE solution data
  const [timePoints, setTimePoints] = useState([]);
  const [xPositions, setXPositions] = useState([]);
  const [Cmatrix_mRNA, setCmatrix_mRNA] = useState([]);
  const [Cmatrix_protein, setCmatrix_protein] = useState([]);
  const [Cmatrix_ntps, setCmatrix_ntps] = useState([]);
  const [interpolatedTimes, setInterpolatedTimes] = useState([]);
  const [interpolatedIndices, setInterpolatedIndices] = useState([]);

  // Diafiltration data
  const [td, setTd] = useState([]);
  const [TFF_protein, setTFF_protein] = useState([]);
  const [TFF_ntps, setTFF_ntps] = useState([]);
  const [TFF_mRNA, setTFF_mRNA] = useState([]);

  // Outputs
  const [outputs, setOutputs] = useState({
    Jcrit: 0.0,
    Xactual: 0.0,
  });

  // Graph / panel selections
  const [selectedInputVar, setSelectedInputVar] = useState(null);
  const [concSelection, setConcSelection] = useState({
    species: 'mRNA',
    plotType: 'OUTLET_VS_TIME',
  });
  const [diafSelection, setDiafSelection] = useState({
    variable: 'Protein',
    stage: 1,
  });

  // Additional run-time placeholders
  const [runTime, setRunTime] = useState(30);

  // Error / loading states
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  // -----------------------------------
  // 2. Chain Mode: Fetch Stored Results If uniqueId Provided
  // -----------------------------------
  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const uniqueId = params.get('uniqueId');

    if (!unitUniqueId) {
      setLoading(false);
      return; 
    }

    (async () => {
      try {
        const result = await getUnitResult(runId, unitUniqueId);
        if (!result) {
          setError(`No Membrane result found for uniqueId=${unitUniqueId}`);
        } else {
          // "result" shape: { time_points, x_positions, Cmatrix_mRNA, ... }
          setTimePoints(result.time_points || []);
          setXPositions(result.x_positions || []);
          setCmatrix_mRNA(result.Cmatrix_mRNA || []);
          setCmatrix_protein(result.Cmatrix_protein || []);
          setCmatrix_ntps(result.Cmatrix_ntps || []);
          setInterpolatedTimes(result.interpolated_times || []);
          setInterpolatedIndices(result.interpolated_indices || []);
          setTd(result.td || []);
          setTFF_protein(result.TFF_protein || []);
          setTFF_ntps(result.TFF_ntps || []);
          setTFF_mRNA(result.TFF_mRNA || []);
          setOutputs({
            Jcrit: result.Jcrit || 0.0,
            Xactual: result.Xactual || 0.0,
          });
        }
      } catch (err) {
        console.error('Error fetching Membrane chain data:', err);
        setError('Failed to load Membrane chain data.');
      } finally {
        setLoading(false);
      }
    })();
  }, [runId, unitUniqueId, getUnitResult]);

  // -----------------------------------
  // 3. Handle Input Changes
  // -----------------------------------
  const handleInputChange = (e, key) => {
    const val = e.target.value;
    setInputs((prev) => ({
      ...prev,
      [key]: isNaN(parseFloat(val)) ? val : parseFloat(val),
    }));
  };

  const handleTagClick = ({ type, name }) => {
    if (type === 'input') {
      setSelectedInputVar({ type, name });
    }
  };

  // PDE sub-panel: which species, plot type
  const handleConcentrationSelection = (sel) => {
    setConcSelection(sel);
  };

  // Diafiltration sub-panel: which variable, stage
  const handleDiafiltrationSelection = (sel) => {
    setDiafSelection(sel);
  };

  // -----------------------------------
  // 4. Single-Unit Run (Standalone) => /run_chain
  // -----------------------------------
  const handleRunMembrane = async () => {
    // If in chain mode, you might hide or disable this button anyway
    setLoading(true);
    setError(null);

    try {
      const localUniqueId = `membrane_${uuidv4()}`;

      // Build single-unit chain
      const chain = [
        {
          id: 'membrane',
          uniqueId: localUniqueId,
          inputs: {
            ...inputs,
            // Any additional fields the chain code uses?
            // ex: c0_mRNA is used in main.py => run_membrane_model(...)
          },
        },
      ];

      const response = await fetch('http://127.0.0.1:8000/run_chain', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chain }),
      });

      if (!response.ok) {
        const errData = await response.json();
        throw new Error(errData.error || 'Error calling /run_chain');
      }

      const data = await response.json();
      if (data.error) {
        throw new Error(data.error);
      }

      // Extract our single result
      const singleResult = data.chainResults.find(
        (item) => item.uniqueId === localUniqueId
      );
      if (!singleResult) {
        throw new Error('No Membrane result found in chainResults.');
      }

      // singleResult.result => {
      //   time_points, x_positions, Cmatrix_mRNA, ...
      // }
      const sim = singleResult.result;
      setTimePoints(sim.time_points || []);
      setXPositions(sim.x_positions || []);
      setCmatrix_mRNA(sim.Cmatrix_mRNA || []);
      setCmatrix_protein(sim.Cmatrix_protein || []);
      setCmatrix_ntps(sim.Cmatrix_ntps || []);
      setInterpolatedTimes(sim.interpolated_times || []);
      setInterpolatedIndices(sim.interpolated_indices || []);
      setTd(sim.td || []);
      setTFF_protein(sim.TFF_protein || []);
      setTFF_ntps(sim.TFF_ntps || []);
      setTFF_mRNA(sim.TFF_mRNA || []);
      setOutputs({
        Jcrit: sim.Jcrit || 0.0,
        Xactual: sim.Xactual || 0.0,
      });

      // Optionally store in global context
      addChainResult(localUniqueId, sim);
    } catch (err) {
      console.error('Error in handleRunMembrane:', err);
      setError(err.message || 'Failed to run Membrane simulation.');
    } finally {
      setLoading(false);
    }
  };

  // -----------------------------------
  // 5. Navigation to other units
  // -----------------------------------
  const openIVT = () => {
    window.open(`/ivt`, '_blank', 'width=800,height=600');
  };
  const openCCTC = () => {
    window.open(`/cctc`, '_blank', 'width=800,height=600');
  };
  const openLyo = () => {
    window.open(`/lyo`, '_blank', 'width=800,height=600');
  };
  const openLNP = () => {
    window.open(`/lnp`, '_blank', 'width=800,height=600');
  };

  // -----------------------------------
  // 6. Render
  // -----------------------------------
  // const isChainMode = !!params.get('uniqueId');
  const isChainMode = !!unitUniqueId;

  return (
    <div className="membrane-container">
      <h1>Membrane Unit</h1>

      {/* Navigation Buttons */}
      <div className="navigation-buttons">
        <button onClick={openIVT}>Go to IVT Unit</button>
        <button onClick={openCCTC}>Go to CCTC Unit</button>
        <button onClick={openLNP}>Go to LNP Unit</button>
        <button onClick={openLyo}>Go to Freeze-drying Unit</button>
      </div>

      {loading && <div>Loading...</div>}
      {error && <div className="error-message">{error}</div>}

      {/* Only render the main content if not loading/error */}
      {!loading && !error && (
        <div className="membrane-layout">
          {/* Sidebar on the left */}
          <MembraneSidebar
            inputs={inputs}
            handleInputChange={handleInputChange}
            handleTagClick={handleTagClick}
            selectedInputVar={selectedInputVar}
          />

          {/* Main content on the right */}
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
                TFF_mRNA={TFF_mRNA}
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
                handleTagClick={() => {}}
                selectedOutputVar={null}
              />
            </div>

            {/* Graphs */}
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
                TFF_mRNA={TFF_mRNA}
              />
            </div>

            {/* Membrane Run Panel */}
            <div className="membrane-run-panel">
              <MembraneRun
                runTime={runTime}
                setRunTime={setRunTime}
                handleRunMembrane={handleRunMembrane}
              />
            </div>
          </div>
        </div>
      )}

      {/* Single-run Membrane button, if desired, at bottom:
          Or you can rely on <MembraneRun> already having a button, so maybe redundant. */}
      {!isChainMode && (
        <div className="run-unit-button">
          <button onClick={handleRunMembrane} disabled={loading}>
            {loading ? 'Running...' : 'Run Membrane Unit'}
          </button>
        </div>
      )}
    </div>
  );
}

export default Membrane;
