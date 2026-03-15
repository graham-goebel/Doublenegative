"""Preview render endpoint — the performance-critical core."""
import io
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.image import Image
from models.edit_params import EditParams
from config import settings
from services.raw_processor import load_as_linear_array
from services.image_adjuster import apply_edits
from services import cache_manager

router = APIRouter()


def _render_preview(original_path: str, params: EditParams, max_long_edge: int) -> bytes:
    """Load original, apply edits, encode as JPEG bytes."""
    arr, _ = load_as_linear_array(Path(original_path))

    pil = apply_edits(arr, params)

    # Resize to max long edge
    w, h = pil.size
    long_edge = max(w, h)
    if long_edge > max_long_edge:
        scale = max_long_edge / long_edge
        new_w = int(w * scale)
        new_h = int(h * scale)
        from PIL import Image as PilImage
        pil = pil.resize((new_w, new_h), PilImage.LANCZOS)

    buf = io.BytesIO()
    pil.save(buf, "JPEG", quality=88, optimize=True)
    return buf.getvalue()


@router.post("/{image_id}")
async def render_preview(
    image_id: str,
    params: EditParams,
    db: AsyncSession = Depends(get_db),
):
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")

    params_dict = params.model_dump()
    key = cache_manager.get_cache_key(image_id, params_dict)

    cached = cache_manager.get_cached(key)
    if cached:
        return Response(content=cached, media_type="image/jpeg")

    try:
        data = _render_preview(img.original_path, params, settings.preview_max_long_edge)
    except Exception as e:
        raise HTTPException(500, f"Preview render failed: {e}")

    cache_manager.save_to_cache(key, data)
    return Response(content=data, media_type="image/jpeg")


@router.get("/{image_id}/base")
async def get_base_preview(image_id: str, db: AsyncSession = Depends(get_db)):
    """Render preview with default (unedited) params."""
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")

    defaults = EditParams()
    params_dict = defaults.model_dump()
    key = cache_manager.get_cache_key(image_id, params_dict)

    cached = cache_manager.get_cached(key)
    if cached:
        return Response(content=cached, media_type="image/jpeg")

    try:
        data = _render_preview(img.original_path, defaults, settings.preview_max_long_edge)
    except Exception as e:
        raise HTTPException(500, f"Preview render failed: {e}")

    cache_manager.save_to_cache(key, data)
    return Response(content=data, media_type="image/jpeg")


@router.post("/{image_id}/export")
async def export_image(
    image_id: str,
    params: EditParams,
    db: AsyncSession = Depends(get_db),
):
    """Full-resolution export with applied edits."""
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")

    try:
        arr, _ = load_as_linear_array(Path(img.original_path))
        pil = apply_edits(arr, params)
        buf = io.BytesIO()
        pil.save(buf, "JPEG", quality=95)
        data = buf.getvalue()
    except Exception as e:
        raise HTTPException(500, f"Export failed: {e}")

    stem = Path(img.filename).stem
    return Response(
        content=data,
        media_type="image/jpeg",
        headers={"Content-Disposition": f'attachment; filename="{stem}_edited.jpg"'},
    )
