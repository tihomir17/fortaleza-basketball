import { useState } from 'react'
import { CheckIcon } from '@heroicons/react/24/outline'
import { Button } from './Button'
import { Modal } from './Modal'
import { cn } from '../../utils/cn'

// interface ThemeColor {
//   name: string
//   value: string
//   description: string
// }

interface ThemeOption {
  id: string
  name: string
  description: string
  colors: {
    primary: string
    secondary: string
    accent: string
    background: string
    surface: string
    text: string
  }
}

const predefinedThemes: ThemeOption[] = [
  {
    id: 'fortaleza',
    name: 'Fortaleza',
    description: 'Official team colors',
    colors: {
      primary: '#1e3a8a',
      secondary: '#f59e0b',
      accent: '#10b981',
      background: '#ffffff',
      surface: '#f8fafc',
      text: '#1f2937'
    }
  },
  {
    id: 'dark',
    name: 'Dark Mode',
    description: 'Dark theme for low light',
    colors: {
      primary: '#3b82f6',
      secondary: '#f59e0b',
      accent: '#10b981',
      background: '#111827',
      surface: '#1f2937',
      text: '#f9fafb'
    }
  },
  {
    id: 'lakers',
    name: 'Lakers',
    description: 'Purple and gold theme',
    colors: {
      primary: '#552583',
      secondary: '#fdb927',
      accent: '#ff6b6b',
      background: '#ffffff',
      surface: '#f8fafc',
      text: '#1f2937'
    }
  },
  {
    id: 'celtics',
    name: 'Celtics',
    description: 'Green and white theme',
    colors: {
      primary: '#007a33',
      secondary: '#ffffff',
      accent: '#ffd700',
      background: '#ffffff',
      surface: '#f0f9ff',
      text: '#1f2937'
    }
  },
  {
    id: 'warriors',
    name: 'Warriors',
    description: 'Blue and gold theme',
    colors: {
      primary: '#1d428a',
      secondary: '#ffc72c',
      accent: '#ff6b6b',
      background: '#ffffff',
      surface: '#f8fafc',
      text: '#1f2937'
    }
  }
]

interface ThemeCustomizerProps {
  isOpen: boolean
  onClose: () => void
  currentTheme?: string
  onThemeChange: (theme: ThemeOption) => void
}

export function ThemeCustomizer({ isOpen, onClose, currentTheme = 'fortaleza', onThemeChange }: ThemeCustomizerProps) {
  const [selectedTheme, setSelectedTheme] = useState(currentTheme)
  const [customColors, setCustomColors] = useState({
    primary: '#1e3a8a',
    secondary: '#f59e0b',
    accent: '#10b981'
  })

  const handleThemeSelect = (theme: ThemeOption) => {
    setSelectedTheme(theme.id)
    onThemeChange(theme)
  }

  const handleCustomColorChange = (colorType: keyof typeof customColors, value: string) => {
    setCustomColors(prev => ({ ...prev, [colorType]: value }))
  }

  const applyCustomTheme = () => {
    const customTheme: ThemeOption = {
      id: 'custom',
      name: 'Custom',
      description: 'Your custom theme',
      colors: {
        primary: customColors.primary,
        secondary: customColors.secondary,
        accent: customColors.accent,
        background: '#ffffff',
        surface: '#f8fafc',
        text: '#1f2937'
      }
    }
    onThemeChange(customTheme)
  }

  const resolveTheme = (id: string): ThemeOption => {
    if (id === 'custom') {
      return {
        id: 'custom',
        name: 'Custom',
        description: 'Your custom theme',
        colors: {
          primary: customColors.primary,
          secondary: customColors.secondary,
          accent: customColors.accent,
          background: '#ffffff',
          surface: '#f8fafc',
          text: '#1f2937'
        }
      }
    }
    return predefinedThemes.find(t => t.id === id) || predefinedThemes[0]
  }

  const handleApplyClick = () => {
    const themeToApply = resolveTheme(selectedTheme)
    onThemeChange(themeToApply)
    onClose()
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Customize Theme" size="lg">
      <div className="space-y-6">
        {/* Predefined Themes */}
        <div>
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Predefined Themes
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {predefinedThemes.map((theme) => (
              <div
                key={theme.id}
                className={cn(
                  'relative p-4 border-2 rounded-lg cursor-pointer transition-all',
                  selectedTheme === theme.id
                    ? 'border-fortaleza-blue bg-blue-50 dark:bg-blue-900/20'
                    : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                )}
                onClick={() => handleThemeSelect(theme)}
              >
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-medium text-gray-900 dark:text-white">{theme.name}</h4>
                  {selectedTheme === theme.id && (
                    <CheckIcon className="w-5 h-5 text-fortaleza-blue" />
                  )}
                </div>
                <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                  {theme.description}
                </p>
                <div className="flex space-x-2">
                  <div
                    className="w-6 h-6 rounded-full border border-gray-300"
                    style={{ backgroundColor: theme.colors.primary }}
                  />
                  <div
                    className="w-6 h-6 rounded-full border border-gray-300"
                    style={{ backgroundColor: theme.colors.secondary }}
                  />
                  <div
                    className="w-6 h-6 rounded-full border border-gray-300"
                    style={{ backgroundColor: theme.colors.accent }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Custom Theme */}
        <div>
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Custom Theme
          </h3>
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Primary Color
                </label>
                <div className="flex items-center space-x-3">
                  <input
                    type="color"
                    value={customColors.primary}
                    onChange={(e) => handleCustomColorChange('primary', e.target.value)}
                    className="w-12 h-10 border border-gray-300 dark:border-gray-600 rounded cursor-pointer"
                  />
                  <input
                    type="text"
                    value={customColors.primary}
                    onChange={(e) => handleCustomColorChange('primary', e.target.value)}
                    className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm font-mono"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Secondary Color
                </label>
                <div className="flex items-center space-x-3">
                  <input
                    type="color"
                    value={customColors.secondary}
                    onChange={(e) => handleCustomColorChange('secondary', e.target.value)}
                    className="w-12 h-10 border border-gray-300 dark:border-gray-600 rounded cursor-pointer"
                  />
                  <input
                    type="text"
                    value={customColors.secondary}
                    onChange={(e) => handleCustomColorChange('secondary', e.target.value)}
                    className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm font-mono"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Accent Color
                </label>
                <div className="flex items-center space-x-3">
                  <input
                    type="color"
                    value={customColors.accent}
                    onChange={(e) => handleCustomColorChange('accent', e.target.value)}
                    className="w-12 h-10 border border-gray-300 dark:border-gray-600 rounded cursor-pointer"
                  />
                  <input
                    type="text"
                    value={customColors.accent}
                    onChange={(e) => handleCustomColorChange('accent', e.target.value)}
                    className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm font-mono"
                  />
                </div>
              </div>
            </div>

            <div className="flex justify-end">
              <Button onClick={applyCustomTheme}>
                Apply Custom Theme
              </Button>
            </div>
          </div>
        </div>

        {/* Theme Preview */}
        <div>
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Preview
          </h3>
          <div className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
            <div className="space-y-3">
              <div className="flex items-center space-x-3">
                <div
                  className="w-4 h-4 rounded"
                  style={{ backgroundColor: selectedTheme === 'custom' ? customColors.primary : predefinedThemes.find(t => t.id === selectedTheme)?.colors.primary }}
                />
                <span className="text-sm text-gray-600 dark:text-gray-400">Primary Color</span>
              </div>
              <div className="flex items-center space-x-3">
                <div
                  className="w-4 h-4 rounded"
                  style={{ backgroundColor: selectedTheme === 'custom' ? customColors.secondary : predefinedThemes.find(t => t.id === selectedTheme)?.colors.secondary }}
                />
                <span className="text-sm text-gray-600 dark:text-gray-400">Secondary Color</span>
              </div>
              <div className="flex items-center space-x-3">
                <div
                  className="w-4 h-4 rounded"
                  style={{ backgroundColor: selectedTheme === 'custom' ? customColors.accent : predefinedThemes.find(t => t.id === selectedTheme)?.colors.accent }}
                />
                <span className="text-sm text-gray-600 dark:text-gray-400">Accent Color</span>
              </div>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex justify-end space-x-3">
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleApplyClick}>
            Apply Theme
          </Button>
        </div>
      </div>
    </Modal>
  )
}

// Theme preview component
interface ThemePreviewProps {
  theme: ThemeOption
  className?: string
}

export function ThemePreview({ theme, className }: ThemePreviewProps) {
  return (
    <div className={cn('p-4 border border-gray-200 dark:border-gray-700 rounded-lg', className)}>
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h4 className="font-medium text-gray-900 dark:text-white">{theme.name}</h4>
          <div className="flex space-x-1">
            <div
              className="w-3 h-3 rounded-full"
              style={{ backgroundColor: theme.colors.primary }}
            />
            <div
              className="w-3 h-3 rounded-full"
              style={{ backgroundColor: theme.colors.secondary }}
            />
            <div
              className="w-3 h-3 rounded-full"
              style={{ backgroundColor: theme.colors.accent }}
            />
          </div>
        </div>
        <p className="text-sm text-gray-600 dark:text-gray-400">{theme.description}</p>
      </div>
    </div>
  )
}
