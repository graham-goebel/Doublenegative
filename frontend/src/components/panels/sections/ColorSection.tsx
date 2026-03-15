import React from 'react'
import { Slider } from '../shared/Slider'
import { useEditStore } from '../../../store/editStore'

export function ColorSection() {
  const { params, setParam } = useEditStore(s => ({ params: s.params, setParam: s.setParam }))

  return (
    <div>
      <Slider label="Temp" value={params.temperature} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('temperature', v)} />
      <Slider label="Tint" value={params.tint} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('tint', v)} />
      <Slider label="Saturation" value={params.saturation} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('saturation', v)} />
      <Slider label="Vibrance" value={params.vibrance} min={-100} max={100} defaultValue={0}
        onChange={v => setParam('vibrance', v)} />
    </div>
  )
}
