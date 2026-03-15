import shutil
import uuid
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from fastapi.responses import FileResponse
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from database import get_db
from models.image import Image
from models.collection import CollectionMembership
from models.edit_params import EditParams
from config import settings
from services.raw_processor import is_raw, load_as_linear_array
from services.thumbnail_service import generate_thumbnail, get_image_dimensions

router = APIRouter()

RAW_EXTENSIONS = {".cr2", ".nef", ".arw", ".dng", ".raf", ".orf", ".rw2", ".pef", ".srw", ".x3f"}
JPEG_EXTENSIONS = {".jpg", ".jpeg", ".tif", ".tiff", ".png"}


def _file_format(ext: str) -> str:
    ext = ext.lower()
    if ext in RAW_EXTENSIONS:
        return "RAW"
    if ext in {".tif", ".tiff"}:
        return "TIFF"
    return "JPEG"


def _image_to_dict(img: Image) -> dict:
    return {
        "id": img.id,
        "filename": img.filename,
        "fileFormat": img.file_format,
        "rawFormat": img.raw_format,
        "fileSizeBytes": img.file_size_bytes,
        "width": img.width,
        "height": img.height,
        "createdAt": img.created_at.isoformat() if img.created_at else None,
        "capturedAt": img.captured_at.isoformat() if img.captured_at else None,
        "cameraMake": img.camera_make,
        "cameraModel": img.camera_model,
        "lens": img.lens,
        "iso": img.iso,
        "aperture": img.aperture,
        "shutterSpeed": img.shutter_speed,
        "focalLength": img.focal_length,
        "editParams": img.edit_params,
        "isEdited": img.is_edited,
        "thumbnailUrl": f"/api/images/{img.id}/thumbnail",
    }


@router.post("/import")
async def import_images(
    files: list[UploadFile] = File(...),
    db: AsyncSession = Depends(get_db),
):
    """Upload one or more image files. Returns list of created Image objects."""
    settings.originals_dir.mkdir(parents=True, exist_ok=True)
    settings.thumbnails_dir.mkdir(parents=True, exist_ok=True)

    results = []
    for upload in files:
        ext = Path(upload.filename).suffix.lower()
        if ext not in RAW_EXTENSIONS and ext not in JPEG_EXTENSIONS:
            continue

        image_id = str(uuid.uuid4())
        dest = settings.originals_dir / f"{image_id}{ext}"

        # Save original
        with dest.open("wb") as f:
            shutil.copyfileobj(upload.file, f)

        # Extract metadata
        try:
            _, exif = load_as_linear_array(dest)
        except Exception:
            exif = {}

        # Dimensions
        try:
            w, h = get_image_dimensions(dest)
        except Exception:
            w, h = 0, 0

        # Thumbnail
        try:
            generate_thumbnail(dest, image_id)
        except Exception:
            pass

        fmt = _file_format(ext)
        raw_fmt = ext.lstrip(".").upper() if fmt == "RAW" else None

        img = Image(
            id=image_id,
            filename=upload.filename,
            original_path=str(dest),
            file_format=fmt,
            raw_format=raw_fmt,
            file_size_bytes=dest.stat().st_size,
            width=w,
            height=h,
            edit_params=EditParams().model_dump(),
            is_edited=False,
            captured_at=exif.get("captured_at"),
            camera_make=exif.get("camera_make"),
            camera_model=exif.get("camera_model"),
            iso=exif.get("iso"),
            aperture=exif.get("aperture"),
            shutter_speed=exif.get("shutter_speed"),
            focal_length=exif.get("focal_length"),
        )
        db.add(img)
        results.append(img)

    await db.commit()
    for img in results:
        await db.refresh(img)

    return [_image_to_dict(img) for img in results]


@router.get("")
async def list_images(
    collection_id: Optional[str] = Query(None),
    sort: str = Query("date", regex="^(date|name|size)$"),
    order: str = Query("desc", regex="^(asc|desc)$"),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Image)

    if collection_id:
        # Filter by collection membership
        member_stmt = select(CollectionMembership.image_id).where(
            CollectionMembership.collection_id == collection_id
        )
        stmt = stmt.where(Image.id.in_(member_stmt))

    if sort == "date":
        col = Image.created_at
    elif sort == "name":
        col = Image.filename
    else:
        col = Image.file_size_bytes

    if order == "desc":
        stmt = stmt.order_by(col.desc())
    else:
        stmt = stmt.order_by(col.asc())

    result = await db.execute(stmt)
    images = result.scalars().all()
    return [_image_to_dict(img) for img in images]


@router.get("/{image_id}")
async def get_image(image_id: str, db: AsyncSession = Depends(get_db)):
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")
    return _image_to_dict(img)


@router.get("/{image_id}/thumbnail")
async def get_thumbnail(image_id: str, db: AsyncSession = Depends(get_db)):
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")

    thumb_path = settings.thumbnails_dir / f"{image_id}.jpg"
    if not thumb_path.exists():
        try:
            generate_thumbnail(Path(img.original_path), image_id)
        except Exception as e:
            raise HTTPException(500, f"Thumbnail generation failed: {e}")

    return FileResponse(str(thumb_path), media_type="image/jpeg")


@router.put("/{image_id}/edits")
async def save_edits(image_id: str, params: EditParams, db: AsyncSession = Depends(get_db)):
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")

    defaults = EditParams()
    is_edited = params.model_dump() != defaults.model_dump()

    img.edit_params = params.model_dump()
    img.is_edited = is_edited
    await db.commit()
    await db.refresh(img)
    return _image_to_dict(img)


@router.post("/{image_id}/reset")
async def reset_edits(image_id: str, db: AsyncSession = Depends(get_db)):
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")

    img.edit_params = EditParams().model_dump()
    img.is_edited = False
    await db.commit()
    await db.refresh(img)
    return _image_to_dict(img)


@router.delete("/{image_id}")
async def delete_image(image_id: str, db: AsyncSession = Depends(get_db)):
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")

    # Remove collection memberships
    await db.execute(delete(CollectionMembership).where(CollectionMembership.image_id == image_id))
    await db.delete(img)
    await db.commit()
    return {"ok": True}
