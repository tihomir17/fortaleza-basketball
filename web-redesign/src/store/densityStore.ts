import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export type Density = 'default' | 'comfortable' | 'cozy' | 'compact' | 'smaller'

interface DensityState {
  density: Density
  setDensity: (density: Density) => void
  applyDensity: (density?: Density) => void
  initialize: () => void
}

const densityToRootFontSize: Record<Density, string> = {
  // Tailwind spacing is rem-based, so adjusting root font-size scales the UI density globally
  default: '100%',
  comfortable: '106%',
  cozy: '96%',
  compact: '90%',
  smaller: '86%',
}

export const useDensityStore = create<DensityState>()(
  persist(
    (set, get) => ({
      density: 'default',

      setDensity: (density: Density) => {
        set({ density })
        get().applyDensity(density)
      },

      applyDensity: (densityParam?: Density) => {
        const density = densityParam ?? get().density
        const root = document.documentElement
        const size = densityToRootFontSize[density] ?? '100%'
        root.style.fontSize = size
        // Add a class for potential future fine-tuning in CSS
        root.classList.remove('density-default', 'density-comfortable', 'density-cozy', 'density-compact', 'density-smaller')
        root.classList.add(`density-${density}`)
      },

      initialize: () => {
        // Apply on load
        get().applyDensity()
      },
    }),
    {
      name: 'ui-density',
      partialize: (state) => ({ density: state.density }),
    }
  )
)


