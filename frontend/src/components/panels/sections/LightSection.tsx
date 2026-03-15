import React from 'react'
import { Slider } from '../shared/Slider'
import { useEditStore } from '../../../store/editStore'

export function LightSection() {
  const { params, setParam } = useEditStore(s => ({ params: s.params, setParam: s.setParam }))

  return (
    <div>
      <Slider label="Exposure" value={params.exposure} min={-5} max={5} step={0.05} defaultValue={0}
        onChange={v => setParam('exposure', v)} formatValue={v => (v >= 0 ? `+${v.toFixed(2)}` : v.toFixed(2))} />
      <Slider label="Contrast" value={params.contrast} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('contrast', v)} />
      <Slider label="Highlights" value={params.highlights} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('highlights', v)} />
      <Slider label="Shadows" value={params.shadows} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('shadows', v)} />
      <Slider label="Whites" value={params.whites} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('whites', v)} />
      <Slider label="Blacks" value={params.blacks} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('blacks', v)} />
    </div>
  )
}
