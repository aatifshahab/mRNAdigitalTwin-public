// src/components/MainConfig/MainConfig.jsx

import React, { useState, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import styles from './MainConfig.module.css';
import { SimulationContext } from '../../context/SimulationContext';
import { v4 as uuidv4 } from 'uuid';

function MainConfig() {
  // Define available units
  const availableUnits = [
    { id: 'ivt', name: 'IVT Unit' },
    { id: 'membrane', name: 'TFF Unit' },
    { id: 'cctc', name: 'CCTC Unit' },
    { id: 'lnp', name: 'LNP Unit' },
    { id: 'lyo', name: 'Freeze-drying Unit' },
  ];

  const navigate = useNavigate();

  // State for arranged units in the process flow
  const [processFlow, setProcessFlow] = useState([]);

  // State for managing which unit is being edited
  const [unitBeingEdited, setUnitBeingEdited] = useState(null);

  // State for editing inputs
  const [editedInputs, setEditedInputs] = useState({});

  // **New State**: Tracks if an error has occurred
  const [error, setError] = useState(null);

  // **New State**: Tracks if the simulation has completed
  const [simulationCompleted, setSimulationCompleted] = useState(false);

  // **Existing State**: Tracks if the simulation is running
  const [isRunningChain, setIsRunningChain] = useState(false);

  // Access Simulation Context
  const { addChainResult } = useContext(SimulationContext);

  // Add a new unit to the flow
  const addUnit = (unit) => {
    // Enforce unit sequence rules: No units after LNP except Lyophilization
    const lastUnit = processFlow[processFlow.length - 1];
    if (lastUnit && lastUnit.id === 'lnp' && unit.id !== 'lyo') {
      alert('Only Lyophilization can follow LNP.');
      return;
    }

    const existingCount = processFlow.filter((u) => u.id === unit.id).length;
    const instanceNum = existingCount + 1;
    const newUnit = {
      ...unit,
      instance: instanceNum,
      uniqueId: `${unit.id}_${uuidv4()}`,
      inputs: getDefaultInputsForUnit(unit.id),
    };
    setProcessFlow((prev) => [...prev, newUnit]);
  };

  const getDefaultInputsForUnit = (unitId) => {
    switch (unitId) {
      case 'ivt':
        return {
          Q: 1.0,
          V: 2.0,
          T7RNAP: 1e-7,
          ATP: 0.0032,
          CTP: 0.0032,
          GTP: 0.0032,
          UTP: 0.0032,
          Mg: 0.008,
          DNA: 7.4,
          finaltime: 2.0,
        };
      case 'membrane':
        return {
          qF: 1.0,
          c0_mRNA: 1.0,
          c0_protein: 0.5,
          c0_ntps: 0.5,
          X: 0.9,
          n_stages: 3,
          D: 4,
          filterType: 'VIBRO',
        };
      case 'cctc':
        return {
          F103: 1.0,
          mRNA: 0.5,
          resin: 0.0,
        };
      case 'lnp':
        return {
          Residential_time: 3600.0,
          FRR: 3.0,
          pH: 5.5,
          Ion: 0.1,
          TF: 0.0,
          C_lipid: 10.0,
          mRNA_in: 10.0,
        };
      case 'lyo':
        return {
          fluidVolume: 3e-6,
          massFractionmRNA: 0.05,
          InitfreezingTemperature: 298.15,
          InitprimaryDryingTemperature: 228,
          InitsecondaryDryingTemperature: 273,
          TempColdGasfreezing: 268,
          TempShelfprimaryDrying: 270,
          TempShelfsecondaryDrying: 295,
          Pressure: 10,
        };
      default:
        return {};
    }
  };

  // Remove a unit from the flow
  const removeUnit = (uniqueId) => {
    setProcessFlow((prev) => prev.filter((u) => u.uniqueId !== uniqueId));
  };

  // Open a unit in a new tab (simpler approach)
  const openOrFocusWindow = (unit) => {
    // const url = `${window.location.origin}/${unit.id}?uniqueId=${unit.uniqueId}`;
    const url =
      `${window.location.origin}/${unit.id}` +
      `?unit_uniqueId=${unit.uniqueId}`;
    const windowFeatures = 'width=800,height=600';

    // Always open in a new tab/window
    const newWindow = window.open(url, '_blank', windowFeatures);
    if (!newWindow) {
      alert('Popup blocked! Please allow popups for this domain.');
    }
  };

  // Handle chain run
  const runChain = async () => {
    // Show that we are running
    setIsRunningChain(true);
    // **Reset simulationCompleted** when a new run starts
    setSimulationCompleted(false);
    // **Reset error** when a new run starts
    setError(null);

    // Prepare the chain array
    const chain = processFlow.map((unit) => ({
      id: unit.id,
      inputs: unit.inputs,
      uniqueId: unit.uniqueId,
    }));

    try {
      const response = await fetch(`http://127.0.0.1:8000/run_chain`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chain }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        setError(errorData.error || 'An unexpected error occurred.');
        alert(`Error: ${errorData.error || 'An unexpected error occurred.'}`);
        setIsRunningChain(false);
        return;
      }

      const data = await response.json();
      console.log('Chain Results:', data.chainResults);

      // Store the results in the global context
      data.chainResults.forEach((unitRes) => {
        addChainResult(unitRes.uniqueId, unitRes.result);
      });

      // **Set simulationCompleted to true** after successful run
      setSimulationCompleted(true);
    } catch (error) {
      console.error('Error running chain:', error);
      setError('An error occurred while running the plant simulation.');
      alert('An error occurred while running the plant simulation.');
    } finally {
      setIsRunningChain(false);
    }
  };

  // Edit unit
  const editUnit = (unit) => {
    setUnitBeingEdited(unit.uniqueId);
    // 🔧 CHANGED: store as strings so user can type decimals/partials freely
    const asStrings = Object.fromEntries(
      Object.entries(unit.inputs).map(([k, v]) => [k, v === undefined ? '' : String(v)])
    );
    setEditedInputs(asStrings);
  };

  // Input changes in edit form
  const handleEditInputChange = (e, name) => {
    const value = e.target.value;
    // 🔧 CHANGED: keep raw string while typing (no parse here)
    setEditedInputs((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  // Save edited inputs
  const saveEditedInputs = () => {
    const unit = processFlow.find((u) => u.uniqueId === unitBeingEdited);
    if (!unit) {
      alert('Unit not found.');
      return;
    }

    // 🔧 CHANGED: convert back to numbers ONLY for fields that were numbers originally
    const coerced = Object.fromEntries(
      Object.entries(editedInputs).map(([k, v]) => {
        const wasNumber = typeof unit.inputs[k] === 'number';
        if (!wasNumber) return [k, v]; // keep strings (e.g., filterType)

        const cleaned = String(v).replace(/,/g, '').trim();
        if (cleaned === '') {
          // keep previous numeric if empty
          return [k, unit.inputs[k]];
        }
        const num = Number(cleaned);
        return Number.isFinite(num) ? [k, num] : [k, unit.inputs[k]];
      })
    );

    const updatedFlow = processFlow.map((u) => {
      if (u.uniqueId === unitBeingEdited) {
        return { ...u, inputs: coerced };
      }
      return u;
    });

    setProcessFlow(updatedFlow);
    setUnitBeingEdited(null);
    setEditedInputs({});
  };

  // Cancel editing
  const cancelEditing = () => {
    setUnitBeingEdited(null);
    setEditedInputs({});
  };

  // Helper to get current unit + check numeric fields in render
  const currentUnit = unitBeingEdited
    ? processFlow.find((u) => u.uniqueId === unitBeingEdited)
    : null;
  const originalInputs = currentUnit ? currentUnit.inputs : {};

  return (
    <div className={styles.mainConfigContainer}>
      <h1>Continuous mRNA Vaccine Manufacturing</h1>

      {/* AVAILABLE UNITS */}
      <div className={styles.availableUnitsSection}>
        <h2>Available Units</h2>
        <div className={styles.availableUnitsRow}>
          {availableUnits.map((unit) => (
            <button
              key={unit.id}
              className={styles.availableUnitButton}
              onClick={() => addUnit(unit)}
            >
              {unit.name}
            </button>
          ))}
        </div>
      </div>

      {/* CURRENT FLOW */}
      <div className={styles.currentFlowSection}>
        <h2>Current Flow</h2>
        {processFlow.length === 0 ? (
          <p>No units added. Click a unit above to add.</p>
        ) : (
          <div className={styles.currentFlowRow}>
            {processFlow.map((unit) => (
              <div key={unit.uniqueId} className={styles.flowItem}>
                <button
                  className={styles.flowItemButton}
                  onClick={() => openOrFocusWindow(unit)}
                >
                  {unit.name} {unit.instance}
                </button>
                <button
                  className={styles.editButton}
                  onClick={() => editUnit(unit)}
                  title="Edit Inputs"
                  aria-label={`Edit ${unit.name}`}
                >
                  ✎
                </button>
                <button
                  className={styles.removeButton}
                  onClick={() => removeUnit(unit.uniqueId)}
                  title="Remove this unit"
                  aria-label={`Remove ${unit.name}`}
                >
                  &times;
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Edit Form Modal */}
      {unitBeingEdited && (
        <div className={styles.modalOverlay}>
          <div className={styles.modalContent}>
            <h3>
              Edit Inputs for{' '}
              {processFlow.find((u) => u.uniqueId === unitBeingEdited).name}{' '}
              {processFlow.find((u) => u.uniqueId === unitBeingEdited).instance}
            </h3>
            <form className={styles.editForm}>
              {Object.keys(editedInputs).map((key) => {
                const wasNumber = typeof originalInputs[key] === 'number';
                return (
                  <div key={key} className={styles.formGroup}>
                    <label htmlFor={key}>{key}:</label>
                    <input
                      type="text"                   // 🔧 keep text to allow partials like "0.", "-.5"
                      id={key}
                      name={key}
                      value={editedInputs[key] ?? ''}
                      onChange={(e) => handleEditInputChange(e, key)}
                      // Hint numeric keypad on mobile for numeric fields
                      {...(wasNumber ? { inputMode: 'decimal', placeholder: 'Enter a number' } : {})}
                    />
                  </div>
                );
              })}
            </form>
            <div className={styles.modalButtons}>
              <button onClick={saveEditedInputs} className={styles.saveButton}>
                Save
              </button>
              <button onClick={cancelEditing} className={styles.cancelButton}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* RUN PLANT Section */}
      {processFlow.length > 0 && (
        <div className={styles.runPlantSection}>
          <button
            className={styles.runPlantButton}
            onClick={runChain}
            disabled={isRunningChain} // disable if running
          >
            {isRunningChain ? 'Running...' : 'Run Plant'}
          </button>

          {/* **New Message**: Displayed after simulation completes */}
          {simulationCompleted && (
            <div className={styles.simulationCompletedMessage}>
              Simulation completed successfully! Click on each unit in the Current Flow to inspect the results of each unit.
            </div>
          )}
        </div>
      )}

      {/* Error Message */}
      {error && <div className={styles.errorMessage}>{error}</div>}

      <button onClick={() => navigate('/all-runs')}>
        View Past Runs / Compare
      </button>
    </div>
  );
}

export default MainConfig;
