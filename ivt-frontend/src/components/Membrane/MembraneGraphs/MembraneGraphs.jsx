// src/components/Membrane/MembraneGraphs/MembraneGraphs.jsx
import React from 'react';
import styles from './MembraneGraphs.module.css';

// For 2D line charts with Chart.js
import MembraneGraph from './MembraneGraph';

// For 3D surface with Plotly
import MembraneGraph3D from './MembraneGraph3D';

/*
  This code shows 3 graph panels:

  Graph #1 -> Input variables
    - uses selectedInputVar, plots a constant line: inputValue vs timePoints

  Graph #2 -> PDE (concentration step)
    - uses concSelection => { species, plotType }
    - If plotType="OUTLET_VS_TIME", we do a 2D line at the outlet
    - If plotType="THREE_D", we do a 3D surface of (time, position, concentration)
    - We get data from:
      timePoints, xPositions, Cmatrix_mRNA, Cmatrix_protein, Cmatrix_ntps

  Graph #3 -> Diafiltration (TFF) step
    - uses diafSelection => { variable, stage }
    - We plot TFF_protein[stage-1] or TFF_ntps[stage-1] vs td (2D line)
*/

function MembraneGraphs({
  // Graph #1: input
  selectedInputVar,
  inputs,
  timePoints,

  // Graph #2: PDE
  concSelection, // { species, plotType }
  xPositions,
  Cmatrix_mRNA,
  Cmatrix_protein,
  Cmatrix_ntps,

  // Graph #3: TFF
  diafSelection, // { variable, stage }
  td,
  TFF_protein,
  TFF_ntps,
  TFF_mRNA,
}) {
  //======================================================
  // Graph #1 => Input
  //======================================================
  const inputLabel = selectedInputVar?.name || 'No Input Selected';
  // x-axis can be timePoints
  const inputX = timePoints;
  // y-axis is a constant array = inputs[inputLabel], if numeric
  let inputY = [];
  if (timePoints.length && inputs[inputLabel] !== undefined) {
    const val = parseFloat(inputs[inputLabel]) || 0;
    inputY = timePoints.map(() => val);
  }

  //======================================================
  // Graph #2 => PDE (Concentration Step)
  //======================================================
  const species = concSelection.species; // 'mRNA' | 'Protein' | 'NTPs'
  const plotType = concSelection.plotType; // 'OUTLET_VS_TIME' or 'THREE_D'

  // pick the correct matrix
  let Cmatrix = [];
  if (species === 'mRNA') {
    Cmatrix = Cmatrix_mRNA;
  } else if (species === 'Protein') {
    Cmatrix = Cmatrix_protein;
  } else {
    Cmatrix = Cmatrix_ntps;
  }

  // 2D line: "OUTLET_VS_TIME"
  //   We plot c(t, x=end) => final column of the matrix
  let pde2DLabel = `${species} at outlet`;
  let pde2D_x = [];
  let pde2D_y = [];
  if (plotType === 'OUTLET_VS_TIME' && Cmatrix.length && xPositions.length) {
    pde2D_x = timePoints;
    const outletIndex = xPositions.length - 1;
    pde2D_y = Cmatrix.map((row) => row[outletIndex]);
  }

  // 3D surface: "THREE_D"
  //   pass the entire matrix (Cmatrix) + timePoints + xPositions
  //   to a Plotly surface
  //   z => shape(N, M), x => xPositions, y => timePoints
  //   handle that in MembraneGraph3D

  //======================================================
  // Graph #3 => TFF (Diafiltration)
  //======================================================
  const tffVar = diafSelection.variable;   // 'Protein' | 'NTPs'
  const stage = diafSelection.stage;       // e.g. 1-based
  let tffData = [];
  if (tffVar === 'Protein') {
    tffData = TFF_protein[stage - 1] || [];
  } else if (tffVar === 'NTPs') {
    tffData = TFF_ntps[stage - 1] || [];
  } else if (tffVar === 'mRNA') { // ***Added Section: handle 'mRNA'***
    tffData = TFF_mRNA[stage - 1] || [];
  }
  const tffLabel = `${tffVar} (Stage ${stage})`;
  const tffX = td || [];
  const tffY = tffData; // same length as td

  return (
    <div className={styles.graphs}>
      {/* ==================== Graph 1: Input ==================== */}
      <div className={styles.graphSection}>
        <h3>Input Graph</h3>
        <MembraneGraph
          label={inputLabel}
          xData={inputX}
          yData={inputY}
          xTitle="Time"
          yTitle={inputLabel}
        />
      </div>

      {/* ==================== Graph 2: PDE (Conc Step) ==================== */}
      <div className={styles.graphSection}>
        <h3>Concentration Step</h3>
        {plotType === 'OUTLET_VS_TIME' ? (
          // 2D line
          <MembraneGraph
            label={pde2DLabel}
            xData={pde2D_x}
            yData={pde2D_y}
            xTitle="Time"
            yTitle={pde2DLabel}
          />
        ) : (
          // 3D surface
          <MembraneGraph3D
            timePoints={timePoints}
            xPositions={xPositions}
            Cmatrix={Cmatrix}
            species={species}
          />
        )}
      </div>

      {/* ==================== Graph 3: TFF (Diafiltration) ==================== */}
      <div className={styles.graphSection}>
        <h3>Diafiltration</h3>
        <MembraneGraph
          label={tffLabel}
          xData={tffX}
          yData={tffY}
          xTitle="Time"
          yTitle={tffLabel}
        />
      </div>
    </div>
  );
}

export default MembraneGraphs;
