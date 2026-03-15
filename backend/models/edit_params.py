from pydantic import BaseModel, Field


class EditParams(BaseModel):
    # Light
    exposure: float = Field(0.0, ge=-5.0, le=5.0)
    contrast: float = Field(0.0, ge=-100.0, le=100.0)
    highlights: float = Field(0.0, ge=-100.0, le=100.0)
    shadows: float = Field(0.0, ge=-100.0, le=100.0)
    whites: float = Field(0.0, ge=-100.0, le=100.0)
    blacks: float = Field(0.0, ge=-100.0, le=100.0)
    # Color
    temperature: float = Field(0.0, ge=-100.0, le=100.0)
    tint: float = Field(0.0, ge=-100.0, le=100.0)
    saturation: float = Field(0.0, ge=-100.0, le=100.0)
    vibrance: float = Field(0.0, ge=-100.0, le=100.0)
    # Detail
    sharpening: float = Field(0.0, ge=0.0, le=150.0)
    sharpening_radius: float = Field(1.0, ge=0.5, le=3.0)
    sharpening_detail: float = Field(25.0, ge=0.0, le=100.0)
    noise_reduction: float = Field(0.0, ge=0.0, le=100.0)
    noise_reduction_detail: float = Field(50.0, ge=0.0, le=100.0)
    noise_reduction_color: float = Field(25.0, ge=0.0, le=100.0)
