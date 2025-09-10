import { useState } from 'react'
import { 
  ArrowDownTrayIcon, 
  DocumentArrowDownIcon,
  TableCellsIcon,
  DocumentTextIcon
} from '@heroicons/react/24/outline'
import { exportData, exportGames, exportPlayers, exportTeams, exportAnalytics, type ExportableData } from '../../utils/exportUtils'
import { notify } from '../../store/notificationsStore'

interface ExportButtonProps {
  data: ExportableData[]
  dataType: 'games' | 'players' | 'teams' | 'analytics' | 'custom'
  title?: string
  filename?: string
  className?: string
  size?: 'sm' | 'md' | 'lg'
  variant?: 'primary' | 'secondary' | 'outline'
}

export function ExportButton({
  data,
  dataType,
  title,
  filename,
  className = '',
  size = 'md',
  variant = 'outline'
}: ExportButtonProps) {
  const [isExporting, setIsExporting] = useState(false)
  const [showDropdown, setShowDropdown] = useState(false)

  const handleExport = async (format: 'pdf' | 'excel' | 'csv') => {
    if (data.length === 0) {
      notify.warning('No Data', 'There is no data to export')
      return
    }

    setIsExporting(true)
    setShowDropdown(false)

    try {
      const exportOptions = {
        title: title || `${dataType.charAt(0).toUpperCase() + dataType.slice(1)} Export`,
        filename: filename || `${dataType}_export_${Date.now()}.${format === 'excel' ? 'xlsx' : format}`,
        includeTimestamp: true
      }

      switch (dataType) {
        case 'games':
          exportGames(data, format)
          break
        case 'players':
          exportPlayers(data, format)
          break
        case 'teams':
          exportTeams(data, format)
          break
        case 'analytics':
          exportAnalytics(data, format)
          break
        case 'custom':
        default:
          exportData(data, format, exportOptions)
          break
      }

      notify.success(
        'Export Successful', 
        `Data exported to ${format.toUpperCase()} format successfully`
      )
    } catch (error) {
      console.error('Export error:', error)
      notify.error(
        'Export Failed', 
        `Failed to export data to ${format.toUpperCase()} format`
      )
    } finally {
      setIsExporting(false)
    }
  }

  const getSizeClasses = () => {
    switch (size) {
      case 'sm':
        return 'px-3 py-1.5 text-sm'
      case 'lg':
        return 'px-6 py-3 text-lg'
      default:
        return 'px-4 py-2 text-base'
    }
  }

  const getVariantClasses = () => {
    switch (variant) {
      case 'primary':
        return 'bg-fortaleza-blue text-white hover:bg-blue-700 border-fortaleza-blue'
      case 'secondary':
        return 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-200 dark:hover:bg-gray-600 border-gray-300 dark:border-gray-600'
      default:
        return 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 border-gray-300 dark:border-gray-600'
    }
  }

  const getIconSize = () => {
    switch (size) {
      case 'sm':
        return 'w-4 h-4'
      case 'lg':
        return 'w-6 h-6'
      default:
        return 'w-5 h-5'
    }
  }

  return (
    <div className={`relative ${className}`}>
      <button
        onClick={() => setShowDropdown(!showDropdown)}
        disabled={isExporting || data.length === 0}
        className={`
          ${getSizeClasses()}
          ${getVariantClasses()}
          border rounded-lg font-medium transition-all duration-200
          flex items-center space-x-2
          ${isExporting ? 'opacity-50 cursor-not-allowed' : 'hover:shadow-md'}
          ${data.length === 0 ? 'opacity-50 cursor-not-allowed' : ''}
        `}
      >
        {isExporting ? (
          <>
            <div className={`${getIconSize()} animate-spin`}>
              <svg className="w-full h-full" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            </div>
            <span>Exporting...</span>
          </>
        ) : (
          <>
            <ArrowDownTrayIcon className={getIconSize()} />
            <span>Export</span>
          </>
        )}
      </button>

      {/* Dropdown Menu */}
      {showDropdown && !isExporting && data.length > 0 && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 z-10"
            onClick={() => setShowDropdown(false)}
          />
          
          {/* Dropdown */}
          <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-20">
            <div className="py-1">
              <button
                onClick={() => handleExport('excel')}
                className="flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <TableCellsIcon className="w-4 h-4 mr-3 text-green-600" />
                Export to Excel
              </button>
              
              <button
                onClick={() => handleExport('csv')}
                className="flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <DocumentTextIcon className="w-4 h-4 mr-3 text-blue-600" />
                Export to CSV
              </button>
              
              <button
                onClick={() => handleExport('pdf')}
                className="flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <DocumentArrowDownIcon className="w-4 h-4 mr-3 text-red-600" />
                Export to PDF
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  )
}

// Quick export buttons for specific formats
export function QuickExportButtons({
  data,
  dataType,
  title,
  filename,
  className = ''
}: Omit<ExportButtonProps, 'size' | 'variant'>) {
  const [isExporting, setIsExporting] = useState<string | null>(null)

  const handleQuickExport = async (format: 'pdf' | 'excel' | 'csv') => {
    if (data.length === 0) {
      notify.warning('No Data', 'There is no data to export')
      return
    }

    setIsExporting(format)

    try {
      const exportOptions = {
        title: title || `${dataType.charAt(0).toUpperCase() + dataType.slice(1)} Export`,
        filename: filename || `${dataType}_export_${Date.now()}.${format === 'excel' ? 'xlsx' : format}`,
        includeTimestamp: true
      }

      switch (dataType) {
        case 'games':
          exportGames(data, format)
          break
        case 'players':
          exportPlayers(data, format)
          break
        case 'teams':
          exportTeams(data, format)
          break
        case 'analytics':
          exportAnalytics(data, format)
          break
        case 'custom':
        default:
          exportData(data, format, exportOptions)
          break
      }

      notify.success(
        'Export Successful', 
        `Data exported to ${format.toUpperCase()} format successfully`
      )
    } catch (error) {
      console.error('Export error:', error)
      notify.error(
        'Export Failed', 
        `Failed to export data to ${format.toUpperCase()} format`
      )
    } finally {
      setIsExporting(null)
    }
  }

  return (
    <div className={`flex space-x-2 ${className}`}>
      <button
        onClick={() => handleQuickExport('excel')}
        disabled={isExporting !== null || data.length === 0}
        className="flex items-center px-3 py-2 text-sm bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 border border-green-200 dark:border-green-800 rounded-lg hover:bg-green-100 dark:hover:bg-green-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        title="Export to Excel"
      >
        {isExporting === 'excel' ? (
          <div className="w-4 h-4 animate-spin mr-2">
            <svg className="w-full h-full" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
        ) : (
          <TableCellsIcon className="w-4 h-4 mr-2" />
        )}
        Excel
      </button>

      <button
        onClick={() => handleQuickExport('csv')}
        disabled={isExporting !== null || data.length === 0}
        className="flex items-center px-3 py-2 text-sm bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400 border border-blue-200 dark:border-blue-800 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        title="Export to CSV"
      >
        {isExporting === 'csv' ? (
          <div className="w-4 h-4 animate-spin mr-2">
            <svg className="w-full h-full" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
        ) : (
          <DocumentTextIcon className="w-4 h-4 mr-2" />
        )}
        CSV
      </button>

      <button
        onClick={() => handleQuickExport('pdf')}
        disabled={isExporting !== null || data.length === 0}
        className="flex items-center px-3 py-2 text-sm bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 border border-red-200 dark:border-red-800 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        title="Export to PDF"
      >
        {isExporting === 'pdf' ? (
          <div className="w-4 h-4 animate-spin mr-2">
            <svg className="w-full h-full" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
        ) : (
          <DocumentArrowDownIcon className="w-4 h-4 mr-2" />
        )}
        PDF
      </button>
    </div>
  )
}
