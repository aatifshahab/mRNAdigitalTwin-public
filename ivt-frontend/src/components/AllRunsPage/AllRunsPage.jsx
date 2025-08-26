// src/components/AllRunsPage/AllRunsPage.jsx
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

function AllRunsPage() {
  const navigate = useNavigate();

  // 1) All runs: [{ run_id, timestamp }, ...]
  const [allRuns, setAllRuns] = useState([]);
  const [error, setError] = useState(null);

  // 2) Track selected run IDs via checkboxes
  const [selectedRunIds, setSelectedRunIds] = useState([]);

  // 3) Comparison data after fetching details
  const [comparisonData, setComparisonData] = useState([]);

  // 4) The user-chosen “(unitId, variable)” to compare
  const [selectedVariable, setSelectedVariable] = useState('ivt:TotalRNAo');

  // ---- Output variables for each unit you actually want to compare ----
  // Format "unitId:variableName" => e.g. "ivt:TotalRNAo"
  // Add or remove as needed, matching the keys in main.py's results.
  const variableOptions = [
    'ivt:TotalRNAo',
    'ivt:Time',            // Possibly you have "Time"
    'membrane:TFF_mRNA',   // Membrane
    'cctc:bound_mRNA',
    'lnp:Fraction',
    'lyo:someOutput',      // If Lyo has an output array you want to compare
  ];

  // ===================== Fetch all runs on mount =====================
  useEffect(() => {
    fetch('http://127.0.0.1:8000/get_all_runs')
      .then((res) => {
        if (!res.ok) throw new Error('Failed to fetch runs');
        return res.json();
      })
      .then((data) => {
        if (data.runs) {
          setAllRuns(data.runs);
        } else {
          setAllRuns([]);
        }
      })
      .catch((err) => setError(err.message));
  }, []);

  // ===================== Toggle checkboxes =====================
  const handleCheckboxChange = (runId) => {
    setSelectedRunIds((prev) => {
      if (prev.includes(runId)) {
        return prev.filter((id) => id !== runId);
      } else {
        return [...prev, runId];
      }
    });
  };

  // ===================== Compare selected runs =====================
  const compareSelectedRuns = async () => {
    setComparisonData([]); // reset
    if (!selectedRunIds.length) return;

    try {
      const [unitId, varName] = selectedVariable.split(':');

      // Fetch each run's details
      const fetchPromises = selectedRunIds.map(async (runId) => {
        const res = await fetch(`http://127.0.0.1:8000/get_run_details?run_id=${runId}`);
        if (!res.ok) {
          throw new Error(`Failed to fetch details for run_id=${runId}`);
        }
        return res.json(); // => { run_id, timestamp, chain_request, chain_results }
      });

      const runsData = await Promise.all(fetchPromises);

      // Now parse the final value of chosen var for each run
      const parsedData = runsData.map((runObj) => {
        const chainResultsArray = runObj.chain_results?.chainResults || [];
        // Find the correct unit
        const unitResult = chainResultsArray.find(
          (u) => u.unitId === unitId
        );

        let finalValue = null;
        if (unitResult && unitResult.result && unitResult.result[varName]) {
          const val = unitResult.result[varName];
          if (Array.isArray(val)) {
            // If it's an array, final = last item
            finalValue = val[val.length - 1];
            // If it's a 2D array, you might do:
            // finalValue = val[val.length - 1][ val[val.length - 1].length - 1 ];
          } else {
            // If it's a single value
            finalValue = val;
          }
        }

        return {
          run_id: runObj.run_id,
          timestamp: runObj.timestamp,
          finalValue,
        };
      });

      setComparisonData(parsedData);
    } catch (err) {
      console.error(err);
      setError(err.message);
    }
  };

  return (
    <div style={{ padding: '1rem' }}>
      <h2>All Simulation Runs</h2>

      {error && <div style={{ color: 'red' }}>Error: {error}</div>}

      {/* --- Table of all runs with checkboxes + “View Details” button --- */}
      {!allRuns.length ? (
        <p>No runs found in the database.</p>
      ) : (
        <table border="1" cellPadding="6" cellSpacing="0">
          <thead>
            <tr>
              <th>Select</th>
              <th>Run ID</th>
              <th>Timestamp</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {allRuns.map((run) => (
              <tr key={run.run_id}>
                <td>
                  <input
                    type="checkbox"
                    checked={selectedRunIds.includes(run.run_id)}
                    onChange={() => handleCheckboxChange(run.run_id)}
                  />
                </td>
                <td>{run.run_id}</td>
                <td>{run.timestamp}</td>
                <td>
                  {/* “View Details” -> goes to RunDetailsPage with that run_id */}
                  <button onClick={() => navigate(`/run-details/${run.run_id}`)}>
                    View Details
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {/* --- Dropdown to pick which variable to compare + Compare button --- */}
      <div style={{ margin: '1rem 0' }}>
        <label style={{ marginRight: '0.5rem' }}>
          Select variable to compare:
        </label>
        <select
          value={selectedVariable}
          onChange={(e) => setSelectedVariable(e.target.value)}
        >
          {variableOptions.map((opt) => (
            <option key={opt} value={opt}>
              {opt}
            </option>
          ))}
        </select>

        <button
          onClick={compareSelectedRuns}
          disabled={!selectedRunIds.length}
          style={{ marginLeft: '1rem' }}
        >
          Compare Selected Runs
        </button>
      </div>

      {/* --- Comparison Table with final values only --- */}
      {comparisonData.length > 0 && (
        <div style={{ marginTop: '2rem' }}>
          <h3>Comparison of “{selectedVariable}” (final value)</h3>
          <table border="1" cellPadding="6" cellSpacing="0">
            <thead>
              <tr>
                <th>Run ID</th>
                <th>Timestamp</th>
                <th>Final Value</th>
              </tr>
            </thead>
            <tbody>
              {comparisonData.map((item) => (
                <tr key={item.run_id}>
                  <td>{item.run_id}</td>
                  <td>{item.timestamp}</td>
                  <td>
                    {item.finalValue !== null
                      ? JSON.stringify(item.finalValue)
                      : 'N/A'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Optional: a “Back to MainConfig” button */}
      <button style={{ marginTop: '1rem' }} onClick={() => navigate('/')}>
        Back to Main Config
      </button>
    </div>
  );
}

export default AllRunsPage;
