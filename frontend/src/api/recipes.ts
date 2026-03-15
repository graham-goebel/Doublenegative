import client from './client'
import type { Recipe, EditParams } from '../types'

export const recipesApi = {
  list: async (): Promise<Recipe[]> => {
    const res = await client.get<Recipe[]>('/recipes')
    return res.data
  },

  create: async (name: string, params: EditParams, description?: string): Promise<Recipe> => {
    const res = await client.post<Recipe>('/recipes', { name, params, description })
    return res.data
  },

  update: async (id: string, updates: { name?: string; description?: string; params?: EditParams }): Promise<Recipe> => {
    const res = await client.put<Recipe>(`/recipes/${id}`, updates)
    return res.data
  },

  delete: async (id: string): Promise<void> => {
    await client.delete(`/recipes/${id}`)
  },

  apply: async (id: string, imageIds: string[]): Promise<{ applied: string[]; failed: string[] }> => {
    const res = await client.post(`/recipes/${id}/apply`, { image_ids: imageIds })
    return res.data
  },

  fromImage: async (imageId: string): Promise<Recipe> => {
    const res = await client.post<Recipe>(`/recipes/from-image/${imageId}`)
    return res.data
  },
}
