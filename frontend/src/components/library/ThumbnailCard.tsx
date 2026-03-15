import React from 'react'
import { clsx } from 'clsx'
import type { ImageMeta } from '../../types'

interface Props {
  image: ImageMeta
  isSelected: boolean
  onClick: (e: React.MouseEvent) => void
  onDoubleClick: () => void
}

export function ThumbnailCard({ image, isSelected, onClick, onDoubleClick }: Props) {
  return (
    <div
      onClick={onClick}
      onDoubleClick={onDoubleClick}
      className={clsx(
        'relative cursor-pointer rounded overflow-hidden transition-all',
        'aspect-square bg-surface',
        isSelected ? 'ring-2 ring-accent' : 'hover:ring-1 hover:ring-gray-500'
      )}
    >
      <img
        src={image.thumbnailUrl}
        alt={image.filename}
        className="w-full h-full object-cover"
        loading="lazy"
      />
      {/* Edited badge */}
      {image.isEdited && (
        <div className="absolute top-1 right-1 w-2 h-2 rounded-full bg-accent" title="Edited" />
      )}
      {/* Filename tooltip on hover */}
      <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent p-1 opacity-0 hover:opacity-100 transition-opacity">
        <p className="text-xs text-white truncate">{image.filename}</p>
      </div>
    </div>
  )
}
