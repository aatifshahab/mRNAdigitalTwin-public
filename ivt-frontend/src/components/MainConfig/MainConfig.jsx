// src/components/MainConfig/MainConfig.jsx

import React, { useState, useContext } from 'react';
import styles from './MainConfig.module.css';
import { SimulationContext } from '../../context/SimulationContext';
import { v4 as uuidv4 } from 'uuid';

function MainConfig() {
  // Define available units
  const availableUnits = [
    { id: 'ivt', name: 'IVT Unit' },
    { id: 'membrane', name: 'Membrane Unit' },
    { id: 'cctc', name: 'CCTC Unit' },
    { id: 'lnp', name: 'LNP Unit' },
    { id: 'lyo', name: 'Freeze-drying Unit' },
  ];

  // State for arranged units in the process flow
  const [processFlow, setProcessFlow] = useState([]);

  // State for managing which unit is being edited
  const [unitBeingEdited, setUnitBeingEdited] = useState(null);

  // State for editing inputs
  const [editedInputs, setEditedInputs] = useState({});

  // **New** state to show running feedback
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
          Residential_time: 60.0,
          FRR: 3.0,
          pH: 5.5,
          Ion: 0.1,
          TF: 0.0,
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
    const url = `${window.location.origin}/${unit.id}?uniqueId=${unit.uniqueId}`;
    const windowFeatures = 'width=800,height=600';

    // Always open in a new tab/window, ignoring the old approach
    const newWindow = window.open(url, '_blank', windowFeatures);
    if (!newWindow) {
      alert('Popup blocked! Please allow popups for this domain.');
    }
  };

  // Handle chain run
  const runChain = async () => {
    // Show that we are running
    setIsRunningChain(true);

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
        alert(`Error: ${errorData.error}`);
        setIsRunningChain(false);
        return;
      }

      const data = await response.json();
      console.log('Chain Results:', data.chainResults);

      // Store the results in the global context
      data.chainResults.forEach((unitRes) => {
        addChainResult(unitRes.uniqueId, unitRes.result);
      });

      // (Optional) If you want to update the processFlow with
      // new inputs based on the chain results, do so here:
      /*
      const updatedFlow = processFlow.map((unit) => {
        const simulationResult = data.chainResults.find(
          (res) => res.uniqueId === unit.uniqueId
        );
        if (simulationResult) {
          // example: update some field in unit.inputs
          // switch (unit.id) { ... }
        }
        return unit;
      });
      setProcessFlow(updatedFlow);
      */

      alert('Plant simulation completed successfully!');
    } catch (error) {
      console.error('Error running chain:', error);
      alert('An error occurred while running the plant simulation.');
    } finally {
      setIsRunningChain(false);
    }
  };

  // Edit unit
  const editUnit = (unit) => {
    setUnitBeingEdited(unit.uniqueId);
    setEditedInputs(unit.inputs);
  };

  // Input changes in edit form
  const handleEditInputChange = (e, name) => {
    const value = e.target.value;
    setEditedInputs((prev) => ({
      ...prev,
      [name]: isNaN(parseFloat(value)) ? value : parseFloat(value),
    }));
  };

  // Save edited inputs
  const saveEditedInputs = () => {
    const unit = processFlow.find((u) => u.uniqueId === unitBeingEdited);
    if (!unit) {
      alert('Unit not found.');
      return;
    }

    const updatedFlow = processFlow.map((u) => {
      if (u.uniqueId === unitBeingEdited) {
        return { ...u, inputs: editedInputs };
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

  return (
    <div className={styles.mainConfigContainer}>
      <h1>Continuous mRNA Vaccine Manufacturing</h1>

      {/* AVAILABLE UNITS (Top, horizontally) */}
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

      {/* CURRENT FLOW (Below) */}
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
                >
                  ✎
                </button>
                <button
                  className={styles.removeButton}
                  onClick={() => removeUnit(unit.uniqueId)}
                  title="Remove this unit"
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
              {Object.keys(editedInputs).map((key) => (
                <div key={key} className={styles.formGroup}>
                  <label htmlFor={key}>{key}:</label>
                  <input
                    type="text"
                    id={key}
                    name={key}
                    value={editedInputs[key]}
                    onChange={(e) => handleEditInputChange(e, key)}
                  />
                </div>
              ))}
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
          {isRunningChain && (
            <div className={styles.runningMessage}>
              {/* Could be a spinner, or just text */}
              Simulation in progress, please wait...
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default MainConfig;
