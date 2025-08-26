// src/context/SimulationContext.jsx

import React, { createContext, useState } from 'react';
import axios from 'axios';

// Create the context
export const SimulationContext = createContext();

// Create the provider component
export const SimulationProvider = ({ children }) => {
  // In-memory storage for simulation results
  // Key: uniqueId, Value: the actual simulation result object
  const [simulationStorage, setSimulationStorage] = useState({});

  /**
   * Adds a simulation result to the storage.
   * @param {string} uniqueId - The unique identifier for the simulation.
   * @param {object} result - The simulation result data.
   */
  const addChainResult = (uniqueId, result) => {
    console.log('Storing simulation result in context:', uniqueId, result);
    setSimulationStorage((prevStorage) => ({
      ...prevStorage,
      [uniqueId]: result,
    }));
  };

  /**
   * Retrieves a simulation result by uniqueId.
   * 1) Checks in local storage first.
   * 2) If not found, fetches from the backend (/get_unit_result).
   * @param {string} uniqueId
   * @returns {object|null} - The simulation result, or null if not found.
   */
  // const getUnitResult = async (uniqueId) => {
  //   // 1) Check local storage
  //   if (simulationStorage[uniqueId]) {
  //     console.log(`getUnitResult: returning cached result for ${uniqueId}`);
  //     return simulationStorage[uniqueId];
  //   }

  //   // 2) Otherwise, fetch from the backend
  //   try {
  //     const response = await axios.get(
  //       `http://127.0.0.1:8000/get_unit_result?uniqueId=${uniqueId}`
  //     );
  //     // The endpoint returns: { "result": { ... your actual data ... } }
  //     const fetchedResult = response.data.result;

  //     // 3) Store in local memory
  //     setSimulationStorage((prevStorage) => ({
  //       ...prevStorage,
  //       [uniqueId]: fetchedResult,
  //     }));

  //     return fetchedResult;
  //   } catch (error) {
  //     console.error(`Error fetching simulation data for ${uniqueId}:`, error);
  //     return null;
  //   }
  // };


    // Now takes both runId and the unit’s uniqueId
  const getUnitResult = async (runId, unitUniqueId) => {
    // 1) Check in-memory cache first
    if (simulationStorage[unitUniqueId]) {
      console.log(`getUnitResult: returning cached result for ${unitUniqueId}`);
      return simulationStorage[unitUniqueId];
    }

    // 2) Fetch from the backend using both params
    try {
      const response = await axios.get(
        `http://127.0.0.1:8000/get_unit_result`
        + `?run_id=${runId}`
        + `&unit_uniqueId=${unitUniqueId}`
      );
      const fetchedResult = response.data.result;

      // 3) Cache it under the unitUniqueId key
      setSimulationStorage((prev) => ({
        ...prev,
        [unitUniqueId]: fetchedResult,
      }));

      return fetchedResult;
    } catch (error) {
      console.error(
        `Error fetching simulation data for ${unitUniqueId}:`,
        error
      );
      return null;
    }
  };

  return (
    <SimulationContext.Provider
      value={{ simulationStorage, addChainResult, getUnitResult }}
    >
      {children}
    </SimulationContext.Provider>
  );
};
