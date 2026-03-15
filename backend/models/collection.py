import uuid
from datetime import datetime
from sqlalchemy import String, Integer, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column
from database import Base


class Collection(Base):
    __tablename__ = "collections"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    cover_image_id: Mapped[str | None] = mapped_column(String, nullable=True)


class CollectionMembership(Base):
    __tablename__ = "collection_memberships"

    collection_id: Mapped[str] = mapped_column(String, ForeignKey("collections.id", ondelete="CASCADE"), primary_key=True)
    image_id: Mapped[str] = mapped_column(String, ForeignKey("images.id", ondelete="CASCADE"), primary_key=True)
    added_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
