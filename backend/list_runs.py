import sqlite3

def main():
    # Connect to the SQLite file in this directory
    conn = sqlite3.connect("runs.db")

    # Fetch all run IDs and timestamps
    rows = conn.execute(
        "SELECT run_id, timestamp FROM runs ORDER BY timestamp DESC"
    ).fetchall()
    conn.close()

    # Print a summary
    print(f"Found {len(rows)} runs:")
    for run_id, ts in rows:
        print(f" • {run_id} @ {ts}")

if __name__ == "__main__":
    main()
