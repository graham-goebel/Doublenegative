import React from 'react'

interface SliderProps {
  label: string
  value: number
  min: number
  max: number
  step?: number
  defaultValue?: number
  onChange: (value: number) => void
  formatValue?: (v: number) => string
}

export function Slider({
  label,
  value,
  min,
  max,
  step = 1,
  defaultValue = 0,
  onChange,
  formatValue,
}: SliderProps) {
  const display = formatValue ? formatValue(value) : (value >= 0 ? `+${value}` : `${value}`)
  const isDefault = value === defaultValue

  return (
    <div className="mb-3">
      <div className="flex justify-between items-center mb-1">
        <span className="text-xs text-gray-400 font-medium">{label}</span>
        <span
          className={`text-xs font-mono cursor-pointer ${isDefault ? 'text-gray-500' : 'text-accent'}`}
          onDoubleClick={() => onChange(defaultValue)}
          title="Double-click to reset"
        >
          {isDefault ? '0' : display}
        </span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={e => onChange(parseFloat(e.target.value))}
        className="w-full h-1 appearance-none bg-gray-600 rounded-full outline-none cursor-pointer
          [&::-webkit-slider-thumb]:appearance-none
          [&::-webkit-slider-thumb]:w-3
          [&::-webkit-slider-thumb]:h-3
          [&::-webkit-slider-thumb]:rounded-full
          [&::-webkit-slider-thumb]:bg-white
          [&::-webkit-slider-thumb]:cursor-pointer"
      />
    </div>
  )
}
