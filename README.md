# mRNA Digital Twin — Complete Local Installation Guide (Windows-first) 

## 1) Overview 

The project includes: 

- Backend API (FastAPI, Python) orchestrating unit operations and calling MATLAB models (via MATLAB Engine) and Julia code for IVT (via PyJulia). 
- Frontend (React) to run individual units or chains. 
- Sensitivity analysis scripts (Morris screening) for lyophilization and TFF. 

## 2) System Requirements 

- OS: Windows 10/11 
- RAM: 8 GB minimum (16 GB recommended) 
- Disk: ~10 GB free 
- MATLAB: Valid license (R2020b or later) 

## 3) Software Prerequisites 

- MATLAB R2020b+ with MATLAB Engine for Python 
- Python: >3.9 and <3.12 (use 3.10 recommended) 
- Julia 1.9+ (required) 
- Node.js 20.x LTS (npm included) 
- Git 

> MATLAB Engine must be installed into a Python version supported by your MATLAB release (e.g., MATLAB R2023a supports Python 3.8–3.10). Use Python 3.10 unless you have a specific reason to use another supported version. 

## 5) Step-by-Step Installation 

### Step 1 — Install Git 

- Download: https://git-scm.com/download/win 
- Use default options. 
- Verify in a new PowerShell window: 

```powershell
git --version
```
Step 2 — Clone the repository
```powershell
git clone https://github.com/aatifshahab/mRNAdigitalTwin.git 
cd mRNAdigitalTwin
```
Step 3 — Install Node.js (for the React frontend)
Download Node.js 20.x LTS from: https://nodejs.org
(Use the Windows Installer, keep the default options.)

Complete the installer. When prompted, allow the installer to add Node to PATH.

Open a new PowerShell/Command Prompt and verify:

```powershell

node --version 
npm --version
```
You should see something like v20.x.x and 10.x.x.

Step 4 — Install Python 3.10 and create a virtual environment
Download Python 3.10 from https://www.python.org/downloads/

During install: check “Add Python to PATH.”

Create and activate a venv:

```powershell
py -3.10 -m venv .venv310 
.\.venv310\Scripts\Activate.ps1 
python --version      # should show 3.10.x 
python -m pip install --upgrade pip setuptools wheel
```
Step 5 — Install MATLAB and the MATLAB Engine for Python
Install MATLAB R2023a or later.

With your .venv310 activated, install the engine (adjust path if needed):

```powershell

cd "C:\Program Files\MATLAB\R2023a\extern\engines\python" 
python -m pip install .
```
Test:
```
powershell
python -c "import matlab.engine as me; eng=me.start_matlab(); print(eng.sqrt(4.0)); eng.quit()"
```
Expected output: 2.0

Step 6— Install Julia 1.9+ and link it to Python (PyJulia)
Download from https://julialang.org/downloads/ and ensure Julia is on PATH.

Verify:

```powershell

julia --version
```
In your .venv310, install and initialize PyJulia:

```powershell

cd mRNAdigitalTwin 

.\.venv310\Scripts\Activate.ps1 

python -m pip install julia 

python -c "import julia; julia.install()" 

python -c "from julia import Julia, Base; Julia(); print(Base.sqrt(9))"
```
Expected output: 3.0

Instantiate IVT2.0/ :

```powershell

cd IVT2.0 
julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate(); Pkg.precompile();" 
cd ..
```
Step 7 — Backend setup (FastAPI)
Activate your .venv310 (same one used for MATLAB Engine and PyJulia):

```powershell

cd backend 
..\ .venv310\Scripts\Activate.ps1   
python -m pip install --upgrade pip 
python -m pip install fastapi uvicorn pydantic numpy scipy pandas matplotlib SALib
```
 (or requirements.txt) 
Run the backend (development mode):

```powershell

uvicorn main:app --reload
```
Step 8 — Frontend setup (React)
In a new terminal:

```powershell

cd ivt-frontend 
npm install 
npm start
```
# Running Units and Chains
Use the React UI or Swagger (/docs) to run:

Single unit (e.g., CCTC alone)

Sequence (e.g., IVT → Membrane → CCTC → LNP → LYO)

# Sensitivity Analyses
Lyophilization (phase-wise Morris)

Script (example): backend/sensitivity_lyo.py

Outputs phase-mean product temperature (and optionally bound water) per phase

Freezing prints a text summary; Primary/Secondary save μ* (±σ) bar plots

Run:

```powershell

cd backend 
python sensitivity_lyo.py
```
TFF / Membrane (Morris)

Script: backend/sensitivity_tff.py

Varies qF, D, c0_mRNA (conversion X fixed at 0.90)

Saves μ* (±σ) bar chart

Run:

```powershell
python sensitivity_tff.p
```
# Troubleshooting
MATLAB Engine import fails

Confirm you installed the engine into this venv and Python is in MATLAB’s supported range.

Quick check:

```powershell
python -c "import matlab.engine"
``` 
PyJulia / julia.install() errors

Ensure julia is on PATH (where julia).

Re-run:

```powershell
python -c "import julia; julia.install()"
```
If needed, rebuild PyCall from Julia:

```powershell
julia -e "using Pkg; Pkg.build(\"PyCall\")"
```
