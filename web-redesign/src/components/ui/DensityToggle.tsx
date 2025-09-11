import { useEffect, useState } from 'react'
import { useDensityStore, type Density } from '../../store/densityStore'

const options: { label: string; value: Density }[] = [
  { label: 'Default', value: 'default' },
  { label: 'Comfortable', value: 'comfortable' },
  { label: 'Cozy', value: 'cozy' },
  { label: 'Compact', value: 'compact' },
  { label: 'Smaller', value: 'smaller' },
]

interface DensityToggleProps {
  compact?: boolean
}

export function DensityToggle({ compact = true }: DensityToggleProps) {
  const { density, setDensity, initialize } = useDensityStore()
  const [open, setOpen] = useState(false)

  useEffect(() => {
    initialize()
  }, [initialize])

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="px-3 py-2 text-sm rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700 transition"
        title={`Density: ${density}`}
      >
        {compact ? 'Density' : `Density: ${density}`}
      </button>
      {open && (
        <div
          className="absolute right-0 mt-2 w-44 rounded-lg shadow-lg bg-white dark:bg-gray-800 ring-1 ring-black ring-opacity-5 p-1 z-50"
          onMouseLeave={() => setOpen(false)}
        >
          {options.map(opt => (
            <button
              key={opt.value}
              onClick={() => {
                setDensity(opt.value)
                setOpen(false)
              }}
              className={`w-full text-left px-3 py-2 text-sm rounded-md transition hover:bg-gray-100 dark:hover:bg-gray-700 ${
                density === opt.value ? 'bg-gray-100 dark:bg-gray-700 font-medium' : ''
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}


