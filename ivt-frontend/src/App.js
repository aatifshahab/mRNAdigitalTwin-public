// src/App.jsx

import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import MainConfig from './components/MainConfig/MainConfig';
import IVT from './components/IVT/IVT';
import Membrane from './components/Membrane/Membrane';
import CCTC from './components/CCTC/CCTC';
import LNP from './components/LNP/LNP';
import Lyo from './components/Lyo/Lyo';
import { SimulationProvider } from './context/SimulationContext';
import AllRunsPage from './components/AllRunsPage/AllRunsPage';
import RunDetailsPage from './components/RunDetailsPage/RunDetailsPage';
import './App.css';

function App() {
  return (
    <SimulationProvider>
      <Router>
        <div className="App">
          <Routes>
            <Route path="/" element={<MainConfig />} />
            <Route path="/ivt" element={<IVT />} />
            <Route path="/membrane" element={<Membrane />} />
            <Route path="/cctc" element={<CCTC />} />
            <Route path="/lnp" element={<LNP />} />
            <Route path="/lyo" element={<Lyo />} />
            <Route path="/all-runs" element={<AllRunsPage />} />
            <Route path="/run-details/:run_id" element={<RunDetailsPage />} />
            <Route path="*" element={<div>404 Not Found</div>} />
          </Routes>
        </div>
      </Router>
    </SimulationProvider>
  );
}

export default App;
