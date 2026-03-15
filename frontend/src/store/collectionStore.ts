import { create } from 'zustand'
import type { Collection } from '../types'
import { collectionsApi } from '../api/collections'

interface CollectionState {
  collections: Collection[]
  isLoading: boolean

  fetch: () => Promise<void>
  create: (name: string) => Promise<void>
  rename: (id: string, name: string) => Promise<void>
  delete: (id: string) => Promise<void>
  addImages: (id: string, imageIds: string[]) => Promise<void>
  removeImage: (collectionId: string, imageId: string) => Promise<void>
}

export const useCollectionStore = create<CollectionState>((set, get) => ({
  collections: [],
  isLoading: false,

  fetch: async () => {
    set({ isLoading: true })
    const collections = await collectionsApi.list()
    set({ collections, isLoading: false })
  },

  create: async (name) => {
    const c = await collectionsApi.create(name)
    set(state => ({ collections: [...state.collections, c] }))
  },

  rename: async (id, name) => {
    const updated = await collectionsApi.rename(id, name)
    set(state => ({
      collections: state.collections.map(c => c.id === id ? updated : c),
    }))
  },

  delete: async (id) => {
    await collectionsApi.delete(id)
    set(state => ({ collections: state.collections.filter(c => c.id !== id) }))
  },

  addImages: async (id, imageIds) => {
    await collectionsApi.addImages(id, imageIds)
    await get().fetch()
  },

  removeImage: async (collectionId, imageId) => {
    await collectionsApi.removeImage(collectionId, imageId)
    await get().fetch()
  },
}))
