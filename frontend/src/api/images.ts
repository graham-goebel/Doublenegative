import client from './client'
import type { ImageMeta, EditParams } from '../types'

export const imagesApi = {
  import: async (files: FileList | File[]): Promise<ImageMeta[]> => {
    const form = new FormData()
    Array.from(files).forEach(f => form.append('files', f))
    const res = await client.post<ImageMeta[]>('/images/import', form, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    return res.data
  },

  list: async (params?: { collection_id?: string; sort?: string; order?: string }): Promise<ImageMeta[]> => {
    const res = await client.get<ImageMeta[]>('/images', { params })
    return res.data
  },

  get: async (id: string): Promise<ImageMeta> => {
    const res = await client.get<ImageMeta>(`/images/${id}`)
    return res.data
  },

  saveEdits: async (id: string, editParams: EditParams): Promise<ImageMeta> => {
    const res = await client.put<ImageMeta>(`/images/${id}/edits`, editParams)
    return res.data
  },

  resetEdits: async (id: string): Promise<ImageMeta> => {
    const res = await client.post<ImageMeta>(`/images/${id}/reset`)
    return res.data
  },

  delete: async (id: string): Promise<void> => {
    await client.delete(`/images/${id}`)
  },
}
