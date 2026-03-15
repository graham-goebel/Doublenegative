import uuid
from datetime import datetime
from sqlalchemy import String, Integer, Float, Boolean, DateTime, JSON, func
from sqlalchemy.orm import Mapped, mapped_column
from database import Base
from models.edit_params import EditParams


def _default_edit_params() -> dict:
    return EditParams().model_dump()


class Image(Base):
    __tablename__ = "images"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    filename: Mapped[str] = mapped_column(String, nullable=False)
    original_path: Mapped[str] = mapped_column(String, nullable=False)
    file_format: Mapped[str] = mapped_column(String, nullable=False)  # RAW | JPEG | TIFF
    raw_format: Mapped[str | None] = mapped_column(String, nullable=True)  # CR2 | NEF | ARW | DNG | None
    file_size_bytes: Mapped[int] = mapped_column(Integer, nullable=False)
    width: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    height: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    captured_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    camera_make: Mapped[str | None] = mapped_column(String, nullable=True)
    camera_model: Mapped[str | None] = mapped_column(String, nullable=True)
    lens: Mapped[str | None] = mapped_column(String, nullable=True)
    iso: Mapped[int | None] = mapped_column(Integer, nullable=True)
    aperture: Mapped[float | None] = mapped_column(Float, nullable=True)
    shutter_speed: Mapped[str | None] = mapped_column(String, nullable=True)
    focal_length: Mapped[float | None] = mapped_column(Float, nullable=True)
    edit_params: Mapped[dict] = mapped_column(JSON, nullable=False, default=_default_edit_params)
    is_edited: Mapped[bool] = mapped_column(Boolean, default=False)
