# mRNA Digital Twin — Quick Start (Docker)

Run the whole app with essentially two commands. Everything except MATLAB is
containerized; **MATLAB stays on your machine** because the MATLAB Engine must run
natively against your licensed install.

```
┌─ YOUR WINDOWS HOST (needs licensed MATLAB) ─┐   ┌──── Docker Desktop ─────────────┐
│  setup-matlab-bridge.ps1                    │   │  backend  (FastAPI + Julia/IVT) │
│  → MATLAB bridge on http://localhost:8001   │◄──┤  frontend (React via nginx)     │
└─────────────────────────────────────────────┘   └─────────────────────────────────┘
```

## Prerequisites (one-time)

1. **MATLAB** R2020b+ with a valid license (you already have this).
2. **Python 3.10** on PATH — used only for the small MATLAB bridge.
   <https://www.python.org/downloads/> (tick "Add Python to PATH").
3. **Docker Desktop** for Windows (with the WSL2 backend).
   <https://www.docker.com/products/docker-desktop/>

## Step 1 — Start the MATLAB bridge (host)

In PowerShell, from the repo root:

```powershell
.\setup-matlab-bridge.ps1
```

The first run finds MATLAB, creates a virtual environment, installs the MATLAB
Engine for Python, verifies it starts, then launches the bridge on port **8001**.
**Leave this window open** while you use the app. Later runs just relaunch the bridge.

> If PowerShell blocks the script, allow it for this session:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

## Step 2 — Start the app (Docker)

In a second terminal, from the repo root:

```powershell
docker compose up --build
```

- First build is **slow** (10–40 min): it installs Julia and precompiles the heavy
  Julia packages (DifferentialEquations, Turing, …). Subsequent runs are cached and fast.
- When it's up, open **<http://localhost:3000>**.
- The backend API/docs are at **<http://localhost:8000/docs>**.

To stop: `Ctrl+C`, then `docker compose down`.

## How the pieces connect

| Piece | Where it runs | Port |
|-------|---------------|------|
| Frontend (React/nginx) | container | host `3000` → `80` |
| Backend (FastAPI + Julia) | container | host `8000` |
| MATLAB bridge | host (native) | `8001` |

- The browser calls the backend at `127.0.0.1:8000` (backend port is published to the host).
- The backend calls the MATLAB bridge at `host.docker.internal:8001` (the host).
- Selection between in-process MATLAB and the bridge is via the `USE_MATLAB_BRIDGE`
  env var — set to `1` in the container, unset for native dev (see `backend/matlab_provider.py`).

## Troubleshooting

- **"Could not reach the MATLAB bridge"** in backend logs → Step 1 isn't running, or
  it's on a different port. Keep the `setup-matlab-bridge.ps1` window open.
- **Engine install fails** → your MATLAB release may require a specific Python version.
  Check MathWorks' "Versions of Python Compatible with MATLAB Products" page and install
  that Python, then re-run `.\setup-matlab-bridge.ps1 -Reinstall`.
- **Port already in use** → change the host port mappings in `docker-compose.yml`
  (and `-Port` for the bridge, keeping `MATLAB_BRIDGE_URL` in sync).

## Native (no-Docker) install

The original step-by-step native setup still works and is unchanged — see `README.md`.
In native mode leave `USE_MATLAB_BRIDGE` unset so the backend uses the in-process engine.
