// src/components/RunDetailsPage/RunDetailsPage.jsx
import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';

function RunDetailsPage() {
  const { run_id } = useParams();
  const navigate = useNavigate();

  const [runData, setRunData] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Fetch the full run details from the backend
    fetch(`http://127.0.0.1:8000/get_run_details?run_id=${run_id}`)
      .then((res) => {
        if (!res.ok) {
          throw new Error('Failed to fetch run details');
        }
        return res.json();
      })
      .then((data) => setRunData(data))
      .catch((err) => setError(err.message));
  }, [run_id]);

  if (error) {
    return (
      <div>
        <p style={{ color: 'red' }}>{error}</p>
        <button onClick={() => navigate('/all-runs')}>Back to All Runs</button>
      </div>
    );
  }

  if (!runData) {
    return <div>Loading...</div>;
  }

  // runData structure:
  // {
  //   run_id: "...",
  //   timestamp: "...",
  //   chain_request: { chain: [ {id, uniqueId, inputs}, ... ] },
  //   chain_results: { chainResults: [ {unitId, uniqueId, result}, ... ] }
  // }

  const { run_id: rId, timestamp } = runData;
  const chain = runData.chain_request?.chain || [];
  // We can match each chain-request unit with its chain-result by uniqueId

  // const handleOpenGUI = (unitId, uniqueId) => {
  //   // If your unit’s dedicated GUI is accessible at e.g. /unitId?uniqueId=xxx:
  //   // Then do:
  //   const url = `${window.location.origin}/${unitId}?uniqueId=${uniqueId}`;
  //   window.open(url, '_blank'); // opens in new tab
  // };

  const handleOpenGUI = (unitId, uniqueId) => {
  // include the run_id so the unit page can fetch with both params
  const url = `${window.location.origin}/${unitId}`
            + `?run_id=${rId}`
            + `&unit_uniqueId=${uniqueId}`;
  window.open(url, '_blank');
};


  return (
    <div style={{ padding: '1rem' }}>
      <h2>Run Details</h2>
      <p><strong>Run ID:</strong> {rId}</p>
      <p><strong>Timestamp:</strong> {timestamp}</p>

      <h3>Units in this Run</h3>
      {chain.length === 0 ? (
        <p>No units found in chain_request.</p>
      ) : (
        <ul>
          {chain.map((unit, idx) => (
            <li key={idx} style={{ marginBottom: '0.5rem' }}>
              <strong>{unit.id}</strong> (uniqueId: {unit.uniqueId}){' '}
              <button
                onClick={() => handleOpenGUI(unit.id, unit.uniqueId)}
              >
                Open {unit.id} GUI
              </button>
            </li>
          ))}
        </ul>
      )}

      <button onClick={() => navigate('/all-runs')}>Back to All Runs</button>
    </div>
  );
}

export default RunDetailsPage;
