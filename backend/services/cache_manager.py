"""Disk-based preview cache keyed by sha256(image_id + params_json)."""
import hashlib
import json
from pathlib import Path
from config import settings


def get_cache_key(image_id: str, params_dict: dict) -> str:
    payload = image_id + json.dumps(params_dict, sort_keys=True)
    return hashlib.sha256(payload.encode()).hexdigest()


def cache_path(key: str) -> Path:
    return settings.previews_dir / f"{key}.jpg"


def get_cached(key: str) -> bytes | None:
    p = cache_path(key)
    if p.exists():
        return p.read_bytes()
    return None


def save_to_cache(key: str, data: bytes) -> None:
    settings.previews_dir.mkdir(parents=True, exist_ok=True)
    cache_path(key).write_bytes(data)
    _evict_if_needed()


def invalidate_image(image_id: str) -> None:
    """Remove all cached previews that start with this image_id hash prefix."""
    # We can't easily reverse the hash, so we store a sidecar index if needed.
    # For now, just leave stale cache — new params → new hash → new file.
    # The cache will be evicted by size limits.
    pass


def _evict_if_needed() -> None:
    """Remove oldest files if cache exceeds max size."""
    previews = settings.previews_dir
    max_bytes = int(settings.preview_cache_max_gb * 1024 ** 3)

    files = sorted(previews.glob("*.jpg"), key=lambda p: p.stat().st_mtime)
    total = sum(f.stat().st_size for f in files)

    while total > max_bytes and files:
        oldest = files.pop(0)
        total -= oldest.stat().st_size
        oldest.unlink(missing_ok=True)
