"""Generate and serve 256px JPEG thumbnails."""
from pathlib import Path
import numpy as np
from PIL import Image as PilImage
from config import settings
from services.raw_processor import is_raw


def generate_thumbnail(original_path: Path, image_id: str) -> Path:
    """Generate a 256px thumbnail and save to thumbnails dir. Returns thumbnail path."""
    thumb_path = settings.thumbnails_dir / f"{image_id}.jpg"

    if thumb_path.exists():
        return thumb_path

    if is_raw(original_path):
        pil = _thumbnail_from_raw(original_path)
    else:
        pil = _thumbnail_from_jpeg(original_path)

    thumb_path.parent.mkdir(parents=True, exist_ok=True)
    pil.save(str(thumb_path), "JPEG", quality=85, optimize=True)
    return thumb_path


def _thumbnail_from_raw(path: Path) -> PilImage.Image:
    """Use rawpy embedded thumbnail or quick postprocess for RAW files."""
    import rawpy

    with rawpy.imread(str(path)) as raw:
        # Try embedded thumbnail first (fast path)
        try:
            thumb = raw.extract_thumb()
            if thumb.format == rawpy.ThumbFormat.JPEG:
                import io
                pil = PilImage.open(io.BytesIO(thumb.data)).convert("RGB")
                pil.thumbnail((settings.thumbnail_size, settings.thumbnail_size), PilImage.LANCZOS)
                return pil
            elif thumb.format == rawpy.ThumbFormat.BITMAP:
                pil = PilImage.fromarray(thumb.data, mode="RGB")
                pil.thumbnail((settings.thumbnail_size, settings.thumbnail_size), PilImage.LANCZOS)
                return pil
        except rawpy.LibRawNoThumbnailError:
            pass

        # Fall back to quick postprocess
        rgb = raw.postprocess(
            use_auto_wb=True,
            output_bps=8,
            half_size=True,  # 2x faster
        )
    pil = PilImage.fromarray(rgb, mode="RGB")
    pil.thumbnail((settings.thumbnail_size, settings.thumbnail_size), PilImage.LANCZOS)
    return pil


def _thumbnail_from_jpeg(path: Path) -> PilImage.Image:
    pil = PilImage.open(path).convert("RGB")
    pil.thumbnail((settings.thumbnail_size, settings.thumbnail_size), PilImage.LANCZOS)
    return pil


def get_image_dimensions(original_path: Path) -> tuple[int, int]:
    """Return (width, height) of the image."""
    if is_raw(original_path):
        import rawpy
        with rawpy.imread(str(original_path)) as raw:
            sizes = raw.sizes
            return sizes.width, sizes.height
    else:
        with PilImage.open(original_path) as img:
            return img.width, img.height
