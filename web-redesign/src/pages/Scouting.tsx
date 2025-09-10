import { useState, useEffect } from 'react'
import { 
  EyeIcon, 
  PlusIcon, 
  MagnifyingGlassIcon,
  FunnelIcon,
  ChartBarIcon,
  UserGroupIcon,
  DocumentTextIcon,
  CalendarDaysIcon
} from '@heroicons/react/24/outline'
import { ScoutingLoading } from '../components/ui/LoadingStates'
import { ScoutingBreadcrumb } from '../components/ui/Breadcrumb'

interface ScoutingReport {
  id: number
  opponent: string
  date: string
  status: 'DRAFT' | 'COMPLETED' | 'REVIEWED'
  priority: 'HIGH' | 'MEDIUM' | 'LOW'
  lastUpdated: string
  createdBy: string
  notes: string
  keyPlayers: Array<{
    name: string
    position: string
    strengths: string[]
    weaknesses: string[]
  }>
  teamTendencies: {
    offense: string[]
    defense: string[]
    specialSituations: string[]
  }
}

export function Scouting() {
  const [isLoading, setIsLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'reports' | 'opponents' | 'analytics'>('reports')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [searchValue, setSearchValue] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [priorityFilter, setPriorityFilter] = useState('')
  const [showFilters, setShowFilters] = useState(false)

  // Sample data - replace with real API calls
  const [reports] = useState<ScoutingReport[]>([
    {
      id: 1,
      opponent: 'Lakers',
      date: '2024-01-15',
      status: 'COMPLETED',
      priority: 'HIGH',
      lastUpdated: '2024-01-10',
      createdBy: 'Coach Smith',
      notes: 'Strong perimeter shooting team with excellent ball movement.',
      keyPlayers: [
        {
          name: 'LeBron James',
          position: 'SF',
          strengths: ['Leadership', 'Versatility', 'Basketball IQ'],
          weaknesses: ['Age', 'Defensive consistency']
        },
        {
          name: 'Anthony Davis',
          position: 'PF',
          strengths: ['Shot blocking', 'Post scoring', 'Rebounding'],
          weaknesses: ['Injury prone', 'Free throw shooting']
        }
      ],
      teamTendencies: {
        offense: ['Pick and roll', 'Fast break', 'Three-point shooting'],
        defense: ['Zone defense', 'Full court press'],
        specialSituations: ['Late game execution', 'Free throw shooting']
      }
    },
    {
      id: 2,
      opponent: 'Warriors',
      date: '2024-01-20',
      status: 'DRAFT',
      priority: 'MEDIUM',
      lastUpdated: '2024-01-12',
      createdBy: 'Assistant Coach',
      notes: 'High-paced offense with excellent three-point shooting.',
      keyPlayers: [
        {
          name: 'Stephen Curry',
          position: 'PG',
          strengths: ['Three-point shooting', 'Ball handling', 'Leadership'],
          weaknesses: ['Size', 'Defensive matchups']
        }
      ],
      teamTendencies: {
        offense: ['Three-point shooting', 'Ball movement', 'Fast pace'],
        defense: ['Switch everything', 'Help defense'],
        specialSituations: ['Clutch shooting', 'Timeout execution']
      }
    }
  ])

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsLoading(false)
    }, 1000)
    return () => clearTimeout(timer)
  }, [])

  const getFilteredReports = () => {
    return reports.filter(report => {
      if (searchValue && !report.opponent.toLowerCase().includes(searchValue.toLowerCase())) {
        return false
      }
      if (statusFilter && report.status !== statusFilter) {
        return false
      }
      if (priorityFilter && report.priority !== priorityFilter) {
        return false
      }
      return true
    })
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'COMPLETED':
        return 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300'
      case 'DRAFT':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-300'
      case 'REVIEWED':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/50 dark:text-gray-300'
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'HIGH':
        return 'bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-300'
      case 'MEDIUM':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-300'
      case 'LOW':
        return 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/50 dark:text-gray-300'
    }
  }

  if (isLoading) {
    return <ScoutingLoading />
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      {/* Breadcrumb */}
      <div className="mb-6">
        <ScoutingBreadcrumb />
      </div>

      {/* Page Header */}
      <div className="mb-8">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Scouting</h1>
            <p className="mt-2 text-gray-600 dark:text-gray-400">Manage scouting reports and opponent analysis.</p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {activeTab === 'reports' && `${getFilteredReports().length} reports`}
              {activeTab === 'opponents' && 'Opponent analysis'}
              {activeTab === 'analytics' && 'Scouting analytics'}
            </p>
          </div>
          <div className="flex items-center space-x-3 mt-4 sm:mt-0">
            <button className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center space-x-2">
              <PlusIcon className="w-5 h-5" />
              <span>New Report</span>
            </button>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="border-b border-gray-200 dark:border-gray-700">
          <nav className="-mb-px flex space-x-8">
            {[
              { id: 'reports', name: 'Reports', icon: DocumentTextIcon },
              { id: 'opponents', name: 'Opponents', icon: UserGroupIcon },
              { id: 'analytics', name: 'Analytics', icon: ChartBarIcon }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center space-x-2 py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                }`}
              >
                <tab.icon className="w-4 h-4" />
                <span>{tab.name}</span>
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Tab Content */}
      {activeTab === 'reports' && (
        <div className="space-y-6">
          {/* Controls */}
          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between space-y-4 lg:space-y-0">
            <div className="flex flex-col sm:flex-row sm:items-center space-y-3 sm:space-y-0 sm:space-x-4">
              <div className="relative">
                <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search reports..."
                  value={searchValue}
                  onChange={(e) => setSearchValue(e.target.value)}
                  className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                />
              </div>
              
              <button
                onClick={() => setShowFilters(!showFilters)}
                className={`flex items-center space-x-2 px-4 py-2 rounded-lg border transition-colors ${
                  showFilters 
                    ? 'bg-blue-50 border-blue-200 text-blue-700 dark:bg-blue-900/50 dark:border-blue-700 dark:text-blue-300'
                    : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600'
                }`}
              >
                <FunnelIcon className="w-4 h-4" />
                <span>Filters</span>
              </button>
            </div>

            <div className="flex items-center space-x-4">
              {/* View Mode Toggle */}
              <div className="flex items-center bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
                <button
                  onClick={() => setViewMode('grid')}
                  className={`p-2 rounded-md transition-colors ${
                    viewMode === 'grid' 
                      ? 'bg-white dark:bg-gray-600 shadow-sm' 
                      : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                  }`}
                >
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M5 3a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2V5a2 2 0 00-2-2H5zM5 11a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2v-2a2 2 0 00-2-2H5zM11 5a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V5zM11 13a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                  </svg>
                </button>
                <button
                  onClick={() => setViewMode('list')}
                  className={`p-2 rounded-md transition-colors ${
                    viewMode === 'list' 
                      ? 'bg-white dark:bg-gray-600 shadow-sm' 
                      : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                  }`}
                >
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clipRule="evenodd" />
                  </svg>
                </button>
              </div>
            </div>
          </div>

          {/* Filters Panel */}
          {showFilters && (
            <div className="p-4 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600">
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Status</label>
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-600 dark:border-gray-500 dark:text-white"
                  >
                    <option value="">All Status</option>
                    <option value="DRAFT">Draft</option>
                    <option value="COMPLETED">Completed</option>
                    <option value="REVIEWED">Reviewed</option>
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Priority</label>
                  <select
                    value={priorityFilter}
                    onChange={(e) => setPriorityFilter(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-600 dark:border-gray-500 dark:text-white"
                  >
                    <option value="">All Priorities</option>
                    <option value="HIGH">High</option>
                    <option value="MEDIUM">Medium</option>
                    <option value="LOW">Low</option>
                  </select>
                </div>
                
                <div className="flex items-end">
                  <button
                    onClick={() => {
                      setSearchValue('')
                      setStatusFilter('')
                      setPriorityFilter('')
                    }}
                    className="w-full px-4 py-2 bg-gray-200 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded-md hover:bg-gray-300 dark:hover:bg-gray-500 transition-colors text-sm"
                  >
                    Clear Filters
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Reports Grid/List */}
          {viewMode === 'grid' ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {getFilteredReports().map((report) => (
                <div key={report.id} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1">
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{report.opponent}</h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400">Game: {new Date(report.date).toLocaleDateString()}</p>
                    </div>
                    <div className="flex space-x-2">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(report.status)}`}>
                        {report.status}
                      </span>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(report.priority)}`}>
                        {report.priority}
                      </span>
                    </div>
                  </div>
                  
                  <p className="text-sm text-gray-600 dark:text-gray-400 mb-4 line-clamp-2">{report.notes}</p>
                  
                  <div className="space-y-2 mb-4">
                    <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
                      <UserGroupIcon className="w-4 h-4 mr-2" />
                      <span>{report.keyPlayers.length} key players</span>
                    </div>
                    <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
                      <CalendarDaysIcon className="w-4 h-4 mr-2" />
                      <span>Updated: {new Date(report.lastUpdated).toLocaleDateString()}</span>
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500 dark:text-gray-400">By {report.createdBy}</span>
                    <button className="flex items-center space-x-1 text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 transition-colors">
                      <EyeIcon className="w-4 h-4" />
                      <span className="text-sm">View</span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                  <thead className="bg-gray-50 dark:bg-gray-700">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Opponent</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Game Date</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Status</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Priority</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Created By</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                    {getFilteredReports().map((report) => (
                      <tr key={report.id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-gray-900 dark:text-white">{report.opponent}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                          {new Date(report.date).toLocaleDateString()}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(report.status)}`}>
                            {report.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(report.priority)}`}>
                            {report.priority}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                          {report.createdBy}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button className="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 transition-colors">
                            View
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {activeTab === 'opponents' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-8">
            <div className="text-center">
              <UserGroupIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">Opponent Analysis</h3>
              <p className="text-gray-600 dark:text-gray-400 mb-4">Detailed opponent analysis and team tendencies.</p>
              <button className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
                Analyze Opponent
              </button>
            </div>
          </div>
        </div>
      )}

      {activeTab === 'analytics' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-8">
            <div className="text-center">
              <ChartBarIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">Scouting Analytics</h3>
              <p className="text-gray-600 dark:text-gray-400 mb-4">Advanced analytics and insights from scouting data.</p>
              <button className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
                View Analytics
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
