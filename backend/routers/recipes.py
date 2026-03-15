from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from database import get_db
from models.recipe import Recipe
from models.image import Image
from models.edit_params import EditParams

router = APIRouter()


class RecipeCreate(BaseModel):
    name: str
    description: Optional[str] = None
    params: EditParams


class RecipeUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    params: Optional[EditParams] = None


class ApplyRecipe(BaseModel):
    image_ids: list[str]


def _recipe_to_dict(r: Recipe) -> dict:
    return {
        "id": r.id,
        "name": r.name,
        "description": r.description,
        "params": r.params,
        "createdAt": r.created_at.isoformat() if r.created_at else None,
        "updatedAt": r.updated_at.isoformat() if r.updated_at else None,
        "sourceImageId": r.source_image_id,
    }


@router.get("")
async def list_recipes(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Recipe))
    return [_recipe_to_dict(r) for r in result.scalars().all()]


@router.post("")
async def create_recipe(body: RecipeCreate, db: AsyncSession = Depends(get_db)):
    r = Recipe(name=body.name, description=body.description, params=body.params.model_dump())
    db.add(r)
    await db.commit()
    await db.refresh(r)
    return _recipe_to_dict(r)


@router.get("/{recipe_id}")
async def get_recipe(recipe_id: str, db: AsyncSession = Depends(get_db)):
    r = await db.get(Recipe, recipe_id)
    if not r:
        raise HTTPException(404, "Recipe not found")
    return _recipe_to_dict(r)


@router.put("/{recipe_id}")
async def update_recipe(recipe_id: str, body: RecipeUpdate, db: AsyncSession = Depends(get_db)):
    r = await db.get(Recipe, recipe_id)
    if not r:
        raise HTTPException(404, "Recipe not found")
    if body.name is not None:
        r.name = body.name
    if body.description is not None:
        r.description = body.description
    if body.params is not None:
        r.params = body.params.model_dump()
    await db.commit()
    await db.refresh(r)
    return _recipe_to_dict(r)


@router.delete("/{recipe_id}")
async def delete_recipe(recipe_id: str, db: AsyncSession = Depends(get_db)):
    r = await db.get(Recipe, recipe_id)
    if not r:
        raise HTTPException(404, "Recipe not found")
    await db.delete(r)
    await db.commit()
    return {"ok": True}


@router.post("/{recipe_id}/apply")
async def apply_recipe(recipe_id: str, body: ApplyRecipe, db: AsyncSession = Depends(get_db)):
    r = await db.get(Recipe, recipe_id)
    if not r:
        raise HTTPException(404, "Recipe not found")

    results = {"applied": [], "failed": []}
    defaults = EditParams()

    for image_id in body.image_ids:
        img = await db.get(Image, image_id)
        if not img:
            results["failed"].append(image_id)
            continue
        img.edit_params = r.params
        img.is_edited = r.params != defaults.model_dump()
        results["applied"].append(image_id)

    await db.commit()
    return results


@router.post("/from-image/{image_id}")
async def recipe_from_image(image_id: str, db: AsyncSession = Depends(get_db)):
    """Create a recipe from an image's current edit params."""
    img = await db.get(Image, image_id)
    if not img:
        raise HTTPException(404, "Image not found")

    r = Recipe(
        name=f"Recipe from {img.filename}",
        params=img.edit_params,
        source_image_id=image_id,
    )
    db.add(r)
    await db.commit()
    await db.refresh(r)
    return _recipe_to_dict(r)
