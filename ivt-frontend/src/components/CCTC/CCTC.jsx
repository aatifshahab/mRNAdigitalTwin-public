// src/components/CCTC/CCTC.jsx

import React, { useState, useEffect } from 'react';
import axios from 'axios';
import CCTCInputs from './CCTCInputs/CCTCInputs';
import CCTCOutputs from './CCTCOutputs/CCTCOutputs';
import CCTCFigure from './CCTCFigure/CCTCFigure';
import CCTCGraphs from './CCTCGraphs/CCTCGraphs';
import './CCTC.css';
import { useLocation } from 'react-router-dom';

function CCTC() {
    const location = useLocation();

    // State for CCTC inputs
    const [cctcInputs, setCctcInputs] = useState({
        F103: 1.0,        // Flow Rate (L/hr) - Placeholder 
        mRNA: 0.5,        // Concentration of mRNA (mol/L)
        resin: 0.0,       // Resin Concentration (mol/L) - Placeholder
    });

    // Conversion constants
    const MOLAR_MASS_MRNA = 660000; // g/mol (assuming 2000 nucleotides)
    const MICROMOLAR_TO_MOLAR = 1e-6; // Conversion factor from µM to mol/L

    // Function to convert µM to g/L
    const convertToGramsPerLiter = (concentrationInMicromolar) => {
        return concentrationInMicromolar * MICROMOLAR_TO_MOLAR * MOLAR_MASS_MRNA;
    };

    // State for selected input tag
    const [selectedTag, setSelectedTag] = useState('F103'); // Default selection

    // State for CCTC outputs
    const [cctcOutputs, setCctcOutputs] = useState({
        time: [],
        unbound_mRNA: [],
        bound_mRNA: [],
    });

    // State for error handling and loading
    const [error, setError] = useState(null);
    const [loading, setLoading] = useState(false);

    // Function to handle CCTC input changes
    const handleCCTCInputChange = (e, name) => {
        const value = parseFloat(e.target.value);
        if (!isNaN(value)) {
            // Convert mRNA value from µM to g/L before updating the state
            if (name === 'mRNA') {
                const valueInGL = convertToGramsPerLiter(value);
                setCctcInputs({ ...cctcInputs, [name]: valueInGL });
            } else {
                setCctcInputs({ ...cctcInputs, [name]: value });
            }
        }
    };

    // Initialize mRNA concentration from query parameters
    useEffect(() => {
        const params = new URLSearchParams(location.search);
        const mRNA = parseFloat(params.get('mRNA'));

        if (!isNaN(mRNA)) {
            // Convert mRNA value from µM to g/L before setting the state
            const mRNAInGL = convertToGramsPerLiter(mRNA);
            setCctcInputs((prevInputs) => ({
                ...prevInputs,
                mRNA: mRNAInGL,
            }));
        }
    }, [location.search]);

    // Function to handle Run CCTC simulation
    const handleRunCCTC = async () => {
        setLoading(true);
        setError(null);
        try {
            const payload = {
                states0_last_value: cctcInputs.mRNA, // Mapping mRNA to states0_last_value
            };
            const response = await axios.post('http://127.0.0.1:8000/run_cctc', payload);
            if (response.data.error) {
                setError(response.data.error);
            } else {
                setCctcOutputs({
                    time: response.data.time,
                    unbound_mRNA: response.data.unbound_mRNA,
                    bound_mRNA: response.data.bound_mRNA,
                });
            }
        } catch (err) {
            setError('Failed to run CCTC simulation.');
            console.error(err);
        }
        setLoading(false);
    };

    // Function to open IVT in a new window
    const openIVT = () => {
        const ivtWindow = window.open('/', 'IVT Window', 'width=800,height=600');

        // Optional: Handle if the window fails to open
        if (!ivtWindow) {
            alert('Popup blocked! Please allow popups for this website.');
        }
    };

    // Function to open Lyo in a new window
    const openLyo = () => {
        const lyoWindow = window.open('/lyo', 'Lyo Window', 'width=800,height=600');

        // Optional: Handle if the window fails to open
        if (!lyoWindow) {
            alert('Popup blocked! Please allow popups for this website.');
        }
    };

    const openMembrane = () => {
        // Open Membrane in a new tab (or same tab)
        const membraneWindow = window.open('/membrane', '_blank', 'width=800,height=600');
        if (!membraneWindow) {
          alert('Popup blocked! Please allow popups for this website.');
        }
      };

    const openLNP = () => {
        // Open Membrane in a new tab (or same tab)
        const LnpWindow = window.open('/lnp', '_blank', 'width=800,height=600');
        if (!LnpWindow) {
          alert('Popup blocked! Please allow popups for this website.');
        }
      };

    return (
        <div className="cctc-container">
            <h1>CCTC Unit</h1>

            {/* Navigation Buttons */}
            <div className="navigation-buttons">
                <button onClick={openIVT}>Go to IVT Unit</button>
                <button onClick={openMembrane}>Go to Membrane Unit</button>
                <button onClick={openLNP}>Go to LNP Unit</button>
                <button onClick={openLyo}>Go to Freeze-drying Unit</button> {/* Added navigation to Lyo */}
            </div>

            {/* Top Section: Inputs, Figure, Outputs */}
            <div className="cctc-top-section">
                {/* CCTC Inputs */}
                <div className="cctc-inputs-wrapper">
                    <CCTCInputs
                        cctcInputs={cctcInputs}
                        handleCCTCInputChange={handleCCTCInputChange}
                        selectedTag={selectedTag}
                        setSelectedTag={setSelectedTag}
                    />
                </div>

                {/* CCTC Figure */}
                <div className="cctc-figure-wrapper">
                    <CCTCFigure />
                </div>

                {/* CCTC Outputs */}
                <div className="cctc-outputs-wrapper">
                    <CCTCOutputs
                        cctcOutputs={cctcOutputs}
                    />
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

            {/* Run Unit Button */}
            <div className="run-unit-button">
                <button onClick={handleRunCCTC} disabled={loading}>
                    {loading ? 'Running...' : 'Run CCTC Unit'}
                </button>
            </div>

            {/* Error Display */}
            {error && <div className="error-message">{error}</div>}
        </div>
    );

}

export default CCTC;
