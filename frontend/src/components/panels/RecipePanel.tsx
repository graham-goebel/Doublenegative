import React, { useEffect, useState } from 'react'
import { useRecipeStore } from '../../store/recipeStore'
import { useEditStore } from '../../store/editStore'
import { useLibraryStore } from '../../store/libraryStore'
import { previewApi } from '../../api/preview'
import type { Recipe } from '../../types'

export function RecipePanel() {
  const { recipes, fetch, create, delete: deleteRecipe, apply, fromImage } = useRecipeStore()
  const { params, activeImageId, setParams, resetAll } = useEditStore(s => ({
    params: s.params,
    activeImageId: s.activeImageId,
    setParams: s.setParams,
    resetAll: s.resetAll,
  }))
  const { selectedIds, images } = useLibraryStore(s => ({ selectedIds: s.selectedIds, images: s.images }))

  const [saveName, setSaveName] = useState('')
  const [isSavingRecipe, setIsSavingRecipe] = useState(false)
  const [applyingId, setApplyingId] = useState<string | null>(null)
  const [applyStatus, setApplyStatus] = useState<string | null>(null)
  const [showSave, setShowSave] = useState(false)

  useEffect(() => { fetch() }, [])

  const handleSave = async () => {
    if (!saveName.trim()) return
    setIsSavingRecipe(true)
    await create(saveName.trim(), params)
    setSaveName('')
    setShowSave(false)
    setIsSavingRecipe(false)
  }

  const handleApplyToImage = (recipe: Recipe) => {
    setParams({ ...recipe.params })
  }

  const handleApplyToSelection = async (recipe: Recipe) => {
    const ids = Array.from(selectedIds)
    if (ids.length === 0) return
    setApplyingId(recipe.id)
    const result = await apply(recipe.id, ids)
    setApplyingId(null)
    setApplyStatus(`Applied to ${result.applied.length} image(s)`)
    setTimeout(() => setApplyStatus(null), 3000)
  }

  const handleExport = async () => {
    if (!activeImageId) return
    const blob = await previewApi.export(activeImageId, params)
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'export.jpg'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="border-t border-border">
      {/* Recipe Save */}
      <div className="px-3 py-2 border-b border-border">
        <div className="flex gap-2 items-center">
          <button
            onClick={() => setShowSave(!showSave)}
            className="text-xs text-gray-400 hover:text-accent transition-colors"
          >
            {showSave ? 'Cancel' : '+ Save as Recipe'}
          </button>
          <div className="flex-1" />
          <button
            onClick={resetAll}
            className="text-xs text-gray-600 hover:text-red-400 transition-colors"
          >
            Reset All
          </button>
        </div>

        {showSave && (
          <div className="mt-2 flex gap-2">
            <input
              autoFocus
              value={saveName}
              onChange={e => setSaveName(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter') handleSave() }}
              placeholder="Recipe name…"
              className="flex-1 bg-surface border border-border rounded px-2 py-1 text-xs text-white outline-none focus:border-accent"
            />
            <button
              onClick={handleSave}
              disabled={isSavingRecipe}
              className="text-xs bg-accent text-black px-2 py-1 rounded font-medium"
            >
              Save
            </button>
          </div>
        )}
      </div>

      {/* Recipes List */}
      {recipes.length > 0 && (
        <div className="max-h-48 overflow-y-auto">
          <p className="px-3 py-1 text-xs text-gray-600 uppercase font-semibold tracking-wider">Recipes</p>
          {recipes.map(recipe => (
            <div key={recipe.id} className="group flex items-center gap-1 px-3 py-1 hover:bg-surface">
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-300 truncate">{recipe.name}</p>
              </div>
              <button
                onClick={() => handleApplyToImage(recipe)}
                className="text-xs text-gray-600 hover:text-accent transition-colors shrink-0"
                title="Apply to current image"
              >
                Apply
              </button>
              {selectedIds.size > 1 && (
                <button
                  onClick={() => handleApplyToSelection(recipe)}
                  disabled={applyingId === recipe.id}
                  className="text-xs text-gray-600 hover:text-accent transition-colors shrink-0"
                  title={`Apply to ${selectedIds.size} selected images`}
                >
                  {applyingId === recipe.id ? '…' : `×${selectedIds.size}`}
                </button>
              )}
              <button
                onClick={() => deleteRecipe(recipe.id)}
                className="text-xs text-gray-700 hover:text-red-400 transition-colors opacity-0 group-hover:opacity-100 shrink-0"
              >
                ✕
              </button>
            </div>
          ))}
        </div>
      )}

      {applyStatus && (
        <p className="px-3 py-1 text-xs text-accent">{applyStatus}</p>
      )}

      {/* Export */}
      {activeImageId && (
        <div className="px-3 py-2 border-t border-border">
          <button
            onClick={handleExport}
            className="w-full text-xs bg-surface border border-border text-gray-300 rounded px-3 py-1.5 hover:border-gray-400 transition-colors"
          >
            Export JPEG
          </button>
        </div>
      )}
    </div>
  )
}
