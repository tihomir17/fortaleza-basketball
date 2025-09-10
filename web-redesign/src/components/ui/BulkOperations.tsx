import { useState, useEffect } from 'react'
import { TrashIcon, PencilIcon, XMarkIcon } from '@heroicons/react/24/outline'
import { Button } from './Button'
import { cn } from '../../utils/cn'

interface BulkOperationsProps {
  selectedItems: string[]
  totalItems: number
  onSelectAll: () => void
  onClearSelection: () => void
  onBulkDelete?: () => void
  onBulkEdit?: () => void
  onBulkExport?: () => void
  className?: string
}

export function BulkOperations({
  selectedItems,
  totalItems,
  onSelectAll,
  onClearSelection,
  onBulkDelete,
  onBulkEdit,
  onBulkExport,
  className
}: BulkOperationsProps) {
  const [isExpanded, setIsExpanded] = useState(false)

  const selectedCount = selectedItems.length
  // const isAllSelected = selectedCount === totalItems && totalItems > 0
  const isPartiallySelected = selectedCount > 0 && selectedCount < totalItems

  useEffect(() => {
    if (selectedCount > 0) {
      setIsExpanded(true)
    } else {
      setIsExpanded(false)
    }
  }, [selectedCount])

  if (selectedCount === 0) {
    return null
  }

  return (
    <div className={cn(
      'fixed bottom-4 left-1/2 transform -translate-x-1/2 z-50 transition-all duration-300',
      isExpanded ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4 pointer-events-none',
      className
    )}>
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 p-4">
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <span className="text-sm font-medium text-gray-900 dark:text-white">
              {selectedCount} selected
            </span>
            {isPartiallySelected && (
              <button
                onClick={onSelectAll}
                className="text-sm text-fortaleza-blue hover:text-blue-700 dark:text-fortaleza-gold dark:hover:text-yellow-600"
              >
                Select all {totalItems}
              </button>
            )}
          </div>

          <div className="flex items-center space-x-2">
            {onBulkEdit && (
              <Button
                size="sm"
                variant="outline"
                leftIcon={<PencilIcon className="w-4 h-4" />}
                onClick={onBulkEdit}
              >
                Edit
              </Button>
            )}

            {onBulkExport && (
              <Button
                size="sm"
                variant="outline"
                onClick={onBulkExport}
              >
                Export
              </Button>
            )}

            {onBulkDelete && (
              <Button
                size="sm"
                variant="danger"
                leftIcon={<TrashIcon className="w-4 h-4" />}
                onClick={onBulkDelete}
              >
                Delete
              </Button>
            )}

            <Button
              size="sm"
              variant="ghost"
              onClick={onClearSelection}
            >
              <XMarkIcon className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}

// Bulk selection checkbox
interface BulkSelectCheckboxProps {
  checked: boolean
  indeterminate?: boolean
  onChange: (checked: boolean) => void
  className?: string
}

export function BulkSelectCheckbox({ checked, indeterminate, onChange, className }: BulkSelectCheckboxProps) {
  return (
    <input
      type="checkbox"
      checked={checked}
      ref={(el) => {
        if (el) el.indeterminate = indeterminate || false
      }}
      onChange={(e) => onChange(e.target.checked)}
      className={cn(
        'h-4 w-4 text-fortaleza-blue focus:ring-fortaleza-blue border-gray-300 dark:border-gray-600 rounded',
        className
      )}
    />
  )
}

// Bulk actions toolbar
interface BulkActionsToolbarProps {
  selectedItems: string[]
  onSelectAll: () => void
  onClearSelection: () => void
  actions: Array<{
    label: string
    icon?: React.ReactNode
    onClick: () => void
    variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger'
    disabled?: boolean
  }>
  className?: string
}

export function BulkActionsToolbar({
  selectedItems,
  onSelectAll,
  onClearSelection,
  actions,
  className
}: BulkActionsToolbarProps) {
  const selectedCount = selectedItems.length

  if (selectedCount === 0) {
    return null
  }

  return (
    <div className={cn(
      'bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-4',
      className
    )}>
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <span className="text-sm font-medium text-blue-900 dark:text-blue-100">
            {selectedCount} item{selectedCount !== 1 ? 's' : ''} selected
          </span>
          <button
            onClick={onSelectAll}
            className="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-200"
          >
            Select all
          </button>
        </div>

        <div className="flex items-center space-x-2">
          {actions.map((action, index) => (
            <Button
              key={index}
              size="sm"
              variant={action.variant || 'outline'}
              leftIcon={action.icon}
              onClick={action.onClick}
              disabled={action.disabled}
            >
              {action.label}
            </Button>
          ))}
          <Button
            size="sm"
            variant="ghost"
            onClick={onClearSelection}
          >
            Cancel
          </Button>
        </div>
      </div>
    </div>
  )
}

// Bulk edit modal
interface BulkEditModalProps {
  isOpen: boolean
  onClose: () => void
  selectedItems: string[]
  fields: Array<{
    name: string
    label: string
    type: 'text' | 'select' | 'checkbox'
    options?: Array<{ value: string; label: string }>
  }>
  onSave: (data: Record<string, any>) => void
}

export function BulkEditModal({ isOpen, onClose, selectedItems, fields, onSave }: BulkEditModalProps) {
  const [formData, setFormData] = useState<Record<string, any>>({})

  const handleSave = () => {
    onSave(formData)
    onClose()
    setFormData({})
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
        <div className="relative bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-md w-full p-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Bulk Edit {selectedItems.length} Items
          </h3>

          <div className="space-y-4">
            {fields.map((field) => (
              <div key={field.name}>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  {field.label}
                </label>
                {field.type === 'text' && (
                  <input
                    type="text"
                    value={formData[field.name] || ''}
                    onChange={(e) => setFormData(prev => ({ ...prev, [field.name]: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  />
                )}
                {field.type === 'select' && (
                  <select
                    value={formData[field.name] || ''}
                    onChange={(e) => setFormData(prev => ({ ...prev, [field.name]: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  >
                    <option value="">No change</option>
                    {field.options?.map((option) => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                )}
                {field.type === 'checkbox' && (
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={formData[field.name] || false}
                      onChange={(e) => setFormData(prev => ({ ...prev, [field.name]: e.target.checked }))}
                      className="h-4 w-4 text-fortaleza-blue focus:ring-fortaleza-blue border-gray-300 dark:border-gray-600 rounded"
                    />
                    <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                      Apply to all selected items
                    </span>
                  </label>
                )}
              </div>
            ))}
          </div>

          <div className="flex justify-end space-x-3 mt-6">
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button onClick={handleSave}>
              Save Changes
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
