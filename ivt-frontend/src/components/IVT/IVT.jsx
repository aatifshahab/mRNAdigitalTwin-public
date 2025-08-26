// src/components/IVT/IVT.jsx

import React, { useState, useEffect, useContext } from 'react';
import { useLocation } from 'react-router-dom';
import Sidebar from './Sidebar/Sidebar';
import MeasuredVariables from './MeasuredVariables/MeasuredVariables';
// import OutputVariables from './OutputVariables/OutputVariables';
import CstrFigure from './CstrFigure/CstrFigure';
import Graphs from './Graphs/Graphs';
import RunPlant from './RunPlant/RunPlant';
// import axios from 'axios';  // We can just use fetch instead if we like
import  styles from './IVT.module.css';
import { labelMapping } from '../utilits/labelMapping';
import { calculateF102 } from '../utilits/calculateF102';
import { SimulationContext } from '../../context/SimulationContext'; 
import { v4 as uuidv4 } from 'uuid';
import UpdatedOutput from './UpdatedOutput/UpdatedOutput';
// in src/components/Graphs/Graphs.jsx (or IVT.jsx)




function useQuery() {
  return new URLSearchParams(useLocation().search);
}

function IVT() {
  const query    = useQuery();
  const { search } = useLocation();
  const uniqueId = query.get('uniqueId');
  const params        = new URLSearchParams(search);
  const runId         = query.get('run_id');        
  const unitUniqueId  = query.get('unit_uniqueId');  
  const isChainMode   = !!unitUniqueId;


  const { getUnitResult, addChainResult } = useContext(SimulationContext);

  // -----------------------------------
  // 1. State Management
  // -----------------------------------
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

  // State for measured variables
  const [measuredVariables, setMeasuredVariables] = useState({
    ATP: [0.00],
    GTP: [0.00],
    CTP: [0.00],
    UTP: [0.00],
    Phosphate: [0.00],
    pH: [7.00],
    Mg: [0.00],
    // mRNA: [0.00],
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

  // State for output variables
  // const [outputVariables, setOutputVariables] = useState({
  //   F102: [0.00],
  // });
  // const [outputUnits, setOutputUnits] = useState({
  //   F102: 'L/hr',
  // });

  
  const [outputVariables, setOutputVariables] = useState({ mRNA: [] });
  const [outputUnits, setOutputUnits]         = useState({ mRNA: '' });
  // State for selected variables
  const [selectedInputVariable, setSelectedInputVariable] = useState(null);
  const [selectedMeasuredVariable, setSelectedMeasuredVariable] = useState(null);
  const [selectedOutputVariable, setSelectedOutputVariable] = useState(null);

  // Error / loading
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  // -----------------------------------
  // 2. Helper Mappings
  // -----------------------------------
  const unitsMapping = {
    ATPo: 'mM',
    GTPo: 'mM',
    CTPo: 'mM',
    UTPo: 'mM',
    pHo: '',
    TotalMgo: 'mM',
    Phosphateo: 'mM',
    TotalRNAo: 'µM',
  };

  const variableNameMapping = {
    TotalMgo: 'Mg',
    TotalRNAo: 'mRNA',
  };

  const outputUnitsMapping = {
    mRNA: 'µM',
  };

  // -----------------------------------
  // 3. Utility Functions
  // -----------------------------------
  // Map backend variable names to frontend-friendly names
  const mapVariableNames = (data) => {
    const mappedVariables = {};
    const mappedUnits = {};

    Object.keys(data).forEach((key) => {
      if (key === 'time') return;

      const frontendName =
        labelMapping[key] || (key.endsWith('o') ? key.slice(0, -1) : key);

      mappedVariables[frontendName] = data[key];
      mappedUnits[frontendName] = unitsMapping[key] || '';
    });

    return { mappedVariables, mappedUnits };
  };

  // -----------------------------------
  // 4. Single-Unit Simulation via /run_chain
  // -----------------------------------
  // (Standalone mode: user not coming from MainConfig, so there's no uniqueId param)
  const handleRunPlant = async () => {
    // We'll generate our own uniqueId
    const localUniqueId = `ivt_${uuidv4()}`;

    // Prepare a chain array with only one item
    const chain = [
      {
        id: 'ivt',
        uniqueId: localUniqueId,
        inputs: {
          ...inputs,
          finaltime: finalTime,
        },
      },
    ];

    try {
      // Call the chain endpoint
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
        alert(`Error: ${data.error}`);
        return;
      }
      if (!data.chainResults) {
        alert('No chainResults returned.');
        return;
      }

      // Find our single result
      const singleResult = data.chainResults.find(
        (r) => r.uniqueId === localUniqueId
      );
      if (!singleResult) {
        alert('No matching result for the IVT unit in chainResults');
        return;
      }

      // Store this result in simulationResult
      setSimulationResult(singleResult.result);

      // Also store in global context if desired
      addChainResult(singleResult);

      // Extract time data
      const simData = singleResult.result;
      setTimeData(simData.time || []);

      // Map measured variables
      const { mappedVariables, mappedUnits } = mapVariableNames(simData);
      setMeasuredVariables(mappedVariables);
      setMeasuredUnits(mappedUnits);

      // // Generate F102
      // const F102Data = calculateF102(simData.time, inputs.Q, inputs.V);
      // setOutputVariables({
      //   F102: F102Data,
      // });
      setOutputVariables({ mRNA: mappedVariables.mRNA || [] });
      setOutputUnits(outputUnitsMapping);

      alert('IVT Simulation (single-unit) completed successfully!');
      setError(null);

    } catch (err) {
      console.error('Error running single-unit chain for IVT:', err);
      alert('Error running IVT simulation (chain). Check console for details.');
      setError(err.message);
    }
  };

  // Function to handle input changes
  const handleInputChange = (e, name) => {
    const value = parseFloat(e.target.value);
    if (!isNaN(value)) {
      setInputs({ ...inputs, [name]: value });
      if (simulationResult) {
        alert('Changing inputs clears previous simulation results.');
        clearSimulationData();
      }
    }
  };

  const handleFinalTimeChange = (e) => {
    const value = parseFloat(e.target.value);
    if (!isNaN(value)) {
      setFinalTime(value);
      if (simulationResult) {
        alert('Changing final time clears previous simulation results.');
        clearSimulationData();
      }
    }
  };

  const clearSimulationData = () => {
    setSimulationResult(null);
    setMeasuredVariables({
      ATP: [0.00],
      GTP: [0.00],
      CTP: [0.00],
      UTP: [0.00],
      Phosphate: [0.00],
      pH: [7.00],
      Mg: [0.00],
      mRNA: [0.00],
    });
    setMeasuredUnits({
      ATP: 'mM',
      GTP: 'mM',
      CTP: 'mM',
      UTP: 'mM',
      pH: '',
      Mg: 'mM',
      Phosphate: 'mM',
      mRNA: 'µM',
    });
    setOutputVariables({
      F102: [0.00],
    });
    setOutputUnits({
      mRNA: 'µM',
    });
    setTimeData([]);
  };

  // -----------------------------------
  // 5. Handle Chain Mode (uniqueId from URL)
  // -----------------------------------
useEffect(() => {
  // Chain‐mode: only fetch if both runId and unitUniqueId are present
  if (!unitUniqueId) {
    setLoading(false);
    return;
  }

  (async () => {
    try {
      const result = await getUnitResult(runId, unitUniqueId);
      if (result) {
        setSimulationResult(result);
        setTimeData(result.time || []);

        const { mappedVariables, mappedUnits } = mapVariableNames(result);
        setMeasuredVariables(mappedVariables);
        setMeasuredUnits(mappedUnits);

        setOutputVariables({ mRNA: mappedVariables.mRNA || [] });
        setOutputUnits(outputUnitsMapping);

        setError(null);
      } else {
        setError('No simulation result found for this unit.');
      }
    } catch (err) {
      console.error('Error fetching simulation data:', err);
      setError('Error fetching simulation data.');
    } finally {
      setLoading(false);
    }
  })();
}, [runId, unitUniqueId, getUnitResult]);


  // Function to handle Tag click
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
    if (!uniqueId) {
      // Standalone: set default selection
      if (!selectedInputVariable && Object.keys(inputs).length > 0) {
        setSelectedInputVariable({
          type: 'input',
          name: Object.keys(inputs)[0],
        });
      }
    }
    if (!selectedMeasuredVariable && Object.keys(measuredVariables).length > 0) {
      setSelectedMeasuredVariable({
        type: 'measured',
        name: Object.keys(measuredVariables)[0],
      });
    }
    if (!selectedOutputVariable && Object.keys(outputVariables).length > 0) {
      setSelectedOutputVariable({
        type: 'output',
        name: Object.keys(outputVariables)[0],
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    inputs,
    measuredVariables,
    outputVariables,
    selectedInputVariable,
    selectedMeasuredVariable,
    selectedOutputVariable,
    uniqueId,
  ]);

  // Navigation to other units (if you still want them in single-standalone mode)
  const openMembrane = () => {
    const newUniqueId = `membrane_${uuidv4()}`;
    window.open(`/membrane?uniqueId=${newUniqueId}`, '_blank', 'width=800,height=600');
  };
  const openCCTC = () => {
    const newUniqueId = `cctc_${uuidv4()}`;
    window.open(`/cctc?uniqueId=${newUniqueId}`, '_blank', 'width=800,height=600');
  };
  const openLNP = () => {
    const newUniqueId = `lnp_${uuidv4()}`;
    window.open(`/lnp?uniqueId=${newUniqueId}`, '_blank', 'width=800,height=600');
  };
  const openLyo = () => {
    const newUniqueId = `lyo_${uuidv4()}`;
    window.open(`/lyo?uniqueId=${newUniqueId}`, '_blank', 'width=800,height=600');
  };

  return (
    <div className={styles.ivtContainer}>
      <h1 className={styles.heading}>IVT Unit</h1>

      <div className={styles.navigationButtons}>
        <button onClick={openMembrane}>Go to Membrane Unit</button>
        <button onClick={openCCTC}>Go to CCTC Unit</button>
        <button onClick={openLNP}>Go to LNP Unit</button>
        <button onClick={openLyo}>Go to Freeze-drying Unit</button>
      </div>

      <div className={styles.layout}>
        <Sidebar
          inputs={inputs}
          inputUnits={inputUnits}
          handleInputChange={handleInputChange}
          handleTagClick={handleTagClick}
          selectedInputVariable={selectedInputVariable}
        />

        <div className={styles.mainContent}>
          <div className={styles.topSection}>
            <MeasuredVariables
              measuredVariables={measuredVariables}
              measuredUnits={measuredUnits}
              handleTagClick={handleTagClick}
              selectedMeasuredVariable={selectedMeasuredVariable}
            />

            <div className={styles.ivtFigureOutput}>
              <CstrFigure />
              <UpdatedOutput
                outputVariables={outputVariables}
                outputUnits={outputUnits}
                handleTagClick={handleTagClick}
                selectedOutputVariable={selectedOutputVariable}
              />
            </div>
          </div>

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

          {!isChainMode && (
            <RunPlant
              finalTime={finalTime}
              handleFinalTimeChange={handleFinalTimeChange}
              handleRunPlant={handleRunPlant}
            />
          )}
        </div>
      </div>

      {error && <div className={styles.errorMessage}>{error}</div>}
      {!isChainMode && loading && (
        <div className={styles.loadingMessage}>Loading simulation data...</div>
      )}
    </div>
  );
}

export default IVT;
