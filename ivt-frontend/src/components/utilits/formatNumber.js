// src/utilits/formatNumber.js

/**
 * Formats a number based on its magnitude.
 * - Uses exponential notation with specified decimal places for very large or very small numbers.
 * - Uses fixed decimal places otherwise.
 *
 * @param {number} num - The number to format.
 * @param {number} [decimalPlaces=0] - Number of decimal places for formatting.
 * @returns {string} - The formatted number as a string.
 */
export function formatNumber(num, decimalPlaces = 0) {
    if (num === 0) return '0';
    
    const absNum = Math.abs(num);
    
    // Define thresholds for exponential notation
    const upperThreshold = 1e5;
    const lowerThreshold = 1e-3;
    
    if (absNum >= upperThreshold || absNum <= lowerThreshold) {
        // Use exponential notation with fixed decimal places
        return num.toExponential(decimalPlaces);
    } else if (absNum >= 2) {
        // Use fixed decimal places for numbers >= 2
        return num.toFixed(2);
    } else {
        // Use more fixed decimal places for numbers < 2 but >= 1e-2
        return num.toFixed(2);
    }
}
