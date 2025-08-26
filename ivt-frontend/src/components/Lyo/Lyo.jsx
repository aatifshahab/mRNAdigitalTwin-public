// src/components/Lyo/Lyo.jsx

import React, { useState, useEffect, useContext } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { useLocation } from 'react-router-dom';
import styles from './Lyo.module.css';

import { SimulationContext } from '../../context/SimulationContext';

import LyoInputs from './Inputs/LyoInputs';
import LyoMeasured from './Measured/LyoMeasured';
import LyoOutputs from './Outputs/LyoOutputs';
import LyoGraphs from './Graphs/LyoGraphs';
import LyoFigure from './Figure/LyoFigure';

function Lyo() {
  const location = useLocation();
  const { getUnitResult, addChainResult } = useContext(SimulationContext);
  const params        = new URLSearchParams(location.search);
  const runId         = params.get('run_id');         // top‐level run UUID
  const unitUniqueId  = params.get('unit_uniqueId');
  const uniqueId = params.get('uniqueId');

  // -----------------------------------
  // 1. State Management
  // -----------------------------------
  const [lyoInputs, setLyoInputs] = useState({
    InitfreezingTemperature: 298.15,
    InitprimaryDryingTemperature: 228,
    InitsecondaryDryingTemperature: 273,
    TempColdGasfreezing: 268,
    TempShelfprimaryDrying: 270,
    TempShelfsecondaryDrying: 295,
    Pressure: 10,
    massFractionmRNA: 0.05,
    fluidVolume: 3e-6,
  });

  // For selected "tags"/variables
  const [selectedInputTag, setSelectedInputTag] = useState('Temperature');
  const [selectedMeasuredVariable, setSelectedMeasuredVariable] = useState(null);
  const [selectedOutputVariable, setSelectedOutputVariable] = useState(null);

  // Outputs
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

  // Measured
  const [lyoMeasured, setLyoMeasured] = useState({
    operatingTemperature: [],
    operatingPressure: [],
  });

  // Loading & error
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  // -----------------------------------
  // 2. Check for `uniqueId` => Chain Mode
  // -----------------------------------
  useEffect(() => {
    

    if ( !unitUniqueId) {
      // Standalone => no fetch
      setIsLoading(false);
      return;
    }

    // Chain mode => fetch from backend
    (async () => {
      try {
        const fetched = await getUnitResult(runId, unitUniqueId);
        if (!fetched) {
          setError(`No Lyo result found for uniqueId=${unitUniqueId}`);
        } else {
          // The shape from main.py => { time1, time2, time3, time, massOfIce, ... }
          setLyoOutputs({
            time1: fetched.time1 || [],
            time2: fetched.time2 || [],
            time3: fetched.time3 || [],
            time: fetched.time || [],
            massOfIce: fetched.massOfIce || [],
            boundWater: fetched.boundWater || [],
            productTemperature: fetched.productTemperature || [],
            operatingPressure: fetched.operatingPressure || [],
            operatingTemperature: fetched.operatingTemperature || [],
          });
          setLyoMeasured({
            operatingTemperature: fetched.operatingTemperature || [],
            operatingPressure: fetched.operatingPressure || [],
          });
        }
      } catch (err) {
        console.error('Error loading Lyo chain data:', err);
        setError('Failed to load Lyo chain data.');
      }
      setIsLoading(false);
    })();
  }, [runId, unitUniqueId, getUnitResult]);

  // -----------------------------------
  // 3. Handle Input Changes
  // -----------------------------------
  const handleInputChange = (e, name) => {
    const value = e.target.value;
    setLyoInputs((prev) => ({
      ...prev,
      [name]: isNaN(parseFloat(value)) ? value : parseFloat(value),
    }));
  };

  // -----------------------------------
  // 4. Standalone Run => Single-Unit Chain
  // -----------------------------------
  const handleRunLyo = async () => {
    // Optional: Validate inputs
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
      if (!lyoInputs[field] && lyoInputs[field] !== 0) {
        alert(`Please enter a valid value for ${field}`);
        return;
      }
      if (isNaN(parseFloat(lyoInputs[field]))) {
        alert(`Please enter a numeric value for ${field}`);
        return;
      }
    }

    setIsLoading(true);
    setError(null);

    try {
      // Build single-unit chain
      const localUniqueId = `lyo_${uuidv4()}`;
      const chain = [
        {
          id: 'lyo',
          uniqueId: localUniqueId,
          inputs: { ...lyoInputs },
        },
      ];

      // Call run_chain
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

      // Extract single result
      const singleResult = data.chainResults.find(
        (item) => item.uniqueId === localUniqueId
      );
      if (!singleResult) {
        throw new Error('No Lyo result found in chainResults.');
      }

      const sim = singleResult.result;
      setLyoOutputs({
        time1: sim.time1 || [],
        time2: sim.time2 || [],
        time3: sim.time3 || [],
        time: sim.time || [],
        massOfIce: sim.massOfIce || [],
        boundWater: sim.boundWater || [],
        productTemperature: sim.productTemperature || [],
        operatingPressure: sim.operatingPressure || [],
        operatingTemperature: sim.operatingTemperature || [],
      });

      setLyoMeasured({
        operatingTemperature: sim.operatingTemperature || [],
        operatingPressure: sim.operatingPressure || [],
      });

      addChainResult(localUniqueId, sim);

      alert('Lyophilization simulation completed successfully!');
    } catch (err) {
      console.error('Error running Lyo simulation:', err);
      setError(err.message || 'Failed to run simulation. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // -----------------------------------
  // 5. Navigation Functions
  // -----------------------------------
  const openIVT = () => {
    window.open('/ivt', '_blank', 'width=800,height=600');
  };
  const openMembrane = () => {
    window.open('/membrane', '_blank', 'width=800,height=600');
  };
  const openCCTC = () => {
    window.open('/cctc', '_blank', 'width=800,height=600');
  };
  const openLNP = () => {
    window.open('/lnp', '_blank', 'width=800,height=600');
  };

  // Check if chain mode
  // const isChainMode = !!params.get('uniqueId');
  const isChainMode = !!unitUniqueId;

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Lyophilization Unit</h1>

      {/* Navigation Buttons */}
      <div className={styles.navigationButtons}>
        <button onClick={openIVT} className={styles.navButton}>
          Go to IVT Unit
        </button>
        <button onClick={openMembrane} className={styles.navButton}>
          Go to Membrane Unit
        </button>
        <button onClick={openCCTC} className={styles.navButton}>
          Go to CCTC Unit
        </button>
        <button onClick={openLNP} className={styles.navButton}>
          Go to LNP Unit
        </button>
      </div>

      {isLoading && <div>Loading...</div>}
      {error && <div className={styles.errorMessage}>{error}</div>}

      {!isLoading && !error && (
        <>
          {/* Inputs */}
          <div className={styles.inputsContainer}>
            <LyoInputs
              lyoInputs={lyoInputs}
              handleInputChange={handleInputChange}
              selectedInputTag={selectedInputTag}
              setSelectedInputTag={setSelectedInputTag}
            />
          </div>

          {/* Measured */}
          <div className={styles.measuredContainer}>
            <LyoMeasured
              lyoMeasured={lyoMeasured}
              selectedMeasuredVariable={selectedMeasuredVariable}
              setSelectedMeasuredVariable={setSelectedMeasuredVariable}
            />
          </div>

          {/* Outputs */}
          <div className={styles.outputContainer}>
            <LyoOutputs
              lyoOutputs={lyoOutputs}
              selectedOutputVariable={selectedOutputVariable}
              setSelectedOutputVariable={setSelectedOutputVariable}
            />
          </div>

          {/* Lyo diagram */}

          <LyoFigure/>  

          {/* Graphs */}
          <div className={styles.graphContainer}>
            <LyoGraphs
              selectedMeasuredVariable={selectedMeasuredVariable}
              selectedOutputVariable={selectedOutputVariable}
              lyoOutputs={lyoOutputs}
              lyoMeasured={lyoMeasured}
            />
          </div>

          {/* Run Unit Button (Standalone) */}
          {!isChainMode && (
            <div className={styles.runUnitButton}>
              <button
                onClick={handleRunLyo}
                className={styles.runButton}
                disabled={isLoading}
              >
                {isLoading ? 'Running...' : 'Run Lyophilization Unit'}
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default Lyo;
