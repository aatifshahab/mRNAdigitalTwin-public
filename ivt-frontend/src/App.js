// src/App.js

import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import IVT from './components/IVT/IVT';
import CCTC from './components/CCTC/CCTC';
import Lyo from './components/Lyo/Lyo';
import Membrane from './components/Membrane/Membrane';
import LNP from './components/LNP/LNP';
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        {/* Define Routes */}
        <Routes>
          <Route path="/" element={<IVT />} />
          <Route path="/cctc" element={<CCTC />} />
          <Route path="/lnp" element={<LNP />} /> 
          <Route path="/lyo" element={<Lyo />} /> 
          <Route path="/membrane" element={<Membrane />} />
        </Routes>
      </div>
    </Router>
  );
}



export default App;
