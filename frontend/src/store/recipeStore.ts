import { create } from 'zustand'
import type { Recipe, EditParams } from '../types'
import { recipesApi } from '../api/recipes'

interface RecipeState {
  recipes: Recipe[]
  isLoading: boolean

  fetch: () => Promise<void>
  create: (name: string, params: EditParams, description?: string) => Promise<Recipe>
  delete: (id: string) => Promise<void>
  apply: (id: string, imageIds: string[]) => Promise<{ applied: string[]; failed: string[] }>
  fromImage: (imageId: string) => Promise<Recipe>
}

export const useRecipeStore = create<RecipeState>((set) => ({
  recipes: [],
  isLoading: false,

  fetch: async () => {
    set({ isLoading: true })
    const recipes = await recipesApi.list()
    set({ recipes, isLoading: false })
  },

  create: async (name, params, description) => {
    const r = await recipesApi.create(name, params, description)
    set(state => ({ recipes: [...state.recipes, r] }))
    return r
  },

  delete: async (id) => {
    await recipesApi.delete(id)
    set(state => ({ recipes: state.recipes.filter(r => r.id !== id) }))
  },

  apply: async (id, imageIds) => {
    return await recipesApi.apply(id, imageIds)
  },

  fromImage: async (imageId) => {
    const r = await recipesApi.fromImage(imageId)
    set(state => ({ recipes: [...state.recipes, r] }))
    return r
  },
}))
