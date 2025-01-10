// src/utilits/calculateF102.js

/**
 * Calculates the F102 flow rate over time.
 * F102 is 0 until the reactor volume V is filled, then equals Q or F101.
 *
 * @param {Array<number>} timeData - Array of time points (in hours).
 * @param {number} Q - Flow rate (L/hr).
 * @param {number} V - Reactor volume (L).
 * @returns {Array<number>} - Array of F102 values corresponding to each time point.
 */
export function calculateF102(timeData, Q, V) {
    const T_fill = V / Q; // Time to fill reactor volume
    return timeData.map((t) => (t < T_fill ? 0 : Q));
  }
  