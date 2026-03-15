import { create } from 'zustand'
import type { ImageMeta } from '../types'
import { imagesApi } from '../api/images'

interface LibraryState {
  images: ImageMeta[]
  selectedIds: Set<string>
  activeImageId: string | null
  activeCollectionId: string | null
  viewMode: 'library' | 'develop'
  sortBy: 'date' | 'name' | 'size'
  isLoading: boolean
  error: string | null

  fetchImages: () => Promise<void>
  importFiles: (files: FileList | File[]) => Promise<void>
  selectImage: (id: string, multi?: boolean) => void
  clearSelection: () => void
  openInDevelop: (id: string) => void
  setViewMode: (mode: 'library' | 'develop') => void
  setCollection: (id: string | null) => void
  setSortBy: (sort: 'date' | 'name' | 'size') => void
  updateImage: (img: ImageMeta) => void
  removeImage: (id: string) => void
}

export const useLibraryStore = create<LibraryState>((set, get) => ({
  images: [],
  selectedIds: new Set(),
  activeImageId: null,
  activeCollectionId: null,
  viewMode: 'library',
  sortBy: 'date',
  isLoading: false,
  error: null,

  fetchImages: async () => {
    set({ isLoading: true, error: null })
    try {
      const { activeCollectionId, sortBy } = get()
      const images = await imagesApi.list({
        collection_id: activeCollectionId ?? undefined,
        sort: sortBy,
        order: 'desc',
      })
      set({ images, isLoading: false })
    } catch (e: any) {
      set({ isLoading: false, error: e.message })
    }
  },

  importFiles: async (files) => {
    set({ isLoading: true })
    try {
      const newImages = await imagesApi.import(files)
      set(state => ({
        images: [...newImages, ...state.images],
        isLoading: false,
      }))
    } catch (e: any) {
      set({ isLoading: false, error: e.message })
    }
  },

  selectImage: (id, multi = false) => {
    set(state => {
      if (multi) {
        const next = new Set(state.selectedIds)
        if (next.has(id)) next.delete(id)
        else next.add(id)
        return { selectedIds: next }
      }
      return { selectedIds: new Set([id]), activeImageId: id }
    })
  },

  clearSelection: () => set({ selectedIds: new Set() }),

  openInDevelop: (id) => set({ activeImageId: id, viewMode: 'develop' }),

  setViewMode: (mode) => set({ viewMode: mode }),

  setCollection: (id) => {
    set({ activeCollectionId: id })
    get().fetchImages()
  },

  setSortBy: (sort) => {
    set({ sortBy: sort })
    get().fetchImages()
  },

  updateImage: (img) => {
    set(state => ({
      images: state.images.map(i => i.id === img.id ? img : i),
    }))
  },

  removeImage: (id) => {
    set(state => ({
      images: state.images.filter(i => i.id !== id),
      selectedIds: new Set([...state.selectedIds].filter(sid => sid !== id)),
      activeImageId: state.activeImageId === id ? null : state.activeImageId,
    }))
  },
}))
