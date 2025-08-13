import sqlite3
import json

# ←── Replace this with one of your actual run_ids:
RUN_ID = "76429373-154e-4403-9278-f2cb2cfe3bcd"

def main():
    conn = sqlite3.connect("runs.db")
    cur = conn.execute(
        "SELECT run_id, timestamp, chain_request, chain_results "
        "FROM runs WHERE run_id = ?",
        (RUN_ID,)
    )
    row = cur.fetchone()
    conn.close()

    if not row:
        print(f"No record found for run_id={RUN_ID}")
        return

    run_id, timestamp, req_json, res_json = row
    print(f"run_id:   {run_id}")
    print(f"timestamp:{timestamp}\n")

    try:
        request = json.loads(req_json)
        results = json.loads(res_json)
    except json.JSONDecodeError as e:
        print("❌ JSON decode error:", e)
        print("Raw request JSON:", req_json[:200], "…")
        print("Raw results JSON:", res_json[:200], "…")
        return

    print("chain_request:")
    print(json.dumps(request, indent=2))
    print("\nchain_results:")
    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()
