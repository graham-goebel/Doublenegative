from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from contextlib import asynccontextmanager

from config import settings
from database import engine, Base
from routers import images, collections, recipes, preview

# Import all models so SQLAlchemy registers them with Base
import models  # noqa: F401

# Path to the built frontend — populated in Docker, absent in local dev
FRONTEND_DIST = Path(__file__).parent.parent / "frontend" / "dist"


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create storage dirs and DB tables
    for d in [settings.originals_dir, settings.thumbnails_dir, settings.previews_dir]:
        d.mkdir(parents=True, exist_ok=True)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield

    # Shutdown: dispose engine
    await engine.dispose()


app = FastAPI(title="Doublenegative", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(images.router, prefix="/api/images", tags=["images"])
app.include_router(collections.router, prefix="/api/collections", tags=["collections"])
app.include_router(recipes.router, prefix="/api/recipes", tags=["recipes"])
app.include_router(preview.router, prefix="/api/preview", tags=["preview"])


@app.get("/health")
async def health():
    return {"status": "ok"}


# Serve the built React frontend for all non-API routes.
# In local dev this directory won't exist — that's fine, Vite dev server handles it.
if FRONTEND_DIST.exists():
    # Mount static assets (JS/CSS/images)
    app.mount("/assets", StaticFiles(directory=str(FRONTEND_DIST / "assets")), name="assets")

    # Catch-all: serve index.html for any route not matched above (SPA client-side routing)
    @app.get("/{full_path:path}")
    async def serve_spa(full_path: str):
        index = FRONTEND_DIST / "index.html"
        return FileResponse(str(index))
