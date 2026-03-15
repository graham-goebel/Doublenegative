import { create } from 'zustand'
import type { EditParams, ImageMeta } from '../types'
import { DEFAULT_EDIT_PARAMS } from '../types'
import { imagesApi } from '../api/images'
import { useLibraryStore } from './libraryStore'

const MAX_HISTORY = 50

interface EditState {
  params: EditParams
  savedParams: EditParams
  history: EditParams[]
  historyIndex: number
  previewUrl: string | null
  isPreviewLoading: boolean
  isSaving: boolean
  activeImageId: string | null

  loadImage: (img: ImageMeta) => void
  setParam: <K extends keyof EditParams>(key: K, value: number) => void
  setParams: (params: EditParams) => void
  resetAll: () => void
  saveEdits: () => Promise<void>
  undo: () => void
  redo: () => void
  canUndo: () => boolean
  canRedo: () => boolean
  setPreviewUrl: (url: string | null) => void
  setPreviewLoading: (loading: boolean) => void
  isDirty: () => boolean
}

export const useEditStore = create<EditState>((set, get) => ({
  params: { ...DEFAULT_EDIT_PARAMS },
  savedParams: { ...DEFAULT_EDIT_PARAMS },
  history: [{ ...DEFAULT_EDIT_PARAMS }],
  historyIndex: 0,
  previewUrl: null,
  isPreviewLoading: false,
  isSaving: false,
  activeImageId: null,

  loadImage: (img) => {
    const params = { ...DEFAULT_EDIT_PARAMS, ...img.editParams }
    set({
      params,
      savedParams: params,
      history: [params],
      historyIndex: 0,
      previewUrl: null,
      activeImageId: img.id,
    })
  },

  setParam: (key, value) => {
    set(state => {
      const next = { ...state.params, [key]: value }
      // Truncate forward history and append
      const history = state.history.slice(0, state.historyIndex + 1)
      if (history.length >= MAX_HISTORY) history.shift()
      return {
        params: next,
        history: [...history, next],
        historyIndex: Math.min(history.length, MAX_HISTORY - 1),
      }
    })
  },

  setParams: (params) => {
    set(state => {
      const history = state.history.slice(0, state.historyIndex + 1)
      if (history.length >= MAX_HISTORY) history.shift()
      return {
        params,
        history: [...history, params],
        historyIndex: Math.min(history.length, MAX_HISTORY - 1),
      }
    })
  },

  resetAll: () => {
    const params = { ...DEFAULT_EDIT_PARAMS }
    set(state => ({
      params,
      history: [...state.history.slice(0, state.historyIndex + 1), params],
      historyIndex: state.historyIndex + 1,
    }))
  },

  saveEdits: async () => {
    const { activeImageId, params } = get()
    if (!activeImageId) return
    set({ isSaving: true })
    try {
      const updated = await imagesApi.saveEdits(activeImageId, params)
      set({ savedParams: { ...params }, isSaving: false })
      useLibraryStore.getState().updateImage(updated)
    } catch {
      set({ isSaving: false })
    }
  },

  undo: () => {
    set(state => {
      if (state.historyIndex <= 0) return state
      const idx = state.historyIndex - 1
      return { historyIndex: idx, params: { ...state.history[idx] } }
    })
  },

  redo: () => {
    set(state => {
      if (state.historyIndex >= state.history.length - 1) return state
      const idx = state.historyIndex + 1
      return { historyIndex: idx, params: { ...state.history[idx] } }
    })
  },

  canUndo: () => get().historyIndex > 0,
  canRedo: () => get().historyIndex < get().history.length - 1,

  setPreviewUrl: (url) => {
    const old = get().previewUrl
    if (old && old.startsWith('blob:')) URL.revokeObjectURL(old)
    set({ previewUrl: url })
  },

  setPreviewLoading: (loading) => set({ isPreviewLoading: loading }),

  isDirty: () => {
    const { params, savedParams } = get()
    return JSON.stringify(params) !== JSON.stringify(savedParams)
  },
}))
