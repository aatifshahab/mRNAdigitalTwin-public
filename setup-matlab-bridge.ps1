<#
.SYNOPSIS
    Starts the host-side MATLAB bridge for the mRNA Digital Twin.

.DESCRIPTION
    The dockerized backend cannot launch your Windows MATLAB directly, so this
    script runs a tiny FastAPI service (matlab_bridge.py) natively on the host and
    the container calls it at http://host.docker.internal:8001.

    You only need this if you want to use the MATLAB-based units (CCTC, Lyo,
    Membrane, LNP). The IVT unit works without it.

    The script figures out the Python for you, in this order:
      1. An existing Python env that ALREADY has the MATLAB engine (used as-is).
      2. Otherwise it creates one (conda if available, else the 'py' launcher),
         installs the MATLAB engine from your MATLAB folder, and the bridge deps.
    Then it launches the bridge. Leave the window open while you use the app.

.PARAMETER Port
    Port the bridge listens on (default 8001). If you change it, also change
    MATLAB_BRIDGE_URL in docker-compose.yml.

.EXAMPLE
    .\setup-matlab-bridge.ps1
#>

[CmdletBinding()]
param([int]$Port = 8001)

# NOTE: we deliberately do NOT set $ErrorActionPreference = 'Stop' here, because
# probing tools like 'py' write to stderr when they find nothing, which would
# otherwise abort the script. We check exit codes explicitly instead.

$RepoRoot   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BackendDir = Join-Path $RepoRoot "backend"
$EnvName    = "mrna-matlab-bridge"   # conda env created only if we need one

function Write-Step($m) { Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Has-Matlab($py) {
    if (-not $py -or -not (Test-Path $py)) { return $false }
    & $py -c "import matlab.engine" 2>$null
    return ($LASTEXITCODE -eq 0)
}

# --- 1. Locate MATLAB (informational; the engine install needs it) -----------
Write-Step "Locating MATLAB"
$matlabRoot = $null
foreach ($base in @("C:\Program Files\MATLAB", "C:\Program Files (x86)\MATLAB")) {
    if (Test-Path $base) {
        $cand = Get-ChildItem $base -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName "extern\engines\python") } |
            Sort-Object Name -Descending | Select-Object -First 1
        if ($cand) { $matlabRoot = $cand.FullName; break }
    }
}
if ($matlabRoot) { Write-Host "Found MATLAB: $matlabRoot" }
else { Write-Host "No MATLAB found yet (only needed if the engine isn't already installed)." -ForegroundColor Yellow }

# --- 2. Find a Python that ALREADY has the MATLAB engine ---------------------
Write-Step "Looking for a Python with the MATLAB engine already installed"
$bridgePython = $null

# 2a. Scan conda environments (base + envs/*), if conda is available.
$conda = Get-Command conda -ErrorAction SilentlyContinue
$condaBase = $null
if ($conda) {
    $condaBase = (& conda info --base 2>$null | Select-Object -First 1)
    $candidates = @()
    if ($condaBase) { $candidates += (Join-Path $condaBase "python.exe") }
    $envsDir = if ($condaBase) { Join-Path $condaBase "envs" } else { $null }
    if ($envsDir -and (Test-Path $envsDir)) {
        $candidates += (Get-ChildItem $envsDir -Directory | ForEach-Object { Join-Path $_.FullName "python.exe" })
    }
    foreach ($c in $candidates) {
        if (Has-Matlab $c) { $bridgePython = $c; break }
    }
}

if ($bridgePython) {
    Write-Host "Reusing existing env with MATLAB engine:" -ForegroundColor Green
    Write-Host "  $bridgePython"
}

# --- 3. Otherwise, create an environment and install the engine --------------
if (-not $bridgePython) {
    Write-Step "No engine-ready Python found - creating one"
    if (-not $matlabRoot) {
        Write-Host "MATLAB is required to install the engine but none was found." -ForegroundColor Red
        Write-Host "Install MATLAB (R2020b+) with a valid license, then re-run." -ForegroundColor Red
        exit 1
    }
    $enginePath = Join-Path $matlabRoot "extern\engines\python"

    if ($conda) {
        # Reuse our dedicated env if it exists, else create it with Python 3.10.
        $envPy = if ($condaBase) { Join-Path $condaBase "envs\$EnvName\python.exe" } else { $null }
        if (-not ($envPy -and (Test-Path $envPy))) {
            Write-Host "Creating conda env '$EnvName' (Python 3.10)..."
            & conda create -y -n $EnvName python=3.10 | Out-Null
            $envPy = Join-Path $condaBase "envs\$EnvName\python.exe"
        }
        $bridgePython = $envPy
    }
    else {
        # No conda: use the 'py' launcher to make a venv (3.10/3.9/3.8 for R2023a).
        $pyVer = $null
        foreach ($v in @("3.10", "3.9", "3.8")) {
            & py -$v --version 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $pyVer = $v; break }
        }
        if (-not $pyVer) {
            Write-Host "No suitable Python found. Install Anaconda or Python 3.10 and re-run." -ForegroundColor Red
            Write-Host "  https://www.python.org/downloads/release/python-31011/" -ForegroundColor Red
            exit 1
        }
        $venv = Join-Path $RepoRoot ".venv-matlab-bridge"
        if (-not (Test-Path (Join-Path $venv "Scripts\python.exe"))) {
            & py -$pyVer -m venv $venv
        }
        $bridgePython = Join-Path $venv "Scripts\python.exe"
    }

    & $bridgePython -m pip install --upgrade pip setuptools wheel | Out-Null

    Write-Step "Installing the MATLAB Engine for Python"
    Push-Location $enginePath
    try { & $bridgePython -m pip install . }
    finally { Pop-Location }
    if (-not (Has-Matlab $bridgePython)) {
        Write-Host "MATLAB engine install failed. Your MATLAB release may need a specific" -ForegroundColor Red
        Write-Host "Python version - see MathWorks 'Versions of Python Compatible with MATLAB'." -ForegroundColor Red
        exit 1
    }
}

# --- 4. Ensure bridge dependencies are present -------------------------------
Write-Step "Checking bridge dependencies (fastapi, uvicorn, numpy, pydantic)"
& $bridgePython -c "import fastapi, uvicorn, numpy, pydantic" 2>$null
if ($LASTEXITCODE -ne 0) {
    & $bridgePython -m pip install -r (Join-Path $BackendDir "requirements-matlab-bridge.txt")
}

# --- 5. Launch the bridge ----------------------------------------------------
Write-Step "Starting the MATLAB bridge on http://localhost:$Port"
Write-Host "Health check: http://localhost:$Port/health" -ForegroundColor Green
Write-Host "Keep this window open while you use the app. Press Ctrl+C to stop." -ForegroundColor Green
Push-Location $BackendDir
try {
    & $bridgePython -m uvicorn matlab_bridge:app --host 0.0.0.0 --port $Port
}
finally {
    Pop-Location
}