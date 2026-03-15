import os
from pathlib import Path
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    storage_root: Path = Path(__file__).parent / "storage"
    preview_max_long_edge: int = 1800
    preview_cache_max_gb: float = 2.0
    thumbnail_size: int = 256
    # Comma-separated origins, e.g. "https://myapp.railway.app,http://localhost:5173"
    cors_origins: list[str] = ["http://localhost:5173", "http://localhost:3000"]
    max_upload_size_mb: int = 500

    @property
    def originals_dir(self) -> Path:
        return self.storage_root / "originals"

    @property
    def thumbnails_dir(self) -> Path:
        return self.storage_root / "thumbnails"

    @property
    def previews_dir(self) -> Path:
        return self.storage_root / "previews"

    @property
    def db_path(self) -> Path:
        return self.storage_root / "doublenegative.db"

    class Config:
        env_prefix = "DN_"


settings = Settings()
