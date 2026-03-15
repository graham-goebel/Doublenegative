#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

# ── Install dependencies if needed ─────────────────────────────────────────────
if ! python3 -c "import fastapi" 2>/dev/null; then
  echo "→ Installing Python dependencies..."
  pip install -r "$ROOT/backend/requirements.txt"
fi

if [ ! -d "$ROOT/frontend/node_modules" ]; then
  echo "→ Installing frontend dependencies..."
  cd "$ROOT/frontend" && npm install
fi

# ── Detect local IP for network access (iPad etc.) ─────────────────────────────
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || \
           ip route get 1 2>/dev/null | awk '{print $7; exit}' || \
           echo "localhost")

# ── Start backend (bind to all interfaces) ─────────────────────────────────────
echo "→ Starting backend on http://0.0.0.0:8000"
cd "$ROOT/backend"
uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# ── Start frontend (bind to all interfaces) ────────────────────────────────────
echo "→ Starting frontend on http://0.0.0.0:5173"
cd "$ROOT/frontend"
npm run dev -- --host &
FRONTEND_PID=$!

# ── Cleanup on Ctrl+C ───────────────────────────────────────────────────────────
trap "echo '→ Stopping...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit 0" INT TERM

echo ""
echo "  Local:  http://localhost:5173"
echo "  iPad:   http://${LOCAL_IP}:5173"
echo "  API:    http://localhost:8000/docs"
echo "  Press Ctrl+C to stop"
echo ""

wait
