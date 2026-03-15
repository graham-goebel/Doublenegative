import React, { useEffect } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { CollectionPanel } from './CollectionPanel'
import { ThumbnailCard } from './ThumbnailCard'
import { ImportDropzone } from './ImportDropzone'

export function LibraryView() {
  const { images, selectedIds, selectImage, openInDevelop, fetchImages, isLoading } = useLibraryStore()

  useEffect(() => {
    fetchImages()
  }, [])

  return (
    <div className="flex flex-1 overflow-hidden">
      <CollectionPanel />

      <ImportDropzone>
        <div className="flex-1 h-full overflow-y-auto p-4">
          {isLoading && images.length === 0 && (
            <div className="flex items-center justify-center h-full text-gray-500">
              Loading…
            </div>
          )}

          {!isLoading && images.length === 0 && (
            <div className="flex flex-col items-center justify-center h-full text-gray-600 gap-4">
              <div className="text-6xl">📷</div>
              <p className="text-lg">No images yet</p>
              <p className="text-sm">Drag & drop images here or click Import</p>
            </div>
          )}

          <div className="grid grid-cols-[repeat(auto-fill,minmax(160px,1fr))] gap-2">
            {images.map(img => (
              <ThumbnailCard
                key={img.id}
                image={img}
                isSelected={selectedIds.has(img.id)}
                onClick={e => selectImage(img.id, e.ctrlKey || e.metaKey)}
                onDoubleClick={() => openInDevelop(img.id)}
              />
            ))}
          </div>
        </div>
      </ImportDropzone>
    </div>
  )
}
