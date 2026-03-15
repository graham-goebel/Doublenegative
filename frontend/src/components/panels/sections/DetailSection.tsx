import React from 'react'
import { Slider } from '../shared/Slider'
import { useEditStore } from '../../../store/editStore'

export function DetailSection() {
  const { params, setParam } = useEditStore(s => ({ params: s.params, setParam: s.setParam }))

  return (
    <div>
      <p className="text-xs text-gray-600 mb-2 font-medium">Sharpening</p>
      <Slider label="Amount" value={params.sharpening} min={0} max={150} defaultValue={0}
        onChange={v => setParam('sharpening', v)} formatValue={v => `${v}`} />
      <Slider label="Radius" value={params.sharpening_radius} min={0.5} max={3} step={0.1} defaultValue={1}
        onChange={v => setParam('sharpening_radius', v)} formatValue={v => v.toFixed(1)} />
      <Slider label="Detail" value={params.sharpening_detail} min={0} max={100} defaultValue={25}
        onChange={v => setParam('sharpening_detail', v)} formatValue={v => `${v}`} />

      <p className="text-xs text-gray-600 mb-2 mt-3 font-medium">Noise Reduction</p>
      <Slider label="Luminance" value={params.noise_reduction} min={0} max={100} defaultValue={0}
        onChange={v => setParam('noise_reduction', v)} formatValue={v => `${v}`} />
      <Slider label="Detail" value={params.noise_reduction_detail} min={0} max={100} defaultValue={50}
        onChange={v => setParam('noise_reduction_detail', v)} formatValue={v => `${v}`} />
      <Slider label="Color" value={params.noise_reduction_color} min={0} max={100} defaultValue={25}
        onChange={v => setParam('noise_reduction_color', v)} formatValue={v => `${v}`} />
    </div>
  )
}
