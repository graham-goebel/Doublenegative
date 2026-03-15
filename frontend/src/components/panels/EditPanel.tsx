import React, { useState } from 'react'
import { useEditStore } from '../../store/editStore'
import { HistogramDisplay } from './HistogramDisplay'
import { LightSection } from './sections/LightSection'
import { ColorSection } from './sections/ColorSection'
import { DetailSection } from './sections/DetailSection'
import { RecipePanel } from './RecipePanel'
import { useLibraryStore } from '../../store/libraryStore'
import { clsx } from 'clsx'

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  const [open, setOpen] = useState(true)
  return (
    <div className="border-b border-border">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between px-3 py-2 text-xs text-gray-400 uppercase font-semibold tracking-wider hover:text-white transition-colors"
      >
        <span>{title}</span>
        <span className={clsx('transition-transform', open ? 'rotate-0' : '-rotate-90')}>▾</span>
      </button>
      {open && <div className="px-3 pb-3">{children}</div>}
    </div>
  )
}

export function EditPanel() {
  const { previewUrl, activeImageId, undo, redo, canUndo, canRedo } = useEditStore(s => ({
    previewUrl: s.previewUrl,
    activeImageId: s.activeImageId,
    undo: s.undo,
    redo: s.redo,
    canUndo: s.canUndo,
    canRedo: s.canRedo,
  }))

  const activeImage = useLibraryStore(s => s.images.find(i => i.id === s.activeImageId))

  return (
    <div className="w-64 shrink-0 bg-panel border-l border-border flex flex-col h-full overflow-hidden">
      {/* Histogram */}
      <HistogramDisplay previewUrl={previewUrl} />

      {/* Image Info */}
      {activeImage && (
        <div className="px-3 py-2 border-b border-border text-xs text-gray-500 space-y-0.5">
          <p className="text-gray-400 font-medium truncate">{activeImage.filename}</p>
          {activeImage.cameraModel && <p>{activeImage.cameraMake} {activeImage.cameraModel}</p>}
          <p className="flex gap-3">
            {activeImage.iso && <span>ISO {activeImage.iso}</span>}
            {activeImage.aperture && <span>f/{activeImage.aperture}</span>}
            {activeImage.shutterSpeed && <span>{activeImage.shutterSpeed}</span>}
            {activeImage.focalLength && <span>{activeImage.focalLength}mm</span>}
          </p>
        </div>
      )}

      {/* Undo/Redo */}
      <div className="px-3 py-1.5 border-b border-border flex gap-3">
        <button
          onClick={undo}
          disabled={!canUndo()}
          className="text-xs text-gray-500 hover:text-white disabled:opacity-30 transition-colors"
        >
          ← Undo
        </button>
        <button
          onClick={redo}
          disabled={!canRedo()}
          className="text-xs text-gray-500 hover:text-white disabled:opacity-30 transition-colors"
        >
          Redo →
        </button>
      </div>

      {/* Edit sections (scrollable) */}
      <div className="flex-1 overflow-y-auto">
        <Section title="Light">
          <LightSection />
        </Section>
        <Section title="Color">
          <ColorSection />
        </Section>
        <Section title="Detail">
          <DetailSection />
        </Section>
      </div>

      {/* Recipe panel (fixed at bottom) */}
      <RecipePanel />
    </div>
  )
}
