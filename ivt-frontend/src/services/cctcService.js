// src/services/cctcService.js

import { fetchIVTData, processIVTData } from './ivtService';

export const integrateIVTIntoCCTC = async () => {
  try {
    const ivtData = await fetchIVTData();
    const processedData = processIVTData(ivtData);
    // Further integration logic if needed
    return processedData;
  } catch (error) {
    console.error('Error integrating IVT into CCTC:', error);
    return null;
  }
};
