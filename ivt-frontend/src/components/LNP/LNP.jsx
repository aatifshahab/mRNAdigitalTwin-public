// src/components/LNP/LNP.jsx

import React, { useState, useEffect, useContext } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { useLocation } from 'react-router-dom';
import styles from './LNP.module.css';

import { SimulationContext } from '../../context/SimulationContext';

import LNPInputs from './Inputs/LNPInputs';
import LNPOutputs from './Outputs/LNPOutputs';
import LNPGraphs from './Graphs/LNPGraphs';
import LNPFigure from './Figure/LNPFigure';
import LNPRun from './Run/LNPRun';

function LNP() {
  const location = useLocation();
  const { getUnitResult, addChainResult } = useContext(SimulationContext);
  const params        = new URLSearchParams(location.search);
  const runId         = params.get('run_id');         // the top‐level run UUID
  const unitUniqueId  = params.get('unit_uniqueId');
  const uniqueId = params.get('uniqueId');

  // -----------------------------------
  // 1. State: Inputs and Outputs
  // -----------------------------------
  const [inputs, setInputs] = useState({
    Residential_time: 3600, 
    FRR: 3,
    pH: 5.5,
    Ion: 0.1,
    TF: 0,
    C_lipid: 10,    
    mRNA_in: 10,
  });

  const [outputs, setOutputs] = useState({
    Diameter: [],
    PSD: [],
    EE: null,       
    Fraction: null,
    error: null,
  });

  // Manage loading/error states
  const [isRunning, setIsRunning] = useState(false);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  // -----------------------------------
  // 2. Check if there's a uniqueId in the URL => Chain Mode
  // -----------------------------------
  useEffect(() => {
    

    if ( !unitUniqueId) {
      // Standalone mode => skip fetch
      setLoading(false);
      return;
    }

    // If chain mode, fetch from the backend (via context)
    (async () => {
      try {
        const result = await getUnitResult(runId, unitUniqueId);
        if (!result) {
          setError(`No LNP result found for uniqueId=${unitUniqueId}`);
        } else {
          setOutputs({
            Diameter: result.Diameter || [],
            PSD: result.PSD || [],
            EE:       result.EE         != null ? result.EE       : null,
            Fraction: result.Fraction   != null ? result.Fraction : null,
            error: result.error || null,
          });
        }
      } catch (err) {
        console.error('Error fetching LNP chain data:', err);
        setError('Failed to load LNP chain data.');
      }
      setLoading(false);
    })();
  }, [runId, unitUniqueId, getUnitResult]);

  // -----------------------------------
  // 3. Handle Input Changes
  // -----------------------------------
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setInputs((prev) => ({
      ...prev,
      [name]: parseFloat(value),
    }));
    // Optionally reset outputs if you want
  };

  // -----------------------------------
  // 4. Single-Unit Chain Run
  // -----------------------------------
  const handleRun = async () => {
    setIsRunning(true);
    setError(null);

    try {
      const localUniqueId = `lnp_${uuidv4()}`;
      // Build the chain array with just one LNP unit
      const chain = [
        {
          id: 'lnp',
          uniqueId: localUniqueId,
          inputs: { ...inputs },
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

      // Find our single result
      const singleResult = data.chainResults.find(
        (item) => item.uniqueId === localUniqueId
      );
      if (!singleResult) {
        throw new Error('No LNP result found in chainResults.');
      }

      const sim = singleResult.result;
      // sim => { Diameter: [...], PSD: [...], error: null }
      setOutputs({
        Diameter: sim.Diameter || [],
        PSD: sim.PSD || [],
        error: sim.error || null,
      });

      // Optionally store in context
      addChainResult(localUniqueId, sim);

      alert('LNP Simulation Completed Successfully!');
    } catch (err) {
      console.error('Error in handleRun:', err);
      setOutputs({ Diameter: [], PSD: [], error: err.message });
      setError(err.message);
    } finally {
      setIsRunning(false);
    }
  };

  // -----------------------------------
  // 5. Navigation to Other Units
  // -----------------------------------
  const openIVT = () => {
    window.open(`/ivt`, '_blank', 'width=800,height=600');
  };
  const openCCTC = () => {
    window.open(`/cctc`, '_blank', 'width=800,height=600');
  };
  const openMembrane = () => {
    window.open(`/membrane`, '_blank', 'width=800,height=600');
  };
  const openLyo = () => {
    window.open(`/lyo`, '_blank', 'width=800,height=600');
  };

  // Check chain vs. standalone
  // const isChainMode = !!params.get('uniqueId');
  const isChainMode = !!unitUniqueId;

  return (
    <div className={styles.lnpContainer}>
      <h1 className={styles.title}>LNP Unit</h1>

      {/* Navigation Buttons */}
      <div className={styles.navigationButtons}>
        <button onClick={openIVT} className={styles.navButton}>
          Go to IVT Unit
        </button>
        <button onClick={openCCTC} className={styles.navButton}>
          Go to CCTC Unit
        </button>
        <button onClick={openMembrane} className={styles.navButton}>
          Go to Membrane Unit
        </button>
        <button onClick={openLyo} className={styles.navButton}>
          Go to Freeze-drying Unit
        </button>
      </div>

      {loading && <div>Loading...</div>}
      {error && <div className={styles.errorMessage}>{error}</div>}

      {!loading && !error && (
        <>
          {/* Layout with Inputs and Outputs */}
          <div className={styles.lnpLayout}>
            <LNPInputs inputs={inputs} handleInputChange={handleInputChange} />
            <LNPOutputs outputs={outputs} />
          </div>

          {/* Graphs */}
          <LNPGraphs outputs={outputs} />

          {/* Figure */}
          <LNPFigure />

          {/* Run Button (only in standalone mode) */}
          {!isChainMode && (
            <LNPRun handleRun={handleRun} isRunning={isRunning} />
          )}
        </>
      )}
    </div>
  );
}

export default LNP;
