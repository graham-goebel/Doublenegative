# ── Stage 1: Build the React frontend ──────────────────────────────────────────
FROM node:22-slim AS frontend-build

WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --silent

COPY frontend/ ./

# VITE_BASE_URL defaults to / for Railway/Render (single-domain deployment)
ARG VITE_BASE_URL=/
ENV VITE_BASE_URL=${VITE_BASE_URL}
RUN NODE_ENV=production npx vite build

# ── Stage 2: Python backend + serve the built frontend ─────────────────────────
FROM python:3.11-slim

# LibRaw for rawpy RAW decoding, libjpeg for Pillow
RUN apt-get update && \
    apt-get install -y --no-install-recommends libraw-dev libjpeg-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app/backend
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./

# Copy built frontend assets so FastAPI can serve them
COPY --from=frontend-build /app/frontend/dist /app/frontend/dist

# Persistent storage will be mounted here (Railway/Render volumes)
ENV DN_STORAGE_ROOT=/data
ENV PORT=8000

EXPOSE 8000

CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}
