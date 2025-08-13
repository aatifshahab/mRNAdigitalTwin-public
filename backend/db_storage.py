# backend/db_storage.py

import sqlite3
import json
import uuid
from datetime import datetime

DB_FILE = "runs.db"  # This file will be created in the working directory (usually the project root)

def init_db():
    """Initializes the SQLite database and creates the 'runs' table if it doesn't exist."""
    with sqlite3.connect(DB_FILE) as conn:
        conn.execute("""
        CREATE TABLE IF NOT EXISTS runs (
            run_id TEXT PRIMARY KEY,
            timestamp TEXT,
            chain_request TEXT,
            chain_results TEXT
        );
        """)
        conn.commit()

def store_run_in_db(run_id, timestamp_str, chain_request, chain_results):
    """
    Stores a simulation run in the database.
    
    Parameters:
      run_id (str): A unique identifier for the run.
      timestamp_str (str): Timestamp in ISO format.
      chain_request (dict): The JSON-serializable input data (chain request).
      chain_results (dict): The JSON-serializable simulation output.
    """
    with sqlite3.connect(DB_FILE) as conn:
        conn.execute("""
            INSERT INTO runs (run_id, timestamp, chain_request, chain_results)
            VALUES (?, ?, ?, ?)
        """, (
            run_id,
            timestamp_str,
            json.dumps(chain_request),
            json.dumps(chain_results)
        ))
        conn.commit()

def get_run_from_db(run_id):
    """
    Retrieves a simulation run from the database by run_id.
    
    Parameters:
      run_id (str): The unique identifier for the run.
    
    Returns:
      dict or None: A dictionary with run data if found, otherwise None.
    """
    with sqlite3.connect(DB_FILE) as conn:
        row = conn.execute("""
            SELECT run_id, timestamp, chain_request, chain_results
            FROM runs
            WHERE run_id = ?
        """, (run_id,)).fetchone()
        
        if row:
            return {
                "run_id": row[0],
                "timestamp": row[1],
                "chain_request": json.loads(row[2]),
                "chain_results": json.loads(row[3])
            }
        else:
            return None

def get_all_runs():
    with sqlite3.connect(DB_FILE) as conn:
        rows = conn.execute("""
            SELECT run_id, timestamp FROM runs ORDER BY timestamp DESC
        """).fetchall()
        runs = []
        for row in rows:
            runs.append({
                "run_id": row[0],
                "timestamp": row[1]
            })
        return runs