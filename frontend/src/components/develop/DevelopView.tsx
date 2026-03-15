import React, { useEffect } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { useEditStore } from '../../store/editStore'
import { ImageCanvas } from './ImageCanvas'
import { FilmStrip } from './FilmStrip'
import { EditPanel } from '../panels/EditPanel'

export function DevelopView() {
  const { activeImageId, images } = useLibraryStore(s => ({
    activeImageId: s.activeImageId,
    images: s.images,
  }))
  const loadImage = useEditStore(s => s.loadImage)

  useEffect(() => {
    if (!activeImageId) return
    const img = images.find(i => i.id === activeImageId)
    if (img) loadImage(img)
  }, [activeImageId])

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      {/* Main content: canvas + right panel */}
      <div className="flex flex-1 overflow-hidden">
        <ImageCanvas />
        <EditPanel />
      </div>

      {/* Film strip at bottom */}
      <FilmStrip />
    </div>
  )
}
