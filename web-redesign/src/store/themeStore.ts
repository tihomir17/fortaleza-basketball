import { create } from 'zustand'
import { persist } from 'zustand/middleware'

type Theme = 'light' | 'dark' | 'system'

interface ThemeState {
  theme: Theme
  setTheme: (theme: Theme) => void
  toggleTheme: () => void
  isDark: boolean
  updateTheme: () => void
  initialize: () => () => void
}

export const useThemeStore = create<ThemeState>()(
  persist(
    (set, get) => ({
      theme: 'system',
      isDark: false,

      setTheme: (theme: Theme) => {
        set({ theme })
        get().updateTheme()
      },

      toggleTheme: () => {
        const currentTheme = get().theme
        const newTheme = currentTheme === 'light' ? 'dark' : 'light'
        set({ theme: newTheme })
        get().updateTheme()
      },

      updateTheme: () => {
        const { theme } = get()
        const root = document.documentElement

        if (theme === 'system') {
          const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
          set({ isDark: systemPrefersDark })
          root.classList.toggle('dark', systemPrefersDark)
        } else {
          const isDark = theme === 'dark'
          set({ isDark })
          root.classList.toggle('dark', isDark)
        }
      },

      initialize: () => {
        get().updateTheme()
        
        // Listen for system theme changes
        const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
        const handleChange = () => {
          if (get().theme === 'system') {
            get().updateTheme()
          }
        }
        
        mediaQuery.addEventListener('change', handleChange)
        
        return () => {
          mediaQuery.removeEventListener('change', handleChange)
        }
      }
    }),
    {
      name: 'theme-storage',
      partialize: (state) => ({ theme: state.theme }),
    }
  )
)
