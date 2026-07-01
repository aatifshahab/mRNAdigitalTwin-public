# mRNA Digital Twin

Model and simulate a full mRNA manufacturing process: IVT → Membrane filtration → CCTC → LNP formulation → Lyophilization.

## Quick Start (Recommended)

Everything except MATLAB runs in Docker — you only need two things installed.

### Prerequisites

| Requirement | Notes |
|-------------|-------|
| **MATLAB R2020b+** with a valid license | Required for CCTC, Lyo, Membrane, LNP units |
| **Docker Desktop** for Windows | [Install guide (includes WSL2 setup)](https://docs.docker.com/desktop/setup/install/windows-install/) |

### Step 1 — Start the MATLAB bridge (one terminal)

```powershell
.\setup-matlab-bridge.ps1
```

This finds your MATLAB install, sets up a Python environment, and starts a lightweight local bridge on port **8001**. Keep this window open while you use the app.

> **First run only:** if PowerShell blocks the script, run this first:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

### Step 2 — Start the app (second terminal)

```powershell
docker compose up --build
```

First build takes **10–40 minutes** (Julia packages compile once and are cached). After that, builds are fast.

Open **http://localhost:3000** when it's ready.

To stop: `Ctrl+C`, then `docker compose down`.

### URLs

| Service | URL |
|---------|-----|
| App (React frontend) | http://localhost:3000 |
| Backend API / Swagger | http://localhost:8000/docs |
| MATLAB bridge health | http://localhost:8001/health |

---

## Troubleshooting

**"Could not reach the MATLAB bridge"** in backend logs  
→ Step 1 is not running. Keep the `setup-matlab-bridge.ps1` window open.

**MATLAB engine install fails**  
→ Your MATLAB release may require a specific Python version. Check MathWorks' "Versions of Python Compatible with MATLAB Products" and re-run the script.

**Port already in use**  
→ Change port mappings in `docker-compose.yml` (and pass `-Port <n>` to the bridge script, keeping `MATLAB_BRIDGE_URL` in sync).

**Docker Desktop — WSL not installed**  
→ Run `wsl --install` in an elevated PowerShell, reboot, then re-open Docker Desktop.

---

## Sensitivity Analysis Scripts (host only)

These run natively (not in Docker) and require the MATLAB bridge to be running:

```powershell
cd backend
python sensitivity_lyo.py   # Lyophilization (Morris screening)
python sensitivity_tff.py   # TFF / Membrane
python sensitivity_lnp.py   # LNP formulation
```

---

## Advanced — Native Install (no Docker)

If you prefer to run everything natively without Docker:

<details>
<summary>Expand native install steps</summary>

### Requirements
- Windows 10/11, 8 GB RAM (16 GB recommended), ~10 GB disk
- MATLAB R2020b+ with MATLAB Engine for Python
- Python 3.10 (recommended; must be in MATLAB's supported range)
- Julia 1.9+
- Node.js 20.x LTS

### 1. Clone and install dependencies

```powershell
git clone https://github.com/aatifshahab/mRNAdigitalTwin.git
cd mRNAdigitalTwin
```

### 2. Python virtual environment

```powershell
py -3.10 -m venv .venv310
.\.venv310\Scripts\Activate.ps1
python -m pip install --upgrade pip setuptools wheel
```

### 3. MATLAB Engine for Python

```powershell
cd "C:\Program Files\MATLAB\R2023a\extern\engines\python"
python -m pip install .
cd <repo root>
```

### 4. Julia + PyJulia

```powershell
# Install Julia from https://julialang.org/downloads/ and add to PATH
python -m pip install julia
python -c "import julia; julia.install()"

cd IVT2.0
julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate(); Pkg.precompile();"
cd ..
```

### 5. Backend

```powershell
cd backend
python -m pip install -r requirements.txt
uvicorn main:app --reload
```

### 6. Frontend

```powershell
cd ivt-frontend
npm install
npm start
```

In native mode, leave `USE_MATLAB_BRIDGE` unset — the backend uses the in-process MATLAB engine directly.

</details>
