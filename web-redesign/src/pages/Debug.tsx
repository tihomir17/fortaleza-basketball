import { useState, useEffect } from 'react'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Badge } from '../components/ui/Badge'

interface SystemInfo {
  userAgent: string
  platform: string
  language: string
  cookieEnabled: boolean
  onLine: boolean
  screenResolution: string
  timezone: string
  localStorage: boolean
  sessionStorage: boolean
}

interface ApiStatus {
  backend: 'connected' | 'disconnected' | 'checking'
  lastCheck: Date | null
  responseTime: number | null
}

export function Debug() {
  const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null)
  const [apiStatus, setApiStatus] = useState<ApiStatus>({
    backend: 'checking',
    lastCheck: null,
    responseTime: null
  })
  const [logs, setLogs] = useState<string[]>([])

  useEffect(() => {
    // Gather system information
    const info: SystemInfo = {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      language: navigator.language,
      cookieEnabled: navigator.cookieEnabled,
      onLine: navigator.onLine,
      screenResolution: `${screen.width}x${screen.height}`,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      localStorage: typeof Storage !== 'undefined',
      sessionStorage: typeof Storage !== 'undefined'
    }
    setSystemInfo(info)

    // Check API status
    checkApiStatus()

    // Add initial log
    addLog('Debug screen initialized')
  }, [])

  const checkApiStatus = async () => {
    const startTime = Date.now()
    setApiStatus(prev => ({ ...prev, backend: 'checking' }))
    
    try {
      const response = await fetch('/api/health', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      })
      
      const responseTime = Date.now() - startTime
      
      if (response.ok) {
        setApiStatus({
          backend: 'connected',
          lastCheck: new Date(),
          responseTime
        })
        addLog(`API check successful - ${responseTime}ms`)
      } else {
        setApiStatus({
          backend: 'disconnected',
          lastCheck: new Date(),
          responseTime
        })
        addLog(`API check failed - ${response.status} ${response.statusText}`)
      }
    } catch (error) {
      const responseTime = Date.now() - startTime
      setApiStatus({
        backend: 'disconnected',
        lastCheck: new Date(),
        responseTime
      })
      addLog(`API check error - ${error}`)
    }
  }

  const addLog = (message: string) => {
    const timestamp = new Date().toLocaleTimeString()
    setLogs(prev => [`[${timestamp}] ${message}`, ...prev.slice(0, 49)]) // Keep last 50 logs
  }

  const clearLogs = () => {
    setLogs([])
    addLog('Logs cleared')
  }

  const testLocalStorage = () => {
    try {
      localStorage.setItem('debug_test', 'test_value')
      const value = localStorage.getItem('debug_test')
      localStorage.removeItem('debug_test')
      addLog(`LocalStorage test: ${value === 'test_value' ? 'PASS' : 'FAIL'}`)
    } catch (error) {
      addLog(`LocalStorage test: FAIL - ${error}`)
    }
  }

  const testSessionStorage = () => {
    try {
      sessionStorage.setItem('debug_test', 'test_value')
      const value = sessionStorage.getItem('debug_test')
      sessionStorage.removeItem('debug_test')
      addLog(`SessionStorage test: ${value === 'test_value' ? 'PASS' : 'FAIL'}`)
    } catch (error) {
      addLog(`SessionStorage test: FAIL - ${error}`)
    }
  }

  const exportLogs = () => {
    const logContent = logs.join('\n')
    const blob = new Blob([logContent], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `debug-logs-${new Date().toISOString().slice(0, 19)}.txt`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    addLog('Logs exported')
  }

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Debug Information</h1>
        <p className="text-gray-600">System information and debugging tools</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* System Information */}
        <Card>
          <div className="p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">System Information</h2>
            {systemInfo && (
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">User Agent:</span>
                  <span className="text-sm font-mono text-gray-900 max-w-xs truncate" title={systemInfo.userAgent}>
                    {systemInfo.userAgent}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Platform:</span>
                  <span className="text-sm text-gray-900">{systemInfo.platform}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Language:</span>
                  <span className="text-sm text-gray-900">{systemInfo.language}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Cookies:</span>
                  <Badge variant={systemInfo.cookieEnabled ? 'success' : 'error'}>
                    {systemInfo.cookieEnabled ? 'Enabled' : 'Disabled'}
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Online:</span>
                  <Badge variant={systemInfo.onLine ? 'success' : 'error'}>
                    {systemInfo.onLine ? 'Online' : 'Offline'}
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Screen:</span>
                  <span className="text-sm text-gray-900">{systemInfo.screenResolution}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Timezone:</span>
                  <span className="text-sm text-gray-900">{systemInfo.timezone}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">LocalStorage:</span>
                  <Badge variant={systemInfo.localStorage ? 'success' : 'error'}>
                    {systemInfo.localStorage ? 'Available' : 'Unavailable'}
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">SessionStorage:</span>
                  <Badge variant={systemInfo.sessionStorage ? 'success' : 'error'}>
                    {systemInfo.sessionStorage ? 'Available' : 'Unavailable'}
                  </Badge>
                </div>
              </div>
            )}
          </div>
        </Card>

        {/* API Status */}
        <Card>
          <div className="p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">API Status</h2>
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Backend:</span>
                <div className="flex items-center space-x-2">
                  <Badge 
                    variant={
                      apiStatus.backend === 'connected' ? 'success' : 
                      apiStatus.backend === 'checking' ? 'warning' : 'error'
                    }
                  >
                    {apiStatus.backend === 'checking' ? 'Checking...' : 
                     apiStatus.backend === 'connected' ? 'Connected' : 'Disconnected'}
                  </Badge>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={checkApiStatus}
                    disabled={apiStatus.backend === 'checking'}
                  >
                    Refresh
                  </Button>
                </div>
              </div>
              {apiStatus.lastCheck && (
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Last Check:</span>
                  <span className="text-sm text-gray-900">
                    {apiStatus.lastCheck.toLocaleTimeString()}
                  </span>
                </div>
              )}
              {apiStatus.responseTime && (
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Response Time:</span>
                  <span className="text-sm text-gray-900">{apiStatus.responseTime}ms</span>
                </div>
              )}
            </div>
          </div>
        </Card>
      </div>

      {/* Debug Tools */}
      <Card>
        <div className="p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Debug Tools</h2>
          <div className="flex flex-wrap gap-3">
            <Button onClick={testLocalStorage} variant="outline">
              Test LocalStorage
            </Button>
            <Button onClick={testSessionStorage} variant="outline">
              Test SessionStorage
            </Button>
            <Button onClick={checkApiStatus} variant="outline">
              Test API Connection
            </Button>
            <Button onClick={exportLogs} variant="outline">
              Export Logs
            </Button>
            <Button onClick={clearLogs} variant="outline">
              Clear Logs
            </Button>
          </div>
        </div>
      </Card>

      {/* Debug Logs */}
      <Card>
        <div className="p-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-gray-900">Debug Logs</h2>
            <span className="text-sm text-gray-500">{logs.length} entries</span>
          </div>
          <div className="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm max-h-96 overflow-y-auto">
            {logs.length === 0 ? (
              <div className="text-gray-500">No logs yet...</div>
            ) : (
              logs.map((log, index) => (
                <div key={index} className="mb-1">
                  {log}
                </div>
              ))
            )}
          </div>
        </div>
      </Card>
    </div>
  )
}
