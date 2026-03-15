import React from 'react'
import { clsx } from 'clsx'
import { useLibraryStore } from '../../store/libraryStore'
import { useEditStore } from '../../store/editStore'

export function FilmStrip() {
  const { images, activeImageId, openInDevelop } = useLibraryStore(s => ({
    images: s.images,
    activeImageId: s.activeImageId,
    openInDevelop: s.openInDevelop,
  }))
  const loadImage = useEditStore(s => s.loadImage)

  const handleSelect = (imageId: string) => {
    const img = images.find(i => i.id === imageId)
    if (!img) return
    openInDevelop(imageId)
    loadImage(img)
  }

  return (
    <div className="h-20 shrink-0 bg-[#111] border-t border-border flex items-center gap-1 px-2 overflow-x-auto">
      {images.map(img => (
        <button
          key={img.id}
          onClick={() => handleSelect(img.id)}
          className={clsx(
            'shrink-0 h-16 w-16 rounded overflow-hidden transition-all',
            activeImageId === img.id
              ? 'ring-2 ring-accent scale-105'
              : 'opacity-60 hover:opacity-100'
          )}
        >
          <img src={img.thumbnailUrl} alt={img.filename} className="w-full h-full object-cover" />
        </button>
      ))}
    </div>
  )
}
