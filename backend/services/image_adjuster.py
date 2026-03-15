"""
Apply EditParams to a linear-light float32 numpy array.
All operations work in float32 [0,1] linear space, except
saturation/vibrance which temporarily convert to HSL.
"""
import numpy as np
from PIL import Image as PilImage, ImageFilter
from models.edit_params import EditParams


def apply_edits(arr: np.ndarray, params: EditParams) -> PilImage.Image:
    """
    arr: float32 [0,1] linear-light RGB, shape (H, W, 3)
    Returns: PIL Image (sRGB, uint8)
    """
    img = arr.copy()

    # 1. White balance (temperature + tint)
    img = _apply_white_balance(img, params.temperature, params.tint)

    # 2. Exposure: multiply by 2^EV
    img *= 2.0 ** params.exposure

    # 3. Tone region adjustments (highlights, shadows, whites, blacks)
    img = _apply_tone_regions(img, params.highlights, params.shadows,
                               params.whites, params.blacks)

    # 4. Contrast S-curve in linear space
    img = _apply_contrast(img, params.contrast)

    # 5. Apply sRGB gamma (linear → sRGB)
    img = _linear_to_srgb(img)

    # 6. Saturation + vibrance (work in HSL space on sRGB values)
    img = _apply_saturation_vibrance(img, params.saturation, params.vibrance)

    # 7. Clip to [0,1]
    img = np.clip(img, 0.0, 1.0)

    # 8. Convert to uint8 for sharpening/NR via PIL
    pil = PilImage.fromarray((img * 255).astype(np.uint8), mode="RGB")

    # 9. Sharpening (unsharp mask)
    if params.sharpening > 0:
        pil = _apply_sharpening(pil, params.sharpening, params.sharpening_radius,
                                  params.sharpening_detail)

    # 10. Noise reduction
    if params.noise_reduction > 0:
        pil = _apply_noise_reduction(pil, params.noise_reduction,
                                      params.noise_reduction_detail,
                                      params.noise_reduction_color)

    return pil


def _apply_white_balance(img: np.ndarray, temperature: float, tint: float) -> np.ndarray:
    """
    Temperature: -100 (cool/blue) to +100 (warm/orange)
    Tint: -100 (green) to +100 (magenta)
    """
    # Shift R/B channels for temperature
    temp_factor = temperature / 100.0
    r_gain = 1.0 + temp_factor * 0.3
    b_gain = 1.0 - temp_factor * 0.3

    # Shift G channel for tint
    tint_factor = tint / 100.0
    g_gain = 1.0 - tint_factor * 0.15

    result = img.copy()
    result[:, :, 0] *= r_gain  # R
    result[:, :, 1] *= g_gain  # G
    result[:, :, 2] *= b_gain  # B
    return result


def _apply_tone_regions(img: np.ndarray, highlights: float, shadows: float,
                         whites: float, blacks: float) -> np.ndarray:
    """Apply selective tone region adjustments using luminance masks."""
    # Compute luminance mask
    lum = 0.2126 * img[:, :, 0] + 0.7152 * img[:, :, 1] + 0.0722 * img[:, :, 2]
    lum = np.clip(lum, 0, 1)

    result = img.copy()

    # Whites: affects very bright areas (lum > 0.85)
    if whites != 0:
        mask = np.clip((lum - 0.85) / 0.15, 0, 1)[:, :, np.newaxis]
        factor = 1.0 + (whites / 100.0) * 0.5
        result = result * (1 - mask) + result * factor * mask

    # Blacks: affects very dark areas (lum < 0.15)
    if blacks != 0:
        mask = np.clip((0.15 - lum) / 0.15, 0, 1)[:, :, np.newaxis]
        factor = 1.0 + (blacks / 100.0) * 0.5
        result = result * (1 - mask) + result * factor * mask

    # Highlights: affects bright areas (lum 0.5-1.0)
    if highlights != 0:
        mask = np.clip((lum - 0.5) / 0.5, 0, 1)[:, :, np.newaxis]
        delta = (highlights / 100.0) * 0.3 * mask
        result = result + delta

    # Shadows: affects dark areas (lum 0.0-0.5)
    if shadows != 0:
        mask = np.clip((0.5 - lum) / 0.5, 0, 1)[:, :, np.newaxis]
        delta = (shadows / 100.0) * 0.3 * mask
        result = result + delta

    return result


def _apply_contrast(img: np.ndarray, contrast: float) -> np.ndarray:
    """S-curve contrast adjustment around midpoint 0.5."""
    if contrast == 0:
        return img
    factor = (contrast / 100.0) * 0.5  # scale to reasonable range
    # Simple S-curve: move values away from or toward 0.5
    mid = 0.5
    result = mid + (img - mid) * (1.0 + factor)
    return result


def _linear_to_srgb(arr: np.ndarray) -> np.ndarray:
    """Apply sRGB gamma transfer function."""
    arr = np.clip(arr, 0, None)
    # Standard sRGB transfer function
    low = arr * 12.92
    high = 1.055 * np.power(np.maximum(arr, 1e-10), 1.0 / 2.4) - 0.055
    return np.where(arr <= 0.0031308, low, high)


def _apply_saturation_vibrance(img: np.ndarray, saturation: float, vibrance: float) -> np.ndarray:
    """Apply saturation and vibrance in sRGB space."""
    if saturation == 0 and vibrance == 0:
        return img

    # Convert to HSV-like: compute per-pixel saturation
    r, g, b = img[:, :, 0], img[:, :, 1], img[:, :, 2]
    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    chroma = cmax - cmin

    result = img.copy()

    # Saturation: global multiplicative adjustment of chroma
    if saturation != 0:
        sat_factor = 1.0 + saturation / 100.0
        # Scale each channel toward/away from luminance
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        lum3 = np.stack([lum, lum, lum], axis=-1)
        result = lum3 + (result - lum3) * sat_factor

    # Vibrance: boost low-saturation colors more, protect already-saturated
    if vibrance != 0:
        vib_factor = vibrance / 100.0
        sat_mask = 1.0 - np.clip(chroma, 0, 1)  # high value = low saturation pixel
        sat_mask3 = np.stack([sat_mask, sat_mask, sat_mask], axis=-1)
        lum = 0.2126 * result[:, :, 0] + 0.7152 * result[:, :, 1] + 0.0722 * result[:, :, 2]
        lum3 = np.stack([lum, lum, lum], axis=-1)
        boost = (result - lum3) * sat_mask3 * vib_factor
        result = result + boost

    return result


def _apply_sharpening(img: PilImage.Image, amount: float, radius: float, detail: float) -> PilImage.Image:
    """Unsharp mask sharpening."""
    # Map amount 0-150 → percent 0-200%
    percent = int(amount * 1.5)
    # Map radius 0.5-3.0 → pixel radius
    px_radius = max(1, int(radius * 2))
    # detail affects threshold (higher = sharpen less fine detail)
    threshold = int((100 - detail) / 10)
    return img.filter(ImageFilter.UnsharpMask(radius=px_radius, percent=percent, threshold=threshold))


def _apply_noise_reduction(img: PilImage.Image, amount: float, detail: float, color: float) -> PilImage.Image:
    """Simple Gaussian blur-based noise reduction."""
    if amount <= 0:
        return img

    # Map amount 0-100 → blur radius 0-3px
    blur_r = (amount / 100.0) * 2.0

    # Luminance NR: blur the luminance channel
    import numpy as np
    from scipy.ndimage import gaussian_filter

    arr = np.array(img, dtype=np.float32) / 255.0
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]

    # Convert to YCbCr-like
    Y = 0.299 * r + 0.587 * g + 0.114 * b
    Cb = b - Y
    Cr = r - Y

    # Detail parameter controls how much luma NR to apply
    luma_blur = blur_r * (1.0 - detail / 200.0)
    color_blur = blur_r * (color / 100.0) * 1.5

    if luma_blur > 0.1:
        Y_smoothed = gaussian_filter(Y, sigma=luma_blur)
        # Blend based on amount
        blend = amount / 100.0
        Y = Y * (1 - blend) + Y_smoothed * blend

    if color_blur > 0.1:
        Cb = gaussian_filter(Cb, sigma=color_blur)
        Cr = gaussian_filter(Cr, sigma=color_blur)

    # Convert back to RGB
    r_out = np.clip(Cr + Y, 0, 1)
    b_out = np.clip(Cb + Y, 0, 1)
    g_out = np.clip((Y - 0.299 * r_out - 0.114 * b_out) / 0.587, 0, 1)

    result = np.stack([r_out, g_out, b_out], axis=-1)
    return PilImage.fromarray((result * 255).astype(np.uint8), mode="RGB")
