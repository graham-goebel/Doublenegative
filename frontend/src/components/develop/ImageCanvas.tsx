import React, { useEffect } from 'react'
import { useEditStore } from '../../store/editStore'
import { usePreview } from '../../hooks/usePreview'
import { useLibraryStore } from '../../store/libraryStore'

export function ImageCanvas() {
  const activeImageId = useLibraryStore(s => s.activeImageId)
  const { previewUrl, isPreviewLoading } = useEditStore(s => ({
    previewUrl: s.previewUrl,
    isPreviewLoading: s.isPreviewLoading,
  }))

  const { cssFilter } = usePreview(activeImageId)

  return (
    <div className="flex-1 flex items-center justify-center bg-[#0d0d0d] relative overflow-hidden">
      {!activeImageId && (
        <p className="text-gray-600">Select an image to edit</p>
      )}

      {activeImageId && !previewUrl && isPreviewLoading && (
        <div className="flex flex-col items-center gap-3 text-gray-500">
          <div className="w-8 h-8 border-2 border-gray-600 border-t-accent rounded-full animate-spin" />
          <span className="text-sm">Rendering preview…</span>
        </div>
      )}

      {previewUrl && (
        <div className="relative max-w-full max-h-full p-4">
          <img
            src={previewUrl}
            alt="Preview"
            className="max-w-full max-h-[calc(100vh-200px)] object-contain rounded shadow-2xl"
            style={{ filter: isPreviewLoading ? cssFilter : 'none', transition: 'filter 0.1s' }}
          />
          {isPreviewLoading && (
            <div className="absolute top-6 right-6 w-5 h-5 border-2 border-gray-600 border-t-accent rounded-full animate-spin" />
          )}
        </div>
      )}
    </div>
  )
}
