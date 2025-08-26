// src/services/ivtService.js

export const fetchIVTData = async () => {
  try {
    const response = await fetch('/api/ivt'); // Replace with your API endpoint
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error fetching IVT data:', error);
    throw error;
  }
};

export const processIVTData = (data) => {
  // Implement any data processing needed for CCTC
  return processedData;
};
