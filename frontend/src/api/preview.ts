import client from './client'
import type { EditParams } from '../types'

export const previewApi = {
  render: async (imageId: string, params: EditParams): Promise<Blob> => {
    const res = await client.post(`/preview/${imageId}`, params, {
      responseType: 'blob',
      timeout: 120000,
    })
    return res.data
  },

  base: async (imageId: string): Promise<Blob> => {
    const res = await client.get(`/preview/${imageId}/base`, {
      responseType: 'blob',
      timeout: 120000,
    })
    return res.data
  },

  export: async (imageId: string, params: EditParams): Promise<Blob> => {
    const res = await client.post(`/preview/${imageId}/export`, params, {
      responseType: 'blob',
      timeout: 300000,
    })
    return res.data
  },
}
