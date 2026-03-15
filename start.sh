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

# ── Start backend ───────────────────────────────────────────────────────────────
echo "→ Starting backend on http://localhost:8000"
cd "$ROOT/backend"
uvicorn main:app --reload --port 8000 &
BACKEND_PID=$!

# ── Start frontend ──────────────────────────────────────────────────────────────
echo "→ Starting frontend on http://localhost:5173"
cd "$ROOT/frontend"
npm run dev &
FRONTEND_PID=$!

# ── Cleanup on Ctrl+C ───────────────────────────────────────────────────────────
trap "echo '→ Stopping...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit 0" INT TERM

echo ""
echo "  App running at http://localhost:5173"
echo "  API docs at  http://localhost:8000/docs"
echo "  Press Ctrl+C to stop"
echo ""

wait
