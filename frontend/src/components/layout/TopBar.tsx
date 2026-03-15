import React, { useRef } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { useEditStore } from '../../store/editStore'
import { clsx } from 'clsx'

export function TopBar() {
  const { viewMode, setViewMode, importFiles, activeImageId, isSavingGlobal } = useLibraryStore(s => ({
    viewMode: s.viewMode,
    setViewMode: s.setViewMode,
    importFiles: s.importFiles,
    activeImageId: s.activeImageId,
    isSavingGlobal: s.isLoading,
  }))
  const { saveEdits, isSaving, isDirty } = useEditStore(s => ({
    saveEdits: s.saveEdits,
    isSaving: s.isSaving,
    isDirty: s.isDirty,
  }))

  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files?.length) {
      importFiles(e.target.files)
      e.target.value = ''
    }
  }

  return (
    <div className="flex items-center justify-between px-4 py-2 bg-[#111] border-b border-border shrink-0 h-12">
      {/* Logo */}
      <div className="text-white font-semibold text-sm tracking-widest uppercase opacity-80">
        Doublenegative
      </div>

      {/* Mode tabs */}
      <div className="flex gap-1 bg-surface rounded px-1 py-1">
        {(['library', 'develop'] as const).map(mode => (
          <button
            key={mode}
            onClick={() => setViewMode(mode)}
            disabled={mode === 'develop' && !activeImageId}
            className={clsx(
              'px-4 py-1 text-xs rounded font-medium capitalize transition-colors',
              viewMode === mode
                ? 'bg-accent text-black'
                : 'text-gray-400 hover:text-white disabled:opacity-30 disabled:cursor-not-allowed'
            )}
          >
            {mode}
          </button>
        ))}
      </div>

      {/* Right actions */}
      <div className="flex items-center gap-2">
        {viewMode === 'develop' && isDirty() && (
          <button
            onClick={saveEdits}
            disabled={isSaving}
            className="px-3 py-1 text-xs bg-accent text-black rounded font-medium hover:bg-yellow-400 disabled:opacity-50"
          >
            {isSaving ? 'Saving…' : 'Save'}
          </button>
        )}
        <button
          onClick={() => fileInputRef.current?.click()}
          className="px-3 py-1 text-xs bg-surface border border-border text-gray-300 rounded hover:border-gray-400 transition-colors"
        >
          Import
        </button>
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept=".jpg,.jpeg,.tif,.tiff,.png,.cr2,.nef,.arw,.dng,.raf,.orf,.rw2,.pef"
          className="hidden"
          onChange={handleFileChange}
        />
      </div>
    </div>
  )
}
