# mRNA Digital Twin — backend image (FastAPI + Julia/IVT model).
#
# MATLAB is NOT installed here. The four MATLAB models are reached over HTTP via
# the host "matlab-bridge" (USE_MATLAB_BRIDGE=1 -> backend/matlab_client.py).
#
# Build context must be the REPOSITORY ROOT (it needs both backend/ and IVT2.0/):
#   docker build -f backend/Dockerfile -t mrna-backend .
# (docker-compose.yml already sets context: . for you.)

FROM python:3.10-slim

# ---- system deps (PyCall/Julia build need a compiler + git + curl) ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# ---- install Julia 1.11.6 (matches the version that generated the Manifest) -
ARG JULIA_VERSION=1.11.6
ARG JULIA_MAJOR=1.11
RUN curl -fsSL "https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_MAJOR}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz" \
        -o /tmp/julia.tar.gz \
    && mkdir -p /opt/julia \
    && tar -xzf /tmp/julia.tar.gz -C /opt/julia --strip-components=1 \
    && ln -s /opt/julia/bin/julia /usr/local/bin/julia \
    && rm /tmp/julia.tar.gz

# Writable, persistent Julia depot (precompiled packages land here)
ENV JULIA_DEPOT_PATH=/opt/julia-depot
# Tell PyCall which Python to bind to (this container's interpreter)
ENV PYTHON=/usr/local/bin/python

WORKDIR /app

# ---- Python dependencies ----------------------------------------------------
COPY backend/requirements.txt /app/backend/requirements.txt
RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install -r /app/backend/requirements.txt

# Build PyCall so PyJulia (the `julia` package) can drive Julia from Python
RUN python -c "import julia; julia.install()"

# ---- application code -------------------------------------------------------
# IVT2.0 is needed by julia_interface.py (it includes IVT2.0/modules/API/reactorAPI.jl)
COPY IVT2.0 /app/IVT2.0
COPY backend /app/backend

# ---- precompile the heavy Julia environment (DifferentialEquations, Turing…) -
# This is the slow part of the build (can take 20-40 min the first time) but makes
# container startup far faster. The project lives in IVT2.0/IVTmodel.
RUN julia --project=/app/IVT2.0/IVTmodel -e \
        "using Pkg; Pkg.instantiate(); Pkg.precompile()"

# Runs.db and any outputs are written relative to the backend working dir
WORKDIR /app/backend

# In Docker, always reach MATLAB through the host bridge
ENV USE_MATLAB_BRIDGE=1
ENV MATLAB_BRIDGE_URL=http://host.docker.internal:8001

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
