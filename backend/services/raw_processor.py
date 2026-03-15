"""
RAW/JPEG to numpy array conversion.
For RAW: uses rawpy to decode to linear-light uint16 array.
For JPEG/TIFF: uses Pillow to load as float32 array.
"""
from pathlib import Path
import numpy as np
from PIL import Image as PilImage


RAW_EXTENSIONS = {".cr2", ".nef", ".arw", ".dng", ".raf", ".orf", ".rw2", ".pef", ".srw", ".x3f"}


def is_raw(path: Path) -> bool:
    return path.suffix.lower() in RAW_EXTENSIONS


def load_as_linear_array(path: Path) -> tuple[np.ndarray, dict]:
    """
    Returns (array, exif_dict).
    array: float32 [0,1] in linear-light RGB, shape (H, W, 3).
    exif_dict: extracted metadata (may be empty).
    """
    if is_raw(path):
        return _load_raw(path)
    else:
        return _load_jpeg(path)


def _load_raw(path: Path) -> tuple[np.ndarray, dict]:
    import rawpy

    with rawpy.imread(str(path)) as raw:
        exif = _extract_raw_exif(raw)
        rgb = raw.postprocess(
            use_camera_wb=False,
            use_auto_wb=True,
            output_bps=16,
            no_auto_bright=True,
            gamma=(1, 1),  # linear output — we apply tone curve ourselves
            demosaic_algorithm=rawpy.DemosaicAlgorithm.AHD,
        )
    # rgb is uint16 (H, W, 3)
    arr = rgb.astype(np.float32) / 65535.0
    return arr, exif


def _load_jpeg(path: Path) -> tuple[np.ndarray, dict]:
    import piexif

    img = PilImage.open(path).convert("RGB")
    exif = {}
    try:
        raw_exif = img.info.get("exif", b"")
        if raw_exif:
            exif_data = piexif.load(raw_exif)
            exif = _parse_piexif(exif_data)
    except Exception:
        pass

    arr = np.array(img, dtype=np.float32) / 255.0
    # Convert sRGB → linear for consistent pipeline
    arr = _srgb_to_linear(arr)
    return arr, exif


def _srgb_to_linear(arr: np.ndarray) -> np.ndarray:
    """Approximate sRGB gamma removal (gamma 2.2)."""
    return np.power(np.clip(arr, 0, 1), 2.2)


def _extract_raw_exif(raw) -> dict:
    """Extract basic EXIF from rawpy object."""
    exif = {}
    try:
        other = raw.other_data
        if other.iso_speed:
            exif["iso"] = int(other.iso_speed)
        if other.shutter:
            s = other.shutter
            if s < 1:
                exif["shutter_speed"] = f"1/{int(round(1/s))}"
            else:
                exif["shutter_speed"] = f"{s:.1f}s"
        if other.aperture:
            exif["aperture"] = round(float(other.aperture), 1)
        if other.focal_len:
            exif["focal_length"] = round(float(other.focal_len), 1)
        if other.timestamp:
            from datetime import datetime
            exif["captured_at"] = datetime.fromtimestamp(other.timestamp)
    except Exception:
        pass

    try:
        make = raw.metadata.make
        model = raw.metadata.model
        if make:
            exif["camera_make"] = make.strip()
        if model:
            exif["camera_model"] = model.strip()
    except Exception:
        pass

    return exif


def _parse_piexif(exif_data: dict) -> dict:
    import piexif

    result = {}
    try:
        ifd0 = exif_data.get("0th", {})
        exif_ifd = exif_data.get("Exif", {})

        make = ifd0.get(piexif.ImageIFD.Make, b"")
        model = ifd0.get(piexif.ImageIFD.Model, b"")
        if make:
            result["camera_make"] = make.decode("utf-8", errors="ignore").strip("\x00").strip()
        if model:
            result["camera_model"] = model.decode("utf-8", errors="ignore").strip("\x00").strip()

        iso = exif_ifd.get(piexif.ExifIFD.ISOSpeedRatings)
        if iso:
            result["iso"] = int(iso) if not isinstance(iso, tuple) else int(iso[0])

        aperture = exif_ifd.get(piexif.ExifIFD.FNumber)
        if aperture and isinstance(aperture, tuple) and aperture[1]:
            result["aperture"] = round(aperture[0] / aperture[1], 1)

        shutter = exif_ifd.get(piexif.ExifIFD.ExposureTime)
        if shutter and isinstance(shutter, tuple) and shutter[1]:
            s = shutter[0] / shutter[1]
            if s < 1:
                result["shutter_speed"] = f"1/{int(round(1/s))}"
            else:
                result["shutter_speed"] = f"{s:.1f}s"

        focal = exif_ifd.get(piexif.ExifIFD.FocalLength)
        if focal and isinstance(focal, tuple) and focal[1]:
            result["focal_length"] = round(focal[0] / focal[1], 1)

        dt_str = exif_ifd.get(piexif.ExifIFD.DateTimeOriginal, b"")
        if dt_str:
            from datetime import datetime
            try:
                result["captured_at"] = datetime.strptime(
                    dt_str.decode("utf-8", errors="ignore"), "%Y:%m:%d %H:%M:%S"
                )
            except Exception:
                pass
    except Exception:
        pass

    return result
