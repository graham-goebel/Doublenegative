import client from './client'
import type { Collection } from '../types'

export const collectionsApi = {
  list: async (): Promise<Collection[]> => {
    const res = await client.get<Collection[]>('/collections')
    return res.data
  },

  create: async (name: string): Promise<Collection> => {
    const res = await client.post<Collection>('/collections', { name })
    return res.data
  },

  rename: async (id: string, name: string): Promise<Collection> => {
    const res = await client.put<Collection>(`/collections/${id}`, { name })
    return res.data
  },

  delete: async (id: string): Promise<void> => {
    await client.delete(`/collections/${id}`)
  },

  addImages: async (id: string, imageIds: string[]): Promise<void> => {
    await client.post(`/collections/${id}/images`, { image_ids: imageIds })
  },

  removeImage: async (id: string, imageId: string): Promise<void> => {
    await client.delete(`/collections/${id}/images/${imageId}`)
  },
}
