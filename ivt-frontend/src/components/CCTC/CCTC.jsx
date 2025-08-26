// src/components/CCTC/CCTC.jsx

import React, { useState, useEffect, useContext } from 'react';
import { useLocation } from 'react-router-dom';
import { v4 as uuidv4 } from 'uuid';

import { SimulationContext } from '../../context/SimulationContext';
import CCTCInputs from './CCTCInputs/CCTCInputs';
import CCTCOutputs from './CCTCOutputs/CCTCOutputs';
import CCTCFigure from './CCTCFigure/CCTCFigure';
import CCTCGraphs from './CCTCGraphs/CCTCGraphs';
import './CCTC.css';

function CCTC() {
  const location = useLocation();
  const { getUnitResult, addChainResult } = useContext(SimulationContext);
  const params        = new URLSearchParams(location.search);
  const runId         = params.get('run_id');         // e.g. "0682…"
  const unitUniqueId  = params.get('unit_uniqueId');

  // -----------------------------------
  // 1. State Management
  // -----------------------------------
  const [cctcInputs, setCctcInputs] = useState({
    F103: 1.0,
    mRNA: 0.5,
    resin: 0.2,
  });

  // We'll store the time arrays, etc. in cctcOutputs
  const [cctcOutputs, setCctcOutputs] = useState({
    time: [],
    unbound_mRNA: [],
    bound_mRNA: [],
  });

  const [selectedTag, setSelectedTag] = useState('F103');
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  // -----------------------------------
  // 2. Check for uniqueId in the URL (Chain Mode)
  // -----------------------------------
  useEffect(() => {
   

    // If no uniqueId => Standalone usage
    if (!unitUniqueId) {
      setLoading(false);
      return;
    }

    // If we do have a uniqueId => attempt to fetch chain results
    (async () => {
      try {
        const fetched = await getUnitResult(runId, unitUniqueId);
        if (!fetched) {
          // Could be a 404 or some other error
          setError(`No simulation result for run=${runId}, unit=${unitUniqueId}`);
        } else {
          // fetched should look like { time: [...], unbound_mRNA: [...], bound_mRNA: [...] }
          setCctcOutputs({
            time: fetched.time || [],
            unbound_mRNA: fetched.unbound_mRNA || [],
            bound_mRNA: fetched.bound_mRNA || [],
          });
          setError(null);
        }
      } catch (err) {
        console.error('Error loading chain data for CCTC:', err);
        setError('Failed to load chain data.');
      }
      setLoading(false);
    })();
  }, [runId, unitUniqueId, getUnitResult]);

  // -----------------------------------
  // 3. Handle Input Changes
  // -----------------------------------
  const handleCCTCInputChange = (e, name) => {
    const value = parseFloat(e.target.value);
    if (!isNaN(value)) {
      setCctcInputs((prev) => ({
        ...prev,
        [name]: value,
      }));
    }
  };

  // -----------------------------------
  // 4. Standalone Single-Unit Run via /run_chain
  // -----------------------------------
  const handleRunCCTC = async () => {
    setLoading(true);
    setError(null);

    try {
      // Generate a uniqueId for this single run
      const localUniqueId = `cctc_${uuidv4()}`;

      // Build the chain array with just one unit
      const chain = [
        {
          id: 'cctc',
          uniqueId: localUniqueId,
          inputs: {
            // The field your main.py chain code expects
            states0_last_value: cctcInputs.mRNA,
            // Optionally pass other fields if your chain logic uses them
          },
        },
      ];

      const response = await fetch('http://127.0.0.1:8000/run_chain', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chain }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Error calling /run_chain');
      }

      const data = await response.json();
      if (data.error) {
        throw new Error(data.error);
      }

      // We expect data.chainResults: [{ unitId, uniqueId, result }, ...]
      const singleResult = data.chainResults.find(
        (item) => item.uniqueId === localUniqueId
      );

      if (!singleResult) {
        throw new Error('No CCTC result found in chainResults.');
      }

      // The actual simulation data is in singleResult.result
      setCctcOutputs({
        time: singleResult.result.time || [],
        unbound_mRNA: singleResult.result.unbound_mRNA || [],
        bound_mRNA: singleResult.result.bound_mRNA || [],
      });

      // Optionally store it in the SimulationContext
      addChainResult(localUniqueId, singleResult.result);

      setError(null);
    } catch (err) {
      console.error('Error in handleRunCCTC:', err);
      setError(err.message || 'Failed to run CCTC simulation.');
    } finally {
      setLoading(false);
    }
  };

  // -----------------------------------
  // 5. Navigation to Other Units (optional)
  // -----------------------------------
  const openIVT = () => {
    window.open(`/ivt`, '_blank', 'width=800,height=600');
  };
  const openMembrane = () => {
    window.open(`/membrane`, '_blank', 'width=800,height=600');
  };
  const openLNP = () => {
    window.open(`/lnp`, '_blank', 'width=800,height=600');
  };
  const openLyo = () => {
    window.open(`/lyo`, '_blank', 'width=800,height=600');
  };

  // -----------------------------------
  // 6. Render
  // -----------------------------------
  // If we're in chain mode (uniqueId in URL), we won't show the 'Run CCTC Unit' button
 
  // const isChainMode = !!params.get('uniqueId');
  const isChainMode = !!unitUniqueId;

  return (
    <div className="cctc-container">
      <h1>CCTC Unit</h1>

      {/* Navigation Buttons */}
      <div className="navigation-buttons">
        <button onClick={openIVT}>Go to IVT Unit</button>
        <button onClick={openMembrane}>Go to Membrane Unit</button>
        <button onClick={openLNP}>Go to LNP Unit</button>
        <button onClick={openLyo}>Go to Freeze-drying Unit</button>
      </div>

      {/* If loading, show a simple loading message */}
      {loading && <div>Loading...</div>}

      {/* If there's an error, show it */}
      {error && <div className="error-message">{error}</div>}

      {/* Only render the main content if not loading */}
      {!loading && !error && (
        <>
          {/* Top Section: Inputs, Figure, Outputs */}
          <div className="cctc-top-section">
            <div className="cctc-inputs-wrapper">
              <CCTCInputs
                cctcInputs={cctcInputs}
                handleCCTCInputChange={handleCCTCInputChange}
                selectedTag={selectedTag}
                setSelectedTag={setSelectedTag}
              />
            </div>

            <div className="cctc-figure-wrapper">
              <CCTCFigure />
            </div>

            <div className="cctc-outputs-wrapper">
              <CCTCOutputs cctcOutputs={cctcOutputs} />
            </div>
          </div>

          {/* Bottom Section: Graphs */}
          <div className="cctc-bottom-section">
            <CCTCGraphs
              cctcOutputs={cctcOutputs}
              cctcInputs={cctcInputs}
              selectedTag={selectedTag}
            />
          </div>

          {/* Run button only in standalone mode (no uniqueId) */}
          {!isChainMode && (
            <div className="run-unit-button">
              <button onClick={handleRunCCTC} disabled={loading}>
                {loading ? 'Running...' : 'Run CCTC Unit'}
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default CCTC;
