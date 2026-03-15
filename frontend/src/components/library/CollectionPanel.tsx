import React, { useEffect, useState } from 'react'
import { clsx } from 'clsx'
import { useLibraryStore } from '../../store/libraryStore'
import { useCollectionStore } from '../../store/collectionStore'

export function CollectionPanel() {
  const { activeCollectionId, setCollection } = useLibraryStore(s => ({
    activeCollectionId: s.activeCollectionId,
    setCollection: s.setCollection,
  }))
  const { collections, fetch, create, delete: deleteCol, rename } = useCollectionStore()

  const [isCreating, setIsCreating] = useState(false)
  const [newName, setNewName] = useState('')
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editName, setEditName] = useState('')

  useEffect(() => {
    fetch()
  }, [])

  const handleCreate = async () => {
    if (!newName.trim()) return
    await create(newName.trim())
    setNewName('')
    setIsCreating(false)
  }

  const handleRename = async (id: string) => {
    if (!editName.trim()) return
    await rename(id, editName.trim())
    setEditingId(null)
  }

  return (
    <div className="w-52 shrink-0 bg-panel border-r border-border flex flex-col h-full">
      <div className="p-3 border-b border-border">
        <p className="text-xs text-gray-500 uppercase font-semibold tracking-wider">Library</p>
      </div>

      <div className="flex-1 overflow-y-auto">
        {/* All Photos */}
        <button
          onClick={() => setCollection(null)}
          className={clsx(
            'w-full text-left px-3 py-2 text-sm flex items-center gap-2 transition-colors',
            activeCollectionId === null ? 'bg-accent/20 text-accent' : 'text-gray-300 hover:bg-surface'
          )}
        >
          <span className="text-lg">🖼</span>
          <span>All Photos</span>
        </button>

        {/* Collections header */}
        <div className="px-3 py-2 flex items-center justify-between">
          <span className="text-xs text-gray-500 uppercase font-semibold tracking-wider">Collections</span>
          <button
            onClick={() => setIsCreating(true)}
            className="text-gray-500 hover:text-accent text-lg leading-none"
            title="New collection"
          >
            +
          </button>
        </div>

        {/* New collection input */}
        {isCreating && (
          <div className="px-3 pb-2">
            <input
              autoFocus
              value={newName}
              onChange={e => setNewName(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter') handleCreate(); if (e.key === 'Escape') setIsCreating(false) }}
              placeholder="Collection name"
              className="w-full bg-surface border border-border rounded px-2 py-1 text-xs text-white outline-none focus:border-accent"
            />
          </div>
        )}

        {/* Collections list */}
        {collections.map(col => (
          <div key={col.id} className="group relative">
            {editingId === col.id ? (
              <div className="px-3 py-1">
                <input
                  autoFocus
                  value={editName}
                  onChange={e => setEditName(e.target.value)}
                  onKeyDown={e => { if (e.key === 'Enter') handleRename(col.id); if (e.key === 'Escape') setEditingId(null) }}
                  className="w-full bg-surface border border-border rounded px-2 py-1 text-xs text-white outline-none focus:border-accent"
                />
              </div>
            ) : (
              <button
                onClick={() => setCollection(col.id)}
                onDoubleClick={() => { setEditingId(col.id); setEditName(col.name) }}
                className={clsx(
                  'w-full text-left px-3 py-2 text-sm flex items-center gap-2 transition-colors',
                  activeCollectionId === col.id ? 'bg-accent/20 text-accent' : 'text-gray-300 hover:bg-surface'
                )}
              >
                <span className="text-base">📁</span>
                <span className="flex-1 truncate">{col.name}</span>
                <span className="text-xs text-gray-600">{col.imageCount}</span>
              </button>
            )}
            <button
              onClick={() => deleteCol(col.id)}
              className="absolute right-2 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 text-gray-600 hover:text-red-400 text-xs transition-opacity"
              title="Delete collection"
            >
              ✕
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}
