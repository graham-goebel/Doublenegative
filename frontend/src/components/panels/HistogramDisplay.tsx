import React, { useRef, useEffect } from 'react'

interface Props {
  previewUrl: string | null
}

export function HistogramDisplay({ previewUrl }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    if (!previewUrl || !canvasRef.current) return
    const canvas = canvasRef.current
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      // Draw image to offscreen canvas to read pixels
      const off = document.createElement('canvas')
      off.width = Math.min(img.width, 256)
      off.height = Math.min(img.height, 256)
      const offCtx = off.getContext('2d')!
      offCtx.drawImage(img, 0, 0, off.width, off.height)

      const data = offCtx.getImageData(0, 0, off.width, off.height).data
      const bins = 256
      const r = new Uint32Array(bins)
      const g = new Uint32Array(bins)
      const b = new Uint32Array(bins)

      for (let i = 0; i < data.length; i += 4) {
        r[data[i]]++
        g[data[i + 1]]++
        b[data[i + 2]]++
      }

      const max = Math.max(...Array.from(r), ...Array.from(g), ...Array.from(b)) || 1

      // Draw histogram
      const W = canvas.width
      const H = canvas.height
      ctx.clearRect(0, 0, W, H)
      ctx.fillStyle = '#111'
      ctx.fillRect(0, 0, W, H)

      const channels: [Uint32Array, string][] = [
        [r, 'rgba(255,80,80,0.5)'],
        [g, 'rgba(80,200,80,0.5)'],
        [b, 'rgba(80,120,255,0.5)'],
      ]

      for (const [ch, color] of channels) {
        ctx.beginPath()
        ctx.fillStyle = color
        ctx.moveTo(0, H)
        for (let i = 0; i < bins; i++) {
          const x = (i / bins) * W
          const y = H - (ch[i] / max) * H * 0.9
          ctx.lineTo(x, y)
        }
        ctx.lineTo(W, H)
        ctx.closePath()
        ctx.fill()
      }
    }
    img.src = previewUrl
  }, [previewUrl])

  return (
    <div className="px-3 py-2 border-b border-border">
      <canvas ref={canvasRef} width={240} height={60} className="w-full rounded" />
    </div>
  )
}
