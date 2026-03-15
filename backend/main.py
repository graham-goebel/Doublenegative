from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from config import settings
from database import engine, Base
from routers import images, collections, recipes, preview

# Import all models so SQLAlchemy registers them with Base
import models  # noqa: F401


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
