import { useEffect, useRef, useCallback } from 'react'
import { useEditStore } from '../store/editStore'
import { previewApi } from '../api/preview'
import type { EditParams } from '../types'

function debounce<T extends (...args: any[]) => any>(fn: T, ms: number) {
  let timer: ReturnType<typeof setTimeout>
  return (...args: Parameters<T>) => {
    clearTimeout(timer)
    timer = setTimeout(() => fn(...args), ms)
  }
}

export function usePreview(imageId: string | null) {
  const { params, setPreviewUrl, setPreviewLoading } = useEditStore()
  const abortRef = useRef<AbortController | null>(null)

  const fetchPreview = useCallback(
    debounce(async (id: string, p: EditParams) => {
      abortRef.current?.abort()
      abortRef.current = new AbortController()

      setPreviewLoading(true)
      try {
        const blob = await previewApi.render(id, p)
        const url = URL.createObjectURL(blob)
        setPreviewUrl(url)
      } catch (e: any) {
        if (e?.code !== 'ERR_CANCELED') {
          console.error('Preview fetch failed:', e)
        }
      } finally {
        setPreviewLoading(false)
      }
    }, 400),
    []
  )

  useEffect(() => {
    if (!imageId) return
    fetchPreview(imageId, params)
  }, [imageId, params])

  // Compute CSS filter for instant visual approximation while server renders
  const cssFilter = [
    `brightness(${1.0 + params.exposure * 0.15})`,
    `contrast(${1.0 + params.contrast / 150})`,
    `saturate(${Math.max(0, 1.0 + params.saturation / 100)})`,
  ].join(' ')

  return { cssFilter }
}
