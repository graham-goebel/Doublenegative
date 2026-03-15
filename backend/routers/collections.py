from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func, delete
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from database import get_db
from models.collection import Collection, CollectionMembership
from models.image import Image

router = APIRouter()


class CollectionCreate(BaseModel):
    name: str


class CollectionRename(BaseModel):
    name: str


class AddImages(BaseModel):
    image_ids: list[str]


def _collection_to_dict(c: Collection, image_count: int) -> dict:
    return {
        "id": c.id,
        "name": c.name,
        "imageCount": image_count,
        "coverImageId": c.cover_image_id,
        "createdAt": c.created_at.isoformat() if c.created_at else None,
    }


@router.get("")
async def list_collections(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Collection))
    collections = result.scalars().all()

    out = []
    for c in collections:
        count_result = await db.execute(
            select(func.count()).where(CollectionMembership.collection_id == c.id)
        )
        count = count_result.scalar() or 0
        out.append(_collection_to_dict(c, count))
    return out


@router.post("")
async def create_collection(body: CollectionCreate, db: AsyncSession = Depends(get_db)):
    c = Collection(name=body.name)
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return _collection_to_dict(c, 0)


@router.get("/{collection_id}")
async def get_collection(collection_id: str, db: AsyncSession = Depends(get_db)):
    c = await db.get(Collection, collection_id)
    if not c:
        raise HTTPException(404, "Collection not found")

    result = await db.execute(
        select(CollectionMembership.image_id).where(
            CollectionMembership.collection_id == collection_id
        )
    )
    image_ids = [row[0] for row in result.all()]
    count_result = await db.execute(
        select(func.count()).where(CollectionMembership.collection_id == collection_id)
    )
    count = count_result.scalar() or 0
    data = _collection_to_dict(c, count)
    data["imageIds"] = image_ids
    return data


@router.put("/{collection_id}")
async def rename_collection(collection_id: str, body: CollectionRename, db: AsyncSession = Depends(get_db)):
    c = await db.get(Collection, collection_id)
    if not c:
        raise HTTPException(404, "Collection not found")
    c.name = body.name
    await db.commit()
    await db.refresh(c)

    count_result = await db.execute(
        select(func.count()).where(CollectionMembership.collection_id == collection_id)
    )
    count = count_result.scalar() or 0
    return _collection_to_dict(c, count)


@router.delete("/{collection_id}")
async def delete_collection(collection_id: str, db: AsyncSession = Depends(get_db)):
    c = await db.get(Collection, collection_id)
    if not c:
        raise HTTPException(404, "Collection not found")
    await db.execute(delete(CollectionMembership).where(CollectionMembership.collection_id == collection_id))
    await db.delete(c)
    await db.commit()
    return {"ok": True}


@router.post("/{collection_id}/images")
async def add_images_to_collection(
    collection_id: str,
    body: AddImages,
    db: AsyncSession = Depends(get_db),
):
    c = await db.get(Collection, collection_id)
    if not c:
        raise HTTPException(404, "Collection not found")

    for image_id in body.image_ids:
        # Check if already member
        existing = await db.get(CollectionMembership, (collection_id, image_id))
        if not existing:
            member = CollectionMembership(collection_id=collection_id, image_id=image_id)
            db.add(member)
            # Set cover image if none set
            if not c.cover_image_id:
                c.cover_image_id = image_id

    await db.commit()
    return {"ok": True}


@router.delete("/{collection_id}/images/{image_id}")
async def remove_image_from_collection(
    collection_id: str,
    image_id: str,
    db: AsyncSession = Depends(get_db),
):
    member = await db.get(CollectionMembership, (collection_id, image_id))
    if not member:
        raise HTTPException(404, "Image not in collection")
    await db.delete(member)
    await db.commit()
    return {"ok": True}
