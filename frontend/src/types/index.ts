export interface EditParams {
  exposure: number          // -5 to +5
  contrast: number          // -100 to +100
  highlights: number        // -100 to +100
  shadows: number           // -100 to +100
  whites: number            // -100 to +100
  blacks: number            // -100 to +100
  temperature: number       // -100 to +100
  tint: number              // -100 to +100
  saturation: number        // -100 to +100
  vibrance: number          // -100 to +100
  sharpening: number        // 0 to 150
  sharpening_radius: number // 0.5 to 3.0
  sharpening_detail: number // 0 to 100
  noise_reduction: number   // 0 to 100
  noise_reduction_detail: number // 0 to 100
  noise_reduction_color: number  // 0 to 100
}

export const DEFAULT_EDIT_PARAMS: EditParams = {
  exposure: 0,
  contrast: 0,
  highlights: 0,
  shadows: 0,
  whites: 0,
  blacks: 0,
  temperature: 0,
  tint: 0,
  saturation: 0,
  vibrance: 0,
  sharpening: 0,
  sharpening_radius: 1,
  sharpening_detail: 25,
  noise_reduction: 0,
  noise_reduction_detail: 50,
  noise_reduction_color: 25,
}

export interface ImageMeta {
  id: string
  filename: string
  fileFormat: 'RAW' | 'JPEG' | 'TIFF'
  rawFormat: string | null
  fileSizeBytes: number
  width: number
  height: number
  createdAt: string
  capturedAt: string | null
  cameraMake: string | null
  cameraModel: string | null
  lens: string | null
  iso: number | null
  aperture: number | null
  shutterSpeed: string | null
  focalLength: number | null
  editParams: EditParams
  isEdited: boolean
  thumbnailUrl: string
}

export interface Collection {
  id: string
  name: string
  imageCount: number
  coverImageId: string | null
  createdAt: string
}

export interface Recipe {
  id: string
  name: string
  description: string | null
  params: EditParams
  createdAt: string
  updatedAt: string
  sourceImageId: string | null
}
